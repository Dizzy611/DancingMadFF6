//Module name: libbps
//Author: Alcaro
//Date: February 6, 2013
//Licence: GPL v3.0 or higher

#include "libbps.h"

#include <stdlib.h>//malloc, realloc, free
#include <string.h>//memcpy, memset

#define byte unsigned char
#define uint size_t
#define uint_max SIZE_MAX

static unsigned int crc32_table[256];
//0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
//0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
//0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
//0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
//0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
//0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
//0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
//0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
//0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
//0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
//0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
//0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
//0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
//0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
//0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
//0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
//0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
//0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
//0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
//0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
//0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
//0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
//0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
//0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
//0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
//0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
//0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
//0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
//0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
//0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
//0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
//0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D

static void make_crc32_table()
{
	for (int n=0;n<256;n++)
	{
		unsigned int c=n;
		for (int k=0;k<8;k++)
		{
			if (c&1) c=0xedb88320L^(c>>1);
			else c>>=1;
		}
		crc32_table[n]=c;
	}
}
#define crc32(old, byte) (((old)>>8)^(crc32_table[((old)&0xFF)^(byte)]))

enum { SourceRead, TargetRead, SourceCopy, TargetCopy };

#define error(which) do { error=which; goto exit; } while(0)
#define assert_sum(a,b) do { if (uint_max-(a)<(b)) error(bps_too_big); } while(0)
#define assert_shift(a,b) do { if (uint_max>>(b)<(a)) error(bps_too_big); } while(0)
enum bpserror bps_apply(struct mem patch, struct mem in, struct mem * out, struct mem * metadata)
{
	make_crc32_table();
	enum bpserror error;
	out->len=0;
	out->ptr=NULL;
	if (metadata)
	{
		metadata->len=0;
		metadata->ptr=NULL;
	}
	if (patch.len<4+3+12) return bps_broken;
	
	if (true)
	{
		byte tmpbyte;
#define read8() (crc_patch=crc32(crc_patch,*patchat),*(patchat++))
#define decodeto(var) \
				do { \
					var=0; \
					unsigned int shift=0; \
					while (true) \
					{ \
						byte next=read8(); \
						assert_shift(next&0x7F, shift); \
						uint addthis=(next&0x7F)<<shift; \
						assert_sum(var, addthis); \
						var+=addthis; \
						if (next&0x80) break; \
						shift+=7; \
						assert_sum(var, 1U<<shift); \
						var+=1<<shift; \
					} \
				} while(false)
#define write8(byte) (tmpbyte=byte,crc_out=crc32(crc_out,tmpbyte),*(outat++)=tmpbyte)
		unsigned int crc_out=~0;
		unsigned int crc_patch=~0;
		
		byte * patchat=patch.ptr;
		byte * patchend=patch.ptr+patch.len-12;
		
		if (read8()!='B') error(bps_broken);
		if (read8()!='P') error(bps_broken);
		if (read8()!='S') error(bps_broken);
		if (read8()!='1') error(bps_broken);
		
		uint inlen;
		decodeto(inlen);
		if (inlen!=in.len) error(bps_not_this);
		
		uint outlen;
		decodeto(outlen);
		out->len=outlen;
		out->ptr=(byte*)malloc(outlen);
		
		byte * instart=in.ptr;
		byte * inreadat=in.ptr;
		byte * inend=in.ptr+in.len;
		
		byte * outstart=out->ptr;
		byte * outreadat=out->ptr;
		byte * outat=out->ptr;
		byte * outend=out->ptr+out->len;
		
		uint metadatalen;
		decodeto(metadatalen);
		
		if (metadata && metadatalen)
		{
			metadata->len=metadatalen;
			metadata->ptr=(byte*)malloc(metadatalen+1);
			for (uint i=0;i<metadatalen;i++) metadata->ptr[i]=read8();
			metadata->ptr[metadatalen]='\0';//just to be on the safe side - that metadata is assumed to be text, might as well terminate it
		}
		else
		{
			for (uint i=0;i<metadatalen;i++) (void)read8();
		}
		
		while (patchat<patchend)
		{
			uint thisinstr;
			decodeto(thisinstr);
			uint length=(thisinstr>>2)+1;
			int action=(thisinstr&3);
			if (outat+length>outend) error(bps_broken);
			
			switch (action)
			{
				case SourceRead:
				{
					for (uint i=0;i<length;i++) write8(outat[instart-outstart]);
				}
				break;
				case TargetRead:
				{
					if (patchat+length>patchend) error(bps_broken);
					for (uint i=0;i<length;i++) write8(read8());
				}
				break;
				case SourceCopy:
				case TargetCopy:
				{
					byte* * thepointer=((action==2)?&inreadat:&outreadat);
					uint encodeddistance;
					decodeto(encodeddistance);
					uint distance=encodeddistance>>1;
					if ((encodeddistance&1)==0) *thepointer+=distance;
					else *thepointer-=distance;
					if (action==SourceCopy)
					{
						if (inreadat<instart || inreadat+length>inend) error(bps_broken);
					}
					else
					{
						if (outreadat<outstart || outreadat>=outend || outreadat+length>outend) error(bps_broken);
					}
					for (uint i=0;i<length;i++) write8(*(*thepointer)++);
				}
				break;
			}
		}
		if (patchat!=patchend) error(bps_broken);
		if (outat!=outend) error(bps_broken);
		unsigned int crc_in_expected=read8(); crc_in_expected|=read8()<<8; crc_in_expected|=read8()<<16; crc_in_expected|=read8()<<24;
		unsigned int crc_out_expected=read8(); crc_out_expected|=read8()<<8; crc_out_expected|=read8()<<16; crc_out_expected|=read8()<<24;
		unsigned int crc_patch_expected=(patchat[0]<<0)|(patchat[1]<<8)|(patchat[2]<<16)|(patchat[3]<<24);
		
		unsigned int crc_in=~0;
		for (byte * i=instart;i<inend;i++) crc_in=crc32(crc_in, *i);
		crc_in=~crc_in;
		if (crc_in!=crc_in_expected) error(bps_not_this);
		
		crc_out=~crc_out;
		crc_patch=~crc_patch;
		if (crc_out!=crc_out_expected) error(bps_not_this);
		if (crc_patch!=crc_patch_expected) error(bps_broken);
		return bps_ok;
#undef read8
#undef decodeto
#undef write8
	}
	
exit:
	free(out->ptr);
	out->len=0;
	out->ptr=NULL;
	if (metadata)
	{
		free(metadata->ptr);
		metadata->len=0;
		metadata->ptr=NULL;
	}
	return error;
}

#define write_nocrc(val) \
			do { \
				out[outlen++]=(val); \
				if (outlen==outbuflen) \
				{ \
					outbuflen*=2; \
					out=(byte*)realloc(out, outbuflen); \
				} \
			} while(0)
#define write(val) \
			do { \
				byte tmpbyte2=(val); \
				crc_patch=crc32(crc_patch, tmpbyte2); \
				write_nocrc(tmpbyte2); \
			} while(0)
#define writenum(val) \
			do { \
				uint tmpval=(val); \
				while (true) \
				{ \
					byte tmpbyte=(tmpval&0x7F); \
					tmpval>>=7; \
					if (!tmpval) \
					{ \
						write(tmpbyte|0x80); \
						break; \
					} \
					write(tmpbyte); \
					tmpval--; \
				} \
			} while(0)

enum bpserror bps_create_linear(struct mem sourcemem, struct mem targetmem, struct mem metadata, struct mem * patchmem)
{
	if (sourcemem.len>=(SIZE_MAX>>2) - 16) return bps_too_big;//the 16 is just to be on the safe side, I don't think it's needed.
	if (targetmem.len>=(SIZE_MAX>>2) - 16) return bps_too_big;
	
	make_crc32_table();
	unsigned int crc_patch=~0;
	
	//uint sourcelen=sourcemem.len;
	//byte * sourcebegin=sourcemem.ptr;
	byte * source=sourcemem.ptr;
	byte * sourceend=sourcemem.ptr+sourcemem.len;
	if (sourcemem.len>targetmem.len) sourceend=sourcemem.ptr+targetmem.len;
	//uint targetlen=targetmem.len;
	byte * targetbegin=targetmem.ptr;
	byte * target=targetmem.ptr;
	byte * targetend=targetmem.ptr+targetmem.len;
	
	byte * targetcopypos=targetbegin;
	
	unsigned int outbuflen=4096;
	unsigned char * out=(byte*)malloc(outbuflen);
	unsigned int outlen=0;
	write('B');
	write('P');
	write('S');
	write('1');
	writenum(sourcemem.len);
	writenum(targetmem.len);
	writenum(metadata.len);
	for (uint i=0;i<metadata.len;i++) write(metadata.ptr[i]);
	
	uint mainContentPos=outlen;
	
	byte * lastknownchange=targetbegin;
	while (target<targetend)
	{
		uint numunchanged=0;
		while (source+numunchanged<sourceend && source[numunchanged]==target[numunchanged]) numunchanged++;
		if (numunchanged>1)
		{
			//assert_shift((numunchanged-1), 2);
			writenum((numunchanged-1)<<2 | 0);//SourceRead
			source+=numunchanged;
			target+=numunchanged;
		}
		
		uint numchanged=0;
		if (lastknownchange>target) numchanged=lastknownchange-target;
		while ((source+numchanged>=sourceend ||
						source[numchanged]!=target[numchanged] ||
						source[numchanged+1]!=target[numchanged+1] ||
						source[numchanged+2]!=target[numchanged+2]) &&
					target+numchanged<targetend)
		{
			numchanged++;
			if (source+numchanged>=sourceend) numchanged=targetend-target;
		}
		lastknownchange=target+numchanged;
		if (numchanged)
		{
			//assert_shift((numchanged-1), 2);
			uint rle1start=(target==targetbegin);
			while (true)
			{
				if (
					target[rle1start-1]==target[rle1start+0] &&
					target[rle1start+0]==target[rle1start+1] &&
					target[rle1start+1]==target[rle1start+2] &&
					target[rle1start+2]==target[rle1start+3])
				{
					numchanged=rle1start;
					break;
				}
				if (
					target[rle1start-2]==target[rle1start+0] &&
					target[rle1start-1]==target[rle1start+1] &&
					target[rle1start+0]==target[rle1start+2] &&
					target[rle1start+1]==target[rle1start+3] &&
					target[rle1start+2]==target[rle1start+4])
				{
					numchanged=rle1start;
					break;
				}
				if (rle1start+3>=numchanged) break;
				rle1start++;
			}
			if (numchanged)
			{
				writenum((numchanged-1)<<2 | TargetRead);
				for (uint i=0;i<numchanged;i++)
				{
					write(target[i]);
				}
				source+=numchanged;
				target+=numchanged;
			}
			if (target[-2]==target[0] && target[-1]==target[1] && target[0]==target[2])
			{
				//two-byte RLE
				uint rlelen=0;
				while (target+rlelen<targetend && target[0]==target[rlelen+0] && target[1]==target[rlelen+1]) rlelen+=2;
				writenum((rlelen-1)<<2 | TargetCopy);
				writenum((target-targetcopypos-2)<<1);
				source+=rlelen;
				target+=rlelen;
				targetcopypos=target-2;
			}
			else if (target[-1]==target[0] && target[0]==target[1])
			{
				//one-byte RLE
				uint rlelen=0;
				while (target+rlelen<targetend && target[0]==target[rlelen]) rlelen++;
				writenum((rlelen-1)<<2 | TargetCopy);
				writenum((target-targetcopypos-1)<<1);
				source+=rlelen;
				target+=rlelen;
				targetcopypos=target-1;
			}
		}
	}
	
	if (true)
	{
		unsigned int crc_in=~0;
		for (byte * i=sourcemem.ptr;i<sourcemem.ptr+sourcemem.len;i++) crc_in=crc32(crc_in, *i);
		crc_in=~crc_in;
		write(crc_in); write(crc_in>>8); write(crc_in>>16); write(crc_in>>24);
		
		unsigned int crc_out=~0;
		for (byte * i=targetmem.ptr;i<targetmem.ptr+targetmem.len;i++) crc_out=crc32(crc_out, *i);
		crc_out=~crc_out;
		write(crc_out); write(crc_out>>8); write(crc_out>>16); write(crc_out>>24);
	}
	
	crc_patch=~crc_patch;
	write_nocrc(crc_patch);
	write_nocrc(crc_patch>>8);
	write_nocrc(crc_patch>>16);
	write_nocrc(crc_patch>>24);
	
	patchmem->ptr=out;
	patchmem->len=outlen;
	
	//while this may look like it can be fooled by a patch containing one of any other command, it
	//  can't, because the ones that aren't SourceRead requires an argument.
	uint i;
	for (i=mainContentPos;(out[i]&0x80)==0x00;i++) {}
	if (i==outlen-12-1) return bps_identical;
	
	return bps_ok;
	
//exit:
//	free(out);
//	patchmem->len=0;
//	patchmem->ptr=NULL;
//	return bps_too_big;
}

//static int cost(uint val)
//{
//	if (val<0x80) return 1;
//	if (val<0x80*0x80) return 2;
//	if (val<0x80*0x80*0x80) return 3;
//	if (val<0x80*0x80*0x80*0x80) return 4;
//	return 5;
//}

enum bpserror bps_create_delta(struct mem sourcemem, struct mem targetmem, struct mem metadata,
															 struct mem * patchmem, bool (* progress)(size_t done, size_t total))
{
	if (sourcemem.len>=(SIZE_MAX>>2) - 16) return bps_too_big;//the 16 is just to be on the safe side, I don't think it's needed.
	if (targetmem.len>=(SIZE_MAX>>2) - 16) return bps_too_big;
	
	make_crc32_table();
	
	unsigned int crc_patch=~0;
	
	unsigned int outbuflen=4096;
	unsigned char * out=(byte*)malloc(outbuflen);
	unsigned int outlen=0;
	write('B');
	write('P');
	write('S');
	write('1');
	writenum(sourcemem.len);
	writenum(targetmem.len);
	writenum(metadata.len);
	for (uint i=0;i<metadata.len;i++) write(metadata.ptr[i]);
	
	uint mainContentPos=outlen;
	
	uint * sourceTree[65536];
	uint sourceTreeLen[65536];
	uint sourceTreeMemLen[65536];
	
	uint * targetTree[65536];
	uint targetTreeLen[65536];
	uint targetTreeMemLen[65536];
	
	for (int i=0;i<65536;i++)
	{
		sourceTree[i]=(uint*)malloc(sizeof(uint)*16);
		sourceTreeLen[i]=0;
		sourceTreeMemLen[i]=16;
		
		targetTree[i]=(uint*)malloc(sizeof(uint)*16);
		targetTreeLen[i]=0;
		targetTreeMemLen[i]=16;
	}
	
	byte * source=sourcemem.ptr;
	uint sourcelen=sourcemem.len;
	
	byte * target=targetmem.ptr;
	uint targetlen=targetmem.len;
	uint targetpos=0;
	
	//source tree creation
	unsigned int crc_in=~0;
	for (uint offset=0;offset<sourcelen-1;offset++)
	{
		unsigned short int symbol=(source[offset+0]<<0) | (source[offset+1]<<8);
		crc_in=crc32(crc_in, symbol&0xFF);
		sourceTree[symbol][sourceTreeLen[symbol]++]=offset;
		if (sourceTreeLen[symbol]==sourceTreeMemLen[symbol])
		{
			sourceTreeMemLen[symbol]*=2;
			sourceTree[symbol]=(uint*)realloc(sourceTree[symbol], sourceTreeMemLen[symbol]*sizeof(uint));
		}
	}
	crc_in=crc32(crc_in, source[sourcelen-1]);
	
	uint targetReadLen=0;
	
	uint sourceCopyPos=0;
	uint targetCopyPos=0;
	
#define targetReadFlush() \
		if (targetReadLen) \
		{ \
			writenum((targetReadLen-1)<<2 | TargetRead); \
			for (uint i=0;i<targetReadLen;i++) \
			{ \
				write(target[targetpos-targetReadLen+i]); \
			} \
			targetReadLen=0; \
		}
	
	static int blockid=0;
	
	while (targetpos<targetlen)
	{
		uint bestMatchLen=0;
		char bestMatchType=0;
		uint bestMatchPos=0;
		uint bestMatchDist=0;
		
		if (targetpos==targetlen-1)
		{
			if (targetReadLen) targetReadLen++;//already targetReading = continue that
			else if (targetpos<sourcelen && source[targetpos]==target[targetpos])
			{
				//no need to flush targetRead; if we'd need that, the previous case would hit
				write(1<<2 | SourceRead);
			}
			else targetReadLen++;//can't sourceRead = targetRead
			targetpos++;
			break;
		}
		
		unsigned short int symbol=(target[targetpos+0]<<0) | (target[targetpos+1]<<8);
		
		{ //source read
			uint length=0;
			uint offset=targetpos;
			while (offset<sourcelen && offset<targetlen && source[offset]==target[offset])
			{
				length++;
				offset++;
			}
			if (length>bestMatchLen)
			{
				bestMatchLen=length;
				bestMatchType=SourceRead;
			}
		}
		
		{ //source copy
			uint * node=sourceTree[symbol];
			unsigned int nodelen=sourceTreeLen[symbol];
			if (nodelen)
			{
				for (unsigned int i=nodelen-1;i;i--)
				{
					uint length=2;
					uint x=node[i]+2;
					uint y=targetpos+2;
					while (x<sourcelen && y<targetlen && source[x++]==target[y++]) length++;
					uint dist=(node[i]>sourceCopyPos)?(node[i]-sourceCopyPos):(sourceCopyPos-node[i]);
					if (length>bestMatchLen || (length==bestMatchLen && dist<bestMatchDist))
					{
						bestMatchLen=length;
						bestMatchType=SourceCopy;
						bestMatchPos=node[i];
						bestMatchDist=dist;
					}
				}
			}
		}
		
		{ //target copy
			uint * node=targetTree[symbol];
			unsigned int nodelen=targetTreeLen[symbol];
			if (nodelen)
			{
				for (unsigned int i=nodelen-1;i;i--)
				{
					uint length=2;
					uint x=node[i]+2;
					uint y=targetpos+2;
					while (y<targetlen && target[x++]==target[y++]) length++;
					uint dist=(node[i]>targetCopyPos)?(node[i]-targetCopyPos):(targetCopyPos-node[i]);
					if (length>bestMatchLen || (length==bestMatchLen && dist<bestMatchDist))
					{
						bestMatchLen=length;
						bestMatchType=TargetCopy;
						bestMatchPos=node[i];
					}
				}
			}
			
			//target tree append
			targetTree[symbol][targetTreeLen[symbol]++]=targetpos;
			if (targetTreeLen[symbol]==targetTreeMemLen[symbol])
			{
				targetTreeMemLen[symbol]*=2;
				targetTree[symbol]=(uint*)realloc(targetTree[symbol], targetTreeMemLen[symbol]*sizeof(uint));
			}
		}
		
		{ //target read
			if (bestMatchLen<2 || (targetReadLen && bestMatchLen<3) || (bestMatchType!=SourceRead && bestMatchLen<5))
			{
				bestMatchLen=1;
				bestMatchType=TargetRead;
			}
		}
		
		if (bestMatchType!=TargetRead) targetReadFlush();
		
//printf("%i %i\n",bestMatchType,bestMatchLen);
		switch (bestMatchType)
		{
		case SourceRead:
			writenum((bestMatchLen-1)<<2 | SourceRead);
			break;
		case TargetRead:
			//delay write to group sequential TargetRead commands into one
			targetReadLen+=bestMatchLen;
			break;
		case SourceCopy:
		case TargetCopy:
			writenum((bestMatchLen-1)<<2 | bestMatchType);
			uint * copypos=((bestMatchType==SourceCopy)?&sourceCopyPos:&targetCopyPos);
			bool negative=(bestMatchPos<*copypos);
			uint offset;
			if (negative) offset=*copypos-bestMatchPos;
			else offset=bestMatchPos-*copypos;
			writenum(negative | (offset<<1));
			*copypos=bestMatchPos+bestMatchLen;
			break;
		}
		targetpos+=bestMatchLen;
		
		//adding this here cuts speed in a sixth and size to 97% - not worth it
		////target tree append
		//for (uint i=1;i<bestMatchLen;i++)
		//{
		//	symbol=(target[targetpos+i+0]<<0) | (target[targetpos+i+1]<<8);
		//	targetTree[symbol][targetTreeLen[symbol]++]=targetpos+i;
		//	if (targetTreeLen[symbol]==targetTreeMemLen[symbol])
		//	{
		//		targetTreeMemLen[symbol]*=2;
		//		targetTree[symbol]=realloc(targetTree[symbol], targetTreeMemLen[symbol]*sizeof(uint));
		//	}
		//}
		
		if (progress)
		{
			if((blockid&0xFF)==0)
			{
				if (!progress(targetpos, targetlen))
				{
					for (int i=0;i<65536;i++)
					{
						free(sourceTree[i]);
						free(targetTree[i]);
					}
					free(out);
					return bps_canceled;
				}
			}
			blockid++;
		}
	}
	
	targetReadFlush();
	
	crc_in=~crc_in;
	write(crc_in>>0); write(crc_in>>8); write(crc_in>>16); write(crc_in>>24);
	
	unsigned int crc_out=~0;
	for (byte * i=targetmem.ptr;i<targetmem.ptr+targetmem.len;i++) crc_out=crc32(crc_out, *i);
	crc_out=~crc_out;
	write(crc_out); write(crc_out>>8); write(crc_out>>16); write(crc_out>>24);
	
	crc_patch=~crc_patch;
	write_nocrc(crc_patch>>0); write_nocrc(crc_patch>>8); write_nocrc(crc_patch>>16); write_nocrc(crc_patch>>24);
	
	patchmem->ptr=out;
	patchmem->len=outlen;
	
	for (int i=0;i<65536;i++)
	{
		free(sourceTree[i]);
		free(targetTree[i]);
	}
	
	//while this may look like it can be fooled by a patch containing one of any other command, it
	//  can't, because the ones that aren't SourceRead requires an argument.
	uint i;
	for (i=mainContentPos;(out[i]&0x80)==0x00;i++) {}
	if (i==outlen-12-1) return bps_identical;
	
#undef targetReadFlush
	return bps_ok;
}

#undef write_nocrc
#undef write
#undef writenum

void bps_free(struct mem mem)
{
	free(mem.ptr);
}

#if 0
#warning Disable this in release versions.

#include <stdio.h>

//Congratulations, you found the undocumented feature! It compares two equivalent BPS patches and
//  tells where each one is more compact. (It crashes or gives bogus answers on invalid or
//  non-equivalent patches.) Have fun.
void bps_compare(struct mem patch1mem, struct mem patch2mem)
{
	byte * patch[2]={patch1mem.ptr, patch2mem.ptr};
	uint patchpos[2]={0,0};
	uint patchlen[2]={patch1mem.len-12, patch2mem.len-12};
	uint patchoutpos[2]={0,0};
	
#define read8(id) (patch[id][patchpos[id]++])
#define decodeto(id, var) \
				do { \
					var=0; \
					int shift=0; \
					while (true) \
					{ \
						byte next=read8(id); \
						uint addthis=(next&0x7F)<<shift; \
						var+=addthis; \
						if (next&0x80) break; \
						shift+=7; \
						var+=1<<shift; \
					} \
				} while(false)
	
	uint lastmatch=0;
	uint patchposatmatch[2]={0,0};
	
	uint outlen;
	patch[0]+=4; patch[1]+=4;//BPS1
	uint tempuint;
	decodeto(0, tempuint); decodeto(1, tempuint);//source-size
	decodeto(0, outlen); decodeto(1, outlen);//target-size
	decodeto(0, tempuint); patch[0]+=tempuint;//metadata
	decodeto(1, tempuint); patch[1]+=tempuint;//metadata
	
	bool show=false;
	while (patchpos[0]<patchlen[0] && patchpos[1]<patchlen[1])
	{
		bool step[2]={(patchoutpos[0]<=patchoutpos[1]), (patchoutpos[0]>=patchoutpos[1])};
		char describe[2][256];
		for (int i=0;i<2;i++)
		{
			if (step[i])
			{
				uint patchposstart=patchpos[i];
				decodeto(i, tempuint);
				uint len=(tempuint>>2)+1;
				patchoutpos[i]+=len;
				int action=(tempuint&3);
				if (action==1) patchpos[i]+=len;
				if (action==2 || action==3) decodeto(i, tempuint);
				const char * actionnames[]={"SourceRead", "TargetRead", "SourceCopy", "TargetCopy"};
				sprintf(describe[i], "%s for %i in %i",  actionnames[action], len, patchpos[i]-patchposstart);
				if (!step[i^1])
				{
					printf("%i: %s\n", i+1, describe[i]);
					show=true;
				}
			}
		}
		if (step[0] && step[1])
		{
			if (!strcmp(describe[0], describe[1])) /*printf("3: %s\n", describe[0])*/;
			else
			{
				printf("1: %s\n2: %s\n", describe[0], describe[1]);
				show=true;
			}
		}
		if (patchoutpos[0]==patchoutpos[1])
		{
			uint used[2]={patchpos[0]-patchposatmatch[0], patchpos[1]-patchposatmatch[1]};
			char which='=';
			if (used[0]<used[1]) which='+';
			if (used[0]>used[1]) which='-';
			if (show)
			{
				printf("%c: %i,%i bytes since last match (%i)\n", which, used[0], used[1], patchoutpos[0]);
				show=false;
			}
			patchposatmatch[0]=patchpos[0];
			patchposatmatch[1]=patchpos[1];
			lastmatch=patchoutpos[0];
		}
	}
}
#endif
