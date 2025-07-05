;;; ORIC timer

;;; reset ORIC timer
_resettime:     
        lda #$ff
        sta $0276
        sta $0276+1

        rts

_reporttime:    
        putc '<'

        ;; counts down so reverse subtract
        ;; printd ( $ffff - timer )
        lda #$ff
        eor $0276
        sta tmp1

        lda #$ff
        eor $0276+1
        sta tmp1+1

        putc ' '
        putc 't'
        jsr _voidprinttmp1d
        putc ' '

        rts
