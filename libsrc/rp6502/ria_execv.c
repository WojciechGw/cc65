#include <rp6502.h>
#include <errno.h>
#include <string.h>

int __fastcall__ ria_execv (const char* path, char* const argv[])
{
    const char* ptrs[16];
    unsigned int lens[16];
    int argc;
    unsigned int total_str;
    unsigned int offset;
    int i, j;

    /* path is prepended as argv[0]; the caller's argv[] becomes argv[1]+. */
    ptrs[0] = path;
    lens[0] = (unsigned int)strlen (path) + 1U;
    argc = 1;
    total_str = lens[0];

    /* Collect the caller's argv[0], argv[1], ... as our argv[1]+. */
    i = 0;
    while (argv[i] != NULL) {
        if (argc >= 16) {
            errno = EINVAL;
            return -1;
        }
        ptrs[argc] = argv[i];
        lens[argc] = (unsigned int)strlen (argv[i]) + 1U;
        total_str += lens[argc];
        if (total_str > 512U) {
            errno = EINVAL;
            return -1;
        }
        argc++;
        i++;
    }

    /* Int table: (argc+1) * 2 bytes; strings start immediately after. */
    if ((unsigned int)(argc + 1) * 2U + total_str > 512U) {
        errno = EINVAL;
        return -1;
    }

    /*
     * Build the xstack buffer (last byte pushed is first byte read by RIA).
     *
     * RIA reads the buffer as: [int_table][string_data]
     *   int_table : argc two-byte offsets (relative to buffer start),
     *               followed by a zero terminator.
     *   string_data: null-terminated strings concatenated in order.
     *
     * Push string_data first so it ends up below the int_table on the stack.
     * Within the string block, push from the last string backward so that the
     * first byte of argv[0] lands on top of the string block (first read).
     */
    for (i = argc - 1; i >= 0; --i) {
        for (j = (int)lens[i] - 1; j >= 0; --j) {
            ria_push_char (ptrs[i][j]);
        }
    }

    /*
     * Push the int table: terminator first (lands at the bottom of the table),
     * then offsets from the last to the first so that offset[0] ends up on top
     * (first read by RIA).
     *
     * Offset[i] = int_table_size + sum(lens[0..i-1]).
     */
    ria_push_int (0);
    offset = (unsigned int)(argc + 1) * 2U + total_str;
    for (i = argc - 1; i >= 0; --i) {
        offset -= lens[i];
        ria_push_int (offset);
    }

    return ria_call_int (RIA_OP_EXEC);
}
