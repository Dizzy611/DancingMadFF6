/*
 * IPS Patcher
 *
 * Sam Elsharif 2012
 *
 */
#pragma once

#define PATCH_APPLY_SUCCESS	0
#define PATCH_IPS_FILE_NOT_FOUND	2
#define PATCH_INVALID_IPS_FILE	3
#define PATCH_SOURCE_FILE_NOT_FOUND	4
#define PATCH_SOURCE_TOO_BIG	5
#define PATCH_TARGET_FILE_CANNOT_OPEN	6
#define PATCH_EMPTY_IPS_FILE_ARG	20
#define PATCH_EMPTY_SOURCE_FILE_ARG	21


class IPSPatcherHandler
{
public:
	IPSPatcherHandler();
	virtual ~IPSPatcherHandler();

    int applyPatch( const char *ipsFile, const char *sourceFile, const char *targetFile );

private:
	char *m_ipsFileData;
	char *m_sourceROMCurrentData;

	unsigned int getFileData( const char *fileName, char **fileData );
	char* resizeBuffer( const char *oldBuffer, unsigned oldSize, unsigned int newSize );
};
