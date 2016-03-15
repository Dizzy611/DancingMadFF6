//Module name: libbps
//Author: Alcaro
//Date: March 8, 2013
//Licence: GPL v3.0 or higher

#include "structmem.h"

#ifndef __cplusplus
#include <stdbool.h>//bool; if this file does not exist (hi msvc), remove it and uncomment the following three lines.
//#define bool int
//#define true 1
//#define false 0
#endif

enum bpserror {
	bps_ok,//Patch applied or created successfully.
	
	bps_not_this,//This is not the intended input file for this patch.
	bps_broken,//This is not a BPS patch, or it's malformed somehow.
	
	bps_identical,//The input files are identical.
	bps_too_big,//One of the files is too big and can't be handled with the current configuration of
	            // libbps. You must recompile it with larger values for uint and uint_max.
	bps_canceled,//The callback returned false.
	
	bps_shut_the_fuck_up_gcc//This one isn't used, it's just to kill a stray comma warning.
};

//Applies the BPS patch in [patch, patchlen] to [in, inlen] and stores it to [out, outlen]. Send the
//  return values to bps_free when you're done with it. It is safe to give a null pointer for the
//  metadata if you're not interested.
enum bpserror bps_apply(struct mem patch, struct mem in, struct mem * out, struct mem * metadata);

//Creates a BPS patch that converts source to target and stores it to patch. It is safe to give
//  {NULL,0} as metadata.
enum bpserror bps_create_linear(struct mem source, struct mem target, struct mem metadata,
																struct mem * patch);

//Very similar to bps_create_linear; the difference is that this one takes much longer to run, but
//  generates smaller patches.
//Because it takes so much longer, a progress meter is supplied; total is guaranteed to be constant
//  between every call until this function returns, done is guaranteed to increase between each
//  call, and done/total is an approximate percentage counter. Anything else is undefined behaviour;
//  for example, progress may or may not be called for done=0, progress may or may not be called for
//  done=total, done may or may not increase by the same amount between each call, and the duration
//  between each call may or may not be constant.
//To cancel the patch creation, return false from the callback.
//It is safe to pass in NULL for the progress indicator if you're not interested. If the callback is
//  NULL, it can not be canceled.
enum bpserror bps_create_delta(struct mem source, struct mem target, struct mem metadata,
															 struct mem * patch, bool (* progress)(size_t done, size_t total));

//Frees the memory returned in the output parameters of the above. Do not call it twice on the same
//  input, nor on anything you got from anywhere else. bps_free is guaranteed to be equivalent to
//  calling stdlib.h's free() on mem.ptr.
void bps_free(struct mem mem);
