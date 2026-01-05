;;; TODO: make this folding work,
;;;   mostly OK, but don't know where to put result
;;;   want to have restartable programs? 
;;;   or like cc65 just put in inline in the code?
;;;   LIMIT: can only do at top-level

;FOLD=1
.ifdef FOLD
        ;; constant partial evaluation!
        ;; TODO: expand to constant folding
        .byte "|const","word","%A="

      .byte "%{"
        putc '{'
        IMM_RET

      .byte "%{"
        ;; save address
        lda dos
        ldx dos+1
        jsr pushax
        ;; save current gen
        lda _out
        sta gos
        ldx _out+1
        stx gos+1
        ;; TODO: should set a flag
        PUTC '@'
        ;; cheat: artificual fail!
        IMM_FAIL
;;; ???
        IMM_RET

;;; TODO: why needed? was it for constant folding?

;        ;; cheat!
;        ;; (it will next rule next!)
;      .byte "|"

;        .byte "const",_T,"%A="
;        .byte "const","word","%A="

.ifdef FFF
      .byte "%{"
        PUTC '?'
;        jsr _iasm
        lda inp
        ldx inp+1
        jsr _printz
        jsr nl
        IMM_RET
.endif
        .byte _C,_D
        .byte ";"
      .byte "["
        ;; make sure we get back!
        rts
      .byte "]"
      .byte "%{"
        PUTC '$'
;        jsr _iasm
        IMM_RET
        ;; TODO: if flag set

      .byte "%{"
;        jsr _iasm
        PUTC '#'
        ;; print address to call
        lda gos
        sta tos
        lda gos+1
        sta tos+1
        jsr puth
        ;; JSR (gos) !
        lda #$4c                ; trampoline: jmp
        sta gos-1
        jsr gos-1
        ;; store result in variable from DSTACK
        sta dos
        stx dos+1
        jsr popax
        sta tos
        stx tos+1
        PUTC '@'
        jsr puth
        ;; store in var
        ldy #0
        lda dos
        sta (tos),y
        iny
        lda dos+1
        sta (tos),y
        ;; print for debug
        putc '='
        lda dos
        ldx dos+1
        sta tos
        stx tos+1
        jsr putu
        ;; remove code run!
        lda gos
        sta _out
        ldx gos+1
        stx _out+1
        ;; continue
        IMM_RET

      .byte "%{"
        putc '}'
        IMM_RET

        .byte TAILREC
.endif ; FOLD
