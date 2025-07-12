;;; altnerative to off-vm.asm
;;; 
;;; not tested, maybe not smaller
;;; but only writeen "when needed"


;;; ----------------------------------------

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

.macro DROP
        inx
        inx
.endmacro

;;; Doesn't consume the value
_nilqkeep:
;;; 17
        lda 0,x
        cmp #<_nil_
        bne @notnil
        lda 1,x
        cmp #>_nil_
        ;; == _nil
@notnil:
        ;; tail calls
        bne _true
        beq _zero
_jnil:
        jsr _nilqkeep
        ;; arrives here with 
        ;; _zero == is nil; _true == is ! not
        ;; -- fall through to _jz
_jz:     
;;; TODO: implement!
        rts

.ifnblank
_duptestelse:
;;; 12
        jsr _dup
        jsr get
        jsr _exec
        jmp _jz
.endif        

;;; TODO: wow so much "msising"
FUNC _printatom     
FUNC _putc
FUNC _getc
FUNC _getatomchar
FUNC _jp
FUNC _null
FUNC _jump
FUNC _lit
FUNC _literal
        rts


FUNC _drop2
        inx
        inx
;;; Notice: jsr/jmp _drop no use!
;;; 
FUNC _drop  
        inx
        inx
        rts

FUNC _cdr
;;; 3
        jsr _inc2
FUNC _car
;;; 17
        lda (0,x)
        tay

        jsr _inc
        lda (0,x)
setlYhA:        
        sta (1,x)
        tya
        sta (0,x)
        rts
        
FUNC _inc2
;;; 10
        jsr _inc
FUNC _inc
        inc 0,x
        bne @noinc
        inc 1,x
@noinc:
        rts

;;; nice chaining:
FUNC _eq 
;;; 15
        ldy #0
        lda 3,x
        cmp 1,x
        bne @neq
        lda 2,x
        cmp 1,x
        bne @neq
@eq:
        dey
@neq:
;;; 6
popsetYY:
        tya
popsetlYhA:
        DROP
        jmp setlYhA

FUNC _FFFF
_true:  
_neg1:  
;;; 3
        lda #0
        SKIPTWO
FUNC _zero
;;; 8
        lda #0
        tay
        dex
        dex
        jmp setlYhA

;;; TODO: if want pick, not not want pick
;;; could choose different impls

FUNC _dup
;;; 11
        lda 0,x
        ldy 1,x
pushAY:
        dex
        dex
AYtoTOS:
        sta 0,x
        sty 1,x

        rts

.ifnblank
FUNC _dup
;;; 2 !
        txa
        tay
;;; TODO: basically it's a COPYreg from y to x-2!!
;;; TODO: _pick?
_pushZPY:
;;; 12
        lda 1,y                 ; hi
        pha
        lda 0,y                 ; lo
        tay
pushlYhA:       
        dex
        dex
setlYhPLA:
        pla
        jmp setlYhA
.endif

FUNC _swap
;;; 14
        dex
        jsr _byteswap
        inx
_byteswap:       
        lda 1,x
        ldy 3,x
        sty 1,x
        sta 3,x
        rts

FUNC _nip
;;; 6
;;; TODO: if have mth, use those instead!
        jsr _swap
        DROP
        rts

FUNC _atomkeep
;;; TODO: can do in less?
;;; 7
        lda 0,x
        and #3
        cmp #1
        rts

;;; "Zull" - Z=1 if _nil
;;; NOTE: modifies C (no use)
FUNC _nullkeep
;;; 9
;;; TODO: is there a getlYhA ?
        lda 256-2,x             ; neg addressing!
        cmp #<_nil_
        lda 256-1,x             ; neg addressing!
        sbc #>_nil_
;;; is Z=1 if equal? or just if last byte == ???
        rts

;;;                                 .... 181
        
;;; _exit_
FUNC _supret
;;; 3
        pla
        pla
        rts
        
;;; returns whatever isn't cons
FUNC _retnotcons
;;; 9
        lda 0,x
        lsr
        bcc _supret
        lsr
        bcc _supret
        rts

;;; ItCurrent
FUNC _dupcar
;;; 6
        jsr _dup
        jmp _car
;;; ItNext
FUNC _dropcdr
;;; 5
        inx
        inx
        jmp _cdr

;;; How about a really tight offset interpreter?
;;; all within one page (so only push 1B!)
        
;;; exec
;;; 
;;; (+ 3 19 5) = 27 !

FUNC _exec  
        lda 0,x
        dex
        dex
        pha

FUNC _semis
;;; 3
        pla
        sta ipy
FUNC _next
;;; 19
        ;; next token
        inc ipy
        ldy ipy
        lda _start,y

;;; TODO: atoms could be self pushing? (if at end)
;;; (10 B but only _nll _T _lambda ... so...)
        cmp #<offbytecode
        bcs enter
        
        sta call+1
call:   jsr call
        jmp _next

enter:  
;;; 5
        ;; Y=ip A=new to interpret
        sta ipy
        tya
        pha
        bne _next
        
FUNC _load
FUNC _store
FUNC _comma
FUNC _ccomma
;;; TODO:
FUNC _rcomma
;;; TODO:
        ;; lol
        rts
