;;; OP16 - OnePage 16-bit VM (256 bytes!)
;;; 
;;; Built for minimal size not speed.
;;; Instructions are byte-coded.
;;; 
;;; There are 24 similar to "a forth".
;;; Plus 5 convience assembly routines.
;;; 
;;; Most can be called directly with JSR,
;;; or from a compact byte-code program.
;;; 
;;; 
;;; Functions:
;;;    stack: dup map drop                      (3)
;;;   memory: store load comma ccomma           (4)
;;;     math: plus minus and or eor div2 inc    (7)
;;;    tests: null -1 zero eq                   (4)
;;;  control: Xexeute exit zbranch branch       (4)
;;;   system: Literal out [init]                (2) [1]
;;;    [conv: pushA pushPLA loada loadApla]         [4]
;;;                                            (24) [5]

;;; inspiration, and goal:
;;; 
;;; "SectorLisp for 6502" asmlisp-asm.asm (+ asmlisp.c)
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org

;;; THIRD attempt - a minimal lispy byte-code intepreter

;;;     asmlisp-asm.asm -- pure ASM - too big?
;;;    basmlisp-asm.asm -- used AX as top of split-stack
;;;      1. started using a byte-coded VM - AL
;;;         Alphabetical Lisp
;;; -> tasmlisp-asm.asm -- uses zp TOP and contig stack
;;;      1. this allows some ops to be easier to do (?)
;;;      2. total rewrite from scratch
;;;      3. uJSR (micro-in-page 2 byte JSR!) save 53 bytes?
;;;      4. experiement with compress map, decompress
;;;      
;;; 



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


;;; worth reading wheler on prog-lang impl 6502
;;; - https://dwheeler.com/6502/a-lang.txt

;;; MINT 6502
;;; - https://github.com/agsb/6502.MINT/tree/main/arch/6502



;;; ----------------------------------------
;;; 
;;;           C   O   N   F   I   G

;;; enable this for size test
;
MINIMAL=1

;;; enable to see if save a byte on each JSR
;;; 244 B with, 245 with ... LOL only uJSR 10x in MINIMAL
;;; 
;;; USE for more than one page...
;;;   actually need to use for simple call macro!
;;;
;;; works if we .align 2 every external name!
;;; avg 43 funcs will waste 22 bytes
;;; 
;;; 589 B with uJSR and 606 otherwise only save (- 606 589)= 17 B
;;;   ... lol
;;; no jsr ... (/ (- 606 528) 3.0) = 26 B saved only... ???
;;; 
;UJSR=1 

;;; 1379
START=$563
;START=$600

;;; TOOD: test to put stack in ZP!
;;;     might save a lot of code bytes!
;;; NO: putting in page zero may save only 5 bytes
;;;     when  LDA stack,x  ops becomes zp :-)

;;; lisp data stack
;;; (needs to be full page)
;;; (page 4 free page on ORIC)
stack= $400

;;; ORIC: charset in hires-mode starts here
;;; (needs to be 4 byte aligned)
TOPMEM	= $9800

;;;           C   O   N   F   I   G
;;; 
;;; ----------------------------------------




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

.ifndef MINIMAL

;;; enable numbers
;NUMBERS=1

;;; enable extra math (div16, mul16)
;MATH=1

;;; enable tests (So far depends on ORICON)
;TEST=1

; turn on tracing of exec
TRACE=1

.endif ; MINIMAL

;;; --------------------------------------------------

;; TODO: not working in ca65, too old?
;.feature string_escape

.feature c_comments

.zeropage

;.org 128+'a'

/*
_A:     .res 1
_B:     .res 1
_C:     .res 1
_D:     .res 1
_E:     .res 1
_F:     .res 1
_G:     .res 1
_H:     .res 1
_I:     .res 1
_J:     .res 1
_K:     .res 1
_L:     .res 1
_M:     .res 1
_N:     .res 1
_O:     .res 1
_P:     .res 1
_Q:     .res 1
_R:     .res 1
_S:     .res 1
_T:     .res 1
_U:     .res 1
_V:     .res 1
_W:     .res 1
_X:     .res 1
_Y:     .res 1
_Z:     .res 1

*/

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

;;; memory
here:    .res 2
lowcons: .res 2

;;; top of the stack
tos:     .res 2

;;; current state of interpretation
startframe:     

ip:     .res 2                  ; code ptr
ipy:    .res 1                  ; offset

.ifndef MINIMAL
ipx:    .res 1                  ; d stack frame start
ipp:    .res 1                  ; n params
.endif ; MININAL

endframe:

token:  .res 1

;;; TODO: for restore at error in interactive
;quitS:  .res 1

;;; used  by _BRK routine
.ifdef UJSR
aBRK:   .res 1
xBRK:   .res 1
pBRK:   .res 2
.endif ; UJSR


;;; bss - area initialized
.bss

;;; data - area not initialized
.data

        
.code

;;; ----------------------------------------
;;;               " B I O S "

;;; requirement from "a bios"
;;; - jsr getchar
;;; - jsr putchar
;;; 
;;; Assumption:
;;; 
;;; Neither routine modifies X or Y register
;;; (they ar saved and restored)
;;; 
;;; A after putchar is assumed to be A before.

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
;;; (saves X, A retains value)
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

;;; ----------------------------------------
;;;            M A C R O S



;;; for DEBUGGING only!

;;; putchar (leaves char in A)
;;; 5B
.macro putc c
        lda #(c)
        jsr _out
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
;;; (cc65: jsr pushAx takes 39c!)
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

;;;              M A C R O S
;;; ----------------------------------------

;;; Funny, if put this here it doesn't run!
;jmp _initlisp

.export _initlisp        

;.assert startaddr=START, error ;"changed .org"

;;; This makes addresses near here FIXED thus can
;;; do fancy calculated alignments!
.org START




;COMPRESSED=1
.ifdef COMPRESSED

;;; ENDCHAR can't occur anywhere in the compressed data
;;; 
;
ENDCHAR=0

_initlisp:      


;;; unzip - decompressor for one pae
;;; 
;;; (- 1 (/ (- 256 43) 256.0)) = 17%
;;; 
;;; Alas the compressed data is 213 BYTES!
;;; 
;;; (can max be 256, without change)
;;; (would have to inc source+1 +8 bytes)
;;; 
;;; We need to achieve a compression ratio
;;; of at least 18% for it to be worth it!
;;; 
;;; Alternatives
;;; - Haruhiko Okumura's lzss.c
;;; - Fabrice Bellard's lzexe
;;; - Markus Oberhumer's NRV series
;;; - 6502 asm FilePack part of OSD
;;; 
;;; REF:
;;; 
;;; - https://github.com/mywave82/unlzexe/blob/master/unlzexe.c
;;; - https:github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Funpack.s
;;; 
;;; was: (42 B for ASCII, (+ 13= 52 B if UNZBINARY))

;;; TODO: variant AX

;;; (+ 4 6 5 13 18 33 22) = 101 slightly smaller...
;;;    BUT WORKS!!!
.proc unz
        ;; init
;;; 4
        lda #<(compresseddata-1)
        ldx #>(compresseddata-1)

loop:   
;;; 6
        jsr unzchar
        jmp loop

unzchar:        
;;; 5
        jsr nextbyte
        bmi minus
        ;; plain
save:   
;;; 14
;;; TODO: remove! debug
        jsr putchar

dest:   sta destination
        ;; step
        inc dest+1
        bne @noinc
        inc dest+2
@noinc: 
        lda savea
        rts

minus:    
;;; 13
        ;; quoted?
        cmp #$ff
        bne ref
        ;; quoted
quoted: 
        lda savea
        jsr nextbyte
        eor #128
        ;; jmp save (always pl!)
        bpl save
        
ref:    
;        lda #':'
;        jsr putchar

;;; 33
        ;; ref to two pos
        dey
        sty savey

        ;; save current pos: hi,lo
        txa
        pha
        lda savea
        pha

        ;; modify pos by add a
        clc ; ? or sec?
        adc savey
        tay
        txa
        adc #$ff                ; we're really sub!
        tax
        tya

        ;; unz(pos+ref)->newpos
        jsr unzchar

        ;; unz(newpos + 1)
        jsr unzchar

        ;; restore pos
        sty savex               ; lol

        pla
        tay                     ; lo
        pla
        tax                     ; hi
        tya                     ; lo

        ldy savex

        rts

nextbyte:
;;; 22
        ;; step
        clc
        adc #1
        bcc noinc
        inx
noinc:  
        sta savea

        sta ptr1
        stx ptr1+1
        ldy #0
        lda (ptr1),y

        ;; end? -> assumes stack will be fixed
        cmp #ENDCHAR
;        beq destination
hlt:    beq hlt

        ;; flags reflect A
        tay
        rts
.endproc


.ifnblank


;;; 86 B - unlimited length, fixed addr, self mod
;;;        (but requires unique stopchar)
;;; 
;;; (+ 8 7 7 12 12 32 15) = 93 correct missed on 12
.proc unz
        ;; init
;;; 8
        lda #<compresseddata
        sta ptr1
        lda #>compresseddata
        sta ptr1+1

loop:   
;;; 7
        ldy #0
        jsr unzchar
        bne loop


unzchar:        
;;; 7
        jsr nextbyte
        cmp #0
        bmi minus
        ;; plain
save:   
;;; 12
dest:   sta dest
        lda savea
        jsr putchar
        ;; step
        inc dest+1
        bne @noinc
        ind dest+2
@noinc: 
        rts

minus:    
;;; 12
        ;; quoted?
        cmp #$ff
        bne ref
        ;; quoted
quoted: 
        pha

        ;; store a $ff
        lda #$ff
        jsr save

        ;; save byte ^ 128 (so it's no ref)
        pla
        jsr nextbyte
        eor #128
        iny ; to handle this at read time
        ;; jmp save (always pl!)
        bpl save
        
ref:    
;;; 32
        ;; ref to two pos
        sta savea
        ;; save current pos
        lda ptr1+1
        pha
        lda ptr1
        pha

        ;; modify by add a
        clc ; ?
        adc savea
        sta ptr1
        lda ptr1+1
        adc #$ff                ; we're really sub!
        sta ptr1+1

        ;; unz(pos+ref)->newpos
        ;; Y==0
        jsr unzchar

        ;; unz(newpos + 1)
        jsr unzchar

        ;; restore pos
        pla
        sta ptr1
        pla
        sta ptr1+1
        ;; Z=0
        rts

nextbyte:
;;; 15
        lda (ptr1),y

        cmp #stopbyte
        beq startaddr

        ;; step
        inc ptr1
        bne noinc
        inc ptr1+1
noinc:  
        rts

.endproc


.proc unz
        adjusteddata= compresseddata+128-1

        ;; when this is read means stop
sentinel:
        lda #0
        pha
        pha

next:   
        inc source+1
        bne noinc2
        inc source+2

load:

source: lda adjusteddata,y
        bpl plain
        ;; done?
        cmp #endchar
        beq startaddr

minus:  
        ;; process pair
        tay
        ;; second part of pair
;;; TODO: how about when quoted?
        iny
        tya
        pha                     ; second pat of pair
        dey
        jmp load                ; first part of pair
        
plain:  
        ;; plain -> store it
dest:   sta startaddr
        inc dest+1
        bne noinc
        inc dest+2
noinc:  

processesqueue: 
        pla
        tay
        bne load
        
.endproc


.proc unz
;;; (+ 9 5 12 18) = 44 lol (+10= 54 B if UNZBINARY)


;;; 9 (if use rts)
        compresslen= (compressend-compresseddata)
        starty= (256-compresslen)

        ldy #starty
        ;;; top level keep track of when to stop
loop:   
        jsr doone
        iny
        bne loop
        ;; done
        ; rts
        ;; (non library optimization)
        beq startaddr
        


doone:
;;; 5
        ;; Y is source read index
        adjusteddata= (compresseddata-starty)

source: lda adjusteddata,y
        bmi ninus


storeit:        
;;; 12
        ;; plain char, store it
dest:   sta startaddr
        ;; inc inline ptr to destination
        inc dest+1
        bne noinc
        inc dest+2
noinc:    
        rts


minus:    

.ifdef UNZBINARY
;;; (10 B)
        ;; is a the quote char?
        cmp #$ff
        bne ref

        ;; read and store
        iny
        lda adjusteddata,y
        bmi store

.endif ; UNZBINARY

ref:    
;;; 18
        ;; at index A we got two chars to process

;;; TODO: maybe start w index in A?

        ;; save A char and get curent index
        sta savea
        tya
        pha

        ;; Y+= ref
        clc
        adc savea
        tay

        ;; process two chars (recursivly)
        jsr doone
        iny
        jsr doone
        
        ;; restore Y
        pla
        tay
        rts

unzip:  
        ldx #0
loop:   
        lda rd,x
unz:    
        pla
        bmi ref
        ;; plain char
        ldy #0
        sta (wr),y
        inc wr
        bne noinc
        inc wr
noinc:  
        inx
        jmp unz
ref:    
        sta savea
        txa

        sec
        sbc #1
        pha
        ;; push delayed call
        ...

        txa
        clc
        adc savea
        tax
load:   
        lda rd,x
        jmp unz
        
data:   

.endif ; nblank

;;; Everything after the unz is compressed data!

compresseddata: 
        .byte "Jonas S Karlsson",10
;;; a b c d e f g h ef hef ef hef
        .byte "abcdefgh",256-4,256-2,256-2,10
        .byte ENDCHAR
compressend:

        

.res 256 - * .mod 256

destination:    
        .res 512


.endif ; COMPRESSED

;;; just for testing COMPRESSED/unz
;.end


;;; DON'T PUT ANY CODE HERE!!!!



;;; enable these 3 lines for NOTHING .tap => 325 bytes
;_initlisp:      rts
;.end

;;; (- (* 6 256) 1379) = 157 bytes before page boudary


;;; JMP table
;;; align on table boundary by padding
.res (256 - * .mod 256)-7
.byte "BEFORE>"

;;; we start program at "sector"
startaddr:      


jmptable:  

;;; INIT - this should be first in jmptable at offset 0
_reset:
_initlisp:      
;;; 9

        lda #<HERESTART
        sta here
        lda #>HERESTART
        sta here+1

.ifdef LISP
;;; (+ 4 14) = 20 ???

;;; (4 B)

;;; TODO: this should go to BOOT
        ; sei
        cld

        ;; cons ptr
        SET (TOPMEM-1)
        sta lowcons            
        stx lowcons+1

.endif ; LISP

.ifndef MINIMAL
        ;; zero stuff
;        lda #0

;;; set's both Data Stack, and R stack
;;; (are we skipping one byte at DS?)
        ldx #$ff
        txs
       
;;; (3 B) - don't count!
 ;; (for now prints some info)
        jsr _test

        jmp _interactive

.endif ; !MINIMAL
       



_error: 
_undef: 
_quit:  

.ifdef MINIMAL
;;; TODO: ?
        rts
.endif       





;;; ========================================
;;; uJSR - 6502 minimalistic 2 byte JSR
;;;
;;; (all library in one page code!)
;;; -------------------------------------------
;;; A two byte JSR for calls within a page.
;;; 
;;; As it's 8 B !
;;; (and you need to install it: +10 B?)
;;; 
;;; You may need to have at least 18 calls!
;;; to see any savings... LOL
;;; 
;;; PS: disable interrrupts SEI

.ifndef UJSR

.macro uJSR addr
       jsr addr
.endmacro

.else

.macro uJSR addr
        ;; make sure read correct dispatch char!
        .assert (addr/256=*/256),error,"can only call within same page"
        ;; we subtrace 1...
        .assert addr,error,"uJSR: can't jsr 0"
        ;; yeah, limit 256 bytes
        ;; (unless we go asl..., and .align 2)
        .assert (addr-jmptable)<=256,error,"uJSR: target too far"
        .out "uJSR"

.ifdef MINIMAL
        .byte 0,(addr-jmptable-1)
.else
;;; TODO: need /2
        .byte 0,(addr-jmptable-1)/2
.endif

.endmacro

_BRK:   
;;; TODO: make sure uJSR isn't used to call with things
;;;    expected to be retained in either A and Y !!!
;;;    possibles are putchar, lol
;;; 
;;; jsr calls *within* one page
;;; 
;;; 9 B - smallest so far!
        pla                     ; throw away P
        pla                     ; lo
        pha
        tay
        lda jmptable-1,y
        bne callAoffset

.ifnblank ; more src uJSR

;;; handle more than from 2 page jmp
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



.ifndef MINIMAL

;;; (14 B)
_interactive:    
;;; this is so we alwAY get back here
;;; (essentially, no need jsr exec and jmp)
;;; (and this tail-calls into exec, same same!)
        uJSR _rdloop
        jmp _interactive
_rdloop:  
        putc '>'
        uJSR _key

.ifdef TRACE
        jsr trace
.endif ; TRACE

        ;;  fallthrough to exec
.endif ; MINIMAL

;;; exec byte instruction in A
;;; 
;;; references
;;; - http://6502org.wikidot.com/software-token-threading
;;; - 
;;; 22 B (+ 6 trans)
_exec:  
        ;; only token
        lda tos
        jmp _nexta

;;; make sure have somewhere to return to
;;; (as we're doing jmp dispatch)
_nextloop:
        uJSR _next
        jmp _nextloop

;;; WARNING: Don't jmp next!!! this isn't forth
;;;   TODO: still valid? lol

;;; get next token to interpret
_next:   
        uJSR _nexttoken

_nexta: 
;;; 0 (+6 trans)

.ifndef MINIMAL

        ;; no trans for >= 128 (already offset)
        bmi notrans
;;; transalte
        tay
        lda transtable,y
notrans:

.endif

.ifdef TRACE
        PUTC 'o'
        ldx #0
;;; TODO: no more AX!
        jsr printd

        NEWLINE
.endif

callAoffset:    
;;; 12
        ;; macro subtroutine?
        ;; (offset > macrostart)

;;; TODO: how to handle more than one page?
;;;   macros maybe user defined...

;;; TODO: use a macro that in one page becomes nothing
;;;   and otherwise becomes indirect invocations?
;;;   need to adjust uJSR ???

;        cmp #(macrostart-jmptable)
;        bcs _interpret

        ;; save in "jmp jmptable" low byte!
        sta call+1

        ;; A= token (for _var _number ...)
        lda token

call:   jmp jmptable

;;; ----------- SAVE MORE BYTeS -------------

;;; TODO: 6 _routines jsr push first thing!
;;;  (maybe A>xx can change this?)

;;; TODO: a number of _routines LDY #0
;;;    others LDA #0 (tya)
;;; enable this.
;;; 
;;; LDY #0 - for all

;;; TODO: fix, retain token A
;;;  or not, easy to read 4B: ldy ipy; lda (ip),y
;;; 
;;; A contains dispatch offset (should be char?)

;;; NOTE: if _routines expect A+Y to be clear then
;;;   some will break if they are called internally!
;;;   maybe have some notation, if have name
;;; 
;;;   _foo_AYZ == optimized w AYZ
;;;   foo      == safe!

;;; call routine after uJSR (brk)
;;; 
;;; 6
.proc _execpla2
        pla                     ; lo
        tay
        pla
        sta savey               ; hi
        tya
.endproc

;;; subroutine call in A
;;; 
;;; start interpreation at IP,Y
;;; 
;;; (+ 2 9 13 11) = 35 B  (+ 4  non-minimal.)
.proc _interpret

enter:  
        ;; save offset of what we're calling
        sta savea

        ;; push current stack frame
        ;; (ip, ipy, (ipx, ipn) )
;;; 9
        ldy #(endframe-startframe)
save:   
        lda startframe-1,y
        pha
        dey
        bne save
        
subr: 
;;; 13 (+ 4)
        ;; set new IP
        ;; (only valid for one page code dispatch)
        lda savea
        sta ip
        lda savey
        sta ip+1

;;; TODO: maybe can use same $ff as net?
.ifndef MINIMAL
        lda #256-1
        sta ipp
.endif 
        ldy #$ff
        sty ipy

        uJSR _nextloop
        
subrexit:
        ;; pop to current stack frame
;;; 11
        ldy #0
restore:   
        pla
        sta startframe,y
        iny
        cpy #(endframe-startframe)
        bne restore

        rts
.endproc

;;; next token from interpration
;;; Returns A = token, also stored in zp: token
_nexttoken:      
;;; 9 B
        inc ipy
        ldy ipy
        lda (ip),y
        sta token
        rts


;;; ----------------------------------------
;;; lambda
;;; 
;;; 3 (+ 5 9 8 17) = 39 \ _vary a Sa ^ ;

.ifndef MINIMAL

;;; (number of \)-1 stored in ipp(arams)
_lambda:        
;;; 5 B
        stx ipx
        inc ipp
        rts

;;; over = (pickn,2), 3rd = (pick,4) ...
;;; 
;;; 3 + 11 = 14 pick ("over" only would be 13 B)
_pickn:   
;;; 6+11 = 17 B
        uJSR _push
        uJSR _nexttoken
        
;;; _loadpickA 4 (99 2 4 6 ... => (4 99 2 4 6 ...)
;;; 
;;; 2 = over = forth.pick 1, 4 = forth.pick 2, 6 = forth.pick 3
;;; 
;;; NOTE: 0 is NOT dup!!!
_loadpickA:
;;; (11)
        tay
        lda stack-2,y 
        pha
        lda stack-2+1,y
        jmp loadApla

;;; 'a -> 2 'b -> 4 (+ ipx)
varindex:  
;;; 9
        uJSR _nexttoken
        and #$f
        asl
        adc ipx
        rts

;;; load variable from stack (a b c .. h)
;;; 
;;; 8 B
_var:   
        uJSR _push
        uJSR varindex
        bne _loadpickA


_setvar:        
;;; 17 B
        jsr varindex           ; canNOT uJSR

_storeunpickA:
;;; (14)
        tay
        lda tos
        sta stack-2,y
        lda tos+1
        sta stack-2+1,y

        jmp _pop

;;; ^ return from lambda
;;; 
;;; adjusts stack to remove parameters atreturn
;;; TOP retained as it contains return value!
_return:  
;;; 7 B
        lda ipp
        asl
        clc
        adc ipx
        tax
        ;; fall-through to _semis

.endif ; MINIMAL

;;; semis (return from interpretastion)
_exit:  
;;; 3
        pla
        pla
_ret:    
        rts



;;; ----------------------------------------



_binliteral:       
;;; 11 B
        uJSR _nexttoken
        sta tos
        uJSR _nexttoken
        sta tos+1
        rts

;;; TODO: idea
;;; 
;;; 0: push zero
;;; 1-9a-f: read while either got this char
;;;   {{{{ ora sta ... loop

        _pushaddr       = _undef
        _cons           = _undef
        _colon          = _undef
        _TOSbytecomma   = _undef
        _hexliteral     = _undef

.ifdef MINIMAL
        ;; set all undef functions of minimal
        _number         = _undef
        _quote          = _undef
        _writez         = _undef
        _dec            = _undef
        _cdr            = _undef
        _mul2           = _undef

        _var            = _undef
        _setvar         = _undef
        _lambda         = _undef
        _return         = _undef

        _printd         = _undef

.else

;;; modifies existing number
;;; first multiplies by 10 (or 16 if in hex!)
;;; then adds current number 
;;; 
;;; (+ 19 12 11) = 42 B macro: (+ 18 6 7) = 31 !!!
.proc _number
;;; 19
        uJSR _MUL10
        
        ;; hex2bin (works for dec too!)
        lda token
        cmp #'a'
        bcc digit
        sbc #7                  ; carry set already
digit:  and #$f

        jsr _pushA              ; canNOT use uJSR
        jmp _plus
.endproc

;;; 'a
_quote: 
;;; 6 B
        uJSR _nexttoken
        jmp _pushA

.ifnblank
;;; NOT NEEDED
_adda:  
;;; 10 B
        clc
        adc tos
        sta tos
        bcc noinc
        inc tos+1
noinc:  
        rts

       
;;; _hexliteral: read exactly 4 hex-digit!
_hexliteral:       
;;; 28
        uJSR _ZERO

        ;; do it 4 times with-out using register
do4:    uJSR do2
do2:    uJSR do
do:     
        uJSR _asl4
        uJSR _nexttoken

        ;; hex2bin
        cmp #'a'
        bcc digit
        sbc #7+32               ; carry set already
digit:  and #$f

        ;; merge into
        ora tos
        sta tos

        rts

;;; : h #15 & '0 + " '9 > B+3 6 + ; 17 B
;;; 
;;; 13 B
_puthex:        
        ;; 0-15 => '0'..'9','a'..'f'
        ;; - from milliforth 6502
        and #$0F
        ora #$30
        cmp #$3A
        bcc done
        adc #$06+32             ; carry set already
done:   
        jmp _out

.endif ; !BLANK



;;; ----------------------------------------
;;; colon
;;; 
;;; 56 B - barely worth it!!!
;;; (milliforth: 59 B...)
.ifnblank
.proc _colon
        uJSR _push

        uJSR _nexttoken
        ;; save alpha name of macro defined
        pha

        ;; save current ip+y of start of code
        lda ip
        clc
        adc ipy
        pha                     ; lo
        lda ip+1
        jsr loadApla            ; canNOT uJSR

;;; TODO: at end of first page can have forwarding
;;;   offsets to funs in page2?
;;; TODO: even aligned addresses? als of offset?
        cmp #>jmptable
        bne secondpage
        ;; does it fit in first page?
firstpage:      
        ;; save offset in translation table
;;; TODO: assuming decompressed table!
        pla
        tay
        lda tos                 ; lo
        sta transtable,y        ; save lo offset!
        rts

secondpage:     
        ldy secondfree

        pla
        ;; store at end of second page
        sta jmptable+256,y
        dey
        lda tos
        sta jmptable+256,y
        dey

        ;; skip to ; or \0
        ;; TODO: [] nesting?
;;; TODO: having compiletime/runtime and making
;;;   distinction of functions allows for maybe
;;;   less code?
        sty secondfree
findend:        
        uJSR _nexttoken
        ;; no need copy, it's just there!
        beq colondone
        cmp #';'
        bne findend
colondone:      

        jmp _pop
.endproc
.endif ; !BLANK

.endif ; MINIMAL

;;; colon
;;; ----------------------------------------
;;; memory
;;; 
;;; (+ 17 8 17) = 42    cdr+car dup swap
;;;               45    tos,+inc+!+drop2+topr,+dec2+dec 

.ifndef MINIMAL
_cdr:    
;;; 3 + 14 = 17 B
        ldy #2
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
.endif ; MINIMAL

_load:  
_car:    
;;; (14 B)
        ldy #0
cYr:    
        lda (tos),y
        pha
        iny
        lda (tos),y
;;; load tos w (A, pla) (hi,lo)
;;; (useless?) kindof opposite 
loadApla:       
;;; (6 B)
        sta tos+1
        pla
        sta tos
        rts


;;; - stack ops: dup swap

;;;  you can see these as
;;; 
;;; lda a b ... -> b (b) ...
;;;   "drop" (dup)

;;; sta a b ... -> a (a) ...
;;;   "swap drop"

;;; lda:   tos= stack[x], x-= 2
;;; sta:   stack[x]= tos, x-= 2


_dup:  
_push:   
;;; 8 B !
        ;; a | b c ...
        dex
        dex
        ;; a | ? b c ..
        uJSR _sta
        ;; a | (a) b c ..

        dex
        dex
        ;; a | a b c ..
        rts

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



;;; tos, inc !=store drop2 tosr, dec2 dec
;;; 
;;; (+ 19 8 18) = 45 B - 6.4 B/word

;;; comma moves words from overstack
;;;   to address in tos, tos advances with 2
;;; 
;;; (addr value ...) -> (addr+2 ...)
;;;   addr+2 !
;;; 
;;; C: *ptr1= stack[x]; x+= 2; tos+= 2;
;;;
;;; ccomma:
;;;   WARNING: stack is misaligned one byte!
;;; 
;;; 12+7= 19 B
_comma:
;;; 12
        ldy #0
        jsr _ccomma             ; canNOT uJSR
_ccomma:
        lda stack,x
        sta (tos),y
        inx
        iny

.proc _inc
;;; (7 B)
        inc tos
        bne ret
        inc tos+1
ret:    
        rts
.endproc

 

_store: 
;;; 8 B
        uJSR _comma
drop2:  
        dex
        dex
        jmp _pop

.ifndef MINIMAL
_rcomma:        
;;; 6+12 = 18
        uJSR dec2
        uJSR _comma
        ;; dec2 again, lol
dec2:   
;;; (3+9 = 12)
        uJSR _dec

.proc _dec
;;; (9 B)
        lda tos
        bne ret
        dec tos+1
ret:    
        dec tos
        rts
.endproc

.endif ; MINIMAL

;;; memory
;;; ----------------------------------------
;;; IO
;;; 6 (+ 9 9 5) = 6 (+ 23)

.ifndef MINIMAL
_key:   
;;; 9 B
        uJSR _ZERO
        ; cli
        jsr getchar             ; canNOT be uJSR
	; sei

;;; TODO: really nothing to it?

;;; 9
_pushA:
        pha
_pushPLA:       
        uJSR _push
_loadA:
        lda #0
        jmp loadApla

;;; 4 B : T #10 O ; # 4
_terpri:
        dex
        dex
        lda #10
        ;; fall-through to _out
.endif ; MINIMAL

;;; keep with _terpri above
_out:  
;;; 6 B
        jsr putchar             ; canNOT be uJSR
        jmp _pop


        

;;; -----------------------------------
;;; TESTS JMPS
;;; 
;;; 14 (+ 8 9 6) = 23

;;; jump/skip on zero (set Y!)
_zbranch:        
;;; 18 B
        lda tos
        ora tos+1
        beq _pop
        ;; zero so branch relative
        ;; (TODO: if not compiled could encode
        ;;  jmp at hibit, and/or some literals!)
        uJSR _pop
_branch:        
        uJSR _nexttoken

        ;; relative jmp
        clc
        adc ipy
        sta ipy

        rts


;;; --------- MATH

;;; 52B _adc _and _eor _ora _sbc (_sta) _pop(_lda) div2
;;;                               ^-- used by dup
;;; 
;;; + & E | - () _ div2 (+ (* 5 2) (* 4 4) 2 17 5)
;;; 
;;; (+ 13 15 27) = 55 using macro !
;;;
;;; X must contain stack pointer always

_plus:  
_adc:  
        ;; ADC stack,x
        clc
        ldy #$7d
        bne mathop

_and:
        ;; AND stack,x
        ldy #$3d
        bne mathop

;;; cmp oper,y $d9 - can't use doesn't ripple
;;; and wrong order...

_eor:
        ;; EOR stack,x
        ldy #$5d
        bne mathop

_ora:
        ;; AND stack,x
        ldy #$1d
        bne mathop


_minus: 
_sbc:   
        ;; SBC stack,x
        sec
        ldy #$fd
        bne mathop

_sta:   
        ;; STA stack,x
        ldy #$9d
        bne mathop

_drop: 
_pop:
_lda:   
        ;; LDA oper,x
        ldy #$bd
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP
;;; 
;;; TODO: could be used for BIGNUMs!
;;; 
;;; 17B
mathop: 
        sty op
        ldy #0
        
        beq genop
        ;; - fallthrough for hibyte Y=1
genop:  
        lda tos,y
op:     adc stack,x
        sta tos,y
        iny
        inx
        rts

_div2:   
;;; 5B !
        lsr tos+1
        ror tos
        rts


.ifndef MINIMAL

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
;;; 9B

_printz:        
_writez: 
;;; 12B
        ldy #0
        lda (tos),y
        beq _pop
        jsr _out                ; canNOT uJSR
        iny
        bne _writez

_printd:        
        jmp printd

;;; comparez (ptr1, tos) strings
;;; starting at offset Y
;;; 
;;; Result: beq if equal (Z set)
;;; 
;;; 8 B !
comparezloop:                   ; haha!
        iny
comparez:
        lda (ptr1),y
        cmp (tos),y
        beq comparezloop
        rts

;;; basmlisp-asm:
;;;   getc     12  (+ 12 8 17) = 37
;;;   skipspc   8
;;;   readatom 17

;;; READ: 31 B - reads ATOM or CONS only

;;; readatom at addres here[Y=4]
;;; 
;;; Returns
;;;   A=0 -> got string (possibly empty)
;;;   A contains breakchar (Z== '(' C== ')
;;; 
;;; 38B - too much...
.ifnblank
.proc _readatom
;;; 11 B - ret breakchar
        ldy breakchar
        lda #0
        sta breakchar
        tya

        ;; if interesting breakchar () - only!
        cmp #'('
        bcs ret
        
white:
;;; 7 B
        uJSR _key

        ;; skip leading white space (any < '(' - LOL)
        cmp #'('
        bcc white

        ;; offset on heap 
        ldy #4

;;; 20 B
readloop:       
        ;; break char: anything <= ')'
        cmp #')'+1
        bcc done
        ;; accept char
        sta (here),y
        iny
        jsr _key                ; canNOT uJSR
        jmp readloop

done:   
        sta breakchar
        lda #0
        sta (here),y
ret:    
        rts
.endproc        
.endif ; !BLANK
               
;;; asmlisp-asm.asm:

;;; READ: 31 B - reads ATOM or CONS only

;;; 16B !!!! --- (still need to find/craate atom)
;;;              (but it's for compare w READ)
.ifnblank
.proc _read
        uJSR _atomread
        bcs readlist

        ;; ATOM
parseatom:      
;;; TODO: possibly empty string? not clear
;;;    maybe for ()  - TEST!

        uJSR findatom
createatom:
        ;;   ...

readlist:
        ;;')' => retnil!
        ;; (is this accurate test? lol)
        ;; (TODO: does this work? ;-)
        bne retnil

        ;; continuation tail, LOL
        ;; car
        uJSR read
;;; read sets Zero on '(' and Carry for '(' and ')'
        ;; cdr
        uJSR readlist
;;; TODO: are flags set for ')' ???

;;; TODO: different cons in town these days...
        jmp cons

.endproc
.endif        


;;; 11 : {{{"+ ; # 6 -> shl shl2 shl3 shl4
_mul16: uJSR _mul4
_mul4:  uJSR _mul2
_mul2:   
;;; 5B (but technically not needed)
        asl tos
        rol tos+1
        rts

.endif ; MINIMAL


;;; >>>>>>>>>>>--- STATE ---<<<<<<<<<<<
;;; how we doing so far till here?
;;; 
;;; MINIMAL: imagine a 16-bit 17 ops VM in one page?
;;;   + - & | E "dup _drop div2 inc X L @ ! , 2drop O K zBranch
;;;   TODO: = (as macro?)
;;; 
;;; !MINIMAL + LISP: 20 more ops, lambda
;;; 
;;;        MINIMAL (lisp/non-minimal)
;;; system:    6  (0)   (_reset)
;;; rdloop:    0 (14)   (_interactive)
;;;   exec:   22  (6)   X _exit (translation)
;;;  enter:   50  (4)   _nexttoken _execpla2 interpret
;;;  colon:    0 (56)   (: [wtf?])
;;; lambda:    3 (39)   ; ( \ ^ a Sa )
;;; literal:  11 (37)   L (6'a 31#dec mul10 mul2 mul4 mul8 mul16 (...$hex))
;;; memory:   39 (20)   (cdr 3B) @car "dup $wap (pick 17B)
;;; setcar:   27 (18)   , I ! drop2 (r, dec2 J)
;;; IO:        6 (22)   O (K T _pusha _pushPLA _loadA)
;;; tests:    18 (10)   zbranch (null 0 true?sym)
;;; math:     52        + - & | E _drop div2
;;; transtab: 0 (102)   (jsr translate, translate)
;;; uJSR: 30     - saves 1 byte in MINIMAL!!! :-D

;;; ------ MINIMAL (not interactive)
;;; TOTAL: 264 B   words: 22    avg: 11.5 B/op
;;; 
;;;      ACTUAL: 253 B !!!!   (counting is approximate...)
;;;; 
;;; _reset X L @ " $ , I ! O K zBranch + & E _ }
;;; 
;;; (+ 6 22 50 3 11 39 27 6 18 52 30)
;;; (+ 1  2  0 1  1  3  4 2  1  7  0)

;;; (/ 253.0 22)   -> bytes per word
;;; (/ 256.0 11.5) -> 22 words possible!

;;; ------- !MINIMAL + LISP & interactive!
;;; TOTAL: 565 B    words: 43    avg 13.9 B/w
;;; 
;;;        ACTUAL: 544 B (probably need update..)
;;; 
;;; NOT COUNTING translate... hoping for compression?
;;; (then can skip rdloop?)
;;; 
;;; need mapping to be interactive!
;;; possibly lisp could be using internal coding
;;; and then map names, but that still cost 55 B symbols.
;;;                                   |
;;; (+ 235 0 6 14 4 39 48 37 3 18 23 10 128)
;;; (+  22 0 0  1 0  1  4  7 1  3  2  2   0)
;;; 
;;; OVERFLOW!!!!
;;; 
;;; (/ 596.0 43)    = 13.9       ; reality
;;; 
;;; CANDO: (/ 512.0 13.9) = 36 words, lol

;;; TODO: uJSR might save 30-50 bytes
;;; TODO: compression... allow for transtable -100? + 70

;;; >>>>>>>>>>>--- STATE ---<<<<<<<<<<<

;;; most common forth words (16):
;;;   (LIT) (;) (THEN) (IF) @ " (TO) _ \0 0= $ + OVER ! (ELSE) __
;;; 
;;; - https://comp.lang.forth.narkive.com/pzlX5mdU/what-is-the-most-compact-ttc-scheme
;;; 

/*

PermalinkTo give an idea of how byte tokens for
primitives might be "compact enough". This is
untested 65N02 code. You will see toward the end of
the core engine why the return stack is X-index
in the zero page.
        
        2DROP ; In initialisation, the three bytes starting at JV are loaded with JMP ;
        ($PRIMTBL)

        ;; PRIMTBL is 64 jump vectors,
        ;;   so 64 primitives are available
        
        ;; IP is initalised at 0,
        ;; probably in Warm Boot

;;; good idea to make exit enter next..

;;; (+ 8 14 21) = 43 next/exec enter call exit
;;;
;;; I have (+ 37 42) = 79!!!!

;;; y is low byte of IP
;;; 

EXIT:   
        DEX
        DEX
        LDY R,X                 ; saves 1B compared to
        LDA R+1,X0              ; pla st? (3B)
        STA IP+1
        ;;  8B 15c
NEXT:   
        INY           ; assumes no bodyt modify Y....
        BNE *+2
        INC IP+1                ; keep Y=@(ip+1) !!!!
ENTER0: 
        LDA (IP),Y
        BMI ENTER
        STA JV+1        ; self-modify? JV where?
        JMP JV
        ;; 14B 23c, +4 on page crossing

;;; A contains subr token (>=128)
ENTER:  
        ;; ip++
        INY
        BNE *+2
        INC IP

        ;; push IP
        ;; upwards growth stack!
        INX
        INX 
        STY R,X     ; store ipy (lo IP)
        LDY IP+1   
        STY R+1,X   ; store (hi IP)

        ;; load new IP
        STA IP+1    ; hi byte? curent subr token???
        ;;                      ;
        LDA (R,X)   ; lo byte? follow pointer at call site!

        TAY
        JMP ENTER0
        ;; 21B 34 cycles, +4 on page crossing

SRT is 11 clocks execution overhead per primitive,
11 clocks ENTER/EXIT overhead for high level words.

This is 23 cycles execution overhead per low level,
roughly 2x, and 49 clocks ENTER/EXIT overhead,
about 4.5x.

*/


;;; TODO: PRINT COND LAMBDA EQ
;;;   need EVAL APPLY ASSOC


;;; T NIL ?QUOTE READ ?PRINT ?COND CONS CAR CDR
;;; ATOM ?LAMBDA ?EQ

;;; AND + * & | ^ , KEY PUTC TERPRI NULL EVAL APPLY INC DEC DIV2 MUL2
;;; 
;;; -- 66 chars including spaces

;;; ========================================
;;; I N T E R N A L   M A C R O S
;;; 
;;; 

.macro DO label
        .byte <(label-jmptable)
.endmacro

.macro LIT w
        DO _binliteral
        .word w
.endmacro

.macro ZBRANCH else
        DO _zbranch
        .byte (256+else-*) .mod 256
.endmacro

.macro BRANCH else,start
        DO _branch
        .byte (256+else-*) .mod 256
.endmacro


;;; define macros after here, then uJSR can be used
;;; to call them having to have a JSR prelude!
macrostart:     

;;; #U give _FFFF

_NULL:
;;; 10 B
        ZBRANCH _ZERO
_FFFF: 
        LIT $ffff
        DO _exit
_ZERO:  
        LIT $0000
        DO _exit

.ifdef MINIMAL
_EQ:    
;;; 3 B
        DO _minus
        DO _NULL
        DO _exit
.endif

;;; 3 B left!!!!!


.ifndef MINIMAL

_MUL10: 
;;; 6 B
        DO _MUL2
        DO _dup
        DO _MUL2
        DO _MUL2
        DO _plus
        DO _exit

_MUL16: 
;;; 6 B
        DO _MUL8
_MUL8:  
        DO _MUL4
_MUL4:  
        DO _MUL2
_MUL2:  
        DO _dup
        DO _plus
        DO _exit

;;; 3 B LEFT! ... (in one page)

.endif        



endtable:       

.ifdef MINIMAL
  .assert (endtable-jmptable)<=256, error, "Table too big (>256)"
.else
;  .assert (endtable-jmptable)<=512, error, "Table too big (>512)"
.endif


;;; ========================================
;;;       T  R  A  N  S  T  A  B  L  E

transtable:     

.ifndef MINIMAL

.macro DF label, num, name
        .byte <(label-jmptable)
; NOT USED - LOL
;        .ident(name) = num
.endmacro

;;; > !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ <

;;; TODO: currently more "forthy" ALF
;;;       than being "lisp" AL (AlphabeticalLisp)

        ;; 0--31
        DO _exit               ; \0
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef

        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef

        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef
        DO _undef

        DO _undef
        DO _undef

        ;; ' '-127
        DO _undef              ; ' '
        DF _store, 33,"_STORE" ; !
        DF _dup,   34,"_DUP"   ; " - dup (MINT)
        DF _number,35,"_NUM"   ; # - lit
        DF _swap,  36,"_SWAP"  ; $ - hexlit? swap (MINT)
        DO _undef              ; % - over, or ` (MINT)
        DF _and,   38,"_AND"   ; &
        DF _quote, 39,"_QUOTE" ; '
        DO _undef              ; ( - compile if "zBranch"
        DO _undef              ; ) -
        DO _undef              ; * - mult
        DF _plus,  43,"_PLUS"  ; +
        DF _TOSbytecomma,44,"_COMMA" ; , ccomma
        DF _sbc,   45,"_MINUS" ; -

;;; DEBUG - TODO: cheating - change!!!
;;; TODO: write in CODE
        DF _printd,46,"_PRNUM" ; . - print num

        DO _undef              ; / - TOOD: macro: div
        DO _number             ; 0
        DO _number             ; 1
        DO _number             ; 2
        DO _number             ; 3
        DO _number             ; 4
        DO _number             ; 5
        DO _number             ; 6
        DO _number             ; 7
        DO _number             ; 8
        DO _number             ; 9 
        DF _colon,  58,"_COLON"; :
        DF _exit,   59,"_EXIT" ; ;
        DO _undef              ; < - lt
        DO _undef              ; =   : = -U ; # 4
        DO _undef              ; > - gt
        DO _undef              ; ? - is atom? if?
        DF _load,   64,"_LOAD" ; @ car
        DO _undef              ; A - assoc/alloc
        DF _zbranch,66,"_IF"   ; B
        DF _cons,   67,"_CONS" ; C
        DF _cdr,    68,"_CDR"  ; D
        DF _eor,    69,"_EOR"  ; E
        DO _undef              ; F - follow/iter/forth ext?
        DO _undef              ; G - 
        DO _hexliteral         ; H - (h) hexlit? Happend
        DF _inc,    73,"_INC"  ; I
        DF _dec,    74,"_DEC"  ; J
        DF _key,    75,"_KEY"  ; K
        DF _binliteral,76,"_BLT"; L
        DO _undef              ; M - mem/mapcar/minus
        DO _undef              ; N - number?
        DF _out,     83,"_OUT" ; O
        DO _undef              ; P - print
        DO _undef              ; Q - equal
        DO _undef              ; R - recurse
        DF _setvar,  87,"_SET" ; S - Sa setvar?
        DF _terpri,  88,"_TERPRI" ; T
        DF _NULL,    89,"_NULL"; U
        DO _undef              ; V - prin(c1)/var
        DO _writez             ; W
        DF _exec,    92,"_EXEC"; X
        DO _undef              ; Y - apply/read?
        DO _undef              ; Z - tailcall?
        DO _pushaddr           ; [ - quote lambda
        DF _lambda,  96,"_LAMBDA" ; \
        DO _exit               ; ] - return or ;
        DF _return,  97,"_RETURN" ; ^ - RETURN
        DF _drop,    98,"_DROP" ; _ - drop (on the floor1)
        DO _undef              ; ` - over? find name

        ;; a-h local vars
        DO _var                ; a
        DO _var                ; b
        DO _var                ; c
        DO _var                ; d
        DO _var                ; e
        DO _var                ; f
        DO _var                ; g
        DO _var                ; h

        ;; i-z
        DO _undef              ; i -
        DO _undef              ; j -
        DO _undef              ; k - 
        DO _undef              ; l - 
        DO _undef              ; m - 
        DO _undef              ; n - 
        DO _undef              ; o - 
        DO _undef              ; p - 
        DO _undef              ; q - 
        DO _undef              ; r - 
        DO _undef              ; s - 
        DO _undef              ; t - 
        DO _undef              ; u - 
        DO _undef              ; v - 
        DO _undef              ; w - 
        DO _undef              ; x - 
        DO _undef              ; y - 
        DO _undef              ; z - 

        DF _mul2,   123,"_MUL2"; { - : { "+ ; 
        DF _ora,    124,"_OR"  ; |
        DF _div2,   125,"_DIV2"; }
        DO _undef              ; ~ - not
        DO _undef              ; DEL - 

.endif ; MINIMAL

endtrans:       

.ifndef MINIMAL
.assert (endtrans-transtable)=128, error, "Transtable not right size"
.endif  

;;; maybe for MINIMAL++ ? lol

.ifnblank

;;; compressed trans, zuntrans
;;; 
;;; comp: (+ 32 25) = 57 B to generate table
;;; 
;;; but it removes complicated translation code!
;;; 
;;; raw: (+ 64 4 30) = 98 B (w code toskip byte)

ztrans: 
 ; (+ 7 3 2 4 2 5 2 2 2 2 1) = 32  # 19 funs
        .byte 256-33, _store, _undef, _lit, _swap, _undef, _and
        .byte 256-4, _plus, _comma                             .byte 256-15, _exit
        .byte 256-4, _load, _undef, _zbranch
        .byte 256-2, _eor
        .byte 256-3, _inc, _dec, _key, _literal
        .byte 256-2, _out
        .byte 256-8, _exec
        .byte 256-6, _drop
        .byte 256-3, _div2
        .byte 0

;;; TODO: memset(

;;; fill in a 128 byte table
;;; 
;;; 25 B
zuntrans:
        lda #0
        tay
        tax

znext:  
        lda ztran,x
        beq ret
        bmi zskip

        sta transunz,y
        inx
        iny
zskip:  
        ;; minus means relative skip
        stx savex
        clc
        adc savex
        tax
        bne znext

ret:    
        rts

transuns:       
        .res 128, (_undef-jmptable)
.endif ; !BLANK
        

;;; ----------------------------------------
;;;              U S E R C O D E
;;;                 (overflow)
;;; usercode MACROS!

;;; hash:
;;; - http://forum.6502.org/viewtopic.php?f=9&t=8317
;;; DJB2 is n*33+c on every character, or n+(n<<5)+c, so it is pretty fas
cons:

;;; TODO: better as macro?
.ifnblank
;;; ASMLISP (+ 21 -1 14 13) = 48!!!!
;;; (+ 14 11 11) = 36
        jsr conspush            ; cdr
        jsr _pop
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

;;;  OR

;;; 31
        jsr conspush
        jsr _pop
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
.endif ; !BLANK

;;; --------------------------------------------------
;;; Functions f(AX) => AX

;;; ===================================
;;; LISP:

.ifnblank

.proc _isconSetC
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
.endproc

.endif



endaddr:
.byte "<AFTER"

;;; TODO: do other way? data segment?
HERESTART:      


;;; end usercode
;;; ========================================

;;; testing data

.macro CODE str
;;; TODO: test...
        jsr bytecode
        .byte str,0
.endmacro

.ifndef BLANK
;;; called in nexttoken w A0 token
.proc trace
        RDUP
        pha

        putc 10

        ;; s12d8i4711y>I
        putc 's'
        tsx
        stx savex
        lda #$ff
        sec
        sbc savex
        ldx #0
        jsr printd

        putc 'd'
        lda #$ff
        sec
;        sbc sidx
        ldx #0
        jsr printd

        putc 'i'
        lda ip
        ldx ip+1
        jsr printd

        putc 'y'
        lda ipy
        ldx #0
        jsr printd

        putc '>'
        putc ' '
        pla
        pha
        jsr putchar

        putc ' '
        putc '#'
        pla
        ldx #0
        jsr printd

        RPOP
        rts
.endproc
.endif ; !BLANK


;;; ===============================================
;;; 
;;;             T       E      S     T

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
        SET (_printd-jmptable)
        ldx #0
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
;;; 12
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
;;; 37B
;;; 
;;; _voidprintdptr1
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

/*
-- VARIABLES
(each used takes 2 bytes... some waste)

'ABCDEF - free

'FGH

'I(J)   IP         ptr  == address

('K - cannot be used, too small)

'L(M)  lowcons last allocated cons

'NOPQR

'S(T)    datastack  byte == index

'UVWX

'Y(Z)    IP offset  byte == index


-- PRIMITIVES
@       read word from TOS store in TOS
,       store byte in address TOS, stack+1 swap hi/lo
Ln      literal
#n      small literal (<256)
U       nUll
N       nand
%	swap
/2      div2
$       dup       ; maybe can be made
_       drop

K       getchar
O       putchar
J+-n    jump if 0

# 13 primtives!

('D      just L(64+4) - just variant of literal)

-- CODE
~       $ N                     ; # 2
&       N ~                     ; # 2
|       ~ $ ~ N ~               ; # 5
^       N r N N r N N          - maybe # 7
^       o & ~ % & |            - maybe # 6

o       $ 'S @ #2 +            ; over # 7

A       @
D       #2 + @                  ; # 4
!       , , _ _                 ; setcar # 4
SD      #2 + !                  ; setcdr # 4

dec2    Lfffe +                 ; # 4
Rdec2   $ @ % dec2 % !          ; # 9
Rinc2   $ @ % #2 + % !          ; # 8

$       'S @ dec2  @ 'S @ dec2 ! ; # 9

R,      $ Rdec2 % ! @           ; # 5

C       'L R, 'L R,             ; cons # 6

-       ~ #1 + +                ; # 5
=       -U                      ; # 2

#104 bytes! - 15 xor == (- 104 15) =-= 89

-- MISSING

?cons           L1 & L1 =         ; # 8

readatom
`findatom

\lambda
X
Read

;;; push 0 + chars in reverse, pop print till 0
# 18

Writez       #0 % #1 - $ @ $ J1
             $ J+1 ^ O J-7

;;; only need to print cons and atoms
.. bad list print (foo . (bar . (fie . nil ) ) )
# 20
Print           $  ? J+2 W ^ 
                   $ '( O $ A P '. O D P ') O
Cond

# 19
Eval            $  ? J+2 getval ^
                   $ A Eval
                     `cond = J+2 Cond ^
                             % Evlist Apply ^

;;; push old binding, setup new, after call pop...

Apply 

T
NIL

COND

LAMBDA

dispatch loop 25

# 44 chars 13 atoms = 57

(+ 89 25 57 9 19 21 19 ) = 239

;;; T NIL QUOTE READ PRINT COND CONS CAR CDR
;;; ATOM LAMBDA EQ

# 80 tokens in forth??? for div64
- https://github.com/rufig/spf4-utf8/blob/master/devel/%7Epinka/lib/BigMath.f

@29
multiply peasants algo
        #0 'A !
        $ $ U J1 ^ #1 & J+8 $ 'A @ + 'A ! 
        div2 % mul2 % J0

... idea combine it with compression! backwards
relative reference! lol all words only 2 chars?

new way of evaLulation???? lol

EXEC

(decompress first then run like normal?)
(this method here might have trouble getting
 multibyte instructions... like J2, #0 etc)

        pla (continuation calling)
        pha

        <128 => dispatch
        >=128 => rel ref (-)
          get first
          pha old
          pha new
          jsr exec !

          pla old
          get second
          pha new
          jmp exec ! -- tail call!
        
          

        

*/
