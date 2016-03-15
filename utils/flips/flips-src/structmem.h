//Standard structure for passing around memory blocks.

#ifndef struct_mem
#define struct_mem

//the standard library can be assumed to exist
#include <stddef.h>//size_t, SIZE_MAX

#ifndef SIZE_MAX
#define SIZE_MAX ((size_t)-1)
#endif

struct mem {
	unsigned char * ptr;
	size_t len;
};
#endif
