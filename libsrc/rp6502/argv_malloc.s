;
; 2023, Rumbledethumps
;
; Default argv_malloc: returns NULL so argc/argv are silently skipped.
; Override by providing storage for argv:
; void *__fastcall__ argv_malloc(size_t size) { return malloc(size); }
;

.export _argv_malloc

.proc _argv_malloc

        lda     #0
        tax
        rts

.endproc
