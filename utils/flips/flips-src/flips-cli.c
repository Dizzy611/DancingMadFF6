//Module name: Floating IPS, command line frontend
//Author: Alcaro
//Date: July 11, 2013
//Licence: GPL v3.0 or higher

#include "flips.h"

#ifdef FLIPS_CLI
struct mem ReadWholeFile(const char * filename)
{
	FILE * file=fopen(filename, "rb");
	if (!file) return (struct mem){NULL, 0};
	fseek(file, 0, SEEK_END);
	size_t len=ftell(file);
	fseek(file, 0, SEEK_SET);
	unsigned char * data=(unsigned char*)malloc(len);
	size_t truelen=fread(data, 1,len, file);
	fclose(file);
	if (len!=truelen)
	{
		free(data);
		return (struct mem){NULL, 0};
	}
	return (struct mem){ (unsigned char*)data, len };
}

bool WriteWholeFile(const char * filename, struct mem data)
{
	FILE * file=fopen(filename, "wb");
	if (!file) return false;
	unsigned int truelen=fwrite(data.ptr, 1,data.len, file);
	fclose(file);
	return (truelen==data.len);
}

bool WriteWholeFileWithHeader(const char * filename, struct mem header, struct mem data)
{
	FILE * file=fopen(filename, "wb");
	if (!file) return false;
	fwrite(header.ptr, 1,512, file);
	unsigned int truelen=fwrite(data.ptr, 1,data.len, file);
	fclose(file);
	return (truelen==data.len);
}

void FreeFileMemory(struct mem mem)
{
	free(mem.ptr);
}


int ShowGUI(const char * filename)
{
	usage();
	return 99;//doesn't happen
}

int main(int argc, char * argv[])
{
	return flipsmain(argc, argv);
}
#endif
