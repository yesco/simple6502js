;;; "SectorLisp for 6502" asmlisp-asm.asm (+ asmlisp.c)
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org

;;; Second attempt - a minimal lispy byte-code intepreter

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

;;; NIL     8, 26       = 34
;;; T       8           =  8
;;; CAR:    8, 13	= 21
;;; CDR:    8, (car)+4	= 12
;;; CONS:  12, 14	= 26
;;; EQ:     8, 17	= 25
;;; ATOM:  12, 15	= 27   S= 153

;;; types               =  8
;;;   BIT 8
;;; memory              =  8      169
;;;   initlisp 8

;;; PRINT: 12, 92       =104      273
;;;   print    92
;;;     printz 18
;;;     printlist ??

;;; READ:               = 76++    349
;;;   getc     12  (+ 12 8 17 17 22)
;;;   skipspc   8
;;;   readatom 17
;;;   read     17
;;;     findsym  ??    
;;;   readlist 22

;;; eval:               = 98      447
;;;   simple 12
;;;   apply   (+ 12 52 22 12)
;;;     evlist 52
;;;     apply  22
;;;     lambda 12, ??

;;; COND:

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
;NUMBERS=1

;;; enable math (div16, mul16)
;MATH=1

;;; enable tests (So far depends on ORICON)
;TEST=1

;;; enable to use larger fun instead of macro
;;; goodif used several times
;SWAPFUN=1

;;; generic iter
;ITERFUN=1 

;;; enable ORICON(sole, code for printing)
;;; TODO: debug, not working well get ERROR 800. lol
;ORICON=1
.endif ; MINIMAL

;;; --------------------------------------------------

;; TODO: not working in ca65, too old?
;.feature string_escape

.zeropage

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
BIT0: .res 1
BIT1: .res 1

;;; locals
locidx:  .res 1

;;; memory
lowcons: .res 2

sidx:    .res 1

ip:     .res 2
ipy:    .res 1

.code

biostart:       

;;; TODO: move before startaddr!

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

.ifdef IO
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
.endif ; IO

;;; for DEBUGGING only!

;;; putchar (leaves char in A)
;;; 5B
.macro putc c
        lda #(c)
        jsr putchar
.endmacro

subtract .set 0

;;; for debugging only 'no change registers A'
;;; 7B
.macro PUTC c
;        subtract .set subtract+7
        pha
        putc c
        pla
.endmacro

;;; 7B - only used for testing
.macro NEWLINE
        PUTC 10
.endmacro




;;; 1379
START=$563
;START=$600

startaddr:      

;;; Funny, if put this here it doesn't run!
;jmp _initlisp

.export _initlisp        

;.assert startaddr=START, error ;"changed .org"

;;; This makes addresses near here fixed thus can
;;; do fancy calculated alignments!
.org START


;;; enable these 3 lines for NOTHING .tap => 325 bytes
;_initlisp:      rts
;.end

;;; (- (* 6 256) 1379) = 157 bytes before page boudary

lostack= $400
histack= lostack+128

;;; JMP table
;;; align on table boundary by padding
;.res 256 - * .mod 256

jmptable:  

_cons:
cons:

.ifnblank
;;; ASMLISP (+ 21 -1 14 13) = 48!!!!
;;; (+ 14 11 11) = 36
        jsr conspush            ; cdr
        jsr pop
        jsr conspush            ; car
        lda #<lowcons
        ldx #>lowcons
        rts

conspush:       
        jsr decw2
        ldy #2
        sta (lowcons),y
        txa
        dey
        sta (lowcons),y
        rts
.else
;;; 31
        jsr conspush
        jsr pop
        jsr conspush
        lda #<lowcons
        ldx #>lowcons
        rts

conspush:  
        jsr cpusha
        tax

cpusha:       
        ;; jsr decw
        ;; decw
        ldy lowcons
        bne nodec
        dec lowcons+1
nodec:  
        dec lowcons

        ldy #0
        sta (lowcons),y
        rts
.endif

_cdr:    
        ldy #3
        jmp cYr
;;; car(AX) -> AX forth: @
_car:    
        ldy #1
cYr:    
        sta ptr1
        stx ptr1+1
;;; cYr(ptr1) -> AX
ptr1cYr:        
        lda (ptr1),y
        tax
        dey
        lda (ptr1),y
        rts

_storebyte: 
        jsr _car                 ; just set ptr1
        sta (ptr1),y
        rts
_readbyte: 
        jsr _car                 ; just set ptr1
        ldx #0
        rts
;_eq:
;        lda sidx                ;
_atom:
        ;; 7B        ":atom 1&!;" /3
        bit BIT0
        beq settrue
        jmp setzero
_null:
        tay
        bne setzero
        txa
        bne setzero
        jmp settrue
_true:  
        jsr push
settrue:       
        lda #$ff
        tax
        rts
_zero:
        jsr push
setzero:       
        lda #0
        tax
        rts
_inc:   
        clc
        adc #1
        bne ret
        inx
        rts
_exec:  
        sta ip
        stx ip+1
        jsr pop
        jmp exec

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


;;; --------- MATH

OPT=1

.ifdef OPT
;;; 43B for _adc _and _eor _ora _sbc _pop(?)
;;; 1B less for 6 ops instead of 3
;;; TODO: that is if pop works _lda???
;;; OPS that go from lobyte to hibyte

_plus:  
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

;;; Can't do as it's postdec???
;xxpush:
;xx_sta:   
;       ;; STA oper,y
;        lda #$99
;        bne mathop

;;; TODO: is it ok, efficient?

pop:
_lda:   
        ;; LDA oper,y
        ldy #$b9
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP

;;; 19B - 40c
mathop: 
        sty op1
        sty op2

        ldy sidx
        dec sidx

op1:    adc lostack,y

        pha
        txa
op2:    adc histack,y
        tax
        pla

        rts

.else

_drop:  
pop:    
;;; 11B 21c
        ;; sidx++
        inc sidx
        ldy sidx

        lda lostack,y
        ldx histack+1,y

        rts

;;; 36B _plus and _nand only (ok _nand and +4)
;;;  so 32B

_plus:
;;; 16B 
        ldy sidx
        clc
        adc lostack,y
        pha
        txa
        adc histack,y
        tax
        dec sidx
        pla
        rts
_nand:
;;; 20B
        ldy sidx
        clc
        and lostack,y
        eor #$ff
        pha
        txa
        and histack,y
        eor #$ff
        tax
        dec sidx
        pla
        rts
.endif ; OPT


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
_halve:
;;; 7B 
        tay
        txa
        lsr
        tax
        tya
        ror a
        rts

_putc:  
        jsr putchar
        jmp pop
_getc:         
        jsr push
        jsr getchar
        ldx #0
        rts
        
_number:        
        jsr bytecode
        .byte 0

_undef: 
_error: 
;;; TODO: write something?
_quit:  
;;; TODO: fix?
        sta savea
        pla
        pla
        lda savea
ret:    
        rts

;;; quit exec dup drop 
;;; cons car cdr null atom
;;; zero true inc plus halve nand
;;; putc getc
;;; /17 = 127 ... 224
;;;       161 ... 357 ;; car/cdr inline
;;;       207     346 ;; inline all cons
;;;      (- 346 207 64) = 75 for exec
endtable:       

.assert (endtable-jmptable)<256, error, "Table too big"


transtable:     
.macro DO name
        .byte <(name-jmptable)
.endmacro

;;; > !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ <
        DO _storebyte          ; ! - store byte
        DO _undef              ; " - string, prnt?
        DO _undef              ; # - numberp?
        DO _undef              ; $ - swap/load 2 byte or hex
        DO _undef              ; % - mod?
        DO _and                ; &
        DO _undef              ; ' - quote - hmmm see`
        DO _undef              ; ( - if/loop 
        DO _undef              ; ) -
        DO _shl                ; *
        DO _plus               ; +
        DO _undef              ; , COMMA - true
        DO _sbc                ; -
        DO _undef              ; . - print
        DO _shr                ; /
        DO _zero               ; 0
        DO _number             ; 1
        DO _number             ; 2
        DO _number             ; 3
        DO _number             ; 4
        DO _number             ; 5
        DO _number             ; 6
        DO _number             ; 7
        DO _number             ; 8
        DO _number             ; 9 
        DO _undef              ; : - colon
        DO _undef              ; ; - TODO: load? $imm
        DO _undef              ; < -
        DO _undef              ; = := -U;
        DO _undef              ; > -
        DO _undef              ; ? - is atom? if?
        DO _readbyte           ; @
        DO _car                ; A
        DO _undef              ; B - memBer
        DO _cons               ; C
        DO _cdr                ; D
        DO _exec               ; E
        DO _undef              ; F -
        DO _undef              ; G - 
        DO _undef              ; H -
        DO _inc                ; I
        DO _undef              ; J - apply? jump?
        DO _getc               ; K
        DO _undef              ; L - length/load/imm/lisp
        DO _undef              ; M - mapcar
        DO _undef              ; N - nth?
        DO _putc               ; O
        DO _undef              ; P - print
        DO _quit               ; Q
        DO _undef              ; R - recurse / register
        DO _undef              ; S - swap
        DO _undef              ; T - terpri
        DO _null               ; U
        DO _undef              ; V - princ/prin1
        DO _undef              ; W - printz
        DO _undef              ; X - x10
        DO _undef              ; Y - read
        DO _undef              ; Z - tailcall?
        DO _undef              ; [ - quote lambda
        DO _undef              ; \ - drop
        DO _dup                ; ] - dup 
        DO _eor                ; ^ - xor
        DO _undef              ; _ - negate (?)
        DO _undef              ; ` - find name

        DO _shl                ; {
        DO _ora                ; |
        DO _shr                ; }
        DO _undef              ; ~ - not
endtrans:       

;;; 21 functions!

.assert (*-transtable)=64+4, error, "Transtable not right size"

;;; execute byte code
;;; - either routines exit by rts
;;; - or ... jmp next

bytecode:       
        pla                     ; lo
        tay
        pla                     ; hi
        tax
        tya
        ;; address on stack (w jsr) points
        ;; on last byte of jsr-instruction
;;; TODO: use BRK to get here, no need inc?
        jsr _inc

;;; 21B 30c jsr-loop
exec:   
        ldy #$ff
        sta ipy
loop:
        jsr next
        jmp loop
next:   
        pha
        txa
        pha

nextpushed:     
        PUTC '.'
        inc ipy
        ldy ipy

        lda (ip),y
        clc
        sbc #33                 ; spc is excluded
        cmp #64+1
        bcs over64
again:
        sta call+1              ; lowbyte

        ldx #0
        jsr printd
        putc ' '

        pla
        tax
        pla
call:   jmp jmptable

over64: 
        ;; local variable?
        cmp #'z'-33+1
        bcs other
        ;; variables on stack a,b,c
;;; TODO: relative fun start stack
        adc sidx                ; change
        lda lostack-33,y 
        ldx histack-33,y
        rts

other:  
        ;; we want to fold in > {|}~ <
        ;; (potentially "ijklmnopqrstuvwxyz"!)
        clc
        sbc #'{'-33
        cmp #64+4+1
        bcc again
        ;; rest was <= ' ' (wrapped around)
        ;; or above \127
        bcs nextpushed

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

;;; TODO:
.macro SETNUM num
        SET (num)*2
.endmacro


;;; push A,X on R-stack (AX trashed, use DUP?)
;;; (cc65: jsr pushax takes 39c!)
;;; 3B 7c
.macro RPUSH
        pha
        txa
        pha
.endmacro

;;; 3B 6C
.macro RPOP
        pla
        tax
        pla
.endmacro

;;; DUP AX onto stack (AX retained)
;;; 5B
.macro RDUP
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
.ifnblank
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
.endif

;;; --------------------------------------------------
;;; Functions f(AX) => AX


.ifnblank
popret: 
        RPOP
        rts
.endif

;;; (no newline added that puts does)
;;; 
;;; 17B
.ifdef PRINTZ
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
.proc mul2
        asl
        tay
        txa
        rol
        tax
        tya
        rts
.endproc

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

.ifnblank
.proc _isconSetC
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
.endproc
.endif

.proc _initlisp
        ;; fallthrough to test
        jsr _test
        
        lda #<printa
        ldx #>printa
        jsr _exec

        PUTC 'X'
loop:   
        jsr getchar
        jmp loop
.endproc

endaddr:


printa: 
        DO _zero

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        ;; 68 = 'N'
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc
        DO _inc

        ;; 'A' lol
        DO _putc

        DO _quit

;;; ==================================================
;;; 
;;;               T       E      S     T

.proc _test
        ;; print size info for .CODE
        NEWLINE
        SET startaddr
        jsr printd
        PUTC '-'
        SET endaddr
        jsr printd
        PUTC '='
        SET (endaddr-startaddr-subtract)
        jsr printd

        NEWLINE
        PUTC 'P'
        PUTC '='
        SET (jmptable-startaddr)
        jsr printd

        NEWLINE
        PUTC 'T'
        PUTC '='
        SET (endtable-jmptable)
        jsr printd

        NEWLINE
        PUTC 't'
        PUTC '='
        SET (endtrans-transtable)
        jsr printd

        NEWLINE

        PUTC 'L'
        PUTC 'I'
        PUTC 'S'
        PUTC 'P'
        NEWLINE
        rts
.endproc

;;; TODO: this is duplcated code in test 
;;;   maybe do include?

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
