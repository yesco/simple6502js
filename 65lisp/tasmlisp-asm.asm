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

;;; 1379
START=$563
;START=$600

;;; lisp data stack
;;; (needs to be full page)
;;; (page 4 free page on ORIC)
lostack= $400
histack= lostack+128

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

;;; locals
locidx:  .res 1

;;; memory
lowcons: .res 2

sidx:    .res 1

;;; current state of interpretation
startframe:     

ip:     .res 2                  ; code ptr
ipy:    .res 1                  ; offset

.ifndef MINIMAL
ipx:    .res 1                  ; stack frame
ipp:    .res 1                  ; n params
.endif ; MININAL

endframe:

;;; saved
quitS:  .res 1

;;; used  by _BRK routine
aBRK:   .res 1
xBRK:   .res 1
pBRK:   .res 2

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
        jsr _putc
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

;;;              M A C R O S
;;; ----------------------------------------

;;; Funny, if put this here it doesn't run!
;jmp _initlisp

.export _initlisp        

;.assert startaddr=START, error ;"changed .org"

;;; This makes addresses near here FIXED thus can
;;; do fancy calculated alignments!
.org START



;;; DON'T PUT ANY CODE HERE!!!!



;;; enable these 3 lines for NOTHING .tap => 325 bytes
;_initlisp:      rts
;.end

;;; (- (* 6 256) 1379) = 157 bytes before page boudary

;;; JMP table
;;; align on table boundary by padding
.res 256 - * .mod 256

;;; we start program at "sector"
startaddr:      




jmptable:  

_reset:
_initlisp:      
_quit:  
;;; (+ 4 14) = 20

;;; (4 B)
        cld

.ifdef LISP
        ;; cons ptr
        SET (TOPMEM-1)
        sta lowcons            
        stx lowcons+1
.endif ; LISP        

        ;; zero stuff
;        lda #0

;;; set's both Data Stack, and R stack
;;; (are we skipping one byte at DS?)
        ldx #ff
        txs

;;; (3 B) - don't count!
 ;; (for now prints some info)
        jsr _test
        

;;; (14 B)
_interactive:    
;;; this is so we alwAY get back here
;;; (essentially, no need jsr exec and jmp)
;;; (and this tail-calls into exec, same same!)
        uJSR _rdloop
        jmp retloop
_rdloop:   



;;; 6502 minimalist JSR (all in one page code!)
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

;;; enable to see if save any byte
.ifblank

.macro uJSR addr
        jsr addr
.endmacro

.else

.macro uJSR addr
        assert (addr/256=*/256),error,"can only call within same page"
        assert addr,error,"uJSR: can't jsr 0"
        assert (addr-jmptable)<=256,error,"uJSR: target too far"
        .byte 0,(addr-jmptable-1)
.endmacro

_BRK:   
;;; 8 B
        pla                     ; lo
        pha
        tay
        lda jmptable,y
        bne callAoffset

.endif ; _uJSR

.ifndef MINIMAL
        putc '>'
.endif ; MINIMAL
        
        uJSR _key

.ifdef TRACE
        jsr trace
.endif ; TRACE

        ;;  fallthrough to exec

;;; exec byte instruction in A
;;; 
;;; references
;;; - http://6502org.wikidot.com/software-token-threading
;;; - 
;;; 30 B

_exec:  
;;; 5
        ;; only token
        lda top
        jmp nexta

_nextloop:
        uJSR _next
        jmp loop

;;; WARNING: Don't jmp next!!!
;;; this isn't forth
;;; TODO: still valid? lol
_next:   
;;; 5
        sta token
        uJSR _nexttoken
        ;; at end of string
        beq ret

;;; TODO: enable
;        sta token

_nexta: 
;;; 14
        jsr translate

.ifdef TRACE
        PUTC 'o'
        ldx #0
;;; TODO: no more AX!
        jsr printd

        NEWLINE
.endif

callAoffset:    
        ;; macro subtroutine?
        ;; (offset > codestart)
        cmp #(codestart-jmptable)
        bcs _interpret

        ;; save in "jmp jmptable" low byte!
        sta call+1
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

;;; subroutine call in A
;;; 
;;; start interpreation at IP,Y
;;; 
;;; (+ 2 9 19 12) = 42
;;; 42 B  72c ?update - relative expensive (?)
proc _interpret

;;; TODO: set IP,y?

;;; (+ 2 9 19 12) 
enter:  
        ;; save what we're calling
        sta savea

;;; TODO: only push 2 values???
;;;   can we use a jsr?
;;;   let \lambda and ^ push the others!!!!
;;; OR
;;;   only enable when !MINIMAL
;;;   for safety, otherwise CRASH real good!

        ;; push current stack frame
;;; 9
        ldy #(endframe-startframe)
save:   
        lda startframe-1.y
        pha
        dey
        bne save
        
subr: 
;;; 15
        ;; set new IP
        ;; (only valid for one page code dispatch)
        lda savea
        sta ip

;;; TODO: can this be moved into exec?
;;;   (maybe some problem with Ztail/Recurse?
        lda #0
        sta ipp

        ldy #$ff
        sty ipy

        uJSR _nextloop
        
subrexit:
        ;; pop to current stack frame
;;; 12
        ldy #0
restore:   
        pla
        sta startframe,y
        iny
        cpy #(endframe-startframe)
        bne restore

        rts
.endproc

_nexttoken:      
;;; 7 B
        inc ipy
        ldy ipy
        lda (ip),y
        sta token
        rts


.ifnblank
;;; TODO: 30 jsr so can save 11 bytes only...

;;; MINIMAL:
;;;   TODO: 25+ jsr so can save 15 B !!!


;;; ----------------------------------------
;;; lambda
;;; 
;;; 19 B \ ^ ;

.ifndef MINIMAL
;;; (number of \)-1 stored in ipp(arams)
_lambda:        
;;; 11 B
        uJSR _nexttoken
        cmp #'\\'
        bne ret
        inc ipp
        bne _lambda             ; always true

;;; value to return is in TOP
;;; if we had \\ parameters,
;;; from ipx we need to pop ipp==1
_exit:  
;;; 8 B
        lda ipx
        clc
        sbc ipp
        sta sidx
        rts

.endif ; MINIMAL

;;; a-h gives you parameter to current function
_var:   
;;; TODO: done twice for a-z and 0-9 ... save bytes?
;;;  maybe keep token in A, or zp place?

;;; 12+13 = 25
        lda token

        and #31
        clc
        adc ipx
        tay

;;;     
        stx savex
        ldx savex

;;; 13
        uJSR push
        lda stack,y
        pha
        lda stack+1,y
        jmp loadPOPa
        
;;; ----------------------------------------

_binliteral:       
;;; 11 B
        uJSR _nexttoken
        sta top
        uJSR _nexttoken
        sta top+1
        rts

;;; TODO: idea
;;; 
;;; 0: push zero
;;; 1-9a-f: read while either got this char
;;;   {{{{ ora sta ... loop

.ifdef MINIMAL
_hexliteral = _undef
.esle

;;; 0 pushes 0
;;; 1-9 modifies by x10 + num
;;; means to load 42: 042 
_number:
;;; 30 + 12 = 42 ; _number x10
        dec ipy                 ; lol

_numnext:       
        uJSR _nexttoken
_number:        
        sec
        sbc #'0'
        cmp #10
        bcs ret
        
        pha

        uJSR _mul10

        ;; push digit
        uJSR _pushpla

        ;; finally add num
        uJSR _plus

        uJSR _numnext

;;; just add a real mul (19 B for 16x8->16?)
;;; 38 B for 16x16->16 (?)
;;; 
;;; TODO: cheaper as macro!
;;; 
;;; : x {"{{+ ;   # 6
;;; 
;;; 12
mul10: 
        uJSR _shl
        uJSR _dup
        uJSR _shl2
        uJSR _plus

.ifnblank
;;; NOT NEEDED
_adda:  
;;; 10 B
        clc
        adc top
        sta top
        bcc noinc
        inc top+1
noinc:  
        rts
.endif
        
;;; 'a
_quote: 
;;; 6 B
        uJSR _nexttoken
        jmp _pusha
        
;;; _hexliteral: read exactly 4 hex-digit!
_hexliteral:       
;;; 28
        uJSR _zero

        ;; do it 4 times with-out using register
do4:    uJSR do2
do2:    uJSR do
do:     
        uJSR _asl4
        uJSR _nexttoken

        ;; hex2bin
        cmp #'A'
        bcc digit
        sbc #7                  ; carry set already
digit:  and #$f

        ;; merge into
        ora top
        sta top

        rts

;;; 11
_asl4:  uJSR _asl2
_asl2:  uJSR _asl
_asl:   
        asl top
        rol top+1
        rts
        
;;; : h #15 & '0 + " '9 > B+3 6 + ; 17 B
;;; 
;;; 13 B
_puthex:        
        ;; 0-15 => '0'..'9','A'..'F'
        ;; - from milliforth 6502
        and #$0F
        ora #$30
        cmp #$3A
        bcc @ends
        adc #$06                ; carry set already
        jmp _putc

.endif

;;; ----------------------------------------
;;; colon
;;; 
;;; 56 B - barly worth it!!!
;;; (milliforth: 59 B...)
_colon:        
        uJSR _nexttoken
        ;; save alpha name of macro defined
        pha

        ;; save current ip+y of start of code
        uJSR push
        lda ip
        clc
        adc ipy
        pha                     ; lo
        lda ip+1
        uJSR _loadPOPa          ; hmm more effic?

;;; TODO: at end of first page can have forwarding
;;;   offsets to funs in page2?
;;; TODO: even aligned addresses? als of offset?
        cmp #>'jmptable
        bne secondpage
        ;; does it fit in first page?
firstpage:      
        ;; save offset in translation table
;;; TODO: assuming decompressed table!
        pla
        tay
        lda top                 ; lo
        sta transtable,y        ; save lo offset!
        rts

secondpage:     
        ldy secondfree

        pla
        ;; store at end of second page
        sta jmptable+256,y
        dey
        lda top
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

        jmp pop


;;; colon
;;; ----------------------------------------
;;; memory
;;; 
;;; (+ 17 8 17) = 42    cdr+car dup swap
;;;               45    topo,+inc+!+drop2+topr,+dec2+dec 


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
;;; (useless?) kindof opposite 
loadPLAa: 
;;; (6 B)
        sta top+1
        pla
        sta top
        rts


;;; - stack ops: dup swap

;;;  you can see these as
;;; 
;;; lda a b ... -> b (b) ...
;;;   "drop" (dup)

;;; sta a b ... -> a (a) ...
;;;   "swap drop"

;;; lda:   top= stack[x], x-= 2
;;; sta:   stack[x]= top, x-= 2


;;; over (a b ... -> b a b ...)
.ifnblank
over:   
;;; 13 B
        uJSR push                ; a a b

        dex
        dex                     ; a (a) b
        uJSR _lda                ; b (a b)
        dex
        dex                     ; b (a) b

        dex
        dex                     ; b a b
        rts
.endif

_dup:  
push:   
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

swap:   
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
        jmp loadPOPA
        ;; b | a c ..



;;; top, inc !=store drop2 topr, dec2 dec
;;; 
;;; (+ 19 8 18) = 45 B - 6.4 B/word

;;; comma moves words from overstack
;;;   to address in top, top advances with 2
;;; 
;;; (addr value ...) -> (addr+2 ...)
;;;   addr+2 !
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
        uJSR _ccomma
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
        uJSR _comma
drop2:  
        dex
        dex
        jmp pop

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
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc


;;; memory
;;; ----------------------------------------
;;; IO
;;; (+ 5 6 9) = 20

;;; 5B : T #10 O ; # 4
_terpri:
;;; 5 B
        uJSR push
        lda #10
        ;; fall-through
_putc:  
;;; 6 B
        uJSR putchar
        jmp pop
_key:   
_getc:         
;;; 9 B
        uJSR zero
        uJSR _getc
        sta top
        rts
        

;;; -----------------------------------
;;; TESTS JMPS
;;; 
;;; (+ 17 8 9 6) = 42

_zbranch:        
;;; 17 B
        lda tos,x
        ora tos+1,x
        bne pop
        ;; zero so branch relative
        uJSR _nexttoken
        clc
        adc ipy
        sta ipy
        jmp pop

.ifndef MINIMAL

_null:
;;; 8 B
        lda tos,x
        ora tos+1,x
        bne setfalse
        beq settrue

settrue:        
;;; 3 + 6 = 9 B
        lda #$ff
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
setfalse:       
;;; (6 B)
        lda #0
;;; pushes A on the data stack
_seta: 
        pha
;;; pushes a new value PLAd from hardware stack
_settopPLA:
        lda #0
        jmp _loadPOPa

_pushA: 
        pha
_pushPLA:       
        uJSR push
        jmp loadPLAa

zero:   
;;; 6 B
        uJSR push
        jmp setfalse
        
.endif ; MINIMAL

;;; --------- MATH

;;; 50B _adc _and _eor _ora _sbc (_sta) _pop(_lda) shr (7)
;;; + & E | - () _ shr (+ (* 5 2) (* 4 4) 2 17 5)
;;;                               ^-- used by dup
;;; (+ 13 15 27) = 55 using macro !
;;;
;;; X must contain stack pointer always
;;; 

_plus:  
_adc:  
        ;; ADC stack,x
        clc
        ldy #$7d
        bne mathop

_and:
        ;; AND stack,x
        lda #$3d
        bne mathop

;;; cmp oper,y $d9 - can't use doesn't ripple
;;; and wrong order...

_eor:
        ;; EOR stack,x
        lda #$5d
        bne mathop



.ifndef MINIMAL

_ora:
        ;; AND stack,x
        lda #$1d
        bne mathop


_sbc:   
        ;; SBC stack,x
        sec
        ldy #$fd
        bne mathop

.endif ; MINIMAL



_sta:   
        ;; STA stack,x
        ldy #$9d
        bne mathop

drop: 
pop:
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

_shr:   
;;; 5B !
        lsr top+1
        ror top
        rts


.ifdef MINIMAL

_printd = _undef
_shl = _undef

.else        

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
        lda (top),y
        beq pop
        uJSR _putc
        iny
        bne _writez

_printd:        
        jmp printd

;;; comparez (ptr1, top) strings
;;; starting at offset Y
;;; 
;;; Result: beq if equal (Z set)
;;; 
;;; 8 B !
comparezloop:                   ; haha!
        iny
comparez:
        lda (ptr1),y
        cmp (top),y
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
proc _readatom
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
        uJSR _getc

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
        uJSR _getc
        jmp readloop

done:   
        sta breakchar
        lda #0
        sta (here),y
ret:    
        rts
.endproc        
               
;;; asmlisp-asm.asm:

;;; READ: 31 B - reads ATOM or CONS only

;;; 16B !!!! --- (still need to find/craate atom)
;;;              (but it's for compare w READ)
.proc _read
        uJSR _atomread
        bcs readlist

        ;; ATOM
parseatom:      
;;; TODO: possibly empty string? not clear
;;;    maybe for ()  - TEST!

        uJSR findatom
createatom:
        ...

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

;;; TODO: different cons in town these days...
        jmp cons

.endproc
        


_shl:   
;;; 5B (but technically not needed)
        asl top
        rol top+1
        rts

.endif ; MINIMAL


_exit:  
;;; TODO: fix?
        sta savea
        pla
        pla
        lda savea
_ret:    
        rts

;;; >>>>>>>>>>>--- STATE ---<<<<<<<<<<<
;;; how we doing so far till here?
;;;        MINIMAL (lisp/non-minimal)
;;; system:    4      _reset
;;; rdloop:    9  (5) _interactive
;;;   exec:   37      X
;;;  enter:   42      enter subr exit
;;; lambda:    0 (19) ( \ ^ ; a-h )
;;; literal:   6 (53) L (Hex 'a 1-9dec mul10)
;;; memory:   39  (3) (cdr) @car "dup $wap
;;; setcar:   27 (18) , I ! [drop2] (r, dec2 J)
;;; IO:       15  (5) (T) O K
;;; tests:    17 (23) zbranch (null) (0 true?sym)
;;; math:     41  (9) + & (- |) E _drop shr

;;; ------ MINIMAL
;;; TOTAL: 242 B    words: 19    avg: 12.7 B/op
;;; 
;;; (+ 6 12 37 42 0 6 39 27 15 17 41)
;;; (+ 1  1  1  3 0 1  3  2  1  1  5)
;;; (/ 242.0 19)

;;; TOTAL: 377 B    words: 37    avg 10.2 B/w
;;; 
;;; (+ 242  5 19 53 3 18 5 23 9)
;;; (+  19  1  3  4 1  3 2  2 2)
;;; (/ 377.0 37)
;;; 
;;; CANDO: (/ 512.0 10.2) = 50 words, lol

;;; TODO: uJSR might save 30-50 bytes

;;; >>>>>>>>>>>--- STATE ---<<<<<<<<<<<

;;; TODO: PRINT COND LAMBDA EQ
;;;   need EVAL APPLY ASSOC


;;; T NIL ?QUOTE READ ?PRINT ?COND CONS CAR CDR
;;; ATOM ?LAMBDA ?EQ

;;; AND + * & | ^ , KEY PUTC TERPRI NULL EVAL APPLY INC DEC DIV2 MUL2
;;; 
;;; -- 66 chars including spaces

codestart:

;;; NULL: 14 B
;_TRUE:  
;;; 4 B
;        .byte "L"
;        .word $ffff
;       .byte 0

;_ZERO:  
;;;; 4 B
;        .byte "L"
;        .word $0000
;        .byte 0

;_NULL:
;;; 6 B
;        .byte "B",+2
;        .DO _true
;        .byte 0
;        .DO _zero
;        .byte 0

endtable:       

.assert (endtable-jmptable)<=256, error, "Table too big"

transtable:     
.macro DO name
        .byte <(name-jmptable)
.endmacro

;;; > !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ <

;;; TODO: currently more "forthy" ALF
;;;       than being "lisp" AL (AlphabeticalLisp)

        DO _store              ; !
        DO _undef              ; " - dup (MINT)
        DO _lit                ; # - lit?numberp?
        DO _swap               ; $ - swap (MINT)
        DO _undef              ; % - over (MINT)
        DO _and                ; &
        DO _quote              ; '
        DO _undef              ; ( - if/loop 
        DO _undef              ; ) -
        DO _undef              ; * - mult
        DO _plus               ; +
        DO _TOPbytecomma       ; , ccomma
        DO _sbc                ; -

;;; DEBUG - TODO: cheating - change!!!
;;; TODO: write in CODE
        DO _printd             ; . - print num

        DO _undef              ; / - div
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
        DO _exit               ; ;
        DO _undef              ; < -
        DO _undef              ; =   : = -U ; # 4
        DO _undef              ; > -
        DO _undef              ; ? - is atom? if?
        DO _load               ; @ car
        DO _undef              ; A - assoc/alloc
        DO _zbranch            ; B - ZBRANCH memBer?
        DO _cons               ; C
        DO _cdr                ; D
        DO _eor                ; E
        DO _undef              ; F - follow/iter/forth ext?
        DO _undef              ; G - 
        DO _hexliteral         ; H - (h) hexlit append
        DO _inc                ; I
        DO _dec                ; J
        DO _key                ; K
        DO _literal            ; L
        DO _undef              ; M - mapcar
        DO _undef              ; N - number?nth?
        DO _putc               ; O
        DO _undef              ; P - print
        DO _undef              ; Q - equal
        DO _undef              ; R - recurse / register
        DO _undef              ; S - Sa setvar?
        DO _terpri             ; T
        DO _null               ; U
        DO _undef              ; V - prin(c1)/var
        DO _writez             ; W (print string)
        DO _exec               ; X
        DO _undef              ; Y - apply/read?
        DO _undef              ; Z - tailcall? B\0
        DO _pushaddr           ; [ - quote lambda
        DO _lambda             ; \
        DO _undef              ; ] - return or ;
        DO _return             ; ^ - RETURN
        DO _drop               ; _ - drop (on the floor1)
        DO _undef              ; ` - find name

        DO _shl                ; { - : { "+ ; 
        DO _ora                ; |
        DO _shr                ; }
        DO _undef              ; ~ - not
endtrans:       

.assert (*-transtable)=64+4, error, "Transtable not right size"

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
        .byte 256-3, _inc, _dec, _getc, _literal
        .byte 256-2, _putc
        .byte 256-8, _exec
        .byte 256-6, _drop
        .byte 256-3, _shr
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
        

;;; ----------------------------------------
;;;              U S E R C O D E
;;;                 (overflow)
;;; usercode

;;; hash:
;;; - http://forum.6502.org/viewtopic.php?f=9&t=8317
;;; DJB2 is n*33+c on every character, or n+(n<<5)+c, so it is pretty fas
cons:

;;; TODO: better as 
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

;;; translation cost:
;;;   table: 64+4
;;;   code: 34(+5 for vars)
;;;   => (+ 64 4 34 5) = 107
;;; 
;;; or "unz"
;;;   ztrans: 32 (minimal 19)
;;;   code: 25  nums: 1 vars: 8
;;;   => (+ 32 25 10 8) = 75
;;; 
;;; OR "compression"
;;; 
;;;   how good is compression of code+full (128) table?


;;; translate letter in A to effective offset
;;; of jmptable
;;; 
;;; 34B
translate:      
;;; TODO: change translation to just !!!
;;; 
;;; tay
;;; lda transtable,y

;;; TODO: move to after endaddr
;;;    as it "shouldn't count as bytes needed"
;;;    I.E. we could do translation at "compiletime"
;;;    so no translation would be needed!

        ;; make sure it's in table
        sec
        sbc #33                 ; spc is excluded
;;; 4 ? set at table
        cmp #64+4+1
;;; TODO: enable local vars etc
;        bcs over64
;;; TODO: not correct for one char exec
;;;    todo fix by simple 2 byte buffer?
        jmp potret              ; skip for now


again:      
        ;; translate to offset
        tay
        lda transtable,y

over64: 
        ;; local variable?
        cmp #'z'-33+1
        bcs other

;;; TODO: just replace by func a b c d !!!

        ;; variables on stack a,b,c
;;; TODO: relative fun start stack
        adc sidx                ; change
        lda lostack-33,y 
        ldx histack-33,y
nret:   rts

other:  
        ;; we want to fold in > {|}~ <
        ;; (potentially "ijklmnopqrstuvwxyz"!)
        clc
        sbc #'{'-33
        cmp #64+4+1
        bcc again
        ;; rest was <= ' ' (wrapped around)
        ;; or above \127
        bcs next

;;; uncompress
;;; 

;;; token in A, X is current read offset
;;; (assuming compressed to < 256 bytes) lol

;;; 44 B at least, not worth it?

.ifnblank
wr:     .word destination
rd:     .word data

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

destination:    
.endif ; unzip
        

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

;;; end usercode
;;; ========================================

;;; testing data

.macro CODE str
;;; TODO: test...
        jsr bytecode
        .byte str,0
.endmacro


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
        sbc sidx
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
@       read word from TOP store in TOP
,       store byte in address TOP, stack+1 swap hi/lo
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
