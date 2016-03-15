//Module name: Floating IPS, shared core
//Author: Alcaro
//Date: June 8, 2013
//Licence: GPL v3.0 or higher

#include "flips.h"


PWCHAR GetExtension(LPCWSTR fname)
{
	PWCHAR ptr1=(PWCHAR)fname;
	PWCHAR ptr2;
	ptr2=wcsrchr(ptr1, '/'); if (ptr2) ptr1=ptr2;
#ifdef FLIPS_WINDOWS
	ptr2=wcsrchr(ptr1, '\\'); if (ptr2) ptr1=ptr2;
#endif
	ptr2=wcsrchr(ptr1, '.'); if (ptr2) ptr1=ptr2;
	if (*ptr1=='.') return ptr1;
	else return wcsrchr(ptr1, '\0');
}

PWCHAR GetBaseName(LPCWSTR fname)
{
	PWCHAR ptr1=(PWCHAR)fname;
	PWCHAR ptr2;
	ptr2=wcsrchr(ptr1, '/'); if (ptr2) ptr1=ptr2+1;
#ifdef FLIPS_WINDOWS
	ptr2=wcsrchr(ptr1, '\\'); if (ptr2) ptr1=ptr2+1;
#endif
	return ptr1;
}

bool forceKeepHeader=false;

#ifndef FLIPS_CLI
bool guiActive=false;
#endif




const struct errorinfo ipserrors[]={
		{ el_ok, NULL },//ips_ok
		{ el_unlikelythis, "The patch was applied, but is most likely not intended for this ROM." },//ips_notthis
		{ el_unlikelythis, "The patch was applied, but did nothing. You most likely already had the output file of this patch." },//ips_thisout
		{ el_warning, "The patch was applied, but appears scrambled or malformed." },//ips_suspicious
		{ el_broken, "The patch is broken and can't be used." },//ips_invalid
		
		{ el_warning, "The output file contains changes beyond the 16MB mark. The IPS format is "
									"unable to address those offsets. The patch is most likely unusable." },//ips_16MB
		{ el_warning, "The files are identical! The patch will do nothing." },//ips_identical
	};

const struct errorinfo bpserrors[]={
		{ el_ok, NULL },//bps_ok,
		{ el_notthis, "This patch is not intended for this ROM." },//bps_not_this
		{ el_broken, "This patch is broken and can't be used." },//bps_broken
		
		{ el_warning, "The files are identical! The patch will do nothing." },//bps_identical
		{ el_broken, "Unable to perform this operation due to size constraints." },//bps_too_big
		{ el_broken, "Patch creation was canceled." },//bps_canceled
	};

LPCWSTR GetManifestName(LPCWSTR romname)
{
	//static WCHAR manifestname[MAX_PATH];
	//wcscpy(manifestname, romname);
	//PWCHAR manifestext=GetExtension(manifestname);
	//if (!manifestext) manifestext=wcschr(manifestname, '\0');
	//wcscpy(manifestext, TEXT(".xml"));
	//return manifestname;
	
	static WCHAR * manifestname=NULL;
	if (manifestname) free(manifestname);
	manifestname=(WCHAR*)malloc((wcslen(romname)+1+4)*sizeof(WCHAR));
	wcscpy(manifestname, romname);
	PWCHAR manifestext=GetExtension(manifestname);
	if (manifestext) wcscpy(manifestext, TEXT(".xml"));
	return manifestname;
}

struct errorinfo ApplyPatchMem(struct mem patch, struct mem inrom, bool removeheader, LPCWSTR outromname, struct manifestinfo * manifestinfo)
{
	struct errorinfo errinf;
	removeheader=(removeheader && !memcmp(patch.ptr, "BPS1", 4));
	if (removeheader)
	{
		inrom.ptr+=512;
		inrom.len-=512;
	}
	struct mem outrom={NULL,0};
	struct mem manifest={NULL,0};
	
	errinf=(struct errorinfo){ el_broken, "Unknown patch format." };
	if (!memcmp(patch.ptr, "PATCH", 5)) errinf=ipserrors[ips_apply(patch, inrom, &outrom)];
	if (!memcmp(patch.ptr, "BPS1", 4)) errinf=bpserrors[bps_apply(patch, inrom, &outrom, &manifest)];
	if (!memcmp(patch.ptr, "UPS1", 4)) errinf=bpserrors[ups_apply(patch, inrom, &outrom)];
	if (errinf.level==el_ok) errinf.description="The patch was applied successfully!";
	
	struct manifestinfo defmanifestinfo={true,false,NULL};
	if (!manifestinfo) manifestinfo=&defmanifestinfo;
	if (manifestinfo->use)
	{
		if (manifest.ptr)
		{
			LPCWSTR manifestname;
			if (manifestinfo->name) manifestname=manifestinfo->name;
			else manifestname=GetManifestName(outromname);
			if (!WriteWholeFile(manifestname, manifest) && manifestinfo->required)
			{
				if (errinf.level==el_ok) errinf=(struct errorinfo){ el_warning, "The patch was applied, but the manifest could not be created." };
			}
		}
		else if (manifestinfo->required && errinf.level==el_ok) errinf=(struct errorinfo){ el_ok, "The patch was applied, but there was no manifest present." };
	}
	
	if (removeheader)
	{
		inrom.ptr-=512;
		inrom.len+=512;
		if (errinf.level<el_notthis)
		{
			if (!WriteWholeFileWithHeader(outromname, inrom, outrom)) errinf=(struct errorinfo){ el_broken, "Couldn't write ROM. Are you on a read-only medium?" };
		}
	}
	else if (errinf.level<el_notthis)
	{
		if (!WriteWholeFile(outromname, outrom)) errinf=(struct errorinfo){ el_broken, "Couldn't write ROM. Are you on a read-only medium?" };
	}
	free(outrom.ptr);
	if (errinf.level==el_notthis && removeheader)
	{
		errinf=ApplyPatchMem(patch, inrom, false, outromname, manifestinfo);
		if (errinf.level==el_ok)
		{
			errinf=(struct errorinfo){ el_warning, "The patch was applied, but it was created from a headered ROM, which may not work for everyone." };
		}
	}
	return errinf;
}

bool shouldRemoveHeader(LPCWSTR romname, struct mem rommem)
{
	PWCHAR romext=GetExtension(romname);
	return ((rommem.len&0x7FFF)==512 &&
					(!wcsicmp(romext, TEXT(".smc")) || !wcsicmp(romext, TEXT(".sfc"))) &&
					!forceKeepHeader);
}

struct errorinfo ApplyPatch(LPCWSTR patchname, LPCWSTR inromname, LPCWSTR outromname, struct manifestinfo * manifestinfo)
{
	struct mem inrom=ReadWholeFile(inromname);
	if (!inrom.ptr)
	{
		return (struct errorinfo){ el_broken, "Couldn't read ROM. What exactly are you doing?" };
	}
	struct mem patchmem=ReadWholeFile(patchname);
	if (!patchmem.ptr)
	{
		FreeFileMemory(inrom);
		return (struct errorinfo){ el_broken, "Couldn't read input patch. What exactly are you doing?" };
	}
	struct errorinfo errinf=ApplyPatchMem(patchmem, inrom, shouldRemoveHeader(inromname, inrom), outromname, manifestinfo);
	FreeFileMemory(inrom);
	FreeFileMemory(patchmem);
	return errinf;
}


char bpsdProgStr[24];
int bpsdLastPromille=-1;

bool bpsdeltaGetProgress(size_t done, size_t total)
{
	int promille=done/(total/1000);//don't set this to done*1000/total, it'd just give overflows on huge stuff. 100% is handled later
	if (promille==bpsdLastPromille) return false;
	bpsdLastPromille=promille;
	if (promille>=1000) return false;
	strcpy(bpsdProgStr, "Please wait... ");
	bpsdProgStr[15]='0'+promille/100;
	int digit1=((promille<100)?15:16);
	bpsdProgStr[digit1+0]='0'+promille/10%10;
	bpsdProgStr[digit1+1]='.';
	bpsdProgStr[digit1+2]='0'+promille%10;
	bpsdProgStr[digit1+3]='%';
	bpsdProgStr[digit1+4]='\0';
	return true;
}

bool bpsdeltaProgressCLI(size_t done, size_t total)
{
	if (!bpsdeltaGetProgress(done, total)) return true;
	fputs(bpsdProgStr, stdout);
	putchar('\r');
	fflush(stdout);
	return true;
}

struct errorinfo CreatePatch(LPCWSTR inromname, LPCWSTR outromname, enum patchtype patchtype, LPCWSTR patchname, struct manifestinfo * manifestinfo)
{
	//pick roms
	struct mem roms[2]={{NULL,0},{NULL,0}};
	bool removeheader[2];
	struct mem patch={NULL,0};
	for (int i=0;i<2;i++)
	{
		LPCWSTR romname=((i==0)?inromname:outromname);
		roms[i]=ReadWholeFile(romname);
		if (!roms[i].ptr)
		{
			return (struct errorinfo){ el_broken, "Couldn't read this ROM. What exactly are you doing?" };
		}
		removeheader[i]=(shouldRemoveHeader(romname, roms[i]) && (patchtype==ty_bps_linear || patchtype==ty_bps_delta));
	}
	
	for (int i=0;i<2;i++)
	{
		if (removeheader[i])
		{
			roms[i].ptr+=512;
			roms[i].len-=512;
		}
	}
	
	struct mem manifest={NULL,0};
	struct errorinfo manifesterr={el_ok, NULL};
	struct manifestinfo defmanifestinfo={true,false,NULL};
	if (!manifestinfo) manifestinfo=&defmanifestinfo;
	if (patchtype==ty_bps_linear || patchtype==ty_bps_delta)
	{
		LPCWSTR manifestname;
		if (manifestinfo->name) manifestname=manifestinfo->name;
		else manifestname=GetManifestName(outromname);
		manifest=ReadWholeFile(manifestname);
		if (!manifest.ptr) manifesterr=(struct errorinfo){ el_warning, "The patch was created, but the manifest could not be read." };
	}
	else manifesterr=(struct errorinfo){ el_warning, "The patch was created, but this patch format does not support manifests." };
	
	struct errorinfo errinf={ el_broken, "Unknown patch format." };
	if (patchtype==ty_ips) errinf=ipserrors[ips_create(roms[0], roms[1], &patch)];
	if (patchtype==ty_bps_linear) errinf=bpserrors[bps_create_linear(roms[0], roms[1], manifest, &patch)];
	if (patchtype==ty_bps_delta)
	{
#ifndef FLIPS_CLI
		if (guiActive)
		{
			bpsdeltaBegin();
			errinf=bpserrors[bps_create_delta(roms[0], roms[1], manifest, &patch, bpsdeltaProgress)];
			bpsdeltaEnd();
		}
		else
#endif
		{
			errinf=bpserrors[bps_create_delta(roms[0], roms[1], manifest, &patch, bpsdeltaProgressCLI)];
		}
	}
	FreeFileMemory(manifest);
	if (errinf.level==el_ok) errinf.description="The patch was created successfully!";
	
	if (manifestinfo->required && errinf.level==el_ok && manifesterr.level!=el_ok) errinf=manifesterr;
	
	if (errinf.level==el_ok && roms[0].len>roms[1].len)
	{
		errinf=(struct errorinfo){ el_warning, "The patch was created, but the input ROM is larger than the "
		                                       "output ROM. Double check whether you've gotten them backwards." };
	}
	
	for (int i=0;i<2;i++)
	{
		if (removeheader[i])
		{
			roms[i].ptr-=512;
			roms[i].len+=512;
		}
	}
	if (errinf.level<el_notthis)
	{
		if (!WriteWholeFile(patchname, patch)) errinf=(struct errorinfo){ el_broken, "Couldn't write ROM. Are you on a read-only medium?" };
	}
	
	if (roms[0].ptr) FreeFileMemory(roms[0]);
	if (roms[1].ptr) FreeFileMemory(roms[1]);
	if (patch.ptr) free(patch.ptr);
	return errinf;
}



void usage()
{
	ClaimConsole();
	puts(
	// 12345678901234567890123456789012345678901234567890123456789012345678901234567890
		"usage:\n"
		"   "
#ifndef FLIPS_CLI
       "flips\n"
		"or flips patch.ips\n"
		"or "
#endif
		   "flips [--apply] [--exact] patch.ips rom.smc [outrom.smc]\n"
		"or flips [--create] [--exact] [--ips | --bps-linear | --bps-delta] clean.smc\n"
		"  hack.smc [patch.ips]\n"
#ifndef FLIPS_CLI
		"(for scripting, only the latter two are sensible)\n"
#endif
		"(patch.bps is valid in all cases patch.ips is)\n"
		"\n"
	// 12345678901234567890123456789012345678901234567890123456789012345678901234567890
		"options:\n"
		"--apply: enforce apply mode instead of guessing based on number of arguments\n"
		"--create: enforce create mode instead of guessing based on number of arguments\n"
		"--ips, --bps-linear, --bps-delta: create this patch format instead of guessing\n"
		"  based on file extension; ignored when applying\n"
		"--exact: do not remove SMC headers when applying or creating a BPS patch\n"
		"  (ignored for IPS)\n"
		"--manifest: emit or insert a manifest file as romname.xml (valid only for BPS)\n"
		"--manifest=filename: emit or insert a manifest file exactly here\n"
	// 12345678901234567890123456789012345678901234567890123456789012345678901234567890
		);
	ExitProcess(0);
}


int flipsmain(int argc, WCHAR * argv[])
{
	enum patchtype patchtype=ty_null;
	enum { a_default, a_apply_filepicker, a_apply_given, a_create } action=a_default;
	int numargs=0;
	LPCWSTR arg[3]={NULL,NULL,NULL};
	struct manifestinfo manifestinfo={false, false, NULL};
//	 {
//	bool use;
//	bool required;
//	LPCWSTR name;
//	bool success;
//};
	for (int i=1;i<argc;i++)
	{
		if (argv[i][0]=='-')
		{
			if(0);
			else if (!wcscmp(argv[i], TEXT("--apply")))
			{
				if (action==a_default || action==a_apply_given) action=a_apply_given;
				else usage();
			}
			else if (!wcscmp(argv[i], TEXT("--create")))
			{
				if (action==a_default || action==a_create) action=a_create;
				else usage();
			}
			else if (!wcscmp(argv[i], TEXT("--ips")))
			{
				if (patchtype==ty_null || patchtype==ty_ips) patchtype=ty_ips;
				else usage();
			}
			else if (!wcscmp(argv[i], TEXT("--bps-linear")))
			{
				if (patchtype==ty_null || patchtype==ty_bps_linear) patchtype=ty_bps_linear;
				else usage();
			}
			else if (!wcscmp(argv[i], TEXT("--bps-delta")))
			{
				if (patchtype==ty_null || patchtype==ty_bps_delta) patchtype=ty_bps_delta;
				else usage();
			}
			else if (!wcscmp(argv[i], TEXT("--exact"))) forceKeepHeader=true;
			else if (!wcscmp(argv[i], TEXT("--manifest")))
			{
				manifestinfo.use=true;
				manifestinfo.required=true;
			}
			else if (!wcsncmp(argv[i], TEXT("--manifest="), wcslen(TEXT("--manifest="))))
			{
				manifestinfo.use=true;
				manifestinfo.required=true;
				manifestinfo.name=wcschr(argv[i], '=')+1;
			}
			else if (!wcscmp(argv[i], TEXT("--version")))
			{
				ClaimConsole();
				puts(flipsversion);
				return 0;
			}
			else if (!wcscmp(argv[i], TEXT("--help"))) usage();
			else usage();
		}
		else
		{
			if (numargs==3) usage();
			arg[numargs++]=argv[i];
		}
	}
	if (action==a_default)
	{
		if (numargs==0) action=a_default;
		if (numargs==1) action=a_apply_filepicker;
		if (numargs==2) action=a_apply_given;
		if (numargs==3) action=a_create;
	}
	switch (action)
	{
		case a_default:
		{
			if (numargs!=0) usage();
#ifndef FLIPS_CLI
			guiActive=true;
#endif
			return ShowGUI(NULL);
		}
		case a_apply_filepicker:
		{
			if (numargs!=1) usage();
#ifndef FLIPS_CLI
			guiActive=true;
#endif
			return ShowGUI(arg[0]);
		}
		case a_apply_given:
		{
			if (numargs!=2 && numargs!=3) usage();
			ClaimConsole();
			struct errorinfo errinf=ApplyPatch(arg[0], arg[1], arg[2]?arg[2]:arg[1], &manifestinfo);
			puts(errinf.description);
			return errinf.level;
		}
		case a_create:
		{
			if (numargs!=2 && numargs!=3) usage();
			ClaimConsole();
			if (!arg[2])
			{
				if (patchtype==ty_null)
				{
					puts("Error: Unknown patch type.");
					return el_broken;
				}
				PWCHAR arg2=(WCHAR*)malloc(sizeof(WCHAR)*(wcslen(arg[1])+4+1));
				arg[2]=arg2;
				wcscpy(arg2, arg[1]);
				GetExtension(arg2)[0]='\0';
				if (patchtype==ty_ips) wcscat(arg2, TEXT(".ips"));
				if (patchtype==ty_bps_linear) wcscat(arg2, TEXT(".bps"));
				if (patchtype==ty_bps_delta) wcscat(arg2, TEXT(".bps"));
			}
			if (patchtype==ty_null)
			{
				LPCWSTR patchext=GetExtension(arg[2]);
				if (!*patchext)
				{
					puts("Error: Unknown patch type.");
					return el_broken;
				}
				else if (!wcsicmp(patchext, TEXT(".ips"))) patchtype=ty_ips;
				else if (!wcsicmp(patchext, TEXT(".bps"))) patchtype=ty_bps_linear;
				else
				{
					wprintf(TEXT("Error: Unknown patch type (%s)\n"), patchext);
					return el_broken;
				}
			}
			struct errorinfo errinf=CreatePatch(arg[0], arg[1], patchtype, arg[2], &manifestinfo);
			puts(errinf.description);
			return errinf.level;
		}
	}
	return 99;//doesn't happen
}
