;;; print.asm - asm generic print routines
;;; 
;;; set flags before .include this file

;;; JUST TO GET SIZE
;;; 
;;;   ca65 print.asm -l print.s
;;; 
;;;   #x71 == 113

.if !.definedmacro(FUNC)
  .macro FUNC name
     .ident(.string(name)):
  .endmacro
  ;;; fake
  .zeropage
    tos:    
    tmp1:   
  .code
  plaputchar:     
  _drop:  
  putchar: 
        rts
  PUTDEC=1
  PUTHEX=1        
.endif

.ifnblank
;;; COPY THIS:

;;; PRINT.ASM --------------------
;;; Enable to save bytes (and get slower)
;SAVEBYTES=1 

;;; Enable to print decimal numbers by default
;;; (this one wll use and prefer DIVMOD impl)
;PUTDEC=1

;;; Enable to print decimal numbers by default
;;; (this one uses dedicated putu 35 bytes)
;PUTDECFAST=1

;;; Enable to print hexadecimal numbers by default
;PUTHEX=1

;;; Default to use $abcd notation
;PUTHEXNODOLLAR=1

.include "print.asm"
;;; END PRINT.ASM --------------------

.endif

;;; --- these prints the TOS value and pops it
;;; _printn - pop prints using choosen format
;;; _putu - pop prints in decimal
;;; _puth - pop prints in hex

;;; --- these prints and leaves value on TOS/stack
;;; (typically used for debugging?)
;;; printn - print a number using choosen format
;;; puth - prints hex
;;; putu - prints 

;;; ----------------------------------------

.ifdef PUTHEX
        PRINTER=1

.endif ; PUTHEX

.ifdef PUTDEC
  .ifndef PRINTER
        PRINTER=1
  .endif

  .ifdef SAVEBYTES

    .ifdef DIVMOD
      .ifdef PUTDECFAST
        .error "%% Conflic PUTDECFAST & SAVEBYTES"
      .endif

        PUTDECDIV=1
    .else ; NDIVMOD
        ;; actually smaller than div+putu
        PUTDECFAST=1
    .endif ; NDIVMOD

  .else
    .ifdef DIVMOD
        PUTDECDIV=1
    .else    
        PUTDECFAST=1
    .endif
  .endif ; SAVEBYTES
.endif ; PUTDEC

.ifndef PRINTER
  .ifdef PUTDECFAST
        PRINTER=1
  .endif
.endif

.ifnblank

.proc _putu
;;; 14 B
        BYTECODE

next:   LIT 10
        DO _divmod
        ;; Recurse to print higher value digits first!
        DO _swap
        DO _putu

        DO print1h              ; maybe CALL?
        DO _drop
        BRANCH next

        DO _drop
        DO _exit
.endproc        

.endif ; BLANK


.ifdef PUTDECDIV
;;; print decimal
;;; 
;;; TODO: ironically, the fastest routine to print is 
;;;   voidprintptr1 33 B could do it on tos, +2 for jmp pop
;;;   so 35 B or 29 B requiring _div and is much slower...
;;;           6 B difference...
;;; 
;;; TODO: too big! (might as well use xputu...)
;;; 
;;; Maybe can write as OP16?

;;; 29 B + 14 B (plaprint1h)

;;; TODO: make it a system zp variable?
;;; init cost 4 bytes... lol
BASE=10

;;; this one preserves TOS
printn: 
        jsr _dup

;;; TODO: FUNC "_putu"
.align 2, $ea                   ; NOP
.export _putu
.proc _putu
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
        bne _putu
done:
        jmp _drop
.endproc

.endif ; PUTDECDIV
        

.ifdef PUTHEX

debugprintn:
debugputh:

.ifndef print_for_debug
  printn:
  puth:
.endif

;;; puth: print hex
;;; (+ 5 7 8) = 20 + 14 (plaprint1h)
;;; 5
.ifndef PUTHEXNODOLLAR
        lda #'$'
        jsr putchar
.endif
;;; 7
print4h:        
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
        ;; nice: falls-through to pla!
.endif ; PUTHEX

.if .def(PUTHEX) || .def(PUTDECDIV)
plaprint1h:     
;;; (14)
        pla
.proc print1h
;;; TODO: - http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/some-veryshort-code-bits/
;;; 6 B
;;;   SED
;;;   CMP #$0A
;;;   ADC  #"0"
;;;   CLD

;;; 10 B
        and #$0f
        ora #$30
        cmp #'9'+1
        bcc printit
        adc #6
printit:        
        jmp putchar
.endproc

.endif ; PUTUDCDIV || PUTHEX



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

.macro PRINTZ msg
.scope
.data
@data:       
        .byte msg,0
.code
        lda #<@data
        ldx #>@data
        jsr _printz
.endscope
.endmacro

;;; if had an ITERATOR : dup II swap D swasp @ ;
;;; 
;;; 22 B
FUNC _printz
axputz:   
        sta tos
        stx tos+1

        ldy #0
_writez:
        lda (tos),y
        beq :+
        jsr putchar

        inc tos
        bne _writez
        inc tos+1

        bne _writez
:       
        rts


;;; TODO: this is duplcated code in test 
;;;   maybe do include?

;;; putu print a decimal value from AX (retained, Y trashed)

.ifdef PUTDECFAST

  debugputu:

.ifndef debugprintn
  debugprintn:   
  debugputh:
.endif

.ifndef print_for_debug
  
  _printn:        
  _putu:
      jsr xputu
      jmp _drop

  .ifndef printn
    printn:
  .endif

;  putu:

.endif

.proc xputu
        PHA
        TXA
        PHA

        lda tos
        ldx tos+1

        jsr _voidputu

        PLA
        TAX
        PLA
        rts
.endproc

;;; _voidputu print a decimal value from AX (+Y trashed)
;;; 37B
;;; 
;;; _voidputuptr1
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

_voidputu:    
        sta tmp1
        stx tmp1+1
        
.proc _voidprinttmp1d

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
        rol tmp1
        rol tmp1+1
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

.endif ; PUTDECFAST

.ifdef PUTDEC
        putu=_putu
.endif

axputu:   
        sta tos
        stx tos+1
        jmp putu

axputh: 
        sta tos
        stx tos+1
        jmp puth

.ifdef putd
axputd: 
        sta tos
        stx tos+1
        jmp putd
.endif
        
