#include <rp6502.h>
#include <errno.h>

int __fastcall__ ria_readline_peek (char* peek, int size)
{
    int i, ax;
    char ch;
    if (size < 1) {
        errno = EINVAL;
        return -1;
    }
    ax = ria_call_int (RIA_OP_RLN_PEEK);
    i = 0;
    while ((ch = ria_pop_char ()) != 0) {
        if (i + 1 >= size) {
            RIA.op = RIA_OP_ZXSTACK;
            errno = ENOMEM;
            return -1;
        }
        peek[i++] = ch;
    }
    peek[i] = 0;
    return ax;
}
