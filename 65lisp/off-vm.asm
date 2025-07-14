.feature c_comments
/*
;;; ------------------- STATE ------------------
;;;                  2025-07-06
;;; 
;;;        BYTES: 241      WORDS: 30
;;; 
;;; IO=1
;;; LISP=1
;;; MINIMAL=1


;;; MINIMAL+LISP
;;;   BOOT _djz _key _emit _dupcar _dropcdr toptr1 printatom printz
;;;   (+ 3 6 7 6 2 22) = 46 bytes lisp extra


;;; MINIMAL+LISP exclude:
;;;   _lt _pick(A) _shl _not _minus _plus _or
;;;     (+ 9 (- 23 13) 5 3 5 4 3) = 39

;;;    BOOT:  6  1   _start
;;;    exec: 41  1   [TODO: jump] {_get} _sewis {_next _enter} (+ 8 5 16 12)
;;;    ctrl: 20  3   _jp _jz _djz (+ 3 8 9 )
;;;      IO: 13  2   _key _emit (+ 6 7) (+9 for UNC)
;;;   stack: 35  5   _dup _swap _drop2 _drop _nip (+ 13 14 2 3 3)
;;;    test: 37  6   _eq _null _FFFF _zero _lit _literal (+ 3 8 3 5 8 10) {_pushAA}
;;;     mem: 33  5   _store _dupcar _dropcdr _cdr _car/_load (+ 11 6 2 3 11)
;;;    math: 34  5   _inc2 _inc _shr [_minus _plus] _eor _and {_math} (+ 3 7 5 3 2 14) [_plus 5 _minus 4]
;;;  toptr1: 22  2    _toptr1 _printatom {_printzyplus1} (+ 8 5 9)
;;;    TODO:         _comma _ccomma _getatomchar _jump (+ 1 
;;; 
;;; (+ 6 41 20 13 35 37 33 34 22) = 241 bytes
;;; (+ 1  1  3  2  5  6  5  5  2) =  30 words

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
;;;   exec: 40  1"' _exit_ [get] next+enter
;;; 
;;; 
;;; (+ 40 43 26 59 32 20 21) = 241 (- 256 240) = 16
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

.ifdef UNC
unc:    .res 1
.endif

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



.ifdef MAX_BYTECODES

.zeropage
ip:     .res 2
.code

.endif ; MAX_BYTECODES

;;; TODO: reconsile?
;;; ---------------------------------- OLD exec
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

.ifdef UNC

;;; Reads the next
FUNC _key
;;; 12
        ldy #0
        lda unc
        bne got
        jsr getchar
got:    
        sty unc
        rts

.else

;;; Reads char, put on stack, and in A
;;; TODO: key
FUNC _key
;;; 6
        jsr getchar
        jmp pushA

.endif ; UNC


;;; TODO: emit?
FUNC _emit
;;; 7
        lda 0,x
        inx
        inx
        jmp putchar

.endif ; IO

;;; ------------------ STACK --------------------

.ifdef MINIMAL

FUNC _dup
;;; 8
        lda 0,x
        pha
        lda 1,x
        
        jmp push_hA_lPLA
.else

;;; cheapest w most flex???
; (+ 2 3 2 6 7 3) = 23
.ifnblank
FUNC _over
;;; 3
        lda #1
        SKIPTWO
.endif
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
setfromZPYm2:                   ; LOL
        lda 2,y
        pha
        lda 3,y
        ;; hA lPLA
;;; (3)
        jmp set_hA_lPLA
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
        jsr _eor                ; _minus works, too
        ;; fall-through
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
        jmp pushA

;;; having two "lits" is it worth it?
;;; (need at least 8 _lit to earn bytes...)
FUNC _lit
;;; 8
        jsr _get
pushA: 
        pha
        lda #0
        beq push_hA_lPLA

FUNC _literal
;;; 10
        ;; lo
        jsr _get
        pha
        ;; hi
        jsr _get

;;; (used by _dup too)
;;; 8
push_hA_lPLA:
        dex
        dex
set_hA_lPLA:      
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

        jmp set_hA_lPLA


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

.ifndef MINIMAL

;;; TODO: this one is right,
;;;   but for mul we need reverse!
;;; MINIMAL: needed for _eq!
FUNC _minus
;;; 4 (+1 !MINIMAL)
        sec
        lda #SBCzpx
        SKIPTWO
        bne _math

FUNC _plus
;;; 4
        clc
        lda #ADCzpx

;;; with this (4B extra) _not we save 1B
;;; -2 at _not bne _eor
;;; +1 bne /instead of skiptwo
.ifndef NOT
        SKIPTWO
.else
        bne _math

FUNC _not 
;;; 3
        jsr _neg1
        ;; fall-through to _eor
.endif ; NOT

.endif ; MINIMAL


FUNC _eor
;;; 3
        lda #EORzpx
        SKIPTWO

FUNC _nip                       ; !!!
_swapdrop:
_lda:   
;;; 3
        lda #LDAzpx
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

.ifdef IOSTRING
;;; (+ 8 5 9) = 22 _toptr1 _printatom _printz...

FUNC _toptr1
;;; 8 - 4 as bytecode! ( addr ptr1 store semis )
        lda #ptr1
;;; TODO: not efficient!
storeatZPA:
        jsr pushA
        jmp _store

.ifnblank
FUNC _fromptr1
        lda #ptr1
;;; TODO: not efficient!
pushZPA:
        jsr pushA
        jmp _load
.endif

FUNC _printatom
;;; 5
        jsr _toptr1
        ;; at offset 4
        ldy #4-1

.ifnblank
;;; ... 15+6 would be 21, but...
;;; 
;;; BAD: see _printimmstr
;;; 
;;; (+ 6 10 6) = 22 or (+ 6 3 6)= 15
FUNC _type
;;; (6)
        ;; Let's pretend we're interpreting str
        ;; "enter"
        lda ip
        pha
        lda ipy
        pha
        ;; set str from stack as new "ip"
        ;; "exec"
;;; (10)
        ;; jsr _setip
        inx
        inx
        lda $100-2+0,x
        sta ipy
        lda $100-2+1,x
        sta ip

;;; (6)
        jsr _printimmstr
        ;; this restores it!
        jmp semis

;;; Print Immediate String (following bytes)
;;; ends with 0
;;; 
;;; WARNING:BAD: string can't pass page border!
;;;  - lol - crap (for generitc strings)
FUNC _printimmstr
;;; 9
        jsr _get
        jsr putchar
        bne _type
        rts
.endif

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

.endif ; LISP






;;; VVVV--Keep the _jump instructions close as their
;;; implementations are directly dependent on the
;;; semis/next/enter!

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


.ifndef MAX_BYTECODES
;;; Jump if 0 without removing tos
;;; 
;;; 20
FUNC _djz
        jsr _dup
;;; Remove tos, if 0 jump
FUNC _jz
;;; (17)
        inx
        inx
        lda $100-2+0,x
        ora $100-2+1,x
        bne noj
        ;; do jmp - ipy= new addr
FUNC _jp
        jsr _get
        sta ipy
        rts
noj:
        ;; skip jmp dest byte
        inc ipy
        rts


;;; ^^^^ keep _jp close!

;;; ============ NEW EXEC
;;; (+ 8 5 16 12) = 41
;;; 
;;; Provides an interpreter (next) as well as
;;; way to do subroutines in bytecode (semis/enter).

;;; To make it gerneral lda+pha=3 pla+sta=3 ===> 6
;;; 

FUNC _get
;;; 8 (7)
        inc ipy
        ldy ipy
.ifdef MAX_BYTECODES
        lda (ip),y
.else
        lda bytecodes,y         ; +1 byte for abs addr
.endif


.ifnblank
        PHA
        TYA
        PHA
        TXA
        PHA

        putc '('
        ldy ipy
        lda bytecodes,y
        jsr print2h
        putc ')'

        PLA
        TAX
        PLA
        TAY
        PLA
.endif

        rts


FUNC _semis
;;; 5
;PUTC '\'

;;; TODO: if only 0 is used as semis
;;;   (not ;) then don't need plapla
;;;   but after jsr _get ; beq _semis

        ;; remove call (jsr(loop))
        pla
        pla
        ;; get ipy
        pla
        sta ipy

;;; total +3
;;; but allows jsr _next !
.ifdef JSRLOOP

jsrloop:
;;; 6
        jsr _next
        jmp jsrloop
.endif ; JSRLOOP

FUNC _next
;;; 16
        ;; next token
        jsr _get

.ifdef TRACE
jsr TRACE        
.endif

.ifndef MAX_BYTECODES
        cmp #<offbytecode
        bcs _enter
.endif ; MAX_BYTECODES
        
        ;; primtive ops in first page
        sta call+1

.ifdef JSRLOOP
;;; 3B more, but can jsr _next
call:   jmp _start
.else
call:   jsr _start
        jmp _next
.endif

FUNC _enter
;;; 12
        ;; bytecode in second page (only)
        ;; Y=ipy, A=index 0.. of routine to call!
        ;; C is set

        ;; look up second page offset at Y!
        ;; see label "offbytecode"
        ;; 
        ;;   ipy = _start[bytecodes[adjusted_ipy]]
;PUTC '-'
        tay
        lda bytecodes-(offbytecode-_start),y
        ;; "swap"
        ldy ipy
        sta ipy
        ;; push old Y
        tya
        pha

.ifdef MAX_BYTECODES
;;; 6
        lda ip+1
        pha
        lda ip
        pha
.endif ; MAX_BYTECODES

        bcs _next                ; C still set!

;;; Set this to last function+1 callable in VM
;;; any number >= this will be used to dispatch
;;; to byte code functions automatically.
offbytecode= _enter+1           ; lol

.else

;;; -------------------------------------
;;;     newer jsr _enter ip(y) code

;;; Forth65: (+ 18 25 6) = 49    (+ 16 19) = 35
;;;  84 bytes enter next semis branch zbranch
;;; 
;;;   DOCOL = 18 bytes (+ 3 JMP NEXT)
;;;     rpush(W)
;;;     IP+= 2
;;;     JMP NEXT
;;;   NEXT  = 25 bytes
;;;     W= *IP
;;;     IP+= 2
;;;     JMP W
;;;   SEMIS =  6       (+ 3 JMP NEXT)
;;;     IP= rpop()
;;;     JMP NEXT
;;; 
;;;   BRAN  = 16       (+ 3 JMP NEXT)
;;;   ZBRAN = 19 bytes     ( inc2 )


;;; _djz _jz _jp  _get _semis       _enter _next     _jsr
;;; (+        19     7      4           30     9)=69 (+11)
;;; 
;;; == 69 (+11) bytes ! ugh....

;;; ; >>>>>>>>>>>>>>>> 253 bytes
;;;    (can't fit _jsr)

;;; DO NOTE: _jp _jz _djz need to be relative!
;;;      (or not?)

;;; _dupjumpzero: Jump if 0 without removing tos
;;; (maybe this is the use of ?dup normally?)
;;; 
;;; (+ 3 8 5 3) = 19
FUNC _djz
;;; (3)
        jsr _dup
;;; Remove tos, if 0 jump
FUNC _jz
;;; (8)
        inx
        inx
        lda $100-2+0,x
        ora $100-2+1,x
        bne noj
        ;; do jmp - ipy= new addr
FUNC _jp
;;; (5) 
        jsr _get
;;; jp need to compensate with a +1, lol?

;;; ;;;;;; NONONONONONONO !!!!!!!!!!!!!!
;;; ; BAD IDEA... fixed means cannot have several
;;;   entry points.... lol
;;;   as this is relative a SINGLE start of routine...
;;;   (not a problemin Forth65...) hmmmm.
        sta ipy
noj:
;;; (3)
        ;; skip jmp dest byte
        inc ipy
        rts


;;; (+ 7 4 30 9) =  50

FUNC _get
;;; 7
        inc ipy
        ldy ipy
        lda (ip),y
        rts

;;; (+ 4 30) = 34
FUNC _semis
;;; 4
        pla
        pla

        sec
        SKIPONE
        
;;; JSR _enter BYTECODES...
;;; (+ 1 8 2 9 10) = 30
FUNC _enter
;;; 1
        clc
;;; 8 (3 more savey=ipy)
        pla
        sta savey

        pla
        sta savea
        pla
        tay
;;; +2
        bcs skip_push
;;; 9 (3 more ipy)
        lda ip+1
        pha
        lda ip
        pha
        lda ipy
        pha
skip_push:
;;; 10 (4 more ipy)
        sty ip+1
        lda savea
        sta ip
        lda savey
        sta ipy

        ;; fall-through

FUNC _next
;;; 9 (+4)
        jsr _get

        ;; all bytecodes fit/jmps to one page!
        sta call+1
call:   jmp _start

;;; ?? update
;;; (+ 9 4 13) = 26 ... => 13 indirect refs (/3=8)
offbytecodes= _next+1

.ifnblank

;;; TODO: this needs to be before _next/_enter
;;; 
;;; OR
;;; 
FUNC _call
;;; 13
        jsr _get
        tay
        jsr _get
        pha
        tya
        pha
        jmp _enter
.endif

.ifnblank
;;; call machine-code routine
;;; (could be bytecode w "JSR VM" prefix)
FUNC _foo
FUNC _jsr
;;; 11
        ;; lo
        jsr _get
        tay
        ;; hi
        jsr _get
        pha
        tya
        pha
        ;; famous
        rts
.endif
FUNC _bar

.ifnblank ; _enter alternatives





;;; _djz _jz _jp  _get _semis       _enter _next _jsr
;;; (+ 3  19 9 3    11      4  1 5 2 6 6 9     9   11)
;;; == 98 bytes ! ugh....

;;; DO NOTE: _jp _jz _djz need to be relative!

;;; _dupjumpzero: Jump if 0 without removing tos
;;; (maybe this is the use of ?dup normally?)
;;; 
;;; (+ 3 9 19 3) = 34
FUNC _djz
;;; (3)
        jsr _dup
;;; Remove tos, if 0 jump
FUNC _jz
;;; (9)
        inx
        inx
        lda $100-2+0,x
        ora $100-2+1,x
        bne noj
        ;; do jmp - ipy= new addr
FUNC _jp
;;; (19) -- too big???
        jsr _get

        ;; sign extended add ip+= (+/-)A
        ldy #0
        bpl pos
        dey                     ; $ff if negative!
pos:    
        clc
        adc ip
        sta ip
        ;; add with sign extended value
        tya
        adc ip+1
        sta ip+1

        rts
noj:
;;; (3)
        ;; skip jmp dest byte
        inc ipy
        rts


;;; (+ 11 4 20 9) = 44
;;;                +17 (4+13 for "internal bytecode")
;;;                ---
;;;                 61
;;; 17 bytes code overhead + 2 bytes per routine
;;; but saves 3 bytes no "jsr _enter" neeed.
;;; 
;;; :.  17+2n = 3n  => n>=17 routines gives benefit
;;; 
;;; Bigger saving might be not need CALL bytecodeaddr
;;; 1 byte instead of 3 bytes (+ 13 bytes _call)
;;; 
;;; :.  savings= n-17 + calls*2 + 13 = n+calls*2 - 4
;;; 
;;; n=2 => calls >= 1
;;; n=4 => calls >= 0
;;; n=5 => calls >= 6

FUNC _get
;;; 11
        inc ip
        bne noinc
        inc ip+1
noinc:  
        ldy #0
        lda (ip),y
        rts

;;; BEST BEST BEST!!!
;;; (+ 4 21) = 25
FUNC _semis
;;; 4
        pla
        pla

        sec
        SKIPONE
        
;;; JSR _enter BYTECODES...
;;; (+ 1 5 2 6 6) = 20
FUNC _enter
;;; 1
        clc
;;; 5
        pla
        sta savea
        pla
        beq _enter
        tay
;;; +2
        bcs skip_push
;;; 6
        lda ip+1
        pha
        lda ip
        pha
skip_push:
;;; 6
        sty ip+1
        lda savea
        sta ip

        ;; fall-through

FUNC _next
;;; 9 (+4)
        jsr _get

;;; if TRANSLATION, user interaction
.ifdef FULL_VECTOR

;;; 7 + 3 ==> 10 bytes total
;;;           BUT 256 bytes translation... lol
        asl
.ifdef HIBIT_JUMP
;;; (2)
        bcs jumps
.endif
        sta call+1
call:   jmp (translationtable)


.ifdef HIBIT_JUMP
; hibit set means relative jump
;;; So we can jump +/-63
jumps:
;;; (+ 44 -9 10 2 16) = 63 ... TOO BIG...
;;;                       if have jump table just overflow
;;;                       maybe also not use so minimal...
;;;                       but faster implementation....!
;;; 16
        ;; C=1
        adc #64-1
        ;; ip+= A
        clc
        adc ip
        sta ip
        lda #0
        adc ip+1
        sta ip+1
        jmp _next
.endif ; HIBIT_JUMP

.else
.ifdef INTERNAL_BYTECODE
;;; (+4)
        cmp #<offbytecodes
        bcs internal_bytecodes
.endif
        sta call+1
call:   jmp $ffff
.endif

;;; OPTIONAL
;;; 
;;; These utilize an secondary trampoline
;;; located at the beginning of second page
internal_bytecodes:
;;; 13
        tay
        ;; hi
        lda second_page+(offbytecodes-_start),y
        pha
        ;; lo
        dey
        lda second_page+(offbytecodes-_start),y
        pha
        jmp _enter

;;; (+ 9 4 13) = 26 ... => 13 indirect refs (/3=8)
offbytecodes= _next+1

.ifnblank

;;; TODO: this needs to be before _next/_enter
;;; 
;;; OR
;;; 
FUNC _call
;;; 13
        jsr _get
        tay
        jsr _get
        pha
        tya
        pha
        jmp _enter
.endif

;;; call machine-code routine
;;; (could be bytecode w "JSR VM" prefix)
FUNC _jsr
;;; 11
        ;; lo
        jsr _get
        tay
        ;; hi
        jsr _get
        pha
        tya
        pha
        ;; famous
        rts




;;; (+ 8 18 2) = 28
FUNC _semis
;;; 8
        pla
        pla

        ;; exchange w zero to pop!
        lda #0
        sta ip
        sta ip+1
        
        ;; fall-through

;;; (+ 5 6 6 1) = 18
FUNC _enter
;;; 5 (+2 for _semis)
        pla
        sta savea
        pla
        ;; hi=0 => pop!
        beq _enter
        tay
;;; 6
        lda ip+1
        pha
        lda ip
        pha
;;; 6
        sty ip+1
        lda savea
        sta ip
;;; 1
        rts


;;; what if we had two ip to toggle between? !!!
;;; (+ 8 8 8 3 13 -1) = 39
FUNC _enter
        ;; swap yc yo pointer, lol
;;; 8
        ldy yc
        lda yo
        sty yo
        sta yc
;;; 8
        ;; load new ip
        ldy yc
        pla
        sta ip,y
        pla
        sta ip+1,y
        
;;; 8
        ;; save old ip
        ldy yo
        lda ip,y
        pha
        lda ip+1,y
        pha

;;; 3
        jmp _next
        
FUNC _semis
;;; 13 - 2
        pla
        pla
        
        ;; load "old" new ip
        ldy yc
        pla
        sta ip,y
        pla
        sta ip+1,y
        
        jmp _next



;;; is smallest????
;;; (+ 26 4) = 30
FUNC _semis
;;; 4
        pla
        pla

        sec
        SKIPONE
FUNC _enter
        clc
;;; (+ 3 6 6 11) = 26
;;; 
        ;; _fromR
FUNC _semis2
;;; 6
        pla
        sta savea
        pla
        sta savey
        ;; _rpuship
        bcs skip_push
;;; 6
        lda ip+1
        pha
        lda ip
        pha
skip_push:      
        ;; _jump
        ;; IP= pop
_jump:  
;;; 11
        lda savea
        sta ip
        lda savey
        sta ip+1
        rts



;;; _get 11 _next 9 (single offset still)
;;;         (all callable bytecodes need trampoline)
;;; (+ 11 9 30) = 50 ....

;;; (+ 9 10 11) = 30
;;; swap 2
FUNC _enter
;;; 9 
        stx savex
        txa
        jsr _ripswap
        ldx savex
        SKIPTWO
FUNC _semis
;;; 10
        pla
        pla

        pla
        sta ip
        pla
        sta ip+1
        bne _next
        
_ripswap:       
;;; 4
        jsr _bripswap
        inx
_bripswap:       
;;; 11
        ;; lo
        lda 102,x
        ldy ip
        sta ip
        sty 102,x
        rts


;;; (+ 26 11) = 37
;;; swap 2
FUNC _enter
;;; 26
        stx savex

        txa
        ;; lo
        lda 100,x
        ldy ip
        sta ip
        sty 100,x
        ;; hi
        lda 101,x
        ldy ip
        sta ip
        sty 101,x

        ldx savex
        SKIPTWO
FUNC _semis
;;; 11
        pla
        pla

        pla
        sta ip
        pla
        sta ip+1
        jmp _next



;;;  BEST????

;;; (+ 20 9) = 29 no ipy
FUNC _enter
;;; 20
        ;; save new
        pla
        sta savea
        pla
        sta savey
        ;; push old
        lda ip+1
        pha
        lda ip
        pha
        ;; push new
        lda savey
        pha
        lda savea
        pha

        SKIPTWO
FUNC _semis
;;; 9
;;; remove jsrloop
        pla
        pla
FUNC _loadip2
        pla
        sta ip
        pla
        sta ip+1

;;; ... _next


;;;  plain but ...

FUNC _enter
;;; (+ 5 9 11) = 25
;;; 5
        pla                    
        tay
        pla
        sta savea
;;; 9
        lda ip+1
        pha
        lda ip
        pha
        lda ipy
        pha
;;; 11
        lda savea
        sta ip+1
        sty ip
        ldy #0
        sty ipy

        rts

FUNC _semis
        pla
        pla
        
        pla

        

FUNC _enter
;;; (+ 6 9 13) = 28
        ;; jsr call addr
;;; 6
        pla
        sta savea
        pla
        sta savex
        ;; store current
;;; 9
        lda ip+1
        pha
        lda ip
        pha
        lda ipy
        pha
        ;; set new
;;; 13
        lda savex
        sta ip+1
        lda savea
        sta ip
        lda #0
        sta ipy

        rts


;;; All bytecodes are machine code which require
;;; an "JSR _enter" that'll get here
;;; (cannot return to machine code after)
;;; (TODO: special _semis_to_machinecode?)

;;; (+ 13 33) = 46 ... + _next :-(
FUNC _semis
;;; 13
        ;; get rid of jsrloop
        pla
        pla
        ;; call _enter and...
        jsr _s_ret
        ;; ... and
        ;; here after _enter
        ;; ip(y) has been "reset"
        ;; (drop where we were)
        pla
        pla
        pla
        bne _next               ; never called from ZP

_s_ret: jmp _enter
        

FUNC _enter
;;; 14+19 = 33...
        ;; on stack==bytecodeaddr-1 !
        lda #0
        pha
        ;; swap 3 bytes on stack <-> ip(y)
        stx savex
        tsx

        jsr swaprip

        ldx savex
        jmp _next


;;; swap 3 bytes ip(2) ipy(1) w R stack
swaprip:        
;;; 19
        jsr swaprbyte
        jsr swaprbyte
swaprbyte:
;;; (13)
        ;; rstack: ... newip' newip newipy call' call -
        ;; swap R:ip <-> ip
        lda ip
        ldy 102,x
        sta 102,x
        sty ip
        inx
        inx
        rts
.endif ; NBLANK ; _enter alternatives


.endif ; MAX_BYTECODES




        ;;  NO CALLABLE FUNC CODE AFTER HERE!!!!!





;;; ============END NEW EXEC


        ;;  NO CALLABLE FUNC CODE AFTER HERE!!!!!


FUNC _endvm




.ifdef TRACE
TRACE:  
        ;stx savex
        pha
        tya
        pha
        txa
        pha

        putc 10

        ;lda savex            
        txa
        clc
        adc #'j'
        jsr putchar
        ;jsr print2h

        ;; jsk to find it fast!

        tsx
        txa
        clc
        adc #'M'
        jsr putchar
                                ;jsr print2h

        putc '.'
        lda ipy
        jsr print2h

        putc ':'
        lda call+1
        jsr print2h

        putc ' '

                                ;halt:   jmp halt

        pla
        tax
        pla
        tay
        pla

        rts
.endif ; TRACE
