;;; "SectorLisp for 6502" asmlisp-asm.asm (+ asmlisp.c)
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org

;;; This is an attempt to write a pure assembly minimal
;;; lisp for 6502, similar to SectorLisp that was
;;; only 436 bytes, smaller than the SectoForth at 512
;;; bytes.
;;; 
;;; There is a z80/6502 milliforth is 336/328 bytes!
;;; 
;;; can we create a minimal 6502 lisp?

;;; SectorLisp limitations:
;;; - 512 bytes "bootable"
;;; - assumes prexisting "bios": getch putch
;;; - only SYMBOLS and CONS
;;; - reader and writer (no editor, or backspace)
;;; - T NIL ?QUOTE ?READ PRINT ?COND CONS CAR CDR
;;;     ATOM ?LAMBDA EQ

;;; (/ 512.0 10) = 51.2 B/fun - "sector"
;;; (/ 446.0 10) = 44.6 B/fun - SectorLisp
;;; (/ 328.0 10) = 32.8 B/fun - milliforth 6502

;;;                                    pad
;;; NIL     8, 26       = 34            2
;;; T       8           =  8            0
;;; CAR:    8, 13	= 21            3
;;; CDR:    8, (car)+4	= 12            0
;;; CONS:  12, 14	= 26            2
;;; EQ:     8, 17	= 25            3
;;; ATOM:  12, 15	= 27   S= 153
;;;       ---           ----          ---
;;;        64            153           10
;;;                                UNCOUNTED!

;;; types               =  8
;;;   BIT 8
;;; memory              =  8      169
;;;   initlisp 8

;;; eval:               = 98      251
;;;   simple 12
;;;   apply   (+ 12 52 22 12)
;;;     evlist 52
;;;     apply  22
;;;     lambda 12, ??

;;; PRINT: 12, 92       =104      355
;;;   print    92
;;;     printz 18
;;;     printlist ??

;;; READ:               = 80++    434
;;;   getc     12  (+ 12 8 19 19 22)
;;;   skipspc   8
;;;   readatom 17 xx 19
;;;   read     17 xx 19
;;;     findsym  ??    
;;;   readlist 22

;;; COND: ...             ??       ??

;;;   QUOTE
;;;   

;;; AsmLisp limitations;
;;; - atom maxlength is 15 chars (not checked)
;;; - atoms can only contain chars > ')'
;;; - READ list length is limited by HW stack (no check)
;;; - only SYMBOLS & CONS
;;; - numbers are optional

;;; TODO: READ QUOTE COND LAMBDA

;;; - no GC (or minimal "reset")

;;; ORIC: charset in hires-mode starts here
TOPMEM	= $9800

;;; .TAP delta
;;;  325          bytes - NOTHING (search)
;;; (829 +504     bytes - MINIMAL (- 829 325) no read)
;;;  916 +591     bytes - MINIMAL+READ (- 916 325)
;;;  613?         bytes - ORICON  (raw ORIC, no ROM)
;;;  1048 +133    bytes - NUMBERS (- 1048 915)
;;;  950  +64     bytes - MATH+NUMS (- 950 886) 
;;;  900?         bytes - TEST + ORICON

;;; START

;;; 591 bytes
;;;       initlisp nil 37, T 10,
;;;       print 23 printlist 72, printz 17, eval 49
;;;       getvalue 38, bind 19,
;;;       setnewcar/cdr 14, newcons 21, cons 12, revc 12
;;;       _car _cdr 19, _car _cdr 20, _print 12
;;;       _cons 16, _atom atom 16+15=31
;;;       _eq 8+17=27
;;;       getc 12, skispc 8, _read 10, readatom 23, read 17
;;;             NOT: == READS SEXP OK!
;;; == 554 ==
;;; (+ 37 10 25 71 17 90 38 19 14 21 12 12 19 20 12 16 31 27 12 8 10 23 17)
;;; 
;;;  TODO: wtf? (- 618 554) = 64 bytes missing (align?)

;; MINMIMAL
;MINIMAL=1

.ifndef MINIMAL

;;; enable numbers
;
NUMBERS=1

;;; enable math (div16, mul16)
;MATH=1

;;; enable tests (So far depends on ORICON)
;
TEST=1

;;; enable to use larger fun instead of macro
;;; goodif used several times
;SWAPFUN=1

;;; generic iter
;ITERFUN=1 

;;; enable ORICON(sole, code for printing)
;;; TODO: debug, not working well get ERROR 800. lol
;ORICON=1
.endif ; MINIMAL

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
savez:  .res 1

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

_nil:   .res 4
        .res 4
;        .byte "nil", 0


;;; simulated input
;inptr:  .res 2

;;; read/parse buffer
buff:   .res 16

;;; --------------------------------------------------
;;; Uninitialized data (not stored in binary)

.bss

;;; locals
locidlo:        .res 256
locidhi:        .res 256
loclo:          .res 256
lochi:          .res 256


.code
startaddr:      

;;; $53c
.assert startaddr=1340, error ;"changed .org"

.org $53c

.macro CONSALIGN
  .res 3- * .mod 4
.endmacro

.macro SYMALIGN
  .ifnblank
    .align 4
    .res 1
  .else
  ;;; SAVED 10 BYTES!
  .if (* .mod 4) <> 1
    .res 1
  .endif
  .if (* .mod 4) <> 1
    .res 1
  .endif
  .if (* .mod 4) <> 1
    .res 1
  .endif

.endif
.endmacro

;;; various special data items, constants
;;; - ATOMS
;;; TODO: any evaluate to self, put in ZP?
;;;       (easier test in eval!)
;;; 2458-2450 = 8 bytes saved, lol
SYMALIGN
_T:     .word _T, _nil
        .byte "T", 0

SYMALIGN
_car:   .word car, _T
        .byte "car", 0

SYMALIGN
_cdr:   .word cdr, _car
        .byte "cdr", 0

SYMALIGN
_print: .word print, _cdr
        .byte "print", 0

SYMALIGN
_cons:  .word cons, _print
        .byte "cons", 0
;;; here usese 3 bytes padding
SYMALIGN
_atom:  .word atom, _cons
        .byte "atom", 0
;;; here usese 3 bytes padding
SYMALIGN
_eq:    .word eq, _atom
        .byte "eq", 0

SYMALIGN
_read:  .word read, _eq
        .byte "read", 0
;;; here usese 3 bytes padding

;;; 8 symbols here, 78 bytes (/ 78 8.0) = 9.75 B/sym
symend: 

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
        stx savex
        sty savey

        jsr $023B               ; ORIC ATMOS only
        bpl getchar             ; no char - loop
        tax
        ;; TODO: optional?
        jsr $0238               ; echo char

        ldy savey
        ldx savex

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

.macro ZERO
        lda #0
        tax
.endmacro

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
;;; 17 B
        ldy #3
;;; TODO: bit hack, and .align NOP everywehere
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
;;; 
;;; 1+13
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
;;; by strat @ nesdev forum ; 21 B
;;; 
;;; out: A: remainder; X: 0; Y: unchanged

.ifdef MATH
;;; 16/8
;;; 
;;; 21 B

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
;;;     ptr1/ptr2 => ptr1
;;; 
;;; jsk 37B
.proc div1616
        ldx #16
        lda #0                  ; keeps lowbyte!

@divloop:
        asl ptr1
        rol ptr1+1
        rol a

        ;; hi-byte cmp
        tay
        lda ptr1+1
        cmp ptr2+1
        bcc no_sub              ; one off?
        tya

        ;; lo-byte cmp
        cmp ptr2
        bcc no_sub

        ;; lo-byte sub
        sbc ptr2
        inc ptr1                ; add 1 to result!

        ;; hi-byte sub
        tay
        lda ptr1+1
        sbc ptr2+1
        sta ptr1+1
        tya
  
no_sub:
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
;;; TODO: maybe not need save as print does?
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

; TODO: not used - remove, or update with BIT and make macro?
.ifnblank

.proc _isnumSetC                ; 12c 3B+1
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
.endproc

;;; TODO: consider illegal instruction !
;;; ALR # %11 (test two lower bits in one op?)
;;; 
;;; order of testing...
;;;   C= 0 => number
;;;   Z=01 => atom!
;;;   Z= 1 => cons!
;;; 
;;; ALR (ASR)
;;; AND oper + LSR
;;; 
;;; A AND oper, 0 -> [76543210] -> C
;;; 
;;; N Z C I D V
;;; + + + - - -
;;; 
;;; addressing      assembler       opc     bytes   cycles  
;;; immediate       ALR #oper       4B      2       2  
;;; 

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
.proc isnullSetZ                ; 11-12c 6B+1
        cmp #<_nil               
        bne ret                  ; if Z=0 => not Null
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


;;; xxx00 number
;;; xxx01 atom
;;; xxx10 number
;;; xxx11 cons
;;; 
;;; 31B  (- 815 785)= 30
.ifnblank
.proc type
        clc
        bit BITNOTINT
        beq isnumber            ; N=1 -- number
        bit BITISCONS
        bne iscons              ; N=0
issym:                          ; N=1
        tay
        cpx #<_nil
        bne notnull
        cmp #>_nil
        bne notnull
null:   
        lda #64+4               ; V=1 + Z=1 -- null
        bne setP
notnull:        
        lda #64+4               ; V=1 -- symbol
setP:   
        pha
        tya
        plp
        rts

iscons: 
        sec                     ; C=1 N=0 -- cons
isnumber:        
        clv
        rts
.endproc
.endif


;;; swap: swaps AX <-> R-stack (one level before ret!)
;;; 15B :-(                   ;                  04 03

;;; TODO: OK, reusable but only used once? LOL
;;;   inline is 15B ...

.ifdef SWAPFUN
.proc swap                    ; a  x  y sa sx sy ma mx

;;; 22B
        sta savea
        stx savex             ; A  X  Y  A  X     a  x

        arg 1

        pha
        lda savea
        sta $104,y
        lda savex
        sta $103,y
        pla

        rts

;;; 28B
.ifnblank
        sta savea
        stx savex             ; A  X  Y  A  X     a  x

        ARGSETY

        ;; really other A
        ldx $104,y            ; A  a  S  A  X     a  x
        stx savey             ; A  a  S  A  X  a  a  x

        ;; swap x
        ldx $103,y            ; A  x  S  A  X  a  a  x
        lda savex             ; X  x  S  A  X  a  a  x
        sta $103,y            ; X  x  S  A  X  a  a  X
        
        ;; swap a
        lda savea             ; A  x  S  A  X  a  a  X
        sta $104,y            ; A  x  S  A  X  a  A  X
        lda savey             ; a  x  S  A  X  a  A  X

        rts
.endif
.endproc
        
.macro SWAP
        jsr swap
.endmacro

.else

;;; SWAP (ax <-> R-stack)
;;; 15B
.macro SWAP
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
.endmacro

.endif ; SWAPFUN

.ifdef ITERFUN

;;; iterOrExit - a generic list iteration function
;;;   convenient abstraction
;;; 
;;; IN:  list on stack
;;; OUT: AX=car; cdr list on stack
;;; 
;;;   pop
;;;   !iscons -> super return last cdr
;;;   iscons -> push cdr, ax=car
;;; 
;;; 36B ... 24B (without test 14B)
.proc iterOrExit

;;; TODO: needs debugging

        arg 1
;        PUTC 'a'
;        jsr printd
        jsr isconsSetC
        bcs iscons
;        PUTC 'x'

        ;; RETURNS: nil or last element (= nil)
        ;; not cons => SUPER return!
        ; remove this call and return from prev call!
superret:       
        tay
        ;; remove ret
        pla
        pla
        ;; remove list
        pla
        pla

        tya
        rts

iscons: 
;        PUTC 'c'
        ;; ptr1= AX, AX= cdr
        jsr cdr
;     jsr print
        
        ;; store elt above return address!
;;; TODO: SETARG 1
;;; todo: pha, pla and adjust sta offset, lol
        stx savex
        tsx
        sta $102+2,x
        lda savex
        sta $101+2,x
        
        ;; car (ptr1)
        ldy #1
        jmp ptr1cYr
.endproc
.endif ; ITERFUN

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


;;; TODO: XPUSH
;;; (this may be overwritten so need push,
;;;  but current stack is unsafe, use another!)


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
        ;;
        jsr isconsSetC
        bcc finishedeval

	;; 9B
.ifnblank
        tay
        and #03
        cmp #03
        bne finishedeval
        tya
.endif
        DUP
notnil: 
        jsr car
        jsr eval
        ;PUTC ','
        ;jsr print

        SWAP


        jmp evallist
finishedeval:   
        ;; put last arg in AX
        POP
        ;PUTC '='
        ;jsr print             

        ;; indirect call to atom car number address!
;;; TODO: XJMP
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

;;; 5B (+2 NUMBERS)
.proc isconsSetC
        tay
.ifdef NUMBERS
        and #03
        ;; seems to work with #03 too?
        cmp #03
.else
;;; TODO: bit BITISCONS but sets Z=0
        ;; only have atom/cons
        ror
        ror
.endif
        tya
        rts
.endproc

.align 2
atom:   
;;; 11B ... ?
        ;; assume both _NIL & _T is in zp
        ldx #0

        ror
        beq rettrue
retnil: 
        lda #<_NIL
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
rettrue:
        lda #<_T
        
        rts

atom:   
;;; 15B
        jsr isconsSetC
Crettrue:       
        bcc rettrue
retnil: 
        SET _nil
        rts
rettrue:
        SET _T
        rts

.align 2
;;; 17B
.proc eq
        sta savea
        sta savex
        POP
        cmp savea
        bne retnil
        cpx savex
        bne retnil
        beq rettrue
.endproc     


.align 2
;;; read an sexpr return in AX
;;; 
;;; (nice spagetti!)
;;; 
;;; 39B
read:   
        jsr skipspc
.proc readusingA
        ;; only gives char >='('
        cmp #')'
        beq retnil      ; not needed?
        bcc readlist    ; '('

        ;; valid atom char
        jsr readatom

parseatom:      
.ifdef NUMBERS
        ;; first char digit?
        lda buff

        cmp #'9'+1
        bcs symbol
        cmp #'0'-1
        bcc symbol

        ;; TODO: parsenum
        SETNUM 42 ; LOL
        rts
.endif ; NUMBERS

symbol: 
        ;; TODO: findsym
        SET _T ; LOL
        rts

readlist:       

        jsr skipspc
        ;; ) end of list
        cmp #')'
        beq retnil

        ;; prepare car
        jsr readusingA
;        jsr parseatom

        ;; continuation tail, lol
        PUSH
        jsr readlist
        jmp cons                ; tail-cont-recursion!
.endproc

cunget: .byte 0

;;; 12B
.proc getc
        lda cunget
        bne got
        jsr getchar
got:    
        ldx #0
        stx cunget
        rts
.endproc

;;; 8B
.proc skipspc
        jsr getc
        ;; < '(' is considered white space
        cmp #'('-1
        bcc skipspc
        rts
.endproc

;;; readatom reads and atom into zp buff
;;; X contains number of chars read.

;;; Result: in buff, X length
;;; ->A contains breakchar
;;; (not Y unchanged)

;;; assumes a non-white space char alread in A
;;; 
;;; 17B ... 29B before ... 23B (before...15B)
;;; break char in A
;;; result in buff length in X
.proc readatom
        ldx #0
next:   
        ;; test if valid
    .ifblank
        ;; (we simplify like SectorLisp no char
        ;;  !"#$%&'() may be part of atom name )
        cmp #')'+1
        bcc done ; <= ')'
    .else
        cmp #' '+1
        bcc done                ; eof/spc
        cmp #'('
        beq done
        cmp #')'
        beq done
        ;; see below
        cmp #'.'
        beq done
    .endif

        ;; TODO: minimal no read dotted pair?
        ;cmp #'.'
	;beq ret

        ;; got valid char for atom
        sta buff,x
        jsr getc
        inx
        ;; TODO: overflow?
        bne next                ; jmp next

done:    
        sta cunget
        rts
.endproc



;;; 25B + 71B (printlist)
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
        ldy #4
        jsr printzY
        jmp ret

iscons: 
        jsr printlist
ret:    
        putc ' '
        jmp popret
.endproc


.ifdef ITERFUN

;;; 41B
printlist:
        PUSH
        putc '('
        jsr printelements

;;; TODO: better test
        ;; nil => no dot
        ;; 8B
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
        jmp popret

.else

printlist:
        ;; ptr2= ax
        sta ptr1
        stx ptr1+1

        putc '('

;;; 71B
printelements:      
        ;; push CDR(ptr1)
        ldy #2
        lda (ptr1),y ; a
        pha
        iny
        lda (ptr1),y ; x
        pha

        ;; ptr2= CAR(ptr1)
        ldy #1
        lda (ptr1),y ; x
        tax
        dey
        lda (ptr1),y ; a

        jsr print

        ;; cdr
        POP                   
        
        ;; !iscons => endlist
        ;; 5B
        jsr isconsSetC
        bcc endlist

        ;; ptr1= ax
        sta ptr1
        stx ptr1+1

        ;; TOTALLY correct only if have more...
        ;putc ' '

        jmp printelements

endlist:        

;;; TODO: better test
        ;; nil => no dot
        ;; 8B
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
        rts

.endif ; ITERFUN



.proc _initlisp

.ifdef ORICON        
        jsr _initscr
.endif ; ORICON
        
        ;; type BITs
        ldx #01
        stx BITNOTINT
        inx
        stx BITISCONS

        ;; store _nil as car and cdr of _nil
.assert .hibyte(_nil) = 0, error
        lda #<_nil
        sta _nil
        sta _nil+2
        ; sta _nil+2 ; do below
        ; sta _nil+2 +1 ; do below

        ;; 12B write 'nil'
        lda #110
        sta _nil+4
        lda #105
        sta _nil+5
        lda #108
        sta _nil+6

        ;; init 0
        ldx #0
        stx _nil+7              ; terminate "nil"
        stx _nil+0+1            ; car hi
        stx _nil+2+1            ; cdr hi

        stx locidx              ; 0 means empty

        ;; memory mgt
        lda #<(TOPMEM-4-1)
        sta lowcons
        lda #>(TOPMEM-4-1)
        sta lowcons+1

;;; TODO: move _T here and any selfeval symbol

        ; TODO: store address of "evalsecond"
        ; (nil (+ 3 4) (+ 4 5)) => 9 !

        ;; TODO: move to main?

        ;; fallthrough to test

;;; TODO: read-eval loop

.ifdef MINIMAL
        rts
.endproc
.else

.endproc

endaddr:        

;;; ==================================================
;;; 
;;;               T       E      S     T

.proc _test
        ;; print size info for .CODE
        NEWLINE
        SET startaddr
        jsr printd
        PUTC '#'
        SET (symend-startaddr)
        jsr printd
        PUTC '-'
        SET endaddr
        jsr printd
        PUTC '='
        SET (endaddr-startaddr)
        jsr printd
        NEWLINE
.ifndef TEST
        rts
.endproc
.else
        jsr testiter

        jsr testswap

        jsr testprint
        jsr testnums
        jsr testatoms
        jsr testtypefunc
        jsr testbind
        jsr contcall
        jsr testcons
        jsr testeval
        jsr testtests
        jsr testread

        rts
.endproc ; _test

.proc testiter
.ifdef ITERFUN
        SET acons
        jsr car
        jsr print

        SET acons
        jsr cdr
        jsr print

        NEWLINE

        SET _nil        
        jsr printd

        NEWLINE

        SET acons
        jsr doit
        NEWLINE

; enabling this line fcks things up???
;        PUTC 'W'

        SET ccons
        jsr doit
        NEWLINE

; this messes up whats before???? wtf?
;        SET ccons
;        jsr print

        PUTC 'U'
        SET _T
        jsr print
        jsr eval
        PUTC 'V'
        NEWLINE
        jsr print

        jsr doit
        NEWLINE

        PUTC 'S'
        NEWLINE

        jmp cont
        rts

doit:   
        PUSH
again:  
        jsr iterOrExit
        jsr print
        jmp again

cont:   

.endif ; ITERFUN
        rts
.endproc

.proc testswap
.ifdef SWAPFUN
        SETNUM 5
        PUSH
        SETNUM 4
        PUSH
        SETNUM 3
        PUSH
        SETNUM 2
        PUSH
        SETNUM 1
        PUSH

        SET $0102               ; 258 772
        PUSH
        SET $0304               ; 772 258

;;; 772 258
        jsr swap             
;;; 258 772

        jsr printd
        NEWLINE
        POP
        jsr printd
        NEWLINE

        POP
        POP
        POP
        POP
        POP
.endif ; SWAPFUN
        rts
.endproc ; SWAPFUN

.proc testio
        ;; test putchar getchar
        lda #'Z'
        jsr putchar
        lda #'X'
        jsr putchar
        lda #'Y'
        jsr putchar
        jsr getchar
        jsr putchar
        
        rts
.endproc

.proc testread
;;; readeval loop!
        putc 10
        putc '>'

        jsr read
        NEWLINE
        jsr print
        NEWLINE
        ;jsr eval
        ;jsr print
        jmp testread

;;; debug readatom function
        jsr readatom

        tay
        txa
        pha
        putc 10
        tya
        ;jsr putchar
        ;PUTC ' '
.ifdef NUMBERS
        ;; print break char code
        ldx #0
        jsr printd
        putc '#'
        pla
        ldx #0
        jsr printd
.endif ; NUMBERS
        putc ':'
        
        SET buff
        jsr printz
        jmp testread
.endproc

.proc testnums
.ifdef NUMBERS
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

.endif ; NUMBERS
        rts
.endproc

.proc testtests
        SETNUM 42
        jsr print
        jsr atom
        jsr print
        
        NEWLINE

        SET _nil
        jsr print
        jsr atom
        jsr print
        
        NEWLINE

        SET _T
        jsr print
        jsr atom
        jsr print

        NEWLINE

        SET _print
        jsr print
        jsr atom
        jsr print

        NEWLINE
        SET tcons
        jsr print
        jsr atom
        jsr print

        NEWLINE

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
;rts
;;; ;TODO: thisone goes bezer????? stackmessed up?
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

.proc testprint

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

.endif ; TEST

;;; TODO: this is duplcated code in test 
;;;   maybe do include?

.ifndef NUMBERS
;;; printd print a decimal value from AX (retained, Y trashed)
.proc printd
;;; TODO: maybe not need save as print does?
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
.endif ; MINIMAL
        
.endif ; N NUMBER

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
;;; ! * atom (== !iscons) 31           ..
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

        ;; END
