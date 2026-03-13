;
; 2023, Rumbledethumps
;

; Lower priority than initheap so argv_malloc() can use malloc().
.constructor initmainargs, 23
.import __argc, __argv, _argv_malloc
.importzp ptr1, ptr2
.include "rp6502.inc"

.segment "ONCE"

.proc initmainargs

    ; Ask the RIA for argv data; returns total byte count in AX.
    lda     #RIA_OP_ARGV
    sta     RIA_OP
    jsr     RIA_SPIN

    ; Bail if count <= 0.
    sta     ptr2
    txa
    bmi     zxstack    ; count < 0
    sta     ptr2+1
    ora     ptr2
    beq     zxstack    ; count == 0

    ; Allocate buffer.
    jsr     RIA_SPIN
    jsr     _argv_malloc

    ; Bail if allocation failed.
    sta     ptr1
    stx     ptr1+1
    ora     ptr1+1
    beq     zxstack

    ; Store buffer base in __argv.
    lda     ptr1
    ldx     ptr1+1
    sta     __argv
    stx     __argv+1

    ; Re-obtain byte count from RIA
    jsr     RIA_SPIN
    sta     ptr2
    stx     ptr2+1

    ; Pop ptr2 bytes from RIA_XSTACK into the allocated buffer.
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
    ; adding __argv turns them into usable pointers.
relocate:
    lda     __argv
    sta     ptr1
    lda     __argv+1
    sta     ptr1+1

walkloop:
    ldy     #1
    lda     (ptr1),y        ; high byte of entry
    dey
    ora     (ptr1),y        ; OR with low byte
    beq     done            ; null entry = end of table

    ; Add buffer base to the stored offset.
    ldy     #0
    lda     (ptr1),y
    clc
    adc     __argv
    sta     (ptr1),y
    iny
    lda     (ptr1),y
    adc     __argv+1
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

zxstack:
    lda     #RIA_OP_ZXSTACK
    sta     RIA_OP

done:
    rts

.endproc
