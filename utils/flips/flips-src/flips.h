//Module name: Floating IPS, shared header
//Author: Alcaro
//Date: May 18, 2013
//Licence: GPL v3.0 or higher

//Preprocessor switch documentation:
//
//FLIPS_WINDOWS
//FLIPS_GTK
//FLIPS_CLI
//  Picks which frontend to use for Flips. You can pick one manually, or let Flips choose
//  automatically depending on the platform (Windows -> FLIPS_WINDOWS, Linux -> FLIPS_GTK, anything
//  else -> FLIPS_CLI). FLIPS_WINDOWS and FLIPS_CLI can be compiled under both C99 and C++98;
//  FLIPS_GTK is only tested under C99.
//  Note that picking the platform native frontend will bring a few advantages even if you only
//  intend to use Flips from the command line; Windows gains access to filenames outside the 8bit
//  charset, and GTK+ will gain the ability to handle files on URIs and not the local file system.
//
//All of these must be defined globally, or Flips will behave erratically.

#if defined(FLIPS_WINDOWS) || defined(FLIPS_GTK) || defined(FLIPS_CLI)
//already picked
#elif defined(_WIN32)
#define FLIPS_WINDOWS
#elif defined(__linux__)
#define FLIPS_GTK
#else
#define FLIPS_CLI
#endif

#ifdef __cplusplus
#define TDMMISSING extern "C"
#else
#define TDMMISSING
#endif

#define flipsversion "Flips v1.12"


#if defined(FLIPS_WINDOWS)
#define UNICODE
//# define _UNICODE
//#define WINVER 0x0501
#define _WIN32_WINNT 0x0501
//#define _WIN32_IE 0x0600
//#define __MSVCRT_VERSION__ 0x0601
#include <windows.h>
#include <windowsx.h>
#include <shlobj.h>
#include <wchar.h>
#include <stdio.h>

#define wcsicmp _wcsicmp//wcsicmp deprecated? fuck that, I use what I want. I do not add underlines to a few randomly chosen functions.
TDMMISSING int _wcsicmp(const wchar_t *string1, const wchar_t *string2);
TDMMISSING int swprintf(wchar_t *buffer, const wchar_t *format, ...);//also tdm quit having outdated and/or incomplete headers.


#else
#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <stdio.h>

//Flips uses Windows types internally, since it's easier to #define them to Linux types than
//defining "const char *" to anything else, and since I use char* at some places (mainly libips/etc)
//and really don't want to try to split them. Inventing my own typedefs seems counterproductive as
//well; they would bring no advantage over Windows types except not being Windows types, and I don't
//see that as a valid argument.
#define LPCWSTR const char *
#define PWCHAR char *
#define WCHAR char
#define wcscpy strcpy
#define wcscat strcat
#define wcschr strchr
#define wcslen strlen
#define wcsrchr strrchr
#define wcscmp strcmp
#define wcsncmp strncmp
#define wcsicmp strcasecmp
//#define wcsnicmp strncasecmp
#define wprintf printf
#define TEXT(text) text
#define ExitProcess exit
TDMMISSING int strcasecmp(const char *s1, const char *s2);
#define ClaimConsole() // all other platforms have that function already
#endif

#include "libips.h"
#include "libbps.h"
#include "libups.h"

#ifndef __cplusplus
#include <stdbool.h>//If this file does not exist, remove it and uncomment the following three lines.
//#define bool int
//#define true 1
//#define false 0
#endif


//provided by Flips core
#include "structmem.h"

enum patchtype {
	ty_null,
	ty_ips,
	ty_bps_linear,
	ty_bps_delta,
	ty_shut_up_gcc
};

enum errorlevel {
		el_ok,
		el_unlikelythis,
		el_warning,
		el_notthis,
		el_broken,
		el_shut_up_gcc
	};

struct errorinfo {
	enum errorlevel level;
	const char * description;
};

struct manifestinfo {
	bool use;
	bool required;
	LPCWSTR name;
};

PWCHAR GetExtension(LPCWSTR fname);
PWCHAR GetBaseName(LPCWSTR fname);
bool shouldRemoveHeader(LPCWSTR romname, struct mem rommem);

struct errorinfo ApplyPatchMem(struct mem patch, struct mem inrom, bool removeheader, LPCWSTR outromname, struct manifestinfo * manifestinfo);
struct errorinfo ApplyPatch(LPCWSTR patchname, LPCWSTR inromname, LPCWSTR outromname, struct manifestinfo * manifestinfo);
struct errorinfo CreatePatch(LPCWSTR inromname, LPCWSTR outromname, enum patchtype patchtype, LPCWSTR patchname, struct manifestinfo * manifestinfo);

extern char bpsdProgStr[24];
extern int bpsdLastPromille;
bool bpsdeltaGetProgress(size_t done, size_t total);

int flipsmain(int argc, WCHAR * argv[]);
void usage();//does not return


//provided by the OS port
struct mem ReadWholeFile(LPCWSTR filename);
bool WriteWholeFile(LPCWSTR filename, struct mem data);
bool WriteWholeFileWithHeader(LPCWSTR filename, struct mem header, struct mem data);
void FreeFileMemory(struct mem mem);

void bpsdeltaBegin();
bool bpsdeltaProgress(size_t done, size_t total);
void bpsdeltaEnd();

int ShowGUI(LPCWSTR filename);
#ifdef FLIPS_WINDOWS
void ClaimConsole();
#endif

//the OS port is responsible for main()
