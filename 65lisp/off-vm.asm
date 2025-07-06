.feature c_comments
/*
;;; ------------------- STATE ------------------
;;;                  2025-07-06
;;; 
;;;        BYTES: 246      WORDS: 27
;;; 
;;; IO=1
;;; LISP=1
;;; MINIMAL=1
;;; 
;;;    exec: 39  1   [TODO: jump] {_get} _sewis {_next _enter} (+ 8 3 16 12)
;;;      IO: 15  2   _key _emit (+ 8 7)
;;;   stack: 33  5   _dup _swap _drop2 _drop nip (+ 11 14 2 3 3)
;;;    ctrl: 17  2   _jp _jz (+ 3 14)
;;;    test: 39  6   _eq _null _FFFF _zero _lit _literal (+ 3 8 3 2 8 15) {_pushAA}
;;;     mem: 33  5   _store _dupcar _dropcdr _cdr _car/_load (+ 11 6 2 3 11)
;;;    math: 43  7   _inc2 _inc _shr _minus _plus _eor _and {_math} (+ 3 7 5 5 4 3 2 14)
;;;             TODO: _minus, can eq be made without?
;;;  toptr1: 23  1    {_toptr1} _printatom {_printzyplus1} (+ 9 5 9)
;;;    TODO:         _comma _ccomma _getatomchar _jump (+ 1 
;;; 
;;; (+ 39 15 33 17 39 33 43 23) = 242 wtf bytes (246 in file?)
;;; (+  1  2  5  2  6  5  7  1) =  29 words

*/



;;;    jmps: 17  2    _nilq _jnil (+ 17)





;;; ;;;;;;;;;;;;;;;;; OLD ;;;;;;;;;;;;;;;;;;;
;;;  stack: 43  5"" _drop2 _drop _swap _dup _pick [pushAY AYtoTOS pushAA] (+ 2 2 14 2 23) {_pickA, setpickA}
;;;    mem: 25  2   ! @ (+ 14 11) 
;;;   math: 59 10   nip - + EOR | & _not +shr +shl inc {dec} {9}
;;;  const: 32  4   _true 0 ' _literal (+ 3 6 8 15)
;;;   test: 20  3   _null _eq _lt (+ 8 3 9)
;;; branch: 17  2   _jp _jz (+ 3 14)


;;; --- GENERIC 
;;;   exec: 69  3"' call _exec+_exit_ [get _next _execA] (+ 47 22) subr + get+jsrloop+next+call (+ 7 6 3 6)=22
;;; 
;;;              - OVERFLOW -
;;; 
;;; (+ 69 43 26 59 32 20 17) = 266 !!!!!
;;; (+  3  5  2 10  4  3  2) =  29  extra"""= 6
;;; (/ 267.0 29) =  9.2 B/op !
;;; (- 256  267) = -11... (+ 32 39)=71 mul+divmod



;;; TODO: drop & drop2 was part of BIG exec
;;;    5 bytes more?

;;; --- 2 PAGE (one prims, one bytecodes)
;;;   exec: 39  1"' _exit_ [get] next+enter
;;; 
;;; 
;;; (+ 39 43 26 59 32 20 21) = 249 (- 256 240) = 16
;;; (+  1  5  2 10  4  3  2) =  27
;;; 
;;; :- means can have max 21 bytecode routines in 2nd

;;; -----------------------------------------------
;;; LISP: to be used in a LISP
;;; 
;;;  stack: 43  5"" _drop2 _drop _dup _pick _swap [pushAY AYtoTOS pushAA] (+ 2 2 2 2 5 13 17)
;;;    mem: 26  2   ! @ (+ 12 14) 
;;;   math: 59 10   nip - + EOR | & _not +shr +shl inc {dec} (+ 31 5 5 5 7) {9}
;;;   test: 18  3   _null _eq _lt (+ 8 3 7)
;;; 
;;; (+ 43 26 59 18) = 146 bytes
;;; (+  5  2 10  3) =  19 impls

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

 
.zeropage

.ifndef ipy
ipy:    .res 1
.endif

ptr1:   .res 2

savea:  .res 1
savex:  .res 1
savey:  .res 1
savez:  .res 1                  ; haha!


.code

.feature org_per_seg

;;; TODO: why need?

;.org $700

;.res (255-(* .mod 256))

.ifndef _start
FUNC _start
.endif

.ifnblank

;;; only used in this branch,
;;; the other only have ipy!

.zeropage
ip:     .res 2
.code

;;; subr
;;; (+ 3 11 6 10 3 9 5) = 47
;;; call exec callit enter loadip semis

;;; call bytecode
FUNC _call
;;; 3
        jsr _literal
;;; _exec bytecode from stack ( addr - )
FUNC _exec
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
FUNC _ovm65 
FUNC _interpret
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
FUNC get
;;; 7 (saves at least 3 bytes as subtroutine)
        inc ipy
        ldy ipy
        lda (ip),y
        rts

FUNC _drop2
;;; 2
        inx
        inx
FUNC _drop
;;; 2
        inx
        inx

_next:
;;; 3 20c (+ 12+6+9=27c rts 1B to loop, OR 3c jmp next 3B)
        jsr get
FUNC _execA
;;; 6
        sta go+1                ; lo offset
go:     jmp ONEPAGE


FUNC _semis:
;;; 5
        ;; remove jsrloop
        pla
        pla
        jmp loadip

.endif ; OLD exec


.ifdef IO

;;; Reads char, put on stack, and in A
;;; TODO: key
FUNC _key
;;; 8
        jsr getchar
        ldy #0
        jmp pushAY

;;; TODO: emit?
FUNC _emit
;;; 7
        lda 0,x
        inx
        inx
        jmp putchar

.endif ; IO




;;; ============ NEW EXEC
;;; (+ 8 3 16 12) = 39

FUNC _get
;;; 8 
        inc ipy
        ldy ipy
        lda bytecodes,y
        rts

FUNC _semis
;;; 3
        pla
        sta ipy
FUNC _next
;;; 16
        ;; next token
        jsr _get

        ;; NOTE: C flag modified...
        cmp #<offbytecode
        bcs _enter
        
        ;; primtive ops in first page
        sta call+1
call:   jsr _start
        jmp _next

FUNC _enter 
        ;; bytecode in second page (only)
        ;; Y=ip A=new to interpret

;;; 12
        ;; Y=ipy, A=zeropage offset containing
        ;; C modified before

        ;; look up second page offset at Y!
        ;; see label "offbytecode"
        ;; 
        ;;   ipy = _start[bytecodes[ipy]]
        tay
        lda _start,y
        ;; "swap"
        ldy ipy
        sta ipy
        ;; push old Y
        tya
        pha
        bcs _next                ; C still set!

;;; ============END NEW EXEC

;;; ------------------ STACK --------------------

.ifdef MINIMAL

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

.else

;;; cheapest w most flex???
; (+ 2 3 2 6 7 3) = 23
FUNC _dup
;;; 2
        lda #0
FUNC _pickA 
;;; 3
        dex
        dex
        SKIPTWO
FUNC _pick
;;; 2
        lda 0,x
;;; 15
FUNC _setpickA 
;;; (6)
        asl
        stx savex
        adc savex
        tay

;;; (7)
        lda 2,y   
        pha
        lda 3,y
        ;; hA lPLA
;;; (3)
        jmp setlPLAhA
.endif

;;; TODO: _rot _over _pick
;;;       >R <R (jmp next) @zp !zp (vars?)

;;; 14 (can't do shorter?
FUNC _swap   
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
FUNC _jVsym 
        bvs _j
        bvc noj
FUNC _jZull  
        beq _j
        bne noj

;;; (10)
.ifnblank
FUNC _RetNoCons     
        bcs ret
        bcc _exit_
;;; _jzvc go_Zull go_Vsym ...cons
FUNC _jZVC
        jsr _jZull
        jsr _jVsym
.endif
FUNC _jCons
        bcs _j
noj:    
        inc ipy
        rts
.endif

FUNC _jp
;;; 3
        jsr _zero
FUNC _jz
;;; 14
        inx
        inx

        lda 256-2,x
        ora 256-1,x
        bne @noj
        ;; do jmp - ipy= new addr
        jsr _get
        sta ipy
@noj:   
        rts

.ifndef MINIMAL

FUNC _lt
;;; 9
        jsr _minus
        inx
        inx
        bcc _true
        bcs _zero
.endif

FUNC _eq
;;; 3
        jsr _minus
FUNC _null  
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
FUNC _FFFF  
_neg1:  
_true:  
;;; 3
        lda #$ff
        SKIPTWO
;;; Z=1 after call
FUNC _zero
;;; 6
        lda #0
FUNC pushAA
        pha
        jmp pushlPLAhA

FUNC _lit
;;; 8
        jsr _get
        pha
        lda #0
        beq pushlPLAhA

FUNC _literal
;;; 15
        ;; lo
        jsr _get
        pha
        ;; hi
        jsr _get

pushlPLAhA:     
        dex
        dex
setlPLAhA:      
        sta 1,x
        pla
        sta 0,x

        rts


FUNC _store
;;; 16
        lda 2,x
        sta (0,x)
        jsr _inc

        lda 3,x
        sta (0,x)

;;; TODO: these are counted in "STACK" in docs...
FUNC _drop2 
;;; 2
        inx
        inx
;;; no savings unless can bXX here!
FUNC _drop
;;; 3
        inx
        inx
        rts



.ifnblank
;;; (+ 6 13) = 19
FUNC _store 
;;; (6)
        jsr _comma
        jmp _drop2

;;; ((13))
FUNC _comma
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


.ifdef LISP
FUNC _dupcar
;;; 6
        jsr _dup
        jmp _car

FUNC _dropcdr
;;; 2
        inx
        inx
FUNC _cdr
;;; 3
        jsr _inc2
FUNC _car   
.endif ; LISP
FUNC _load
;;; 11
        ;; lo
        lda (0,x)
        pha
        ;; hi
        jsr _inc
        lda (0,x)

        jmp setlPLAhA


.ifnblank
FUNC _dec   
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

.ifdef LISP
FUNC _inc2
        jsr _inc
.endif
FUNC _inc   
;;; (7)
        inc 0,x
        bne @noinc
        inc 1,x
@noinc:
        rts


FUNC _shr   
;;; 5
        lsr 1,x
        ror 0,x
        rts

.ifndef MINIMAL
FUNC _shl   
;;; 5
        asl 0,x
        rol 1,x
        rts
FUNC _not   
;;; 5
        jsr _neg1
        ;; last op ???
;;; TODO: revisit!
        bne _eor
.endif

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
FUNC _dup: 
_sta:   
        dex
        dex
        lda #STAzpx
        jsr _math
        dex
        dex
        rts
.endif

;;; TODO: this one is right,
;;;   but for mul we need reverse!
FUNC _minus
;;; 5
        sec
        lda #SBCzpx
        bne _math
FUNC _plus
;;; 4
        clc
        lda #ADCzpx
        SKIPTWO

FUNC _nip                       ; !!!
_swapdrop:
_lda:   
;;; 3
        lda #LDAzpx
        SKIPTWO
FUNC _eor
;;; 3
        lda #EORzpx
        SKIPTWO

.ifndef MINIMAL
FUNC _or
;;; 3
        lda #ORAzpx
        SKIPTWO
.endif

FUNC _and
        lda #ANDzpx
;;; 2

FUNC _math
;;; 14
        sta @op
        jsr @one
@one:
        lda 2,x
@op:    adc 0,x
        sta 2,x

        inx
        rts

.ifnblank
;;; If we use _math 2x we saved!
FUNC _plus
;;; 14
        clc
        lda 0,x
        adc 2,x
        sta 2,x
        lda 1,x
        adc 3,x
        sta 3,x
        rts
.endif

.ifdef LISP
FUNC _toptr1
;;; 9
        lda 0,x
        sta ptr1
        lda 1,x
        sta ptr1+1
        rts

FUNC _printatom
;;; 5
        jsr _toptr1
        ;; at offset 4
        ldy #4-1

;;; prints ascizz pointed to at ptr1
;;; starting at position Y+1
;;; 
;;; 9
FUNC _printzyplus1
;       dey ; for printzy
pnext:   
        iny
        lda (ptr1),y
        jsr putchar
        ;; ok, we'll print \0, any harm? lol
        bne pnext

        rts

FUNC _end
.endif ; LISP


.ifdef SECONDPAGE


;;; All "instructions" of our bytecode language
;;; are offsets into the firstpage: _start[instr]
;;; 
;;; Normally, these are machinecode locations for
;;; primtivies.
;;; 
;;; But for "syntesized" bytecode routines, they
;;; are used as an offset to get the offset of
;;; the bytecode routine in page2: _bytecodes[offset].

;;; Effectively:
;;; 
;;; next:
;;; 
;;; get:  
;;;    o= bytecodes[ipy]
;;; 
;;;    if o < offbytecode
;;;      JSR _start+o
;;;    else
;;;      PHA ipy
;;;      ipy= _start[o]
;;;    
;;;    goto next

.macro MAPTO bytecodefun
        .assert (bytecodefun-bytecodes)>=0,error,"%% MAPTO only maps to labels in bytecodes page"
        .assert (bytecodefun-bytecodes)<256,error,"%% MAPTO it seems the bytecodes page is full"

        ;; We store offset-1 as we prc-inc in get
        .byte (bytecodefun-bytecodes)-1
.endmacro


;;; Here is a list of offsets (walk back from 255)
offbytecode:
;;; add directly after here:

;_readbyte:      MAPTO readbyte
;_read:          MAPTO read
FUNC _eval
        MAPTO eval
FUNC _readeval
        MAPTO readeval
FUNC _mul10
        MAPTO mul10

.assert (*-_start)<256,error,"%% Out of space in page 1"

;;; ==================================================

.res (255-(* .mod 256))
bytecodes:     

;;; first byte to "skip"
.byte 42

readeval:
        DO _read
        DO _eval
        JP readeval

read:   
eval:   
        DO _semis

;;; set hi-bit of the last char in string
;;; (saves one byte!)
.macro HISTR str
        .byte .left(.strlen(str)-1, str)
        .byte 128 | .strat(str, .strlen(str)-1)
.endmacro


;;; 5
readbyte:
        DO _load
        LIT $ff
        DO _and
        DO _semis
        

;;; _mul10
mul10:
        DO _shl
        DO _dup
        DO _shl
        DO _shl
        DO _plus
        DO _semis

;;; 

.endif ; SECONDPAGE

