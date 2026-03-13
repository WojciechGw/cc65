#include <rp6502.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>

int __fastcall__ ria_argv (char* buf, int size)
{
    int i, ax;
    ax = ria_call_int (RIA_OP_ARGV);
    if (ax > size) {
        RIA.op = RIA_OP_ZXSTACK;
        errno = ENOMEM;
        return -1;
    }
    for (i = 0; i < ax; i++) {
        buf[i] = ria_pop_char ();
    }
    printf("{%d}",ax);
    {
        unsigned int *ptrs = (unsigned int *)buf;
        while (*ptrs) {
            *ptrs++ += (unsigned int)buf;
        }
    }
    return ax;
}
