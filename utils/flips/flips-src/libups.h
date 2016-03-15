//Module name: libups
//Author: Alcaro
//Date: April 4, 2013
//Licence: GPL v3.0 or higher

#include "structmem.h"

enum upserror {
	ups_ok,//Patch applied or created successfully.
	
	ups_not_this,//This is not the intended input file for this patch.
	ups_broken,//This is not a UPS patch, or it's malformed somehow.
	
	ups_identical,//The input files are identical.
	ups_too_big,//Somehow, you're asking for something a size_t can't represent.
	
	ups_shut_the_fuck_up_gcc//This one isn't used, it's just to kill a stray comma warning.
};

//Applies the UPS patch in [patch, patchlen] to [in, inlen] and stores it to [out, outlen]. Send the
//  return value in out to ups_free when you're done with it.
enum upserror ups_apply(struct mem patch, struct mem in, struct mem * out);

//Creates an UPS patch that converts source to target and stores it to patch.
enum upserror ups_create(struct mem source, struct mem target, struct mem * patch);

//Frees the memory returned in the output parameters of the above. Do not call it twice on the same
//  input, nor on anything you got from anywhere else. ups_free is guaranteed to be equivalent to
//  calling stdlib.h's free() on mem.ptr.
void ups_free(struct mem mem);
