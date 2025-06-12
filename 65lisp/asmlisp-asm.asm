;;; "SectorLisp for 6502" asmlisp-asm.asm (+ asmlisp.c)
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org

;;; This is an attempt to write a pure assembly minimal
;;; lisp for 6502, similar to SectorLisp that was
;;; only 436 bytes, smaller than the SectoForth at 512
;;; bytes.
;;; 
;;; There is a z80/6502 milliforth is 336/328 bytes.
;;; 
;;; can we create a minimal 6502 lisp?

;;; SectorLisp limitations:
;;; - 512 bytes "bootable"
;;; - assumes prexisting "bios": getch putch
;;; - only SYMBOLS and CONS
;;; - reader and writer (no editor, or backspace)
;;; - T NIL QUOTE READ PRINT COND CONS CAR CDR (41)
;;;     ?LAMBDA ?EVAL ?APPLY (16)
;;; - no GC (or minimal "reset")

;;; ORIC: charset in hires-mode starts here
TOPMEM	= $9800

;;; START
;;; 
;;; .TAP delta
;;;  325          bytes - NOTHING (search)
;;;  785 +460     bytes - MINIMAL (- 785 325)
;;;  613?         bytes - ORICON  (raw ORIC, no ROM)
;;;  886 +117     bytes - NUMBERS (- 886 769)
;;;  950  +64     bytes - MATH+NUMS (- 950 886) 
;;;  900?         bytes - TEST + ORICON

;;; 444 bytes (- 785 325) = 460
;;;       initlisp nil 37, T 10,
;;;       print 89, printz 17, eval 49
;;;       getvalue 38, bind 19,
;;;       setnewcar/cdr 14, newcons 21, cons 12, revc 12
;;;       _car _cdr 19, _car _cdr 20, _print 12
;;;       _cons 16
;;; == 426 ==
;;; (+ 37 10 89 17 90 38 19 14 21 12 12 19 20 12 16)
;;;  TODO: wtf? (- 440 410) = 30 bytes missing, LOL

;;; enable numbers
;NUMBERS=1

;;; enable math (div16, mul16)
;MATH=1

;;; enable tests (So far depends on ORICON)
;TEST=1

;;; enable ORICON(sole, code for printing)
;;; TODO: debug, not working well get ERROR 800. lol
;ORICON=1

.import incsp2, incsp4, incsp6, incsp8
;.import addysp

.export _nil
.export _initlisp

.ifdef ORICON

.export _initscr
.export _scrmova
.export printz, printzptr

.endif ; ORICON

.ifdef TEST
.export _test
.endif

;;; --------------------------------------------------

;; TODO: not working in ca65, too old?

;.feature string_escape

.zeropage

.ifdef ORICON
curscr: .res 2
leftx:  .res 1
lefty:  .res 1
        ;;  TODO: do something clever to remove this?
newlineadjust:  .res 1          ; or use tmp1?
.endif ; ORICON

;;; used as (non-modifiable) arguments

ptr1:   .res 2
ptr2:   .res 2
ptr3:   .res 2

;;; be careful saving (as may trash other save!)
savea:  .res 1
savex:  .res 1
savey:  .res 1

;;; TODO: needed? clash with jsr printd???
savexputchar:    .res 1

;;; used to detect type using BIT & beq
BITNOTINT: .res 1
BITISCONS: .res 1

;;; locals
locidx:  .res 1

;;; memory
lowcons: .res 2

;;; various special data items, constants
;;; - ATOMS
.align 4                        ; meaing: 4 or 2^4
.res 1

;;; _nil atom at address 5 (4+1 == atom)
;;; TODO: create segment to reserve memory?

_nil:   .res 6
        .byte "nil", 0


;;; --------------------------------------------------
;;; Uninitialized data (not stored in binary)

.bss

;;; locals
locidlo:        .res 256
locidhi:        .res 256
loclo:          .res 256
lochi:          .res 256


.code

;;; ----------------------------------------

;;; TODO: this doesn't need to be here in the binrary?


.ifdef ORICON
;;; =========================================================
;;; Implements a "mini-terminal" printing strings

;;; _initscr, with leftx and lefty, keeping leftx in X
;;; doesn't modify register Y
.proc _initscr
        lda #$80
        sta curscr
        lda #$BB
        sta curscr+1

        ;; important X must contain leftx when exit
        ldx #40
        stx leftx

        lda #28
        sta lefty

        rts
.endproc

plaputchar:    
        pla

;;; putchar A on screen, move position forward
;;; trashes A,X,Y,ptr1,ptr2
.proc putchar
        ;; save char in 2 byte asciiz buffer end with 0
        sta ptr2
        lda #0
        sta ptr2+1

        lda #<(ptr2)
        ldx #>(ptr2+1)
        ;; fallthrough to printz
.endproc

;;; printz: Prints an ASCIIZ zero terminated string
;;; identified by address in AX.
;;; 
;;; optimized to print strings upto 256 chars
;;; (putchar might call this one with wrapper, lol)
;;; 
;;; wraps around at end of screen
;;; keeps leftx, lefty updated, at end updates curscr
;;; 
;;; special characters recognized:
;;; #10=\n - newline (wraps around to top, too)
;;;           (TODO: should newline clear end of line?)
;;; TODO: \m - move to first col
;;; TODO: #12 = CTRL-L clear screen
;;; TODO: #30 = "home"ax
;;; TODO: skip attributes on screen? (unless wrap?)
;;; TODO: hibit (&7f<32 print as attribute, otherwise inverse)

;;; Note: AX is trashed (it's stored in ptr1!)
PRINTZ  = 1

printz:      
        ldy #0
printzY:       
        sta ptr1
        stx ptr1+1

;;; printzptr: Prints an ASCIIZ zero terminated string
;;; identified by address in ptr1

;;; Note: can be used to print the last string printed!

;; init screen state

printzptr:        
        lda #00
        sta newlineadjust
        ldx leftx

@next:   
        lda (ptr1),y
        beq @end
        cmp #10
        beq @newline
        sta (curscr),y
        iny
        dex
        bne @next

        ;; line overflow
        ;; (this is cheap, only run every 40 chars)
@nextline:
        ldx #40
        dec lefty
        bne @next
        ;; rows overflow - wrap! (TODO: or scroll?)
        jsr _initscr

        ;; adjust address to make Y work
        ;; (todo: redo with reverse subtraction curscr -= Y)
        lda curscr
        sec
        sbc newlineadjust
        sta curscr
        lda curscr+1
        sbc #0
        sta curscr+1

        jmp @next
        
;;; handle special chars
@newline:
        iny
        sty newlineadjust

        ;; skip rest of line
        dex
        txa
        jsr _scrmova
        jmp @nextline


@end:    
        stx leftx

        ;; move forwade
        ;dey                     ; ???
        tya

_scrmova:
        clc
        adc curscr
        sta curscr
        lda curscr+1
        adc #00
        sta curscr+1

        rts

.proc getchar
        lda #'x'
        rts
.endproc

.else ; ORICON

;;; - https:  //github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Fgpchar.s

;;; input char from keyboard
;;;
;;; 10B
.proc getchar      
        jsr $023B               ; ORIC ATMOS only
        bpl getchar             ; no char - loop
        tax
        ;; TODO: optional?
        jsr $0238               ; echo char
        rts
.endproc

;;; platputchar used to delay print A
;;; (search usage in printd)
plaputchar:    
        pla

;;; putchar(c) print char from A
;;; 
;;; 12B
.proc putchar
        stx savexputchar
        ;; '\n' -> '\n\r' = CRLF
        cmp #$0A                ; '\n'
        bne notnl
        pha
        ldx #$0D                ; '\r'
        jsr $0238
        pla
notnl:  
        tax
        jsr $0238
        ldx savexputchar
        rts
.endproc

.endif ; ORICON

;;; enable these 3 lines for NOTHING .tap => 325 bytes
;.export _initlisp        
;_initlisp:      rts
;.end


;;; --------------------------------------------------
;;; Functions f(AX) => AX

.macro SET val
        lda #<val
        ldx #>val
.endmacro

.macro SETNUM num
        SET (num)*2
.endmacro

;;; putchar (leaves char in A)
;;; 5B
.macro putc c
        lda #(c)
        jsr putchar
.endmacro

;;; for debugging only 'no change registers A'
;;; 7B
.macro PUTC c
        pha
        putc c
        pla
.endmacro

;;; 7B - only used for testing
.macro NEWLINE
        PUTC 10
.endmacro


.align 2
cdr:    
        ldy #3
        jmp cYr

;;; car(AX) -> AX
.align 2
car:    
        ldy #1
cYr:    
        sta ptr1
        stx ptr1+1

;;; cYr(ptr1) -> AX
.proc ptr1cYr
        lda (ptr1),y
        tax
        dey
        lda (ptr1),y
        rts
.endproc


;;; print

;;; push A,X on R-stack (AX trashed, use DUP?)
;;; (cc65: jsr pushax takes 39c!)
;;; 3B 7c
.macro PUSH
        pha
        txa
        pha
.endmacro

;;; 3B 6C
.macro POP
        pla
        tax
        pla
.endmacro

;;; DUP AX onto stack (AX retained)
;;; 5B
.macro DUP
        tay
        pha
        txa
        pha
        tya
.endmacro

;;; 3B 6c
.macro ARGSETY
        tsx
        txa
        tay
.endmacro

;;; ARG(n) n n=0 is prev arg, n=1 prev arg
;;; 12B 14c
.macro ARG n
        ARGSETY                 ; probably needed always
        YARGN n
.endmacro

.macro YARGN n
        lda $102+(n*2),y
        ldx $101+(n*2),y
.endmacro

;;; arg number Y
;;; 
;;; (cc65 5B 20c equivalent "ldy #4 ; jsr ldaxsp")

;;; 5B 36c
.macro arg n
        ldy #(n*2)
        jsr yarg
.endmacro

;;; 25c
.proc yarg
        sty savey
        tsx
        txa
        clc
        adc savey
        tay
        lda $104,y
        ldx $103,y
        rts
.endproc

;;; --------------------------------------------------
;;; Functions f(AX) => AX

;;; set car on new cons (A is trashed)
setnewcar:      
        ldy #0
        jmp setnewcYr

setnewcdr:      
        ldy #2
setnewcYr:      
        sta (lowcons),y
        iny
        txa
        sta (lowcons),y
        rts


;;; newcons -> AX address of new cons
;;; 
;;; 21B
.proc newcons
        ;; save current cons to return in AX
        lda lowcons
        pha
        lda lowcons+1
        pha

        ;; lowcons-= 4
        ;; 11B 13-14c
;;; TODO: 7B::: ldy #4 ; ldx #lowcons ; jsr subwy
        sec
        lda lowcons
        sbc #04
        sta lowcons
        bcs nodec
        dec lowcons+1
nodec:  
.endproc

popret: 
        POP
        rts

;;; cons(car, cdr)
.align 2
.proc cons
        jsr setnewcdr
        POP
        jsr setnewcar
        jmp newcons
.endproc

;;; revcons(cdr, car)
.proc revcons
        jsr setnewcar
        POP
        jsr setnewcdr
        jmp newcons
.endproc


;;; printz prints zstring at AX
;;; (no newline added that puts does)
;;; 
;;; 17B
.ifndef PRINTZ
printz:  
        ldy #0

;;; printzY prints zstring from AX starting at offset Y
;;; (no newline added that puts does)
.proc printzY
        sta ptr1
        stx ptr1+1
next:
        lda (ptr1),y
        beq end
        jsr putchar
        iny
        bne next
end:    
        rts
.endproc
.endif ; PRINTZ

;;; ===================================
;;; LISP:

 
;;; various special data items, constants
;;; - ATOMS
;;; TODO: any evaluate to self, put in ZP?
;;;       (easier test in eval!)
.align 4
.res 1

_T:     .word _T, _nil, eval
        .byte "T", 0

.align 4
.res 1
_car:   .word car, _T, eval
        .byte "car", 0

.align 4
.res 1
_cdr:   .word cdr, _car, eval
        .byte "cdr", 0

.align 4
.res 1
_print: .word print, _cdr, eval
        .byte "print", 0

.align 4
.res 1
_cons:  .word cons, _print, eval
        .byte "cons", 0

.ifdef NUMBERS

;;; print one hex digit from A lower 4 bits at position Y
;;; (doesn't trash X)
.proc print1h
        and #15
        ora #'0'
        cmp #('9'+1)
        bcc print
        ;; >'9' => 'A'-'F'
        adc #('A'-'9'-1)

print:  
.ifdef ORICON
        sta (curscr),y
.endif ; ORICON
        iny
        rts
.endproc

;;; div16/16 - 40 Bytes
;;; - http://forum.6502.org/viewtopic.php?f=2&t=6258

;;; div16/8 divide ptr1 16-bits by ptr2 8-bits, result in ptr1
;;; 
;;; by strat @ nesdev forum ; 21B
;;; 
;;; out: A: remainder; X: 0; Y: unchanged

.ifdef MATH

.proc div16
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  cmp ptr2
  bcc @no_sub
  sbc ptr2
  inc ptr1
@no_sub:
  dex
  bne @divloop

  rts
.endproc

;;; 16div16 => 16 ??? works?
;;; jsk 37B
.proc div1616
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  ;; hi-byte cmp
  tay
  lda ptr1+1
  cmp ptr2+1        
  bcc @no_sub                   ; one off?
  tya

  ;; lo-byte cmp
  cmp ptr2
  bcc @no_sub

  ;; lo-byte sub
  sbc ptr2
  inc ptr1

  ;; hi-byte sub
  tay
  lda ptr1+1
  sbc ptr2+1
  sta ptr1+1
  tya
  
@no_sub:
  dex
  bne @divloop

  rts
.endproc

.proc mul2
        asl
        tay
        txa
        rol
        tax
        tya
        rts
.endproc

.endif ; MATH

.ifdef NUMBERS
;;; needed by print for numbers
.proc div2
        tay
        txa
        lsr
        tax
        tya
        ror
        rts
.endproc
.endif ; NUMBERS

;;; printd print a decimal value from AX (retained, Y trashed)
.proc printd
        ;; save ax
        sta savea
        stx savex

        jsr _voidprintd

        ;; restore ax
        ldx savex
        lda savea

        rts
.endproc

;;; _voidprintd print a decimal value from AX (+Y trashed)
;;; 35B - this is a very "minimal" sized routine
;;;       slow, one loop per bit/16
;;;       (+ 3B for store AX)
;;; 
;;; ~554c = (+ (* 26 16) (* 5 24) 6 6 6)
;;;       (not include time to print digits)
;;; 
;;; Based on DecPrint 6502 by Mike B 7/7/2017
;;; Optimized by J. Brooks & qkubma 7/8/2017
;;; This implementation by jsk@yesco.org 2025-06-08

.proc _voidprintd
        sta ptr1
        stx ptr1+1
        
_voidprintptr1d:

digit:  
        lda #0
        tay
        ldx #16

div10:  
        cmp #10/2
        bcc under10
        sbc #10/2
        iny
under10:        
        rol ptr1
        rol ptr1+1
        rol

        dex
        bne div10

        ;; make 0-9 to '0'-'9'
        ora #48                 ; '0'

        ;; push delayed putchar
        ;; (this is clever hack to reverse digits!)
        pha
        lda #>(plaputchar-1)
        pha
        lda #<(plaputchar-1)
        pha

        dey
        bpl digit

        rts
.endproc
        

.proc print2h
        pha
        lsr
        lsr
        lsr
        lsr
        jsr print1h
        pla
        jsr print1h
        rts
.endproc
        
;;; print hex from AX (retained) Y=5
.proc printh
        pha

        ;; print '$'
        pha
        ldy #0
        lda #$24                ; '$'
.ifdef ORICON
        sta (curscr),y
.endif ; ORICON
        iny

        ;; print hi-byte
        txa
        jsr print2h
        pla
        ;; print lo-byte
        jsr print2h

        ;; move cursor forward Y (=5)
        tya
.ifdef ORICON
        jsr _scrmova
.endif ; ORICON
        pla

        rts
.endproc

.endif                          ; NUMBERS

;;; typeNZVC, set flag depending on type of AX (retained):
;;;    N = Number, lol
;;;    Z = Null, Nil
;;;    V = Atom
;;;    C = Cons

.ifnblank
.proc _type                     ; 34 bytes: 18-38c
        tay
        clv

        lsr
        bcs notnum
        ;;; Number => N
        tya
        ldy #$ff
        rts                     ; 18c Number

notnum: 
        lsr                     ; 9c
        bcs iscons

isatom: 
        ;;; Atom

        ;; NULL?
        cpy #<_nil
        bne notnull
        cpx #>_nil
        bne notnull
        ;; is null
        lda #64+2               ; V+N
        bne end                 ; is jmp end (N=0)
notnull:        
        lda #64                 ; V
end:    
        ;; "SEV" (+ "SEZ")
        pha
        tya
        plp

        rts                     ; 38c Vatom (+ maybe Zull)

iscons:
	;;; Cons
        sec
        tya
        ldy #1
        rts		        ; 24c
.endproc
.endif

.ifdef TEST

.ifdef NUMBERS
.proc testnums
        ;; test hex
        ldx #$be
        lda #$ef
        jsr printh
        jsr printh

        ldx #$12
        lda #$34
        jsr printh
        jsr printh

        ;; test dec
        ldx #$10                ; 4321 dec
        lda #$e1
        jsr printd
        jsr printd

        ldx #$dd                ; 56789 dec
        lda #$d5
        jsr printd
        jsr printd

        ldx #$be                ; 48879 dec
        lda #$ef
        jsr printd
        jsr printd

        ldx #$12                ; 4660 dec
        lda #$34
        jsr printd
        jsr printd

        ;;; test type

        ;; Number
        lda #<(2*4711)
        ldx #>(2*4711)
        jsr print
        jsr print
        jsr print
        jsr _testtype

        rts
.endproc
.endif ; TEST

.endif ; NUMBERS

.ifnblank ; TODO: not used - remove, or update with BIT and make macro?

.proc _isnumSetC                ; 12c 3B+1
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
.endproc

;; not inline...
.proc _isconsSetC               ; 14-19c 14B
        tay
        lsr
        bcs maybecons
                                ; C= 0
ret:    
        tya
        rts                     ; 14c

maybecons:      
        lsr
        adc #1                  ; low bit 1 if partity (1+1+1)
        lsr                     ; C= 1 if cons!
        tya
        rts                     ; 19c
.endproc


;;;  TODO: inline macro? 6B
.proc isnullSetN                ; 11-12c 6B+1
        cmp #<_nil               
        bne ret                 ; if Z=0 => not Null
        cpx #>_nil               ; if Z=1 => is Null!
ret:    
        rts

.endproc


;;; TODO: inline macro? 8B
.proc isatomSetC                ; 15-18c 8B+1
        tay
        lsr
        bne ret
        adc #0
        lsr
ret:    
        tya
        rts
.endproc

.endif ; blank

;;; eval(env, x) -> val
;;;   NUM => NUM
;;;   ATOM => assoc(env, x)
;;;      result => return it
;;;    else
;;;      global value lookup (= car)

;;; 49B
.proc eval

.ifdef NUMBERS
        bit BITNOTINT
        beq isnum
.endif
isnotnum:       
        bit BITISCONS
        beq issym
iscons: 
        ;; APPLY
        ;; get function atom
        DUP
        jsr car                 ; car of expr
        ;; this is the f-atom, indirect call CAR!
        sta call+1
        stx call+2
        ;jsr print
        ;; TODO: test is atom? - expesnive, lol
        ;; (ptr1 contains expr, Y-0 after car)
        jsr car                 ; car of f-atom
        bit BITNOTINT
        bne evalnotnum
        ;; have even address==num == machine code
        ;; TODO: Z set if zero page atom called
        ;;   use this for non-eval: cond? ...
        ;;   how about user defined?

        ;; prepare one parameter in AX (rest on stack)

        POP
        ;; AX= eval(car(cdr(expr)))
evallist:       
        ;PUTC '?'
        ;jsr print
        jsr cdr
        ;; while cons
        tay
        and #03
        cmp #03
        bne finishedeval
        tya
        DUP
notnil: 
        jsr car
        jsr eval
        ;PUTC ','
        ;jsr print

        ;SWAP (ax <-> R-stack)           ; S: car cdr
        ;; 15B :-(
        sta savea
        stx savex
        pla
        tax
        pla
        tay
        lda savea
        pha
        lda savex
        pha
        tya

        jmp evallist
finishedeval:   
        POP                     ; get last arg in AX
        ;PUTC '='
        ;jsr print             

        ;; indirect call to atom car number address!
call:   jmp ($0000)

evalnotnum:     
        jmp popret

issym:  
        ;; test if it's in ZP then it's self eval
        ;; (nil/T)
        cpx #0
        bne getvalue

isself: 
isnum:  
        rts
.endproc ; eval

;;; 38B 39++ found
;;; TODO: make smaller! assoc cheaper?
.proc getvalue
        sta savex
        ;; search locals
        ldy locidx
again:  
        beq notfound
        cmp locidlo,y
        bne next

        ;; no cpx mmm,y
        txa
        cmp locidhi,y
        beq found
        lda savex
next:   
        iny
        jmp again

notfound:       
        ;; global (always have value of symbol)
        ;; TODO: if closer to car could beq there!
        jmp car
found:  
        ;; get value
        lda loclo,y
        ldx lochi,y

        rts
.endproc

;;; bind AX symbol name with stacked value
;;; -> AX (A garbled)
;;; 
;;; 19B
.proc bind
        dec locidx
        ldy locidx
        
        sta locidlo,y
        txa
        sta locidhi,y

        ;; TODO: or it's stored in ptr1/2?
        lda ptr1
        sta loclo,y
        lda ptr1+1
        sta lochi,y

        rts
.endproc

;;; 89B (very big)
.align 2
.proc print
        DUP

.ifdef NUMBERS
        bit BITNOTINT
        bne notint
isnum:  
        jsr div2
        jsr printd
        jmp ret
.endif ; NUMBERS

notint: 
        bit BITISCONS
        bne iscons
issym:  
        ;; TODO: struct?
        ldy #6
        jsr printzY
        jmp ret

iscons: 
        ;; ptr2= ax
        sta ptr2
        stx ptr2+1

        putc '('

printlist:      
        ;; push CDR(ptr1)
        ldy #2
        lda (ptr2),y ; a
        pha
        iny
        lda (ptr2),y ; x
        pha

        ;; ptr2= CAR(ptr1)
        ldy #1
        lda (ptr2),y ; x
        tax
        dey
        lda (ptr2),y ; a

        jsr print

        ;; cdr
        POP

        ;; !iscons break
        pha
        and #03
        cmp #03
        bne endlist
        pla

        ;; ptr2= ax
        sta ptr2
        stx ptr2+1

        putc ' '
        jmp printlist

endlist:        
        pla

        ;; nil => no dot
        cmp #<_nil
        bne printdot
        cpx #>_nil
        bne printdot
        jmp donelist

printdot:       
        PUTC '.'
        jsr print
donelist:       
        putc ')'

ret:    
        jmp popret
;        POP
;        rts
.endproc


.proc _initlisp

.ifdef ORICON        
        jsr _initscr
.endif ; ORICON
        
        ;; type BITs
        lda #01
        sta BITNOTINT
        lda #02
        sta BITISCONS

        ;; store _nil as car and cdr of _nil
.assert .hibyte(_nil) = 0, error
        lda #<_nil
        sta _nil
        ; sta _nil+2 ; do below

        lda #>_nil
        sta _nil +1
        ; sta _nil+2 +1 ; do below

        ;;  write 'nil'
        lda #110
        sta _nil+6
        lda #105
        sta _nil+7
        lda #108
        sta _nil+8

        ;; init 0
        ldx #0
        stx _nil+9
        stx _nil+2
        stx _nil+2 +1

        stx locidx

        ;; memory mgt
        lda #<(TOPMEM-4-1)
        sta lowcons
        lda #>(TOPMEM-4-1)
        sta lowcons+1

;;; TODO: move _T here and any selfeval symbol

        ; TODO: store address of "evalsecond"
        ; (nil (+ 3 4) (+ 4 5)) => 9 !

        ;; TODO: move to main?

.ifdef TEST
        jsr _test
.endif ; TEST

        rts
.endproc

.ifdef TEST

thetypeis: .byte "The value and type is: ",0

.proc testatoms
        ;; Atom
        lda #<_T
        ldx #>_T
;;; TODO: somehow value gets lost in print ???
        jsr print

        lda #<_nil
        ldx #>_nil
        jsr print

        lda #<_T
        ldx #>_T
        jsr print

        lda #<_T
        ldx #>_T
        jsr print

        rts
.endproc

.proc _testtype
        jsr print

        pha
        txa
        pha
        
        putc ':'

        pla
        tax
        pla

;;; TODO: fix
;        jsr _type
        bmi isnum
        beq isnull
        bvs issym
        bcs iscons
        
nomatch:        
        lda #'?'
        jmp putchar

isnum:  lda #'N'
        jmp putchar

isnull: lda #'Z'
        jsr putchar

issym:  lda #'S'
        jmp putchar

iscons: lda #'C'
        jmp putchar

.endproc


.proc _test
        ;; test putchar getchar
        lda #'Z'
        jsr putchar
        lda #'X'
        jsr putchar
        lda #'Y'
        jsr putchar
        jsr getchar
        jsr putchar

        jsr _testprint

.ifdef NUMBERS
        jsr testnums
.endif

        jsr testatoms
        jsr testtypefunc

        jsr testbind

        jsr contcall

        jsr testcons

        jsr testeval

        rts
.endproc

.align 4
.res 3
acons:  .word _T,_nil
bcons:  .word _T,acons
ccons:  .word _cons,bcons

.proc testeval
        SET _nil
        jsr print
        jsr eval
        jsr print

        SET _T
        jsr print
        jsr eval
        jsr print

        SET _car
        jsr print
        jsr eval
        jsr print

        SET _cdr
        jsr print
        jsr eval
        jsr print

        SET _print
        jsr print
        jsr eval
        jsr print

;;; eval(cons(_print, cons(4711, nil)))
        SETNUM 4711
        jsr setnewcar
        SET _nil
        jsr setnewcdr
        jsr newcons
        jsr print
        
        PUTC '/'

        jmp call1x
call1: 
        PUSH
        SET _print
        jmp revcons

call1x: jsr call1

        jsr print

        NEWLINE

        jsr eval

        NEWLINE

        ;; test eval of "cons"
        SET ccons
        jsr print
        jsr eval
        jsr print

        NEWLINE
        rts
.endproc

.proc contcall
        ;; crazy idea: continuation for stack
        ;; for parameter passing
        ;; 6B, 6c overhead
        ;; (3B 3c if rest of code inlined)

        NEWLINE

        ;; foo(_T, tcons, _nil) 
        jsr callfoo
        ;; comes here after callfoo!!!
        ;; return result in AX
        jmp afterfoo
callfoo:    
        ;; one parameter 4+3=7 bytes
        ;; (could be lda pha lda sta = 6)
        SET _T
        PUSH

        SET tcons
        PUSH
        ;; last parameter in AX
        SET _nil
        jmp foo
afterfoo:

        NEWLINE

        ;; foo2(_T, tcons, _nil) 
        jmp afterfoo2
callfoo2:    
        ;; one parameter 4+3=7 bytes
        ;; (could be lda pha lda sta = 6)
        SET _T
        PUSH

        SET tcons
        PUSH
        ;; last parameter in AX
        SET _nil
        jmp foo2
afterfoo2:
        jsr callfoo2
        ;; comes here after callfoo!!!
        ;; return result in AX

        NEWLINE

        ;; foo3(_T, tcons, _nil) 
        jmp afterfoo3
callfoo3:    
        ;; one parameter 4+3=7 bytes
        ;; (could be lda pha lda sta = 6)
        SET _T
        PUSH

        SET tcons
        PUSH
        ;; last parameter in AX
        SET _nil
        jmp foo3
afterfoo3:
        jsr callfoo3
        ;; comes here after callfoo!!!
        ;; return result in AX

        NEWLINE

        PUTC '!'

        rts
.endproc

;;; foo(a,b,c) prints c, b, a
;;; 19B
.proc foo
        jsr print
        POP
        jsr print
        POP
        jsr print

        rts
.endproc

;;; 31B
.proc foo2
        PUSH

        PUTC '/'

        ARG 0
        jsr print

        PUTC '/'

        ARG 1
        jsr print

        PUTC '/'

        ARG 2
        jsr print

        PUTC '/'

        ARG 1
        jsr print

;; TODO: this destroyes AX no good make
; POPRET 3
        POP
        POP
        POP
        rts
.endproc

;;; 31B
.proc foo3
        PUSH

        PUTC '+'

        arg 0
        jsr print

        PUTC '+'

        arg 1
        jsr print

        PUTC '+'

        arg 2
        jsr print

        PUTC '+'

        arg 1
        jsr print

        ;; TODO:
        POP
        POP
        POP
        rts
.endproc

;;; create a fake cons to see it recognized
.align 4
.res 3
tcons:      .word _T, _T

.proc testcons
        NEWLINE

        SET tcons
        jsr print

        PUTC 'c'

        ;; make new cons
        SET tcons
        jsr setnewcar

        SET tcons
        jsr setnewcdr

        jsr newcons
        jsr print              
        DUP

        NEWLINE

        POP
        DUP
        jsr setnewcar
        POP
        jsr setnewcdr
        jsr newcons
        jsr print

        NEWLINE

        rts
.endproc


.proc testbind
        PUTC 'D'

        lda locidx
        eor #'0'
        jsr putchar

        SET _T
        jsr getvalue
        jsr print

        PUTC 'X'

        SET tcons
        sta ptr1
        stx ptr1+1

        SET _T

        jsr bind

        lda locidx
        eor #'0'
        jsr putchar

        PUTC 'y'

        SET _T
        jsr getvalue
        jsr print

.ifblank
        lda #$ff                ; 'O' == $ff ^ 48
        eor #'0'
        jsr putchar

        ldy #$ff
        lda lochi,y
        tax
        lda loclo,y
        jsr print

        PUTC 'x'
.endif

.ifblank
        ldy #$ff
        lda locidhi,y
        tax
        lda locidlo,y
        jsr print
.endif

        PUTC 'Y'

        rts
.endproc

;;; 123 bytes
;hello:  .asciiz "2 Hello AsmLisp!",10,""

_hello:	   .byte "4 Hello AsmLisp!",10,0
_helloN:   .byte "5 Hello AsmLisp!",10,0

.proc _testprint

.ifdef ORICON
        ;; an A was written by c-code

        ;; write a B directly
        lda #'B'
        sta $BB81

	;; move 2 char forward to keep AB on screen
        dec leftx
        dec leftx
        lda #02
        jsr _scrmova
.endif ; ORICON

        ;; write string x 17
        SET _hello
        jsr printz
.ifdef ORICON
        jsr printzptr
        jsr printzptr

        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
.endif ; ORICON

        ;; 13 x helloN
        SET _helloN
        jsr printz
.ifdef ORICON
        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr
.endif ; ORICON
        
        SET _helloN
        jsr printz
.ifdef ORICON
        jsr printzptr
        jsr printzptr
        jsr printzptr

        jsr printzptr
        jsr printzptr
        jsr printzptr
        jsr printzptr

        ;; write a C indirectly at current pos
        lda #'C'
        ldy #00
        sta (curscr),y
.endif ; ORICON

        rts
.endproc


.proc testtypefunc
        SET _T
        jsr _testtype
        SET _T
        jsr _testtype

        SET _nil
        jsr _testtype
        SET _nil
        jsr _testtype

        SET _nil
        jsr print

        rts
.endproc

.endif ; TEST


;;; LISP:
;;;   SectorForth: 	512 bytes
;;;   SectorLisp:  	436 bytes
;;;   z80 milliforth:	336 bytes
;;;   6502 milliforth:  328 bytes !
;;; 
;;; - https://github.com/agsb/milliForth-6502
;;;   * no: line editor, bs, cancel, low ascii
;;;         stacks overflow, underflow checks
;;;   primitives: s@ + nand @ ! 0# exit key emit
;;;   internals: spush spull rpull rpush
;;;     copyfrom copyinto (heap code) incr decr add etc
;;;     cold warm quit token skip scan getline
;;;     parse find compile execute
;;;     unnest next nest unnest pick jump
;;;   externals: getch putch byes
;;;   ext: 2/ exec $(jmp to ipt) 
;;;   optional: bye abort .S .R . words dump
;;;;
;;; 6502 asmlisp - "SECTORLISP for 6502"
;;; (goal < 512 bytes, not care speed)
;;; 
;;; ! = done
;;; - = function planned
;;; * = function in SectorLisp
;;; # = number function / optional
;;; 
;;; [42] bytes neeeded but is "bios" (getchar/putchar)
;;; (42) bytes needed for optinoal (numbers)
;;;
;;; x - _type		29 (6)		29
;;;   * atom (== !iscons)
;;; ! * prin1
;;;     - prinz         [75]
;;;     - putchar       [10]
;;;     N printd        (12)
;;;       - voidprintd  (38+1)	 	
;;;     - initscr       (17)
;;;     * print         28 (11)         67 (79) [85]
;;;       * print cons/list (TODO)
;;;   * eq
;;;   * read
;;;     * readatom       15             82
;;;     * readlist
;;;       * quote
;;;     # readnum       (38)              
;;;       # mul16       (33)                (150)  
;;; ! * cons (grow down?)
;;; ! * car
;;; ! * cdr
;;;   * lambda
;;;   * eval            35              117        [85]
;;;     - assoc
;;;   * cond / if
;;;
;;; STACK (TODO: use limited 256 byte? or 80B in zp?)
;;;   - pushax
;;;   - popax
;;;   - incsp2
;;;   - incsp4
;;;
;;;   # plus (+)
;;;
;;; GOODIES
;;;   - def
;;;   - apply
;;;   - and
;;;   - or
;;;   - list
