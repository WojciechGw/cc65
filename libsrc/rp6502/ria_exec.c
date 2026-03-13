#include <rp6502.h>
#include <errno.h>
#include <string.h>

/*

The format of argv:
Max length of one stack size, 512 bytes.
Starts with a list of zero terminated ints that point to:
Followed by a series of zero terminated strings.
The ints are expected to be 0-indexed, not memory pointers.

TODO: Implement execl and execv.
Create execl.c execv.c and add prototypes to header.
Do not allocate temporary storage for strings - build the argv directly
on the xstack. Use C stack to allow up to 16 strings if you can't find
a way to avoid needing this memory. Return EINVAL if > 16.
Don't copy quirks of other targets, we are typical posix 
where argv[0] is the path, 1+ are args.


*/

int __fastcall__ ria_exec (unsigned char *argv, int size)
{
    if (size > 512) {
        errno = EINVAL;
        return -1;
    }
    while (size) {
        ria_push_char (argv[--size]);
    }
    return ria_call_int (RIA_OP_EXEC);
}
