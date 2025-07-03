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
        jsr _neg1
        jsr _pushtime
        jsr _minus
        putc ' '
        putc 't'
        jsr _printd
        putc ' '

        rts

;;; TODO: remove
_pushtime:      
        jsr _push

        lda $0276
        sta tos
        lda $0276+1
        sta tos+1

        rts

_printtime:      
        ;; report time since start
        jsr _pushtime
        jsr _minus
        PUTC ' '
        PUTC 't'
        jsr _printn
        PUTC ' '
;        jsr _drop
        jsr _pushtime
        rts

