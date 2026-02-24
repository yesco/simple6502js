;;; 7 B per key
;;; dispatch table 64+ dispath
;;; (/ 64 7) = 9 trade off
;;; TODO: How about search list?
;;;   3 B/key (/ (+ 29 3 3 (* 10 3)) 7.0)
;;; 9.3 keys 7 B is break even point for 10 keys
;;; total dispatched (all over) then start saving.
.ifnblank

.macro KEYDO key,addr
        ;; key, hi, lo (reverse)
        ;; (-1 because use RTS)
        .byte key, >(addr-1), <(addr-1)
.endmacro

        lda #CTRL('F')

;;; 3*7+1=22 B
        jsr dokey
        KEYDO CTRL('B'), listbuffers
        KEYDO CTRL('F'), openfile
        KEYDO CTRL('S'), _savefile
        KEYDO CTRL('W'), _writefileas
        KEYDO CTRL('C'), _compileInput
        KEYDO CTRL('J'), bytesieve
        ;; No match
        KEYDO 0, _wrongkey

;;; Dispatch on A to addresslist after "jsr dokey'
dokey:  
;;; 29 B
        sta savea
        pla
        sta tos
        pla
        sta tos+1
        ldy #$100-3+1
@next:
        lda (tos),y
        beq @fail               ; 0 match all!
        iny
        cmp savea
@skip:
        iny
        iny
        ;; always
        bne @next
@fail:
@match:
        ;; hi first
        lda (tos),y
        iny
        pha
        ;; lo
        lda (tos),y
        pha
        ;; call lo,hi (from stack)
        rts

.endif
