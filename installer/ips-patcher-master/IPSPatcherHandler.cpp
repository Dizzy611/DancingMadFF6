/*
 * IPS Patcher - implementation
 *
 * Sam Elsharif 2012
 *
 */
#include "IPSPatcherHandler.h"
//#include "stdafx.h"
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>

#include <iostream>
#include <fstream>

using namespace std;

#define HEADER_SIZE 5
#define RECORD_OFFSET_BYTE_COUNT 3
#define RECORD_SIZE_BYTE_COUNT 2
#define RECORD_RLE_SIZE_BYTE_COUNT 2
#define IPS_TRUNCATE_BYTE_COUNT 3

#define BYTE3_TO_UINT(bp) \
     (((unsigned int)(bp)[0] << 16) & 0x00FF0000) | \
     (((unsigned int)(bp)[1] << 8) & 0x0000FF00) | \
     ((unsigned int)(bp)[2] & 0x000000FF)

#define BYTE2_TO_UINT(bp) \
    (((unsigned int)(bp)[0] << 8) & 0xFF00) | \
    ((unsigned int) (bp)[1] & 0x00FF)

#define MINIMUM_IPS_SIZE 8
#define MAXIMUM_IPS_SIZE 16777216
#define MAXIMUM_SOURCE_SIZE 16777216

IPSPatcherHandler::IPSPatcherHandler()
{
	m_ipsFileData = NULL;
	m_sourceROMCurrentData = NULL;
}

IPSPatcherHandler::~IPSPatcherHandler()
{
	if( m_ipsFileData != NULL )
	{
		delete [] m_ipsFileData;
	}

	if( m_sourceROMCurrentData != NULL )
	{
		delete [] m_sourceROMCurrentData;
	}
}

int IPSPatcherHandler::applyPatch( const char *ipsFile, const char *sourceFile, const char *targetFile )
{
	//error checking
	if( ipsFile == NULL )
	{
		return PATCH_EMPTY_IPS_FILE_ARG;
	}

	if( sourceFile == NULL )
	{
		return PATCH_EMPTY_SOURCE_FILE_ARG;
	}

	//read IPS file into a buffer
	char *ipsFileData = NULL;
	unsigned int ipsFileLength = getFileData( ipsFile, &ipsFileData );

	if( ipsFileLength == 0 )
	{
		return PATCH_IPS_FILE_NOT_FOUND;
	}
	else if( ipsFileLength < MINIMUM_IPS_SIZE || ipsFileLength > MAXIMUM_IPS_SIZE )
	{
		return PATCH_INVALID_IPS_FILE;
	}

	//remember this location - need to delete the memory later
	m_ipsFileData = ipsFileData;

	//read source ROM into a buffer
	char *sourceROMCurrentData = NULL;
	unsigned int sourceROMCurrentLength = getFileData( sourceFile, &sourceROMCurrentData );

	m_sourceROMCurrentData = sourceROMCurrentData;

	if( sourceROMCurrentLength == 0 )
	{
		return PATCH_SOURCE_FILE_NOT_FOUND;
	}
	else if( sourceROMCurrentLength > MAXIMUM_SOURCE_SIZE )
	{
		return PATCH_SOURCE_TOO_BIG;
	}

	if( ipsFileData[0] != 'P' || ipsFileData[1] != 'A' || ipsFileData[2] != 'T'
		|| ipsFileData[3] != 'C' || ipsFileData[4] != 'H' )
	{
		return PATCH_INVALID_IPS_FILE;
	}

    int done = false;
	ipsFileData += HEADER_SIZE;

	while( !done )
	{
		//read the offset
		if( ipsFileData[0] == 'E' && ipsFileData[1] == 'O' && ipsFileData[2] == 'F' )
		{
			ipsFileData += RECORD_OFFSET_BYTE_COUNT;
            done = true;
		}
		else
		{
			unsigned int recordOffsetValue = BYTE3_TO_UINT( ipsFileData );

			ipsFileData += RECORD_OFFSET_BYTE_COUNT;

			//read the size
			unsigned int recordSizeValue = BYTE2_TO_UINT( ipsFileData );

			ipsFileData += RECORD_SIZE_BYTE_COUNT;

			if( recordSizeValue == 0 )
			{
				//RLE case
				unsigned int rleSizeValue = BYTE2_TO_UINT( ipsFileData );

				//test if the offset and size are within the current target
				unsigned offsetDataSize = recordOffsetValue + rleSizeValue;
				if( offsetDataSize > sourceROMCurrentLength )
				{
					//regenerate memory for the target
					sourceROMCurrentData = resizeBuffer( sourceROMCurrentData, sourceROMCurrentLength, offsetDataSize );
					m_sourceROMCurrentData = sourceROMCurrentData;
					sourceROMCurrentLength = offsetDataSize;
				}

				ipsFileData += RECORD_RLE_SIZE_BYTE_COUNT;

				memset( &(sourceROMCurrentData[recordOffsetValue]), ipsFileData[0], rleSizeValue );

				ipsFileData++;
			}
			else
			{
				//test if the offset and size are within the current target
				unsigned offsetDataSize = recordOffsetValue + recordSizeValue;
				if( offsetDataSize > sourceROMCurrentLength )
				{
					//regenerate memory for the target
					sourceROMCurrentData = resizeBuffer( sourceROMCurrentData, sourceROMCurrentLength, offsetDataSize );
					m_sourceROMCurrentData = sourceROMCurrentData;
					sourceROMCurrentLength = offsetDataSize;
				}

				//now read the record data from the patch and copy it to the target ROM buffer
				memcpy( &(sourceROMCurrentData[recordOffsetValue]), ipsFileData, recordSizeValue );

				ipsFileData += recordSizeValue;
			}
		}
	}

	//check if we need to truncate - ignore any data other than 3 bytes
	unsigned int truncateDataLength = ipsFileLength - (ipsFileData - m_ipsFileData);

	if( truncateDataLength == IPS_TRUNCATE_BYTE_COUNT )
	{
		unsigned int targetROMTruncatedSize = BYTE3_TO_UINT( ipsFileData );

		if( targetROMTruncatedSize > 0 && targetROMTruncatedSize < sourceROMCurrentLength )
		{
			sourceROMCurrentLength = targetROMTruncatedSize;
		}
	}

	//write the patched data to the target ROM

	//determine if the same source will be patched directly or a new file be generated
    const char *realTargetFile;
	if( targetFile == NULL )
	{
		realTargetFile = sourceFile;
	}
	else
	{
		realTargetFile = targetFile;
	}

	ofstream targetROM;
	targetROM.open( realTargetFile, ios::binary | ios::trunc );
	if ( targetROM.is_open() == 0 )
	{
		return PATCH_TARGET_FILE_CANNOT_OPEN;
	}

	targetROM.seekp( 0 );
	targetROM.write( sourceROMCurrentData, sourceROMCurrentLength );

	targetROM.close();

	return PATCH_APPLY_SUCCESS;
}

unsigned int IPSPatcherHandler::getFileData( const char *fileName, char **fileData )
{
	ifstream file;
	file.open( fileName, ios::binary | ios::in );
	if ( file.is_open() == 0 )
	{
		return 0;
	}

	//copy contents of target to an array
	file.seekg( 0, ios::end );
	unsigned int fileLength = file.tellg();
	file.seekg( 0, ios::beg );

	*fileData = new char[fileLength];
	file.read( *fileData, fileLength );

	file.close();

	return fileLength;
}

char* IPSPatcherHandler::resizeBuffer( const char *oldBuffer, unsigned oldSize, unsigned int newSize )
{
		char *newDataBuffer = new char[newSize];

		memcpy( newDataBuffer, oldBuffer, oldSize );

		delete [] oldBuffer;

		return newDataBuffer;
}
