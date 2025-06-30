;;; print.asm - asm generic print routines
;;; 
;;; set flags before .include this file

.ifnblank
;;; COPY THIS:

;;; PRINT.ASM --------------------
;;; Enable to save bytes (and get slower)
;SAVEBYTES=1 

;;; Enable to print decimal numbers by default
;;; (this one wll use and prefer DIVMOD impl)
;PRINTDEC=1

;;; Enable to print decimal numbers by default
;;; (this one uses dedicated printd 35 bytes)
;PRINTDECFAST=1

;;; Enable to print hexadecimal numbers by default
;PRINTHEX=1

;;; Default to use $abcd notation
PRINTHEXDOLLAR=1

.include "print.asm"
;;; END PRINT.ASM --------------------

.endif

;;; --- these prints the TOS value and pops it
;;; _printn - pop prints using choosen format
;;; _printd - pop prints in decimal
;;; _printh - pop prints in hex

;;; --- these prints and leaves value on TOS/stack
;;; (typically used for debugging?)
;;; printn - print a number using choosen format
;;; printh - prints hex
;;; printd - prints 

;;; ----------------------------------------

.ifdef PRINTHEX
        PRINT=1

.endif ; PRINTHEX

.ifdef PRINTDEC
        PRINT=1

  .ifdef SAVEBYTES

    .ifdef DIVMOD
      .ifdef PRINTDECFAST
        .error "%% Conflic PRINTDECFAST & SAVEBYTES"
      .endif

        PRINTDECDIV=1
    .else ; NDIVMOD
        ;; actually smaller than div+printd
        PRINTDECFAST=1
    .endif ; NDIVMOD

  .else
    .ifdef DIVMOD
        PRINTDECDIV=1
    .else    
        PRINTDECFAST=1
    .endif
  .endif ; SAVEBYTES
.endif ; PRINTDEC


.ifnblank

.proc _printd
;;; 14 B
        BYTECODE

next:   LIT 10
        DO _divmod
        ;; Recurse to print higher value digits first!
        DO _swap
        DO _printd

        DO print1h              ; maybe CALL?
        DO _drop
        BRANCH next

        DO _drop
        DO _exit
.endproc        

.endif ; BLANK


.ifdef PRINTDECDIV
;;; print decimal
;;; 
;;; TODO: ironically, the fastest routine to print is 
;;;   voidprintptr1 33 B could do it on tos, +2 for jmp pop
;;;   so 35 B or 29 B requiring _div and is much slower...
;;;           6 B difference...
;;; 
;;; TODO: too big! (might as well use xprintd...)
;;; 
;;; Maybe can write as OP16?

;;; 29 B + 14 B (plaprint1h)

;;; TODO: make it a system zp variable?
;;; init cost 4 bytes... lol
BASE=10

;;; this one preserves TOS
printn: 
        jsr _dup

;;; TODO: FUNC "_printd"
.align 2, $ea                   ; NOP
.export _printd
.proc _printd
        ;; divide by BASE
        lda #BASE
        jsr _pushA
        jsr _divmod

        ;; delayed print digit (reverses order!)
        lda tos
        pha
        lda #>(plaprint1h-1)
        pha
        lda #<(plaprint1h-1)
        pha

        jsr _drop

        ;; p => done
        lda tos
        ora tos
        bne _printd
done:
        jmp _drop
.endproc

.endif ; PRINTDECDIV
        

.ifdef PRINTHEX

printn:

;;; print hex
printh:
;;; (+ 5 7 8) = 20 + 14 (plaprint1h)
;;; 5
.ifdef PRINTHEXDOLLAR
        lda #'$'
        jsr putchar
.endif
;;; 7
        lda tos+1
        jsr print2h
        lda tos

print2h:      
;;; (8)
        pha
        ;; hi
        ror
        ror
        ror
        ror
        jsr print1h
        ;; lo
        
.endif ; PRINTHEX



.if .def(PRINTHEX) || .def(PRINTDECDIV)

plaprint1h:     
;;; (14)
        pla
.proc print1h        
        and #$0f
        ora #$30
        cmp #'9'+1
        bcc printit
        adc #6
printit:        
        jmp putchar
.endproc

.endif ; PRINTDECDIV || PRINTHEX



.ifnblank

;;; maybe B doesn't pop as well as O?
;        .byte DUP,"@",DUP,"B_",+2,0,DUP,"OIB",WRITEZ
;;; 12 B (3 dup)
;DUP = (_dup-jmptable)
;WRITEZ= (_writez-jmptable)
;;; 
;;; optimal: 'P! 'P@  B+2 _ ;  O 'P++ B-2
;;;          'P! 1 ( @P++ B+2 _ ; O ) 
;;; 
;;; nextc: dup @ swap I swap  # 5

;;; if had an ITERATOR : dup II swap D swasp @ ;
;;; 
;;; 12 B
FUNC "_printz"
_writez: 
        ldy #0
        lda (tos),y
        beq _pop
        jsr _out                ; canNOT uJSR
        iny
        bne _writez


.endif

;;; TODO: this is duplcated code in test 
;;;   maybe do include?

;;; printd print a decimal value from AX (retained, Y trashed)

.ifdef PRINTDECFAST

.ifndef _printd
_printd:        
        jsr xprintd
        jmp _drop
.endif

.ifndef printn
  printn: 
.endif

printd: 
.proc xprintd
;;; 12
;;; TODO: maybe not need save as print does?
        ;; save ax
        sta savea
        stx savex
        sty savey

        lda tos
        ldx tos+1

        jsr _voidprintd

        ;; restore ax
        ldx savex
        lda savea
        ldy savey

        rts
.endproc

;;; _voidprintd print a decimal value from AX (+Y trashed)
;;; 37B
;;; 
;;; _voidprintdptr1
;;; 33B - this is a very "minimal" sized routine
;;;       slow, one loop per bit/16
;;;       (+ 4B for store AX)
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

.endif ; PRINTDECFAST
