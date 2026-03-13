;
; 2023, Rumbledethumps
;

.constructor initmainargs, 24
.import __argc, __argv
.importzp ptr1, ptr2
.include "rp6502.inc"

ARGVBUF_SIZE = 512

.segment "ONCE"

.proc initmainargs

    ; Ask the RIA for argv data; returns total byte count in AX.
    lda     #RIA_OP_ARGV
    sta     RIA_OP
    jsr     RIA_SPIN

    ; Bail if count > ARGVBUF_SIZE: clear xstack and return.
    cpx     #>ARGVBUF_SIZE
    bcc     fetch           ; X < 2 -> count fits
    bne     zxstack         ; X > 2 -> too big
    cmp     #<ARGVBUF_SIZE  ; X == 2: check low byte
    beq     fetch           ; count == 512 -> fits (not strictly greater)
                            ; count > 512 -> fall through

zxstack:
    lda     #RIA_OP_ZXSTACK
    sta     RIA_OP
    bra     done

fetch:
    ; Save byte count in ptr2 (16-bit).
    sta     ptr2
    stx     ptr2+1

    ; Set write pointer to start of argvbuf.
    lda     #<argvbuf
    sta     ptr1
    lda     #>argvbuf
    sta     ptr1+1

    ; Pop ptr2 bytes from RIA_XSTACK into argvbuf.
    ldy     #0
fillloop:
    lda     ptr2
    bne     :+
    lda     ptr2+1
    beq     relocate
:   lda     RIA_XSTACK
    sta     (ptr1),y
    inc     ptr1
    bne     :+
    inc     ptr1+1
:   lda     ptr2
    bne     :+
    dec     ptr2+1
:   dec     ptr2
    bra     fillloop

    ; Walk the pointer table: relocate each offset to an absolute address
    ; and count argc. The RIA stores offsets relative to the buffer start;
    ; adding argvbuf turns them into usable pointers.
relocate:
    lda     #<argvbuf
    sta     ptr1
    lda     #>argvbuf
    sta     ptr1+1

walkloop:
    ldy     #1
    lda     (ptr1),y        ; high byte of entry
    dey
    ora     (ptr1),y        ; OR with low byte
    beq     setargv         ; null entry = end of table

    ; Add argvbuf base to the stored offset.
    ldy     #0
    lda     (ptr1),y
    clc
    adc     #<argvbuf
    sta     (ptr1),y
    iny
    lda     (ptr1),y
    adc     #>argvbuf
    sta     (ptr1),y

    inc     __argc
    bne     :+
    inc     __argc+1
:
    lda     ptr1
    clc
    adc     #2
    sta     ptr1
    bcc     walkloop
    inc     ptr1+1
    bra     walkloop

setargv:
    lda     #<argvbuf
    ldx     #>argvbuf
    sta     __argv
    stx     __argv+1

done:
    rts

.endproc

.bss
argvbuf: .res ARGVBUF_SIZE
