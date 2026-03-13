;
; 2023, Rumbledethumps
;

.constructor initmainargs, 24
.import __argc, __argv
.import pushax

ARGVBUF_SIZE = 512

.segment "ONCE"

.proc initmainargs

    ; Call ria_argv (buf, size)
    lda     #<argvbuf
    ldx     #>argvbuf
    jsr     pushax              ; Push buf
    lda     #<ARGVBUF_SIZE
    ldx     #>ARGVBUF_SIZE      ; size in AX (fastcall)
    jsr     _ria_argv
    cpx     #$FF                ; fail
    beq     done

    ; __argc = TODO
    lda     0
    ldx     0
    sta     __argc
    stx     __argc+1

    ; __argv = argvbuf
    lda     #<argvbuf
    ldx     #>argvbuf
    sta     __argv
    stx     __argv+1

done:
    rts

.endproc

.import _ria_argv

.bss
argvbuf: .res ARGVBUF_SIZE
