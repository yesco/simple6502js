;;;  stack: 44  5"" _drop2 _drop _swap _dup _pick [pushAY AYtoTOS pushAA] (+ 2 2 14 2 21) {_pickA, setpickA}
;;;    mem: 25  2   ! @ (+ 14 11) 
;;;   math: 59 10   nip - + EOR | & _not +shr +shl inc {dec} {9}
;;;  const: 32  4   _true 0 ' _literal (+ 3 6 8 15)
;;;   test: 20  3   _null _eq _lt (+ 8 3 9)
;;; branch: 21  2   _jp _jz (+ 3 18)


;;; --- GENERIC 
;;;   exec: 69  3"' call _exec+_exit_ [get _next _execA] (+ 47 22) subr + get+jsrloop+next+call (+ 7 6 3 6)=22
;;; 
;;;              - OVERFLOW -
;;; 
;;; (+ 69 44 26 59 32 20 21) = 271 !!!!!
;;; (+  3  5  2 10  4  3  2) =  29  extra"""= 6
;;; (/ 266.0 29) =  9.2 B/op !
;;; (- 256  256) =  0 (+ 32 39)=71 mul+divmod



;;; TODO: drop & drop2 was part of BIG exec
;;;    5 bytes more?

;;; --- 2 PAGE (one prims, one bytecodes)
;;;   exec: 38  1"' _exit_ [get] next+enter
;;; 
;;; 
;;; (+ 38 44 26 59 32 20 21) = 240 (- 256 240) = 16
;;; (+  1  5  2 10  4  3  2) =  27
;;; 
;;; :- means can have max 21 bytecode routines in 2nd

;;; LISP: to be used in a LISP
;;; 
;;;  stack: 44  5"" _drop2 _drop _dup _pick _swap [pushAY AYtoTOS pushAA] (+ 2 2 2 2 5 13 15)
;;;    mem: 26  2   ! @ (+ 12 14) 
;;;   math: 59 10   nip - + EOR | & _not +shr +shl inc {dec} (+ 31 5 5 5 7) {9}
;;;   test: 18  3   _null _eq _lt (+ 8 3 7)
;;; 
;;; (+ 41 26 59 18) = 144 bytes
;;; (+  5  2 10  3) =  19 impls

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro


.zeropage

ip:     .res 2
;;; TODO: remove, actually, only have this!!!!
ipy:    .res 1

savea:  .res 1
savex:  .res 1
savey:  .res 1
savez:  .res 1                  ; haha!

.code

.export _start
_start: 

.ifnblank

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

.endif ; OLD exec






;;; ============ NEW EXEC
;;; (+ 7 3 16 12) = 38

get:    
;;; 7 
        inc ipy
        ldy ipy
        lda bytecodes,y
        rts

_semis:
;;; 3
        pla
        sta ipy
next:   
;;; 16
        ;; next token
        jsr get

;;; 
;;; TODO: atoms could be self pushing? (if at end)
;;; (10 B but only __nll __T __lambda ... so...)
        cmp #<offbytecode
;;; NOTE: C flag modified...
        bcs enter
        
        ;; primtive ops in first page
        sta call+1
call:   jsr _start
        jmp next

enter:  
        ;; bytecode in second page (only)
        ;; Y=ip A=new to interpret

;;; 12
        ;; look up second page offset at Y!
        tya
        lda _start,y
        ;; swap
        ldy ipy
        sta ipy
        ;; push old Y
        tya
        pha
        bne next

;;; ============END NEW EXEC

;;; ------------------ STACK --------------------

;;; cheapest w most flex???
; (+ 2 3 2 6 5 3) = 21
_dup:   
;;; 2
        lda #0
_pickA:  
;;; 3
        dex
        dex
        SKIPTWO
_pick:
;;; 2
        lda 0,x
;;; 15
setpickA:  
;;; (6)
        asl
        stx savex
        adc savex
        tay

;;; (5)
        lda 2,y   
        pha
        lda 3,y
        ;; hA lPLA
;;; (3)
        jmp setlPLAhA


;;; TODO: _rot _over _pick
;;;       >R <R (jmp next) @zp !zp (vars?)

;;; 14 (can't do shorter?
_swap:   
        dex
        jsr byteswap
        inx
byteswap:       
        lda 1,x
        ldy 3,x
        sta 1,x
        sty 3,x

        rts

.ifnblank
;;; These tests rely on Vatom Zull Cons flags set
;;; after a jsr _test (part of _car,_cdr!)
;;; 
;;; 13 (+10 RetNoCons+jZVC)
_jVsym: 
        bvs _j
        bvc noj
_jZull:  
        beq _j
        bne noj

;;; (10)
.ifnblank
_RetNoCons:     
        bcs ret
        bcc _exit_
;;; _jzvc go_Zull go_Vsym ...cons
_jZVC:
        jsr _jZull
        jsr _jVsym
.endif
_jCons: 
        bcs _j
noj:    
        inc ipy
        rts
.endif

_j:     
;;; 3
        jsr _zero
_jz:    
;;; 18
        inx
        inx
        ;; current ip
        ldy ipy
        ;; and skip next byte
        iny

        lda 256-2,x
        ora 256-1,x
        bne @noj
        ;; do jmp - add next byte to y
        tya
        clc
        ;; get branch offset
        adc (ip),y
@noj:   
        sty ipy
        rts


_lt:    
;;; 9
        jsr _minus
        inx
        inx
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
;;; Z=0 after call
_FFFF:  
_neg1:  
_true:  
;;; 3
        lda #$ff
        SKIPTWO
;;; Z=1 after call
_zero:  
;;; 6
        lda #0
_pushAA:
        pha
        jmp pushlPLAhA

_lit:   
;;; 8
        jsr get
        pha
        lda #0
        beq pushlPLAhA

_literal:       
;;; 15
        ;; lo
        jsr get
        pha
        ;; hi
        jsr get

pushlPLAhA:
        dex
        dex
setlPLAhA:      
        sta 1,x
        pla
        sta 0,x

        rts


_store: 
;;; 14
        lda 2,x
        sta (0,x)
        jsr _inc

        lda 3,x
        sta (0,x)

;;; TODO: these are counted in "STACK" in docs...
_drop2: 
        inx
        inx
;;; no savings unless can bXX here!
_drop:
        inx
        inx
        rts


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
;;; 11
        ;; lo
        lda (0,x)
        pha
        ;; hi
        jsr _inc
        lda (0,x)

        jmp setlPLAhA


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
;;; (+ 9  5 5 5 5 4  3 3 3 3 14) = 59 (10 ops!)
;;; (/ 59.0 10) = 5.9 B/ops
;;; shr shl not - + nip eor | & inc "math"

_inc:   
;;; (7)
        inc 0,x
        bne @noinc
        inc 1,x
@noinc:
        rts
        

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
        ;; last op ???
;;; TODO: revisit!
        bne _eor

;;; For
SBCzpx=$f5
ADCzpx=$75
LDAzpx=$b5
EORzpx=$55
ANDzpx=$35
ORAzpx=$15
STAzpx=$9d

.ifnblank
;;; Not efficient
;;; 10
_dup:   
_sta:   
        dex
        dex
        lda #STAzpx
        jsr math
        dex
        dex
        rts
.endif

_minus: 
;;; 5
        sec
        lda #SBCzpx
        bne math
_plus:
;;; 4
        clc
        lda #ADCzpx
        SKIPTWO
_nip:                           ; !!!
_swapdrop:
_lda:   
;;; 3
        lda #LDAzpx
        SKIPTWO
_eor:   
;;; 3
        lda #EORzpx
        SKIPTWO
_or:    
;;; 3
        lda #ORAzpx
        SKIPTWO
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

;;; here is a list of offset (walk back from 255)
offbytecode:

_mul10: .byte (mul10-secondpage)

.assert (*-_start)<256,error,"Out of space in page 1"

;;; ==================================================

secondpage:     

bytecodes:      

.macro DO fun
.assert (fun-_start)<256,error,"%% DO can only do funs in first page"
        .byte (fun-_start)
.endmacro

mul10:    
        DO _shl
        DO _dup
        DO _shl
        DO _shl
        DO _plus
        DO _semis
        
        
