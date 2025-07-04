;;; cut-n-paste variants not used?

;;; set hi-bit of the last char in string
;;; (saves one byte!)
.macro HISTR str
        .byte .left(.strlen(str)-1, str)
        .byte 128 | .strat(str, .strlen(str)-1)
.endmacro

;;; 22
_printz: 
;;; (8)
        jsr _toptr1
        ;; read string offset rel start of atom
        ldy #4
        lda (ptr1),y
        tay

pnextc: 
;;; (14)
        lda (ptr1),y
        ;; zero ends
        beq pdone
        pha
        and #$7f
        jsr putchar
        pla
        ;; or if hi bit set of last char
        bpl pnextc
pdone:  
        rts
        


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


; (+ 2 3 2 15) = 22
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

;;; 5
        lda 2,y
        pha
        lda 3,y
        ;; hA lPLA
        
;;; (+ 6 5 4) = 15

        ;; set
;;; 4
        tay
        jmp setPLAY

        ;; push
;;; 4
        tay
        jmp pushAY



; (+ 5 2 6 9) = 22

;;; replaces N with Nth pick
_pick:
;;; 5
        lda 0,x
        inx
        inx
        SKIPTWO
_dup:   
;;; 2
        lda #0
;;; pushes Ath pick
;;; ((15))
pickA:
;;; (6)
        asl
        stx savex
        adc savex
        tay

;;; 11
        dex
        dex
        lda 2,y
        sta 0,x
        lda 3,y
        sta 1,x
        rts
        

;;; (9)
        lda 2,y
        pha
        lda 3,y
        ;; hA lPLA
        tay
        jmp pushAY





;;; -- stack

;;; 24 == too much!
_dup:   
;;; 3
        lda #0
        SKIPTWO
;;; N pick; N=0 => dup, N=1 => over
;;; replaces N to pick with VALUE
_pick:  
;;; 21
        lda 0,x
        ;; replacing value
        inx
        inx
;;; push picked value A
_pickA: 
        dex
        dex
setPickA:
        asl
        stx savex
        adc savex
        tay

setPickZPY: 
        lda 0,y
        sta 2,x
        lda 1,y
        sta 3,x

        rts

;;; 22 == too much!
_dup:   
;;; 5
        lda #0
        dex
        dex
        SKIPTWO
;;; N pick; N=0 => dup, N=1 => over
;;; replaces N to pick with VALUE
_pick:  
;; 17
        lda 0,x
setPickA:
        asl
        stx savex
        adc savex
        tay

setPickZPY: 
        lda 0,y
        sta 2,x
        lda 1,y
        sta 3,x

        rts


.ifnblank

setPickZPY: 
;;; 5+3 = 8
ZPYtolPHAhA:    
        lda 0,y
        pha
        lda 1,y

setlPLAhA:
;;; 6
        sta 1,x
        pla
        sta 0,x
        rts

;;; 17
pickY:   
;;; 8
        sty savey
        txa
        asl savey
        adc savey
        tay
;;; 9
        ...
        

;;; 21
dup:    
;;; 6
        dex
        dex
        lda #1
        sta 0,x                 ; ugly
;;; shortest, but dup is big...
;;; 15
pick:  
;;; 
        txa
        asl 0,x                 ; modify! (throw away)
        adc 0,x
        ;; replace a value
        tay

;;; 9
        lda 0,y
        sta 0,x
        lda 1,y
        sta 1,x

        rts

;;; shorter but can't give A input from reg
;;; 16
pickA:  
        txa
        clc
        adc 0,x
        adc 0,x
        ;; replace a value
        tay

        lda 1,y
        pha
        lda 2,y
        tay

        jmp setPLAY
        
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
.endif


avar=tos
_toA:
        ldy #avar
toY:   
;;; 11
        lda 0,x
        sta 0,y
        lda 1,x
        sta 1,y
        jmp _drop

;;; (+ 6 3 10 3 2 7) = 31
;;; load wread cread incA inc

_load:
;;; (6)
        jsr _toA
        jsr _zero
_wread: 
;;; (3)
        jsr _cread
        ;; fall-through to _cread

;;; NOTE: you may need to _zero first!
_cread:  
;;; (10)
        ;; hi = lo
        lda 0,x
        sta 1,x
        ;; lo = byte[vara++]
        ldy #0
        lda (areg),y
        sta 0,x
_incA: 
;;; (3)
        ldy #areg
        SKIPTWO
_inc:   
;;; (2)
        txa
        tay
_incR:   
;;; (7)
        inc 0,y
        bne @noinc
        inc 1,y
        rts


;;; -----------------------------------
;;; TESTS JMPS
;;; 
;;; (+ 8 9 6) = 23 B

;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;;   to <= do: inc <
;;;   to >  do: swap <
;;;   to >= do: < null
;;;   to == do: - null

;;; 10 B (still 1 byte over!... lol)
FUNC "_lessthan"

        uJSR _minus
C_gives_FFFF_else_0000:     
        ;; C=0 if smaller => $ff else $00 !
        lda #0
        sbc #0                  ; haha! (=> V=0)

;;; Notice require V=0
VC_loadbothAA:     
        pha
        bvc loadApla            ; V=0 for sure!

;;; (+ 5 6 2 6) = 19 B - same as macro, if have _lessthan
FUNC "_eq"
        uJSR _minus
        ;; compensate for _null/_zero that pushes
        dex
        dex
FUNC "_null"
        lda tos
        ora tos+1
        beq _FFFF
FUNC "_zero"
        sec
        ;; hack - BITzp skip one byte
        ;; (not affect C)
        .byte $24
FUNC "_FFFF"
_neg1:  
        clc
pushC:  
        jsr _push
        ;; _push leaves Z=0
        bne C_gives_FFFF_else_0000

.ifndef MINIMAL

;;; 'a
FUNC "_quote"
;;; 6 B
        uJSR _nexttoken
        jmp _pushA

;;; 10 B
.ifnblank
;;; _cmp
;;; 13 B - funny but not smallest....
        uJSR _minus
        ;; Y == 2 (can we assert this somehow???)
        dey                     ;  1   1
        bcc notSmaller
smaller:                        ; !<   <
        dey                     ;      0
notSmaller:     
        dey                     ;  0  -1

        sty tos
        sty tos+1
        rts
.endif

.endif ; MINIMAL _lessthan


;;; TODO: we really want this in!!!
;;;   (17 B too much)
;;;   how about just a < ??
;;;  
.ifnblank

;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;; 17 B (= 262 bytes, lol, 6 too many)
FUNC "_cmp"
        uJSR _minus
;;; TODO: _minus may have been reversed look at _mathop....

        ;; Y == 2
        bcc AisSmaller          ; => -1
        bne AisBigger           ; => +1
        beq equal               ; +   0

;;; LOL (saves 2 bytes)
AisSmaller:                     ; =   >    <
        dey                     ;         +1
equal:
        dey                     ; +1       0
AisBigger:
        dey                     ;  0  +1  -1
        
        sty tos
        sty tos+1               ; $0 $11 $ff - lol
        rts
.endif ; !BLANK


.ifnblank ; more src uJSR



;;;; 13
        pla

        pha
        tay
        lda jmptable-1,y
        jsr callit
        ;; comes back here!
        php
        rti

callit: bne callAoffset


;;;; 14
        pla

        pha
        tay
        lda jmptable-1,y
        sta subr+1              ; change lo
subr:   jsr jmptable
        php
        rti


;;; small but wrong, jmps back one char after when ret with RTS
;;; 9 B - smallest so far!
        pla                     ; throw away P
        pla                     ; lo - points to byte after!
        pha
        tay
        ;; get byte after call (from one page)
        lda jmptable-1,y        ; get previous byte!
        bne callAoffset


;;; handle call from outside onepage/twopage
;;; 
;;; 15 B
        pla                     ; throw away P
        pla
        tay                     ; lo from
        pla
        pha
        sta brkadr+2            ; hi from
        tya
        pha
brkadr: lda jmptable-1,y        ; lo to
        bne callAoffset

.endif ; more alt src uJSR

.endif ; _uJSR

;_initlisp:

        sec                     ; => 00
        clc                     ; => ?? (ff)    (is smaller!)
        lda #0
        sbc #0
;;; V=0 for sure!

        tay

.ifblank
;;;  carray?
        ldx #'1'
        bvs skip
        dex
skip:   
        txa
        jsr putchar

        lda #':'
        jsr putchar
.endif

;;;  print hex
        tya

        and #15
        ora #$30
        jsr putchar

        tya
        ror
        ror
        ror
        ror
        
        and #15
        ora #$30
        jsr putchar

        rts
.end



;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;; 
FUNC "_lessthan"
;;; 13 B

;;; TODO: reverse order of A-B I think mathop makes it
;;; 
;;;        tos -= stack   .... lol
;;; 
;;;     we want tos = stack - tos
;;; 
;;;    but this would also change pop, push, swap .... _lda _sta???
;;;    REVERSE? - need testing...

;;; 10 B
        uJSR _minus
        ;; C=0 if smaller => $ff else $00 !
        lda #0
        sbc #0                  ; haha! (=> V=0)

        pha
        bvc loadApla            ; V=0 for sure!

;;; 10 B
.ifnblank
        uJSR _minus
        
        lda #0
        rol
        pha
        
        jmp loadApla

;;; !!! opposite!
        ;; C=1 => $0101
        ;; C=0 => $0000     is smaller should be ...
        

;;; 13 B - funny but not smallest....
        uJSR _minus
        ;; Y == 2 (can we assert this somehow???)
        dey                     ;  1   1
        bcc notSmaller
smaller:                        ; !<   <
        dey                     ;      0
notSmaller:     
        dey                     ;  0  -1

        sty tos
        sty tos+1
        rts
.endif


;;; TODO: we really want this in!!!
;;;   (17 B too much)
;;;   how about just a < ??
;;;  
.ifndef MINIMAL

;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;; 17 B (= 262 bytes, lol, 6 too many)
FUNC "_cmp"
        uJSR _minus
;;; TODO: _minus may have been reversed look at _mathop....

        ;; Y == 2
        bcc AisSmaller          ; => -1
        bne AisBigger           ; => +1
        beq equal               ; +   0

;;; LOL (saves 2 bytes)
AisSmaller:                     ; =   >    <
        dey                     ;         +1
equal:
        dey                     ; +1       0
AisBigger:
        dey                     ;  0  +1  -1
        
        sty tos
        sty tos+1               ; $0 $11 $ff - lol
        rts
.endif ; MINIMAL

;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;; 
FUNC "_lessthan"
;;; 13 B

;;; TODO: reverse order of A-B I think mathop makes it
;;; 
;;;        tos -= stack   .... lol
;;; 
;;;     we want tos = stack - tos
;;; 
;;;    but this would also change pop, push, swap .... _lda _sta???
;;;    REVERSE? - need testing...

;;; 10 B
        uJSR _minus
        ;; C=0 if smaller => $ff else $00 !
        lda #0
        sbc #0                  ; haha! (=> V=0)

        pha
        bvc loadApla            ; V=0 for sure!

;;; 10 B
.ifnblank
        uJSR _minus
        
        lda #0
        rol
        pha
        
        jmp loadApla

;;; !!! opposite!
        ;; C=1 => $0101
        ;; C=0 => $0000     is smaller should be ...
        

;;; 13 B - funny but not smallest....
        uJSR _minus
        ;; Y == 2 (can we assert this somehow???)
        dey                     ;  1   1
        bcc notSmaller
smaller:                        ; !<   <
        dey                     ;      0
notSmaller:     
        dey                     ;  0  -1

        sty tos
        sty tos+1
        rts
.endif


;;; TODO: we really want this in!!!
;;;   (17 B too much)
;;;   how about just a < ??
;;;  
.ifndef MINIMAL

;;; Compare 16 bits C V Z N flags sets as if 8-bit CMP
;;; 
;;; 17 B (= 262 bytes, lol, 6 too many)
FUNC "_cmp"
        uJSR _minus
;;; TODO: _minus may have been reversed look at _mathop....

        ;; Y == 2
        bcc AisSmaller          ; => -1
        bne AisBigger           ; => +1
        beq equal               ; +   0

;;; LOL (saves 2 bytes)
AisSmaller:                     ; =   >    <
        dey                     ;         +1
equal:
        dey                     ; +1       0
AisBigger:
        dey                     ;  0  +1  -1
        
        sty tos
        sty tos+1               ; $0 $11 $ff - lol
        rts
.endif ; MINIMAL




FUNC "_mul"

_mul:
;;; 35 B - 9 ops from _MUL16 macro in
;;; - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library

;;; stack: A B -- ptr1*ptr2
;;; 
;;; top= ptr1 * ptr2 (ptr1 is trashed, ptr2 remains)
;;; 
;;; 32 B
        ;; top= 0 (push 0 => stack: A B 0 ; A,B in "memstack")
        uJSR _zero

        ;; loop 16
        ldy #16
        sty savey

loop:   
        ;; top *= 2
        uJSR _mul2

        ;; A *= 2 => carry
        rol stack+2,x
        rol stack+2+1,x

        ;; bit not set no add: jmp
        bcc skip

        ;; top += B (perfect it stays there)
        uJSR _add
        ;; steal B back
        dex
        dex

skip:   
        dec savey
        bpl loop

        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts


FUNC "_mul"

_mul:
;;; 35 B - 9 ops from _MUL16 macro in
;;; - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library

;;; stack: A B -- A*B
;;; 
;;; 27 B + 8 = 35 B (uJSR: - 7 => 28)
        ;; top= 0
        uJSR _ZERO
        uJSR do16
        ;; top remains, remove 2 values
        inx
        inx
        inx
        inx
        rts

        ;; loop 16
do16:   uJSR do8
do8:    uJSR do4
do4:    uJSR do2
do2:    
        ;; shl top
        uJSR _mul2
        ;; shl A
        rol stack+2,x
        rol stack+2+1,x

        ;; bit not set jmp
        bcc ret

        ;; top+= B
        uJSR _add
        ;; overflow in C effects rol top? 
ret:    
        rts

;;; poor mans looping 16 times
_MUL16: DO __MUL8
__MUL8: DO __MUL4
__MUL4: DO __MUL2
__MUL2: 
        a{Sa b{Sb
        bcc ret

ret:    rts
        
        
        

        


        ; dup U(''0^)
	; dup #1 & UU over & pick2 _MUL2 pick2 _div2 _div + ^

        ;; 23 B
        ;; :* \\ bUB+2 0^
        ;;       b#1& UU a&
        ;;         a{ b} *
        ;;       +^


.export _swap
_swap:   
;;; 17 B !
        ;; q= tos = b
        lda stack,x
        pha
        lda stack+1,x
        pha
        
        ;; a | b c ..
        uJSR _sta
        ;; stack = a

        ;; a | (a) c ..
        dex
        dex
        ;; a | a c ..

        ;; tos= q (= b)
        pla ; hi
        jmp loadApla
        ;; b | a c ..

.ifnblank
;;; TODO: could a serf-JSR-byte thingie be smaller?
;;;  no it's 24 B

        ldy #0
        dex
        dex
        jsr bswap
bswap:  
        lda tos,y
        pha
        lda stack+2,x
        sta tos,y
        pla
        sta stack+2,x
        iny
        inx
        rts
.endif


;;; 3 + 12 = 15
inc2:   
        lda #2
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
inc:    
;;; 12 B
        lda #1
        clc
        adc top
        sta top
        bcc noinc
        inc top+1
noinc:  
        rts

;;; 13 B ????
        clc
        adc 0,y
        sta 0,y
        bcc noinc
        inc 1,y
noinc:  
        rts



_cons:  
        
;;; 14 B
Sdec4:  
        clc

        lda lowcons
        sbc #4
        sta lowcons
        
        lda lowcons+1
        sbc #0
        sta lowcons
        
        rts

;;; 20 B
RsbcA:  
        sta savea
        stx savex
        tya
        tax

        sec     

        lda 0,y
        sbc savea
        sta 0,y

        lda 1,y
        sbc #0
        sta 1,y

        ldx savex
        rts



;;; mem: CDR CAR could just bytecopy from stack
;;; 10B
        ;; S2<C S2<C   # 3
;;; "move value from S (over) pointed to by top"
        ldy #lowcons
        jsr Rpush

        ;; 'D @ #4 - #4 >S   # 9
        
        ;; 'P@ #4 S2<M

        lda #4
        jsr addY

;;; copy 4 bytes from stack to top
;;; 15 B
        ldy #0
four:   jsr two
two:    jsr one
one:    
        lda stack,x
        dex
        sta (top),y
        iny
        rts
        

;;; memcpy 4 bytes, lol
;;; 14 B
loop:   ldy #0
        lda stack,x
        dex
        sta (top),y
        iny
        cmp #4
        bcc loop
        rts


;;; TODO: not general
_TCOMMA: 
;;; 13 B
        .byte "'L@JJ'L!,,__", 0
;;; better: , and __ 
        .byte "'L@J'L!,_", 0

_CONS:
;;; 6 B
        DO _Lcomma
        DO _Lcomma
        .byte "'L@", 0





_dup:   
push:   
;;; 13 B
        lda top+1
        dex
        sta stack,x

        lda top
        dex
        sta stack,x

        rts

_dup:   
push:   
;;; 8 B !
        dex
        dex
        jsr _sta
        dex
        dex
        rts



_swap:  
;;; 22 B

;;; TDOO: if we could assume Y=0...
        ldy #0
        dex
        dex
        jsr _bswap
_bswap:
        inx
        ;; q= tos
        lda tos,y
        pha
        ;; tos= stack
        lda stack,x
        sta tos,y
        ;; stack= q= tos
        pla
        sta stack,x
        iny
        
        rts

swap:   
;;; 20 B lol
        ;; 
 WRONG????

        ;; q= tos = a
        lda tos+1
        pha
        lda tos
        pha
        
        ;; a | b c ..
        ;; tos= stack
        jsr dup

        inx
        inx

        ;; stack

        jmp loadPOPA

        ;; stack= q= tos
        pla
        sta stack,x
        pla
        sta stack+1,x

        rts

swwap:  
;;; 17 B !
        ;; q= tos = b
        lda stack,x
        pha
        lda stack+1,x
        pha
        
        ;; a | b c ..
        jsr _sta
        ;; stack = a

        ;; a | (a) c ..
        dex
        dex
        ;; a | a c ..

        ;; tos= q (= b)
        pla ; hi
        jmp loadPOPA
        ;; b | a c ..



;;; (+ 13 15 16) = 44

comma:  
;;; 13
        jsr store
inc2:   
        jsr inc
.proc _inc
;;; (7 B)
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc

rcomma:  
;;; 15
        jsr store
dec2:   
        jsr dec
;;; (9 B)
.proc _dec
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc
        
store: 
;;; 16 B
        ldy #0
        lda stack,x
        sta (top),y
        inx

        iny
        lda stack,x
        sta (top),y
        inx

        rts


;;; top, inc !=store topr, dec2 dec
;;; 
;;; WRONG: STORE doesn't pop2!!!
;;; not fair to compare
;;; 
;;; (+ 19 8 18) = 45 
;;; 

;;; comma moves words from stack to ptr1
;;;   ptr1 advances
;;; 
;;; C: *ptr1= stack[x]; x+= 2; top+= 2;
;;;
;;; ccomma:
;;;   WARNING: stack is misaligned one byte!
;;; 
;;; 12+7= 19 B
_comma:
;;; 12
        ldy #0
        jsr _ccomma
_ccomma:
        lda stack,x
        sta (top),y
        inx
        iny

.proc _inc
;;; (7 B)
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc

_store: 
;;; 8 B
        jsr _comma
drop2:  
        dex
        dex
        jmp pop

_rcomma:        
;;; 6+12 = 18
        jsr dec2
        jsr _comma
        ;; dec2 again, lol
dec2:   
;;; 3+9 = 12
        jsr _dec

.proc _dec
;;; (9 B)
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc
;;; 
        

;;; ^ (+ 19 8 18) = 45 top, inc store top, dec2 dec

;;; (+ 14 16 14)= 44 store  topcomma toprc
;;; (+ 3 8 1 9 16 9)=46 load2 store topc toprc

topcomma:
;;; 8+6 = 14
        jsr store
;;; 8
        jsr push
        lda #2
        sta top
        lda #0
        sta top+1
;;; (3)
;        jmp push2              ;

        jmp _sbc

store: 
;;; 16 B
        ldy #0
        lda stack,x
        sta (top),y
        inx

        iny
        lda stack,x
        sta (top),y
        inx

        rts
        
toprcomma:      
;;; 8+6 = 14 B
;;; 8
        jsr push
        lda #2
        sta top
        lda #0
        sta top+1
;;; (3)
;        jsr push2              ;

;;; 6
        jsr _plus
        jmp store
        


;;; rcomma needed for cons
;;; 
_rcomma:        
        

;;; 19B
_rcomma:        
        jsr _rbcomma
_rbcomma:       
        ldy #0
        lda stack+1,x
;;; writing wrong order bytes!
;;;  bakcwards
        dex
        
.proc _dec
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc



_dup:   
push:   
;;; 13 B
        lda top+1
        dex
        sta stack,x

        lda top
        dex
        sta stack,x

        rts


dup:    
push:  
;;; 4+10 = 14 B
        lda top
        ldy top+1

;;; pushAY A low, Y hi, push on data stack
pushAY:
;;; (10 B)
        dex
        dex
        sta stack,x
        tya
        sta stack+1,x
        rts

;;; maybe not needed
.ifnblank

pushA:  
;;; 5 B
        ldy #0
        jmp pushAY

pushreg:        
;;; 9 B
        lda 0,y
        ldx 1,y
        jmp pushAY

car:    
;;; 16
        ldy #0
        lda (top),y
        sta ptr1
        iny
        lda (top),y
        sta ptr1+1

        ldy #ptr1
        jmp pushregY
        
cdr:    
;;; 13 + 3 = 16B
car:    
;;; 13B
        ldy #2
        lda (top),y
        pha
        iny
        lda (top).y
        tay
        pla
        jmp pushAY

cdr:    
;;; 3 + 14 = 17 B
        ldy #2
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
load:  
car:    
;;; (14 B)
        ldy #0
cYr:    
        lda (top),y
        pha
        iny
        lda (top),y
;;; load TOP w (A, pla) (hi,lo)
;;; (useless?)
loadPOPA: 
;;; (6 B)
        sta top+1
        pla
        sta top
        rts

dup:    
;;; 2+13 = 15
        ldy #top
pushregY:       
;;; (13 B)
        lda 0,y
        dex
        sta stack,x
        
        lda 1,y
        dex
        sta stack,x
        rts

pushregY:       
;;; 14 B
        jsr push
        lda 0,y
        sta top
        lda 1,y
        sta top+1
        rts
        


;;; This one would be smaller with recursive dup
;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack,y
        pla

        rts

popret: 
        RPOP
        rts



.macro iJSR where
.assert ((where-jmptable)<(256-4)),error,"iJSR: too far"
        brk
        .byte (where-jmptable)
.endmacro

.macro pJSR where data
        iJSR where
        .byte data
.endmacro

;;; interrupt handler for
;;; BRK dispatch
;;; 
;;;  call _car         - 2 bytes (1 saved) - rti
;;;  pcall _print '>'  - 3 bytes (2 saved) - rts

;;; (lit 'A'           - 3 bytes (2 saved) - rts)
;;; (literal $beef     - 4 bytes (3 saved))

;;; (xcall _extrawork) - 2 bytes (1 saved)
;;; (uses a forwarding byte to call second page)

;;; Generally dispatched functions don't
;;; rely on any value in A or Y when entering.
;;; 
;;; (X contains data stack pointer, don't use)
;;; 36 B - TOO MUCH - probably no savings...
;;; (unless have 36 calls, lol)
_BRK:

;;; stack contains: lo, hi addr to continue
;;; "BRK i j k" pointing to d; rti continues at j;
;;; rts continues at k!

;;; 17 B
;;; (need to save 17 bytes to make it worth!)
        ;; dup
        pla                     ; lo

        ;; pBRK.lo= retaddr.lo-1
        sec
        sbc #1
        sta pBRK
        ;; no need care underflow
        ;; as we keep within page boundaries!

        ;; set return address -1
        ;; so can rely on rts
        pha

        ;; load "i"
        ldy #0
        lda (pBRK),y

        sta docall+1
docall: jmp jmptable


;;; get i(nstruction) byte
;;; 11 B
        ;; dup
        pla                     ; lo
        pha
        ;; pBRK.lo= retaddr.lo-1
        sec
        sbc #1
        sta pBRK
        ;; no need care underflow
        ;; as we keep within page boundaries!
        ;; a= "actual i" (instruction/offset)
        ldy #0
        lda (pBRK),y



;;; dispatch depending on size/function
;;; 
        ;; modify lo of call!
        sta docall+1

;;; LITERAL $beef = brk _literal $be $ef
;        cmp #fourbytes_instructions
;        bcs fourcall

;;; xcall _foo = jsr jmpage+256+offset[_foo-jmppage]
;;; 
;;; eXtended call
;;; (at end page, forward offset to second page)
;;; = eJSR    
;        cmp #vecInstructions
;        bcs vectorcall         ;

        cmp #pInstructions
        bcs paramcall
        cmp #iInstructions
        bcs docall

;;; two byte instruction
;;; tail jmp!
;;; adjust ret address -1
;;; 4 B
        pla
        lda pBRK                ; already dec!
        pha
        ;; fall-through

;;; three byte instruction
;;; tail jmp! (will returns w rts)
docall: jmp jmptable

paramcall:
;;; 7 B
        ;; load parameter
        iny                     ; 1
        lda (pBRK),y

        ;; Y = A= param !
        tay
        
        jmp docall

;;; four byte instruction
fourcall:       
        pop
        sec
        



;;; Follow: loads ptr1 from stack
;;;   it kindof can be used as an iterator
;;;   using , comma operator to
;;;   move values from stack to where ptr1 points
_follow:        
;;; 11 B
        lda top
        sta ptr1
        lda top+1
        sta ptr1+1
        jmp pop

;;; 7
        lda #from
        ldy #to
        jsr copyreg_y2a

copyreg_y2a:
;;; 23 B
        sta savea
        sty savey

        ;; lo: rY -> rA
        lda 0,y
        ldy savea
        sta 0,y

        ;; hi: rY -> rA
        ldy savey
        lda 1,y
        ldy savey
        sta 1,y
        
        rts

;;; comma moves words from stack to ptr1
;;;   ptr1 advances
;;; 
;;; C: *ptr1= stack[x]; x+= 2; top+= 2;
;;;
;;; ccomma:
;;;   WARNING: stack is misaligned one byte!
;;; 
;;; 11+7= 18 B
_comma:
        jsr _ccomma
_ccomma:
        ldy #0
        lda stack,x
        sta (top),y
        inx

.proc _inc
;;; (7 B)
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc


;;; building blocks
;;; 
;;; 20 B
;;; 
;;; ay= top
top2ay:        
        lda top
        ldy top+1
        rts
;;; top= ay
ay2top: 
        sta top
        sty top+1
        rts
;;; ptr1= ay
ay2ptr1:        
        sta ptr1
        sty ptr1+1
        rts
;;; ay= ptr1
ptr12ay:        
        lda ptr1
        ldy ptr1+1
        rts

comma:  
;;; 32B
        ;; ptr1= pop # 10
        lda top
        sta ptr1
        lda top+1
        sta ptr1+1
        inx
        inx

        ;; *ptr= pop # 15
        ldy #0
        lda stack,x
        sta (ptr1),y
        inx

        iny
        lda stack,x
        sta (ptr1),y
        inx

        ;; 
        jsr rinc2
        jmp pop

rinc2:  
;;; 12 B
        jsr rinc
rinc:   
;;; 9 B
        inc 0,y
        bne noinc
noinc:  
        inc 1,y
        rts
        
        

comma:  
;;; 8 + 13
;;;     + 4+13 (radda)  (+ 8 13 4 13) = 38 
;;;  OR + 3+12 (rinc2)  (+ 8 13 3 12) = 36
        jsr top2ay
        inx
        inx
        jsr ay2ptr
        
citer:   
;;; 13
        ;; *ptr1= *stack
        ldy #0
        lda stack,x
        sta (ptr1),y

        iny
        lda stack+1,x
        sta (ptr1),y
        
;;; 3 + 
        jsr pop
        (fall through to rinc2)
;;; 4
        lda #2
        ldy #ptr1
        jsr rinca
        (fall through to radda)
radda:  
;;; 13
        clc
        adc 0,y
        sta 0,y
        bcc noinc
        inc 1,y
        rts

rinc2:  
;;; 12 B
        jsr rinc
rinc:   
;;; 9 B
        inc 0,y
        bne noinc
noinc:  
        inc 1,y
        rts


;;; rcomma
;;; 
_rcomma:        
        

;;; 19B
_rcomma:        
        jsr _rbcomma
_rbcomma:       
        ldy #0
        lda stack+1,x
;;; writing wrong order bytes!
;;;  bakcwards
        dex
        
.proc _dec
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc


;;; TODO: is this just copy from one memory location
;;; to another???

.proc setnewcdr
        ldy #2
        jmp setnewcYr
.endproc

setnewcar:      
        ldy #0
.proc setnewcYr
        sta (lowcons),y
        txa
        iny
        sta (lowcons),y
        jmp pop
.endproc

;;; newcons -> AX address of new cons

;;; 
;;; 16B
;.ifdef USECONS
.proc newcons
        ;; lowcons-= 4
        sec
        lda lowcons
        sbc #04
        sta lowcons
        bcs nodec
        dec lowcons+1
nodec:  
        lda #<lowcons
        ldx #>lowcons
.endproc


;;; decw decrease zp word at Y by A
;.proc dec4w                     
;        clc
;        adc 0,y

;;; 14B + 4B load later
.proc dec4lowcons
        tay
        sec
        lda lowcons
        sbc #4
        sta lowcons
        bcs nodec
        dec lowcons+1
nodec:  
        tya
        rts
.endproc

;;; 16B
.proc newcons
        ldx lowcons
        lda lowcons
        tay

        sec
        sbc #4
        sta lowcons     
        bcs nodec
        dec lowcons+1
nodec:  
        tya
        rts
.endproc

;;; 

;;; 14B - 25c
.proc decw2
        pha

        lda lowcons
        sec
        sbc #2
        sta lowcons
        bcc nodec
        dec lowcons+1
nodec:  
        pla
        rts
.endproc

;;; 14B - 19c+
.proc decw2
        ldy lowcons
        bne nodec
        dec lowcons+1
nodec:  
        dey
        bne nodec2
        dec lowcons+1
nodec2: 
        dey
        sty lowcons
        rts
.endproc

;;; 13B - 16c
.proc decw2
        ldy lowcons
        cpy #2
        bcs noinc
        dec lowcons+1
noinc:  
        dey
        dey
        sty lowcons
        rts
.endproc
        
;;; 11B - slow 6+17=23c
decw2:  
        jsr decw
        ;; -- fallthrough


;;; 9B 17c
.proc decw
        ldy lowcons
        bne nodec
        dec lowcons+1
nodec:  
        dec lowcons
        rts
.endproc



.ifnblank
;;; TODO: no better only 1B
;;; 11B
.proc dup
        jsr write ; A
        txa       ; X
;;; ; WRONG a is lost...
write:  
        dec sidx
        lda sidx
        sta stack,y
        rts
.endproc
.endif


_dup:   
push:   
;;; This one would be smaller with recursive dup
;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack,y
        pla

        rts





;;; 4B 8c
dec foo
ldy foo

;;; 5B 8c
ldy foo
dey
sty foo

;;; 6B 13c
dec foo
dec foo
ldy foo

;;; 8B 10c
ldy foo
dey
dey
sta foo



_shl:   
;;; 8B 19c
        asl a
        stx savex
        ror savex
        ldx savex
        rts
_shl:   
;;; 7B 18c
        asl a
        tay
        txa
        ror a
        tax
        tay
        rts

_shr:   
;;; 8B
        stx savex
        lsr savex
        ror a
        ldx savex
        rts

_halve:
;;; 7B 
        tay
        txa
        lsr
        tax
        tya
        ror
        rts


garbage....
_dup:   
push:   
;;; 15B
        inc sidx
        inc sidx
        ldy sidx
        sta stack,y
        pha
        sta stack+1,y
        pla
        rts

;;; TODO:  generic
;;; _sta _dup

;_ror:  
        ;; ROR oper,x
;        ldy #$7e
;        bne gen
;;; HAHA no use, as it just need to change AX!


_sta:   
push:   
        ;; STA oper,x
        ldy #$9d
        ;; fall-through

gen:    
        sty op1
        sty op2
        ldy sidx
        dey
        dey

        pha
        txa

        pla
        
        sty sidx


;;; 17B ! specialized == 15B
gen:    
        sty genop
        pha
        txa
        jsr gen2                ; X
        pla
        ;; fall-through         ; A

gen2:    
        dec sidx
        ldx sidx
genop:  sta stack,x
        rts

;;; 15B
        inc sidx
        inc sidx
        ldy sidx
        sta stack,y
        pha
        sta stack+1,y
        pla
        rts



.ifnblank
;;; 13B 22c
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dey
        dey
        sta sidx
        rts
.endif

.ifnblank
;;; 13B 28c
ppop:   
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dec sidx
        dec sidx
        rts
.endif
.ifnblank
;;; 13B 22c
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dey
        dey
        sta sidx
        rts
.endif

.ifdef OPT
;;; OPS that go from lobyte to hibyte
_adc:  
        ;; ADC stack,y
        clc
        ldy #$79
        bne mathop
_and:
        ;; AND stack,y
        lda #$39
        bne mathop

;;; cmp oper,y $d9 - can't use doesn't ripple

_eor:
        ;; EOR stack,y
        lda #$59
        bne mathop
_ora:
        ;; AND stack,y
        lda #$19
        bne mathop

;;; no ROL oper,y ????
;_rol:
;        ;; ROL stack,y
 ;       clc
  ;      lda #$


_sbc:   
        ;; SBC stack,y
        sec
        ldy #$f9
        bne mathop

        bne mathop

;;; Can't do as it's postdec???
;xxpush:
;xx_sta:   
;       ;; STA oper,y
;        lda #$99
;        bne mathop

pop:
_lda:   
        ;; LDA oper,y
        ldy #$b9
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP

;;; 22B - 32+2*18=68
mathop:
        sty op
        jsr write
        pha
        txa
        jsr write
        tax
        pla
        rts
write:
        ldy sidx
op:     adc stack,y
        inc sidx
        rts

;;;  mush faster! 1B MORE...
;;; 23B - 36C
mathop: 
        sty op1
        sty op2
        ldy sidx
op1:    adc stack,y
        pha
        txa
        iny
op2:    adc stack,y
        iny
        sty sidx
        tax
        pla
        rts

;;; too slow, doen't save bytes!
;;; 23B - 39+2*12=63
mathop:
        sty op
        ldy sidx
        jsr write ; A
        pha
        txa
        jsr write ; X
        tax
        sty sidx
        pla
        rts
write:
op:     adc stack,y
        iny
        rts


_plus:  
        clc
        ldx #$ff

;;; these are no top in AX

;;; 20B 58c
domath: 
        stx op
        jsr doone

doone:  
        ldy sidx
        lda stack,y
op:     adc stack+2,y
        sta stack+2,y
        inc sidx
        rts

_dup:   
push:   
;;; 16B
        ;; sidx -= 2
        ldy sidx
        dey
        dey
        sty sidx

        sta stack,y
        pha
        txa
        sta stack+1,y
        pla
        rts

;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack+1,y
        pla

        rts


_drop:  
pop:    
;;; 11B 21c
        ;; sidx++
        inc sidx
        ldy sidx

        lda lostack,y
        ldx histack+1,y

        rts

pop:    

;;; 13B 24c
        ;; sidx++
        ldy sidx
        iny
        iny
        sty sidx

        lda stack,y
        ldx stack+1,y

        rts

_sbc:   
        ;; SBC stack,y
        sec
        ldy #$f9
        bne mathop

;;; Can't do as it's postdec???
;xxpush:
;xx_sta:   
;       ;; STA oper,y
;        lda #$99
;        bne mathop

pop:
_lda:   
        ;; LDA oper,y
        ldy #$b9
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP

;;; 22B - 32+2*18=68
mathop:
        sty op
        jsr write
        pha
        txa
        jsr write
        tax
        pla
        rts
write:
        ldy sidx
op:     adc stack,y
        inc sidx
        rts

;;;  mush faster! 1B MORE...
;;; 23B - 36C
mathop: 
        sty op1
        sty op2
        ldy sidx
op1:    adc stack,y
        pha
        txa
        iny
op2:    adc stack,y
        iny
        sty sidx
        tax
        pla
        rts

;;; too slow, doen't save bytes!
;;; 23B - 39+2*12=63
mathop:
        sty op
        ldy sidx
        jsr write ; A
        pha
        txa
        jsr write ; X
        tax
        sty sidx
        pla
        rts
write:
op:     adc stack,y
        iny
        rts

_plus:  
        clc
        ldx #$ff

;;; 21B
mathop: 
        sty op1
        sty op2
        ldy sidx

op1:    adc stack,y

        pha
        txa
op2:    adc stack+1,y
        tax
        pla

        iny
        iny
        sty sidx

        rts

;;; 19B
mathop: 
        sty op1
        sty op2

        ldy sidx
op1:    adc lostack,y
        pha
        txa
op2:    adc histack,y
        tax
        dec sidx
        pla
        rts

