;
; struct tm* __fastcall__ localtime (const time_t* timep);
; void tzset (void);
;

        .export         _localtime
        .export         _tzset

        .import         __time_t_to_tm, __tz
        .import         ldeaxi, pusheax, tosaddeax
        .import         _ria_set_axsreg, _ria_call_int, _ria_call_long

        .importzp       sreg, ptr1

        .include        "rp6502.inc"
        .include        "time.inc"

;--------------------------------------------------------------------------
; void tzset (void)

_tzset: lda     #RIA_OP_TZSET
        jsr     _ria_call_int   ; A/X = result int
        txa
        bmi     @done           ; negative = error, skip
        ldy     #0
@loop:  lda     RIA_XSTACK
        sta     __tz,y
        iny
        cpy     #15             ; sizeof(struct _timezone) = 1+4+5+5
        bne     @loop
        lda     #1
        sta     tzset_set
@done:  rts

;--------------------------------------------------------------------------
; struct tm* __fastcall__ localtime (const time_t* timep)

_localtime:
        cpx     #$00
        bne     @notnull
        cmp     #$00
        beq     @null           ; A/X already 0, return NULL
@notnull:
        jsr     ldeaxi          ; A:X:sreg = *timep (32-bit load)
        jsr     _ria_set_axsreg ; pass time to RIA (clobbers only Y)
        jsr     pusheax         ; push time onto cc65 stack for tosaddeax
        lda     #RIA_OP_TZQUERY
        jsr     _ria_call_long  ; A:X:sreg = UTC offset
        jsr     tosaddeax       ; A:X:sreg = time + offset (pops stack)
        jsr     __time_t_to_tm  ; A:X = struct tm*
        sta     ptr1
        stx     ptr1+1
        lda     RIA_XSTACK      ; ria_pop_char() = tm_isdst
        ldy     #tm::tm_isdst
        sta     (ptr1),y        ; high byte already 0 (zeroed by __time_t_to_tm)
        lda     tzset_set
        bne     @done
        jsr     _tzset
@done:  lda     ptr1
        ldx     ptr1+1
@null:  rts

;--------------------------------------------------------------------------
        .bss

tzset_set:  .res 1
