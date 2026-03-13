;
; 2023, Rumbledethumps
;

.constructor initmainargs, 24
.import __argc, __argv
.import pushax
.importzp ptr1

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

    ; Count argc by walking the null-terminated pointer table.
    ; ria_argv has already relocated the pointers to absolute addresses.
    lda     #<argvbuf
    sta     ptr1
    lda     #>argvbuf
    sta     ptr1+1

countloop:
    ldy     #1
    lda     (ptr1),y        ; high byte of pointer
    dey
    ora     (ptr1),y        ; OR with low byte
    beq     setargv         ; null pointer = end of array

    inc     __argc
    bne     :+
    inc     __argc+1
:
    lda     ptr1
    clc
    adc     #2
    sta     ptr1
    bcc     countloop
    inc     ptr1+1
    jmp     countloop

setargv:
    ; __argv = argvbuf (pointer table starts at top of buffer)
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
