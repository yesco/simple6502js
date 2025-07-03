;;;   exec: 69  3"' call _exec+_exit_ [get _next _execA] (+ 47 22) subr + get+jsrloop+next+call (+ 7 6 3 6)=22
;;;  stack: 37  5"" _drop2 _drop _dup _pick _swap [pushAY AYtoTOS pushAA] (+ 2 2 5 13 15)
;;;    mem: 26  2   @ ! (+ 12 14) 
;;;   math: 53  9   - + EOR | & _not +shr +shl inc {dec} (+ 31 5 5 5 7) {9}
;;;  const: 32  4   _true 0 ' _literal (+ 3 6 7 16)
;;;   test: 18  3   _null _eq _lt (+ 8 3 7)
;;; branch: 21  2   _jp _jz (+ 3 18)
;;; 
;;; (+ 69 37 26 53 32 18 21) = 256 !!!!!
;;; (+  3  5  2  9  4  3  2) =  28  extra"""= 6
;;; (/ 256.0 28) =  9.1 B/op !
;;; (- 256  256) =  0 (+ 32 39)=71 mul+divmod

;;; LISP: to be used in a LISP
;;; 
;;;  stack: 37  5"" _drop2 _drop _dup _pick _swap [pushAY AYtoTOS pushAA] (+ 2 2 5 13 15)
;;;    mem: 26  2   ! @ (+ 12 14) 
;;;   math: 53  9   - + EOR | & _not +shr +shl inc {dec} (+ 31 5 5 5 7) {9}
;;;   test: 18  3   _null _eq _lt (+ 8 3 7)
;;; 
;;; (+ 37 26 53 18) = 134 bytes
;;; (+ 5 2 9 3)     = 19  19 impls

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro


;;; subr
;;; (+ 3 11 6 10 3 9 5) = 47
;;; call exec callit enter loadip semis


;;; call bytecode
_call: 
;;; 3
        jsr _literal
;;; _exec bytecode from stack ( addr - )
_exec:
;;; 11
        ;; remove jsrloop
        pla
        pla
        ;; save current IP
        ;; R.push( IP )
        lda ip+1
        pha
        lda ip
        pha
        lda ipy
        pha

        ;; push another jsrloop, lol
;;; 6
        jsr callit
        jmp jsrloop

callit:        
        ;; call machine code addr
;;; 10
        ;; call( pop )= R.push ( pop ); R.call
        lda 1,x
        pha
        lda 0,x
        pha
        inx
        inx

        ;; "return to addr"
        php
        rti

;;; jsr _ovm65 .byte "3+4+7+", 0
_ovm65: 
_interpret:
_enter:
;;; 3
        ;; (this will skip zeroth byte!)
        lda #0
        pha

        ;; IP= R.pop
loadip:
;;; 9
        pla
        sta ipy
        pla
        sta ip
        pla
        sta ip+1
        ;; continue to jsrloop

jsrloop:        
;;; 6B 9c
        jsr _next
        jmp jsrloop

;;; get next byte
get:
;;; 7 (saves at least 3 bytes as subtroutine)
        inc ipy
        ldy ipy
        lda (ip),y
        rts

_drop2: 
;;; 2
        inx
        inx
_drop:
;;; 2
        inx
        inx

_next:
;;; 3 20c (+ 12+6+9=27c rts 1B to loop, OR 3c jmp next 3B)
        jsr get
_execA: 
;;; 6
        sta go+1                ; lo offset
go:     jmp ONEPAGE

_exit_: 
_semis:
;;; 5
        ;; remove jsrloop
        pla
        pla
        jmp loadip


;;; -- stack

_dup:   
;;; 5
        ;; push a value
        dex
        dex
        lda #1
        ;; skip to pickA
        SKIPTWO
;;; N pick; N=0 => dup, N=1 => over
_pick:  
;;; 16
        lda 0,x
pickA:  
        ;; replace a value
        stx savex
        asl
        adc savex
        
        lda 1,y
        pha
        lda 2,y
        tay
        
        jmp setPLAY

;;; 16
        txa
        clc
        adc 0,x
        adc 0,x
pickA:        
        ;; replace a value
        tay

        lda 1,y
        pha
        lda 2,y
        tay

        jmp setPLAY
        

.ifnblank
_dup: 
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

;;; TODO: _rot _over _pick
;;;       >R <R (jmp next) @zp !zp (vars?)

_swap:  
;;; 15
        dex
        dex
        jsr @one

@one:
        lda 2,x
        ldy 4,x
        sta 4,x
        sty 2,x

        inx
        rts
        
_j:     
;;; 3
        jsr _zero
_jz:    
;;; 18
        ;; current ip
        ldy ipy
        iny

        lda 0,x
        ora 2,x
        bne @noskip
@doskip: 
        ;; add next byte to y
        tya
        clc
        ;; get next byte
        adc (ip),y
@noskip:
        sty ipy
        jmp _drop


_lt:    
;;; 7
        jsr _minus
        bcc _true
        bcs _zero
_eq:
;;; 3
        jsr _minus
_null:  
;;; 8
        ;; compensate for push _zero/_true
        inx
        inx
        ;; read it (!)
        lda 2,x
        ora 3,x
        bne _zero
        ;; =0 fall to _true
_true:  
;;; 3
        lda #$ff
        SKIPTWO
_zero:  
;;; 6
        lda #0
_pushAA:
        tay
        jmp pushAY

_iit:   
;;; 7
        jsr get
        ldy #0
        beq pushAY

_literal:       
;;; 12+4 = 16 (4 is "library")
        ;; lo
        jsr get
        pha
        ;; hi
        jsr get
        tay

pushAY:
        dex
        dex
setPLAY:
        pla
AYtoTOS:
        sta 0,x
        sty 1,x

        rts


_store: 
;;; 14
        lda 2,x
        sta (0,x)
        jsr _inc

        lda 3,x
        sta (0,x)

        jmp _drop2
;;; TODO: optimize w jsr & tail and inx

.ifnblank
;;; (+ 6 13) = 19
_store: 
;;; (6)
        jsr _comma
        jmp _drop2

;;; ((13))
_comma: 
;;; (6)
        jsr _ccomma
        lda 3,x
        SKIPTWO
_ccomma:
;;; (7)
        lda 2,x
_cstainc:  
        sta (0,x)
        jmp _inc
.endif

_load:
;;; 12
        ;; lo
        lda (0,x)
        pha
        ;; hi
        jsr _inc
        lda (0,x)
        tay
        
        jmp setPLAY


.ifnblank
_dec:   
;;; 9
        lda 0,x
        bne @nodec
        dec 1,x
@nodec:
        dec 0,x
        rts
.endif

;;; -- math / logical
;;; 
;;; (+ 5 4 3 3 2 14)= 31B for 5 ops (- + EOR | &) 
;;; (/ 31 5.0) = 6.2B/op + not + shr + shl

_shr:   
;;; 5
        lsr 1,x
        ror 0,x
        rts
_shl:   
;;; 5
        asl 0,x
        rol 1,x
        rts
_not:   
;;; 5
        jsr _neg1
        ;; last op was "dex" in pushAY (Z=0)
;;; TODO: revisit!
        bne _eor
_minus: 
;;; 5
        sec
        lda #SBCzpx
        bne math
_plus:
;;; 4
        clc
        lda #ADCzpx
        SKIP_TWO

.ifnblank
_nip:                           ; !!!
_swapdrop:
_lda:   
;;; 3
        lda #LDAzpx
        SKIP_TWO
.endif

_eor:   
;;; 3
        lda #EORzpx
        SKIP_TWO
_or:    
;;; 3
        lda #ORAzpx
        SKIP_TWO
_and:
        lda #ANDzpx
;;; 2

math:
;;; 14
        sta @op
        jsr @one
@one:
        lda 2,x
@op:    adc 0,x
        sta 2,x

        inx
        rts
