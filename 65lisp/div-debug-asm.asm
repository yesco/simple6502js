;;; throw-ways code for testing div

;;; ----------------------------------------
;;; 
;;;           C   O   N   F   I   G

;;; enable this for size test
;MINIMAL=1

;;; enable this tomake it interactive
;;; (w MINIMAL -> interactive ALF (ALphabetical Forth)

;INTERACTIVE=1

;;; enable this to get AL (Alphabetical Lisp)
;AL=1

;;; enable LAMBDA style functions \ ^ R Z
;LAMBDA=1

;;; enable this to get LISP (written in AL)
;LISP=1

.ifndef MINIMAL
;;; two page dispatch for more code
;;; 
;;; MINIMAL: Uses (- 272 249) = 23 bytes more (align2+dipsatch)
;DOUBLEPAGE=1

.endif ; MINIMAL

;;; enable to see if save a byte on each JSR
;;; 246 B with, 249 without ... LOL only uJSR 13x in MINIMAL
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
;;; 248 !!! lol (from 249) - HAHA!
;UJSR=1 

.ifndef MINIMAL

;;; enable numbers
;NUMBERS=1

;;; enable extra math (div, mul)
;MATH=1

;;; enable tests (So far depends on ORICON)
;TEST=1

; turn on tracing of exec
;TRACE=1

.endif ; MINIMAL

;;; Enable to have stack checked
;CHECKSTACK=1

;;; Enable to have optimization of tail calls
;;; If not enabled can't rely on tail recursions
;
TAILRECURSEOPT=1

.ifndef MINIMAL
;;; Print Error message at Quit (few chars!)
;ERRMSG=1
.endif



;;; 1379
START=$563

;;; TOOD: test to put stack in ZP!
;;;     might save a lot of code bytes!
;;; NO: putting in page zero may save only 5 bytes
;;;     when  LDA stack,x  ops becomes zp :-)

;;; lisp data stack
;;; (needs to be full page!)
;;; (page 4 free page on ORIC)
stack=$400

;;; ORIC: charset in hires-mode starts here
;;; (needs to be 4 byte aligned)
TOPMEM=$9800

;;;           C   O   N   F   I   G
;;; 
;;; ----------------------------------------
;;; 
;;;            Z E R O - P A G E

;; TODO: not working in ca65, too old?
;.feature string_escape

.feature c_comments

.zeropage

;.org 128+'a'

/*
TODO:    global variables 'A @ ... GA VA `A ... A SA lol

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

;;; memory
here:    .res 2
lowcons: .res 2

;;; top of the stack
tos:     .res 2
;;; second "tos" if "jsr _pull2" - lol
second:  .res 2
third:   .res 2 


;;; current state of interpretation
startframe:     

ip:     .res 2                  ; code ptr
ipy:    .res 1                  ; offset

.ifdef LAMBDA
ipx:    .res 1                  ; d stack after cal
ipp:    .res 1                  ; d stack before parameters
.endif ; LAMBDA

endframe:

token:  .res 1

;;; TODO: for restore at error in interactive
;quitS:  .res 1

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






;;; 9 ops from _MUL16 macro in
;;; - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library
;;; 
;;; top= A*B (A is trashed, B remains, both are popped)
;;; 
;;; 32 B
        ;; top= 0 (push 0 => stack: A B 0 ; A,B in "memstack")
.proc _mulx
        jsr _zero

        ;; loop 16
        ldy #16
        sty savey
loop:   
        ;; result = result*2
        jsr _mul2

        ;; A *= 2 => carry
        asl stack+2,x          
        rol stack+2+1,x
        bcc noadd

        ;; tos += B (perfect it stays there)
        jsr _plus
        dex
        dex
noadd:  
        dec savey
        bne loop

        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts
.endproc


;;; 38 - more efficent if second number is small
.proc _muly
        jsr _zero
loop:   
        ;; done when B is 0
        lda stack+2,x
        ora stack+2+1,x
        beq done

        ;; A *= 2 => carry
        lsr stack+2+1,x
        ror stack+2,x
        bcc noadd

        ;; tos += B (perfect it stays there)
        jsr _plus
        dex
        dex
noadd:  
        ;; A *= 2
        asl stack,x
        rol stack+1,x
        jmp loop

done:   
        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts
.endproc

_mul = _muly


;;; (- (* 6 256) 1379) = 157 bytes before page boudary

;;; jsk: mydiv (S D -> S/D)
;;; 
;;; 2025-06-28
;;; 
;;; 39 B - could work, lol
;;; TOOD: - how is different from jskVL02
_div:   
        jsr _zero
        ldy #17
        sty savey
next:   
        ;; shift in one bit result into S!
        rol stack+2,x
        rol stack+2+1,x

        ;; done?
        dec savey
        beq done

        ;; shift in one hi bit from S into tos
        rol tos
        rol tos+1

        ;; tos -= D (reverse _minus)
        jsr _sbc
        dex
        dex

        ;; C=1 if subtract ok (?)
        bcs next

        ;; no, too big

        ;; add B back, lol
        jsr _plus
        dex
        dex
        clc
        ;; carry should be clear

        ;; loop Z=0 always
        bne next

done:   
        inx
        inx
        ;; tos= remaineder stack: quotient
        rts


.macro PUSHNUM num
        jsr _push
        lda #<num
        sta tos
        lda #>num
        sta tos+1
.endmacro

.macro MUL aa,bb
        PUSHNUM aa
        jsr printh
        PUTC '*'
        PUSHNUM bb
        jsr printh
        PUTC '='
        jsr _mul
        jsr printh
        jsr _drop

        PUTC 10
.endmacro

.macro DIV dend, divisor
        PUSHNUM 46666
        PUSHNUM dend
        jsr printh 
        PUTC '/'
        PUSHNUM divisor
        jsr printh
        jsr _div
        PUTC '='

        jsr _swap

        jsr printh
        PUTC ' '
        PUTC '%'
        jsr _swap
        jsr printh

        ;; let's verify by mult!
        PUTC ' '
        PUTC '*'
        jsr _swap
        jsr printh

        PUSHNUM divisor
        jsr printh

        jsr _mul
        jsr printh

        jsr _swap
        jsr printh

        jsr _plus
        jsr printh

        PUTC 10
.endmacro

.export _initlisp
_initlisp:

        PUTC 'd'
        PUTC 'i'
        PUTC 'v'
        PUTC 10

        PUSHNUM $1111
        PUSHNUM $2222
        PUSHNUM $3333
        jsr printh              ; 3333
        jsr _swap
        jsr printh              ; 2222
        jsr _swap
        jsr printh              ; 3333
        jsr _swap               
        jsr printh              ; 2222
        jsr _drop
        jsr printh              ; 3333
        jsr _swap
        jsr printh              ; 1111

        PUTC 10

        PUSHNUM $6666
        MUL $33, $164
        jsr _drop
        jsr printh

        PUTC 10

        ;; => $0164  % = $0025
        DIV $4711, $0033
        DIV $4711, $0033
        DIV 100, 3
        DIV 1000, 3
        DIV 16, 2
        DIV $4711, $0033
        
        MUL 0,0
        MUL 1,1
        MUL 0,1
        MUL 1,0
        MUL 2,2
        MUL 4,4
        MUL 8,8

halt:   jmp halt


;;;  print hex
printh: 
        putc '$'

        lda tos+1
        jsr print2h
        lda tos

print2h:      
        tay
        ;; hi
        ror
        ror
        ror
        ror
        jsr print1h
        ;; lo
        tya
        
print1h:        
        and #$0f
        ora #$30
        cmp #'9'+1
        bcc printit
        adc #6
printit:        
        jmp putchar















;;; DON'T PUT ANY CODE HERE!!!!





;;; ==================================================
;;; |                                                |
;;; |                                                |
;;; |                                                |
;;; |                                                |
;;; |                One Page AL(F)                  |
;;; |                                                |
;;; |                                                |
;;; |                                                |
;;; |                                                |
;;; ==================================================




;;; JMP table
;;; align on table boundary by padding
;.res (256 - * .mod 256)-7
.byte "BEFORE>"

;;; we start program at "sector"
startaddr:      

;;; this macro exports the _NAME func so that 
;;; its size can be determined, as well as labels
;;; the function. 
;;; 
;;; For 2-page dispatch it can also align
.macro FUNC name
  .ifdef DOUBLEPAGE
    .align 2, $ea               ; NOP
  .endif ; DOUBLEPAGE

  .export .ident(name)
  .ident(name):
.endmacro

jmptable:  

;;; INIT - this should be first in jmptable at offset 0

; no -heap 
.ifdef INTERACTIVE

.export _reset
_reset: 
;;; 8
        ;; skip some bytes, align to page?
        lda #(>LOWMEM)+1
        sta here+1
        ;lda #<LOWMEM
        ;sta here
        lda #0
        sta here

        ;; do other init to 0
        ;; ....

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

;;; set's both Data Stack, and R stack
;;; (are we skipping one byte at DS?)
        ldx #$ff
        txs
       
;;; (3 B) - don't count!
 ;; (for now prints some info)
        jsr _test

        jmp _interactive

.endif ; INTERACTIVE
       

;;; Jump here on error
;;; It prints current A
;;; Could be used as "error message"
FUNC "_error" ;; TODO: for some reason can't???
_undef: 
_quit:  
.ifdef ERRMSG
        jsr putchar
        lda token
        jsr putchar
.endif ; ERRMSG
        rts

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
;        .assert (.isupper(.mid(2,1,addr))),error,"uJSR: can't call macros this way"
        jsr addr
.endmacro

.else

.macro uJSR addr
  .ifdef DOUBLEPAGE
        .error "Can'tuse uJSR with DOUBLEPAGE yet"
  .endif
        ;; make sure read correct dispatch char!
        .assert (addr/256=*/256),error,"%% uJSR: can only call within same page"
        ;; we subtrace 1...
        .assert addr,error,"%% uJSR: can't jsr 0"
        ;; yeah, limit 256 bytes
        ;; (unless we go asl..., and .align 2)
        .assert (addr-jmptable)<=256,error,"%% uJSR: target too far"
        .out "uJSR"

    .ifdef MINIMAL
        .byte 0,(addr-jmptable-1)
    .else
        ;;; TODO: need /2 and .align 2 for each function
        .byte 0,(addr-jmptable-1)/2
    .endif

.endmacro

_BRK:   
;;; TODO: make sure uJSR isn't used to call with things
;;;    expected to be retained in either A and Y !!!
;;;    possibles are putchar, lol
;;; 
;;; C V remains
;;; 
;;; jsr calls *within* one page
;;; 
;;; 
;;; 11 B

;;; (6)
        pla                     ; P reg - throw away

        ;; we move BRK RTI return address back 1 byte
        ;; so with RTS we'll continue at next byte
        pla                   
        tay
;;; TODO: wrap call in macro, make sure addr
;;;       doesn't overlap 0 where call is!
        dey
        tya
        pha

;;; (5)
        ;; using address we look up the code where
        ;; we came from and get actual "dispatch offset"
        lda jmptable, y
        bne callAoffset


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
 


.ifdef INTERACTIVE

;;; (14 B)
FUNC "_interactive"
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
.endif ; INTERACTIVE

;;; references
;;; - 44   : TTC - token threaded code - BEST!
;;;    - https://comp.lang.forth.narkive.com/pzlX5mdU/what-is-the-most-compact-ttc-scheme
;;;    (-) super trick: Y lo IP! (and assumed not change) -6B
;;;    (+) X used for R-stack in zero page                -3B (?)
;;;    (-) no RTS must "JMP NEXT"            
;;; - 45 B : forth: dispatch 16B, enter/jmp/exit "6+6+6=18 B", get 11 B
;;;    - http://6502org.wikidot.com/software-token-threading
;;;    (+) they have all subs inside JMP-table => good dispatch
;;;    (-) Y must be retained
;;;    (+) RTS works as well as JMP NEXT       
;;; - 46 B : ArcheronVM: disp 7B enter 11B jmp 15B semis 13B
;;;          (+ 7 11 15 13) = 46B
;;;          "jsr archeon" inline 13B, get? (part of disp)
;;;    - https://github.com/AcheronVM/acheronvm/blob/master/src/dispatch.asm
;;;    - https://github.com/AcheronVM/acheronvm/blob/master/src/ops-callret.asm
;;;   (-) and Y to remain unmod?
;;;   (-) must JMP NEXT, no JSR/RTS loop
;;; - 62 B : disp 15B, enter/jmp/exit (+ 2 9 15 11 1) =38B
;;;          get 9B (+ 15 38 9) = 62 B
;;;          OP16 6B: (not included) cmp 13B archeon!
;;;   (+) Y register free!
;;;   (+) RTS can use, no need "JMP NEXT" - but can use!
;;;   (+) more generic for the stack (to handle \lambda params)
;;;   (-) bigger +18 B? (coz generic stack, save Y
;;; TODO: wrap _interpret around _exec !!!
;;; TODO: push addr to call on Datastack? Then generic Call?

;;; dipatch: 15 B (+ 5 _exec 6 trans)

;;; exec byte instruction in A
;;; 
.ifndef MINIMAL
FUNC "_exec"
        ;; only token
        lda tos
        jmp _nexta
.endif ; MINIMAL

;;; make sure have somewhere to return to
;;; (as we're doing jmp dispatch)
FUNC "_nextloop"
        uJSR _next
        jmp _nextloop

;;; WARNING: Don't jmp next!!! this isn't forth
;;;   TODO: still valid? lol

;;; get next token to interpret
_next:   
        uJSR _nexttoken

_nexta: 
;;; 0 (+6 trans)

;.ifdef INTERACTIVE
.ifdef TWOPAGE

        ;; no trans for >= 128 (already offset)
        bmi notrans
        .error "TODO: make this compiled () jumps!"
;;; transalte
;;; TODO: don't need to translate if use fulladdres
;;;   jump table (very redundant?) and use "JSR (_transtable)"
        tay
        lda _transtable,y
notrans:
.endif ; INTERACTIVE

.ifdef TRACE
        PUTC 'o'
        ldx #0
;;; TODO: no more AX!
        jsr printd

        NEWLINE
.endif

callAoffset:    
;;; (6) 
        ;; macro subtroutine?
        ;; (offset > macrostart)

;        cmp #(macrostart-jmptable)
;        bcs _interpret
; ;; TODO: expects hi in savey!!! if use more than one page

.ifdef DOUBLEPAGE
        asl
        bcs doublepage
.endif ; DOUBLEPAGE
        
        ;; save in "jmp jmptable" low byte!
        sta call+1
call:   jmp jmptable

.ifdef DOUBLEPAGE

doublepage:     
        ;; save in "jmp jmptable" low byte!
        sta call2+1
call2:  jmp (jmptable+256)

.endif ; DOUBLEPAGE

;;; ----------- SAVE MORE BYTeS -------------

;;; TODO: 6 _routines jsr push first thing!
;;;  (maybe A>xx can change this?)
;;;  (but then not save call JSR ???)

FUNC "_OP16"

;;; TODO: if called with JSR then need dec 1 or Y offset higher
;;;    ELSE: if use uJSR maybe can do THIS:
;;; TODO: what if _execpla2 was at address 0?

;;; Assumes called with _BRK : DO _BRKexecpla2
.proc _BRKexecpla2
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
;;; (+ 2 9 15 11 1) = 38 B  (+ 4  non-minimal.)
FUNC "_interpret"
.proc enter
;;; TODO: expects hi in savey!!!
;;; (2)
        ;; save offset of what we're calling
        sta savea

.ifdef CHECKSTACK
        cpx #(endframe-startframe)+6
  .ifdef ERRMSG
        lda #'%'
  .endif
        bcc _quit
.endif ; CHECKSTACK


        ;; push current stack frame
        ;; (ip, ipy, (ipx, ipn) )
;;; (9)
        ldy #(endframe-startframe)
save:   
        lda startframe-1,y
        pha
        dey
        bne save
        
subr: 
;;; (15 (+ 4))
        ;; set new IP
        ;; (only valid for one page code dispatch)
;;; ((8))
        lda savea
        sta ip
        lda savey
        sta ip+1

;;; (4)
        ldy #$ff
        sty ipy

;;; TODO: here, might "fall into" _nextloop if inlined

        uJSR _nextloop
        
;;; TODO: possibly _exit could call here!!! (and do cleanup here)
;;;   then no special case in 

subrexit:
        ;; pop to current stack frame
;;; (11)
        ldy #0
restore:   
        pla
        sta startframe,y
        iny
        cpy #(endframe-startframe)
        bne restore

;;; TODO: this could prepend _nextloop to enter _next???
;;;    does it save 1 byte? lol
;;; (1)

        rts
.endproc

;;; next token from interpration
;;; Returns A = token, also stored in zp: token
FUNC "_nexttoken"
;;; 9 B
        inc ipy
        ldy ipy
        lda (ip),y
        sta token
        rts


;;; ----------------------------------------
;;; lambda
;;; 
;;; 3 (+ 5 8 8 17) = 39 \ _vary a Sa ^ ;

.ifdef LAMBDA

;;; (number of \)-1 stored in ipp(arams)
FUNC "_lambda"
;;; 19 B - too long, but need "push!" (at least once)

;;; TODO: Y is assumed to start at 0
;;;    and the first \ is assumed to be at 0
;;;    this may not be true for
;;;      3 4 \\ aU(b^) aJbI Z
;;; 
;;; TODO: could be solved by:
;;;    IP += ipy,ipy=0 (reuseing current call)

.ifnblank
;;; 12 B
;;; if _inc, _dec  all used this w prelude
;;; (+ 7 9 12)  (+ 13 2 3 3 3 3 4)= 31

todoRincA:
        lda ip
        clc
        adc ipy
        sta ip
        lda ip+1
        adc #0
        sta ip+1
.endif

        ;; All arguments must be on stack proper
        ;; to be picked by a-h or set by Sa-Sh
        jsr _push

taillambda: 
        ;; TODO: can't nest lambdas
        stx ipx
        stx ipp

;;; TODO: need adjust IP if Y!=0 ???
;;;   otherwise tailrecursion/recursion is off!!!

lmore: 
        ;; inc stackx by two for each param
        inc ipp
        inc ipp

        jsr _nexttoken
        cmp #'\'
        beq lmore
ldone:   
        ;; give back last non-\ char
        dec ipy
        rts

;;; load variable from stack (a b c .. h)
;;; 
;;; 15 B
FUNC "_var"
;;; (6)
        uJSR _push
        uJSR _varindex

loadpickY:
;;;  (9)
;;; TODO: maybe, but off by one?
        stx savex
        tax
        jsr _lda
        ldx savex
        rts

.ifnblank
loadpickY:
;;; (10)
        lda stack,y 
        pha                     ; lo
        lda stack+1,y           ; hi
        jmp loadApla
.endif

;;; TODO: handle "outer"-variables (static scope) i-o[p] (7)
;;; 6 B
;;;     cmp #18 ; ('a'+8-'@')*2
;;;     bcc noouter
;;;     and #$7 (actually will miss p, acceptable!)
;;;     adc ipo ; outer ipx... (C should not be set)
;;; noouter:
;;; 
;;; TODO: globals q-rstuvw[x] xyz remains "FREE"

;;; lisp style wouldn't pop value
FUNC "_setvar"
;;; 17 B
        uJSR _nexttoken
        uJSR _varindex

;;; TODO: use _lda?
_storeunpickA:
;;; (11)
        lda tos
        sta stack,y
        lda tos+1
        sta stack+1,y

        rts

;;; 'a -> 2 'b -> 4 (+ ipx)
;;; No need align
FUNC "_varindex"     
;;; - no code savings yet if called only 2x
;;; 9
        lda token
        and #$f
        asl                     ; C=0
        adc ipp
        tay
        rts

;;; Z is the tail-recurse call
;;; (R is functionally equivalent but may blow the stack)
;;; If not enabled fall through to Recurse!

FUNC "_tailrecurse"

.ifdef TAILRECURSEOPT
;;; (+ 16 7) = 23 B

;;; (16)
        ;; basically copy n parameters
        ;; from current stack to [ipx..ipx]
        ldy ipp                 ; before params
        dey
        dey
next:   
        ;; from
        lda stack,x
        dex
        ;; to
        dey
        sta stack,y
        ;; done when reached ipx (== just before call)
        cpy ipx
        bne next

;;; (7)
        ;; restore stack to after call (params there)
        ldx ipx

        ;; go to beginning
        ldy #0
        sty ipy

        ;; next will go parse \ again!
        rts
.endif

FUNC "_recurse"
;;; 9
        ;; IP of current function
        lda ip+1
        sta savea
        lda ip

        jmp _interpret


;;; ^ return from lambda
;;; 
;;; adjusts stack to remove parameters atreturn
;;; TOP retained as it contains return value!
FUNC "_return"
;;; 2
        ldx ipp
        ;; fall-through to _exit

.endif ; LAMBDA


;;; semis (return from interpretastion)
FUNC "_exit_"
_exit: 

;;; Return from nested JSR-loop in exec
;;; 
;;; 3
        pla
        pla
_ret:    
        rts



;;; ----------------------------------------



FUNC "_binliteral"
;;; 10 B
        uJSR _nexttoken         ; lo
        pha
        uJSR _nexttoken         ; hi
        jmp loadApla

;;; TODO: idea
;;; 
;;; 0: push zero
;;; 1-9a-f: read while either got this char
;;;   {{{{ ora sta ... loop

.ifndef LISP
        _cons           = _undef
        _cdr            = _undef
        ; _TOSbytecomma ?
        _dec            = _undef
.endif ; LISP

.ifndef LAMBDA
        _var            = _undef
        _setvar         = _undef
        _lambda         = _undef
        _return         = _undef
.endif ; LAMBDA


;;; TODO:
        _pushaddr       = _undef ; also works as string!
        _colon          = _undef ; INTERACTIVE?
        _TOSbytecomma   = _undef ; LISP
        _hexliteral     = _undef

.ifdef MINIMAL
        ;; set all undef functions of minimal
        _quote          = _undef
        _writez         = _undef
        _mul2           = _undef
;        _mul            = _undef

.endif ; MINIMAL

;;; DEBUG
        _printd         = _undef


.ifdef NUMBERS
;;; modifies existing number
;;; first multiplies by 10 (or 16 if in hex!)
;;; then adds current number 
;;; 
;;; (+ 19 12 11) = 42 B macro: (+ 18 6 7) = 31 !!!
FUNC "_number"
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
FUNC "_hexliteral"
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

.else ; !NUMBERS
        _number         = _undef
        _digit          = _undef
.endif ; NUMBERS



;;; ----------------------------------------
;;; colon
;;; 
;;; 56 B - barely worth it!!!
;;; (milliforth: 59 B...)

;;; TODO:
.ifnblank

FUNC "_colon"
.proc _colonn
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
        sta _transtable,y        ; save lo offset!
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

;;; colon
;;; ----------------------------------------
;;; memory
;;; 
;;; (+ 17 8 17) = 42    cdr+car dup swap
;;;               45    tos,+inc+!+drop2+topr,+dec2+dec 

.ifdef LISP
_cdr:    
;;; 3 + 14 = 17 B
        ldy #2
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
.endif ; LISP

FUNC "_load"
_car:    
;;; (14 B) (can be done in 12 B but then no reuse with loadApla)
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

;; _push leaves Z=0
FUNC "_dup"
_push:   
;;; 8 B !
        ;; tos | memstack
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

FUNC "_swap"
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

loadplapla:                     ; lol
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
FUNC "_comma"
;;; 12
        ldy #0
        jsr _ccomma             ; canNOT uJSR beq Y
;;; cannot call without ldy #0
;;; WARNING: don't use directly, unbalances stack!
_ccomma:
        lda stack,x
        sta (tos),y
        inx
        iny

FUNC "_inc"
;;; (7 B)
        inc tos
        bne ret
        inc tos+1
ret:    
        rts

FUNC "_store"
;;; 8 B
        uJSR _comma
FUNC "_2drop"
        dex
        dex
        jmp _pop

;;; needed by Cons
.ifdef LISP

FUNC "_rcomma"
;;; 6+12 = 18
        uJSR _dec2
        uJSR _comma
        ;; dec2 again, lol
FUNC "_dec2"
;;; (3+9 = 12)
        uJSR _dec

FUNC "_dec"
;;; (9 B)
        lda tos
        bne ret
        dec tos+1
ret:    
        dec tos
        rts
.endproc

.endif ; LISP

;;; memory
;;; ----------------------------------------
;;; IO
;;; 6 (+ 9 9 5) = 6 (+ 23)

.ifndef MINIMAL

FUNC "_key"
;;; 9 B
        uJSR _zero
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
FUNC "_terpri"
        dex
        dex
        lda #10
        ;; fall-through to _out

;;; keep with _terpri above
FUNC "_out"
;;; 6 B
        jsr putchar             ; canNOT be uJSR
;;; TODO: can it return 0? if not can save 1 byte!
        jmp _pop
.endif

        

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

.endif

;;; jump/skip on zero (set Y!)
FUNC "_zbranch"
;;; 21 B
        lda tos
        ora tos+1
        ;; branch on zero
        beq _branch
        ;; skip next token 
        inc ipy
        bne _pop                ; Z=1 for sure (ipy>0)

FUNC "_branch"
        uJSR _nexttoken

        ;; relative jmp ipy += "token"
        clc
        adc ipy
        sta ipy
        ;; can't guarantee C=0 because can add negative
        jmp _pop

;;; --------- MATH

;;; 52B _adc _and _eor _ora _sbc (_sta) _pop(_lda) div2
;;;                               ^-- used by dup
;;; 
;;; + & E | - () _ div2 (+ (* 5 2) (* 4 4) 2 17 5)
;;; 
;;; (+ 13 15 27) = 55 using macro !
;;;
;;; X must contain stack pointer always


;;; Carry is retained after
FUNC "_plus"
        ;; ADC stack,x
        clc
        lda #$7d
        bne _mathop

FUNC "_and"
        ;; AND stack,x
        lda #$3d
        bne _mathop
;;; cmp oper,y $d9 - can't use doesn't ripple
;;; and wrong order...

FUNC "_eor"
        ;; EOR stack,x
        lda #$5d
        bne _mathop

FUNC "_or"
        ;; AND stack,x
        lda #$1d
        bne _mathop

;;; Carry is retained after
FUNC "_minus"
        ;; need to swap as _sbc does opposite!
        uJSR _swap
_sbc:   
        ;; top -= stack
        ;; SBC stack,x 
        sec
        lda #$fd
        bne _mathop

FUNC "_sta"
        ;; STA stack,x
        lda #$9d
        bne _mathop

FUNC "_drop"
_pop:
_lda:   
        ;; LDA oper,x
        lda #$bd
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP
;;; 
;;; TODO: could be used for BIGNUMs!
;;; 
;;; NOTE: Y=2 after exit!
;;; 
;;; 17B
FUNC "_mathop"
        ldy #0
        sta op
opmore:    
        jsr genop
        ;; - fallthrough for hibyte Y=1
genop:  
        lda tos,y
op:     adc stack,x
        sta tos,y
        iny
        inx
        rts

FUNC "_div2"
;;; 5B !
        lsr tos+1
        ror tos
        rts

.ifndef MINIMAL

;;; used by mul/dev pulles tos and second
FUNC "_pull2"
        jsr _pop
;;; wow, any \math op can be done w double precision
;;; by just call once more (taking a "higher-16-bits"
;;; and using a double tos).
        jmp opmore

;;; TODO: maybe should be part of minimal?

FUNC "_mul2"
;;; 5B !
        clc
_rol:   
        rol tos
        rol tos+1
        rts

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

;_printd:        
;       jmp printd

.ifnblank
;;; comparez (ptr1, tos) strings
;;; starting at offset Y
;;; 
;;; Result: beq if equal (Z set)
;;; 
;;; 8 B !
comparezloop:                   ; haha!
        iny
FUNC "_comparez"
comparez:
        lda (ptr1),y
        cmp (tos),y
        beq comparezloop
        rts
.endif

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
        uJSR _key                ; canNOT uJSR
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

;;; NOTE:            o v e r v i e w
;;; 
;;;   stack: 72 bytes   " ' $ (sta/lda) ! , @ 2drop
;;;                       (+ 8 2 17 4 3 19 14 5)
;;;    exec: 69         err nexttoken nextloop OP16 interpret
;;;                       (+ 1 9 15 6 38)
;;;    ctrl: 24         B zB \0exit (+ 11 10 3)
;;;    math: 37         _mathop   + - div2 (+ 19 5 8 5)
;;;   logic: 12         (  ^  )   & | E (+ 4 4 4)
;;;   tests: 35         = U zero FFFF < binliteral
;;;                       (+ 3 6 3 3 10 10)
;;; -------------------
;;;         249         (+ 72 69 24 37 12 35)
;;;         249 actual!

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



;;; ------- TWOPAGE (!MINIMAL)
; exec:  86   _error _exec _nextloop _interpret _nexttoken _quote (+ 2 6 24 38 10 6)
; trns: 128   _transtable
;  ASM:   6   _OP16
; ctrl:  26   _exit_ _zbranch _branch (+ 4 10 12)
;  ASM:  10   _binliteral
;  mem:  38   _load _comma _store (+ 14 20 4)
;  stk:  34   _dup _swap _2drop _drop (+ 8 18 6 2)
;   io:  38   _key _terpri _out _printz (+ 16 4 6 12)
; test:  28   _lessthan _eq _null _zero _FFFF (+ 10 4 6 4 4)
; math:  62   _plus _and _eor _or _minus _sta _mathop _div2 _mul2 (+ 6 4 4 4 8 4 20 6 6)
; xtra:  44   _mul [_mul10 _mul16 _mul8 _mul4] (+ 32 6 2 2 2)
;         _div missing...
; ---------------
;       500 B     36 functions
;;;
;;; 500 bytes
;;; 407 bytes with ./compress-file (flawed)
;;;  93 bytes saved (- 500 407) (- 93 18) = 75
;;; 
;;;  19 bytes align lost (mostly first page?)
;;; 
;;; 372 bytes code (- 500 128)
;;; 354 bytes compressed
;;;  18 bytes saved (- 372 354)
;;; 
;;; (- 512 407 44) = 61 bytes left

;;; -------- LAMBDA 
; 15	_var
; 9	_varindex
; 17	_setvar

; 21	_lambda
; 23	_tailrecurse
; 9 	_recurse
; 2 	_return

; (+ 15 9 17 21 23 9 2) = 96
; (+ 254 96) = 350

;;; way too big! 96 bytes for \ ^ a-h Sa-Sh R Z
;;;  (down 20!!!)




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
;;; TODO: compression... allow for _transtable -100? + 70

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

;;; (+ 8 15 21) = 44 next/exec enter call exit
;;;
;;; y is low byte of IP
;;; 

EXIT:   
        DEX
        DEX
        LDY R,X                 ; saves 1B compared to
        LDA R+1,X               ; pla st? (3B)
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
JV:     JMP JV
        ;; 15B 23c, +4 on page crossing

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
    .ifndef DOUBLEPAGE    
        .byte <(label-jmptable)
    .else
        .assert ((label-jmptable) .mod 2)=0,error,"%% DOUBLEPAGE: use FUNC label to align"
        .byte <((label-jmptable)/2)
    .endif ;  DOUBLEPAGE    
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

;;; 3 B left!!!!!


.ifdef xyaaDIVxxxxMINIMAL

;;; #0UU =>     0   !
;;; x UU => _FFFF   !

FUNC "_mul"
;;; 9 ops from _MUL16 macro in
;;; - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library
;;; 
;;; top= A*B (A is trashed, B remains, both are popped)
;;; 
;;; 32 B
        ;; top= 0 (push 0 => stack: A B 0 ; A,B in "memstack")
        uJSR _zero

        ;; loop 16
        ldy #16
        sty savey

loop:   
        ;; tos *= 2
        uJSR _mul2

        ;; A *= 2 => carry
        asl stack+2,x          
        rol stack+2+1,x
        bcc skip

        ;; tos += B (perfect it stays there)
        uJSR _plus
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

.ifdef DIV

;;; num1 * num2 => tos
;;; 
;;; 35 B - terminates fast for small num1
mul:    
        ;; top= 0
        uJSR _zero
loop:   
        ;; num1 /= 2 => carry
        lsr stack+2+1,x
        ror stack+2,x
        bcc skip

        ;; tos += B
        uJSR _plus
        dex
        dex

skip:   
        ;; num2 *= 2
        asl stack,x
        rol stack+1,x

        ;; till num1 is zero
        lda stack+2,x
        ora stack+2+1,x
        bne loop

        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts


;;; num1 * num2 => tos
;;; 
;;; counter
;;; 
;;; 35 B - lol same!!!
mul:    
        ;; top= 0
        uJSR _zero
        lda #16
        sta savey
loop:   
        ;; num1 /= 2 => carry
        lsr stack+2+1,x
        ror stack+2,x
        bcc skip

        ;; tos += B
        uJSR _plus
        dex
        dex

skip:   
        ;; num2 *= 2
        asl stack,x
        rol stack+1,x

        dec savey
        bne loop

        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts


;;; VL02 MUL 33 B
;;; - http://www.6502.org/source/interpreters/vtl02.htm

;;;  16-bit unsigned multiply routine
;;;    overflow is ignored/discarded
;;;    var[x] *= var[x+2], var[x+2] = 0, {>} is modified
;;; 33 B
mul:    
    lda  0,x
    sta  gthan
    lda  1,x                    ; {>} = var[x]
    sta  gthan+1
    lda  #0
    sta  0,x                    ; var[x] = 0
    sta  1,x
mul2:   
    lsr  gthan+1
    ror  gthan                  ; {>} /= 2
    bcc  mul3
    jsr  plus                   ; form the product in var[x]
mul3:   
    asl  2,x
    rol  3,x                    ; left-shift var[x+2]

;;; jsk: seems like bug, should be use gthan?
    lda  2,x
    ora  3,x                    ; loop until var[x+2] = 0
    bne  mul2

    rts

;;; 31+4 = 35 B - wtf??? LOL fast for small numbers
mul:    
        jsr _zero
mul2:   
        ;; num1 /= 2
        lsr stack+2+1,x
        ror stack+2,x
        bcc mul3

        ;; bit is set: tos += num2
        jsr _plus
        dex
        dex
mul3:   
        ;; num2 *= 2
        asl stack,x
        rol stack+1,x

        ;; loop till 0 (hmmm?) why not other?
        lda stack+2,x
        ora stack+2+1,x
        bne mul2

        inx
        inx
        inx
        inx
        rts


;;; ;                      ^ MUL
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; 16-bit unsigned division routine
;;;    var[x] /= var[x+2], {%} = remainder, {>} modified
;;;    var[x] /= 0 produces {%} = var[x], var[x] = 65535
;;; - http://www.6502.org/source/interpreters/vtl02.htm
;;;
;;; 43 B - nah!
div:    
        lda  #0
        sta  remn
        sta  remn+1

        lda  #16
        sta  gthan

div1:   
        ;; gradually replaced by quotient
        asl  0,x
        rol  1,x
        ;; gradually replaced by remainder
        rol  remn
        rol  remn+1
        ;; partial remainder >= var[2+2]
        lda  remn
        cmp  2,x

        lda  remn+1
        sbc  3,x
        bcc  div2
        ;; yes: update the partial
        sta  remn+1
        ;; set low bit in the partial quotient
        lda  remn
        sbc  2,x
        sta  remn
        inc  0,x

div2:   
        dec  gthan
        bne  div1

        rts


;;; jskVL02 variant of VL02
;;; 49 B or 37 w _sbc and _plus

;;; 39 B is good!    BEST????
div:    
        ;; tos = remn
        uJSR _zero
        lda #16
        sta savea
loop:   
        ;; gradually replaced by quotient
        rol stack+2,x
        rol stack+2+1,x
        ;; gradually replaced by remainder
        rol tos
        rol tos+1

        jsr _sbc
        inx
        inx
        
        bcs ok

        ;; undo
        jsr _plus
        inx
        inx
        ;; C is still 0
        
ok: 
        dec  savea
        bne  loop

        inx
        inx
        inx
        inx
        bne pop                 ; never 0


;;; DIV 16/16
;;; Here's an example that divides the two-byte number NUM1
;;; by the two-byte number NUM2, leaving the quotient in NUM1
;;; and the remainder in REM:
;;; 
;;; NUM1/NUM2 => NUM1 REM
;;; 
;;; - https://llx.com/Neil/a2/mult.html
;;; 
;;; 38 B - no adopted to stack
div:    
        LDA #0                  ;Initialize REM to 0
        STA REM
        STA REM+1
        LDX #16                 ;There are 16 bits in NUM1

L1:     ASL NUM1                ;Shift hi bit of NUM1 into REM
        ROL NUM1+1              ;(vacating the lo bit, which will
        ;;                      ; be used for the quotient)
        ROL REM
        ROL REM+1

        LDA REM

        ;; trial subtraction
        SEC
        SBC NUM2
        TAY
        LDA REM+1
        SBC NUM2+1
        BCC L2                  ;Did subtraction succeed?
        STA REM+1               ;If yes, save it
        STY REM
        INC NUM1                ;and record a 1 in the quotient

L2:     DEX
        BNE L1

        rts


;;; modified for tos & stack by jsk
;;; 
;;; 48 B - bah....
div:    
        ;; tos: REM = 0 
        jsr _zero
        ;; NUM1 is stack+2
        ;; NUM2 is stack
        lda #16
        sta savea

next:   
        ;; Shift hi bit of NUM1 into REM
        asl stack+2
        rol stack+2+1
        rol tos
        rol tos+1

        ;; trial subtraction
        sec
        lda tos
        sbc stack,x
        tay                     ; Y= lo sbc
        lda tos+1
        sbc stack+1,x
        bcc subfail
        ;; sub ok
        sta tos+1
        sty tos
        inc stack+2,x

subfail:
        dec savea
        bne next
done:   
        ;; tos     == REM
        ;; stack   == NUM2
        ;; stack+2 == result
        inx
        inx
        ;; get result
        jmp pop


;;; jsk: mydiv (S D -> S/D)
;;; 
;;; 2025-06-28
;;; 
;;; 39 B - could work, lol
;;; TOOD: - how is different from jskVL02
FUNC "_div"
        jsr _zero
        ldy #17
        sty savey
next:   
        ;; shift in one bit result into S!
        rol stack+2,x
        rol stack+2+1,x

        ;; done?
        dec savey
        beq done

        ;; shift in one hi bit from S into tos
        rol tos
        rol tos+1

        ;; tos -= D (reverse _minus)
        jsr _sbc
        dex
        dex

        ;; C=1 if subtract ok (?)
        bcs next

        ;; no, too big

        ;; add B back, lol
        jsr _plus
        dex
        dex
        ;; carry should be clear

        ;; loop Z=0 always
        bne next

done:   
        ;; done remove D pop S which has the result
        inx
        inx
        bne _pop
.endproc


;;; 16div16 => 16 ??? works?
;;;     ptr1/ptr2 => ptr1
;;; 
;;; did I write this while drunk?
;;; (from asmlisp-asm.asm)
;;; 
;;; jsk 35 B - edited - THIS IS ZERO PAGE
.proc div1616
        ldx #16
        ;; A will keep hi-byte!
        lda #0
divloop:
        asl ptr1
        rol ptr1+1
        rol a

        ;; hi-byte cmp
        cmp ptr2+1
        bcc no_sub

        ;; lo-byte cmp
        tay
        lda ptr1+1
        cmp ptr2
        bcc no_sub

        ;; add 1 to result!
        inc ptr1

        ;; carry is set
        ;; lo-byte sub
        sbc ptr2
        sta ptr1+1

        ;; hi-byte sub
        tya
        sbc ptr2+1
        tay ; lol
no_sub:
        tya
        dex
        bne divloop

        rts
.endproc


;;; take 3
;;; ;
;;; 16div16 => 16 ??? works?
;;;     ptr1/ptr2 => ptr1
;;; 
;;; did I write this while drunk?
;;; (from asmlisp-asm.asm)
;;; 
;;; 
;;; (35 zero page)
;;; 41 B - using tos + stack
;;;  --------------- NO EXTRA for JSR etc?
;;;   little overhead not much calls or pops
;;;   remainder??? 

;;; is this possible? it's trying to keep
;;; both divend as remainder andreply by quotient?!?
;;; 
;;; NO I think 8 bits too little... lol!!!!
;;;  and no remainder....
.proc div1616
        jsr _swap
;;; tos = DIVEND stack = divisor
        lda #16
        sta savey
        
;;; trying to be clever by keeping in A
        ;; A will keep hi-byte!
        lda #0
divloop:
        jsr _mul2
        rol a

        ;; hi-byte sbc
        tay
        sec
        sbc stack+1,x
        bcc no_sub

        ;; store new hi
        sta savea

        ;; lo-byte sbc
        lda tos+1
        sbc stack,x
        bcc no_sub

        ;; save result
        sta tos+1 ; lo
        ldy savea ; hi

        ;; set 1 bit in result
        inc tos

no_sub:
        ;; restore (old) hi
        tya

        dec savey
        bne divloop

        rts
.endproc




;;; jsk modify - take 2!

;;; from nes discussion
;;; - https://forums.nesdev.org/viewtopic.php?t=143
;;; 
;;; 54 B jsk -> 48 lol, HUGE!!!
;;; 
;;;  55B bah - noooo gooood!
Divide: 
        ldy #0
        ;; shift to get highest bit set
shift: 
        iny
        asl tos
        rol tos+1
        bcc shift
        
        ;; restore bit
        ror tos+1
        ror tos

        sty savey

        jsr _swap
        ;; tos: DIVEND stack: divisor
divloop:
        ;; result *= 2
        ASL QUO
        ROL QUO+1       

        ;; cmp/sbc hi-byte
        sec
        lda tos+1
        sbc stack+1,x
        bcc skip

        ;; cmp/sbc lo-byte
        tay
        lda tos
        sbc stack,x
        bcc skip               
        
        ;; yes, we confirm
        ;; store result after sbc
        sta tos
        sty tos+1
        
        ;; set lowest bit
        inc quo
skip:  
        ;; divisor /= 2
        lsr stack+1,x
        ror stack,x
                
        dec savey
        bne divloop

        RTS








;;; jsk modify

;;; from nes discussion
;;; - https://forums.nesdev.org/viewtopic.php?t=143
;;; 
;;; 54 B jsk -> 48 lol, HUGE!!!
Divide: 
        ldy #0
        ;; shift to get highest bit set
shift: 
        INY
        ASL DIVSOR                      
        ROL DIVSOR+1
        BCC shift
        
        ;; restore bit
        ROR DIVSOR+1
        ROR DIVSOR

        sty savey

divloop:
        ;; result *= 2
        ASL QUO
        ROL QUO+1       

        ;; cmp/sbc hi-byte
        SEC
        LDA DIVEND+1
        SBC DIVSOR+1
        BCC skip

        ;; cmp/sbc lo-byte
        tay
        LDA DIVEND
        SBC DIVSOR
        BCC skip               
        
        ;; yes, we confirm
        ;; store result after sbc
        STA DIVEND
        sty DIVEND+1
        
        ;; set lowest bit
        inc quo
skip:  
        ;; divisor /= 2
        LSR DIVSOR+1
        ROR DIVSOR
                
        dec savey
        bne divloop

        RTS



;;; from nes discussion
;;; - https://forums.nesdev.org/viewtopic.php?t=143
;;; 
;;; 54 B
Divide: 
        LDY #0

shift: 
        INY
        
        ASL DIVSOR                      
        ROL DIVSOR+1
        BCC shift
        
        ROR DIVSOR+1
        ROR DIVSOR

divloop:
        DEY
        ASL QUO
        ROL QUO+1       
        SEC
        
        LDA DIVEND+1
        SBC DIVSOR+1
        BCC skip
        
        STA VAR                 
        LDA DIVEND
        SBC DIVSOR
        BCC skip               
        
        STA DIVEND
        LDA VAR
        STA DIVEND+1
        
        LDA #$01
        ORA QUO
        STA QUO

skip:  
        LSR DIVSOR+1
        ROR DIVSOR
                
        CPY #$01                
        BPL divloop

        RTS

;;;  DIVEND / DIVSOR = QUO
;;;  DIVEND contains remainder when finished

;;;  First loop: Shift LO DIVSOR and rotate HI DIVSOR until
;;;  there's a 1 in the highest bit 
;;;  INY for each loop

;;;  After first loop:  rotate LO and HI DIVSOR right so
;;;  correct divisor is in place.

;;;  Second loop:
;;;
;;;  DEY, shift LO QUOTIENT and rotate HI QUOTIENT
;;;  so the correct bits of the result are set
;;;
;;;  Subtract DIVSOR from DIVEND
;;;  if DIVSOR > DIVEND, skip these steps
;;;      -Store difference back in DIVEND
;;;      -Set the lowest bit of the quotient
;;;
;;;  Shift the HI and rotate the LO divisor right
;;; 
;;;  loop if Y >= 1 - if the last loop is unnecessary, it will not affect the remainder or the quotient


;;; shorter as macro: 
;;; 23 B !!!

        ; dup U(''0^)
	; dup #1 & UU over & pick2 _MUL2 pick2 _div2 _div + ^

        ;; 23 B - lambda
        ;; :* \\ bUB+2 0^
        ;;       b#1& UU a&
        ;;         a{ b} *
        ;;       +^

;;; :/ dup 1 swap \\\\ ... a=4711 b=32 c=1 d=32
;;;                             da<( a b c{ d{ R 
;;;                    


;FUNC "_div"
;;; _DIV16 is 11 ops in - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library
;;; 
;;;  Divide the 16 bit number at location VLA
;;;  by the 16 bit number at location VLB
;;;  leaving the 16 bit quotient at QUO and
;;;  the 16 bit remainder in REM. The value in
;;;  location VLA is destroyed.
;;; 
;;;  On exit: A = ??, X = $FF, Y is unchanged.
;;; 
;;;  same same
_DIV16: MACRO VLA,VLB,QUO,REM
        _CLR16 REM
        LDX #16
loop:   
        _ASL16 VLA,VLA
        _ROL16 REM,REM
        _SUB16 REM,VLB,REM
        BCS next
        _ADD16 REM,VLB,REM
next:   
        _ROL16 QUO,QUO
        DEX
        BPL loop
ENDM


FUNC "_mul10"
;;; 6 B (19 B in asm)
        DO _mul2
        DO _dup
        DO _mul2
        DO _mul2
        DO _plus
        DO _exit

FUNC "_mul16"
;;; 4 B
        DO _mul8
FUNC "_mul8"
        DO _mul4
FUNC "_mul4"
        DO _mul2
        DO _exit

;;; 3 B LEFT! ... (in one page)

.endif ; mul div

.endif ; MINIMAL?        



endtable:       

.ifdef MINIMAL
;;; TODO: enable again!!! before checkin
  .assert (endtable-jmptable)<=256, warning, "%% Table too big (>256)"
.else
;  .assert (endtable-jmptable)<=512, warning, "%% Table too big (>512)"
.endif


;;; ========================================
;;;       T  R  A  N  S  T  A  B  L  E

; Without this _transtable isn't shown
FUNC "_foobar"

FUNC "_transtable"              ; 128 B

.ifndef MINIMAL
;.ifnblank

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
        DF _hexliteral,36,"_HEX"; $ - hexlit? swap (MINT)
        DF _swap,  37,"_SWAP"  ; % - swap
        DF _and,   38,"_AND"   ; &
        DF _quote, 39,"_QUOTE" ; '
        DO _undef              ; ( - compile if "zBranch"
        DO _undef              ; ) -
        DO _undef              ; * - mult
        DF _plus,  43,"_PLUS"  ; +
        DF _TOSbytecomma,44,"_COMMA" ; , ccomma
        DF _minus, 45,"_MINUS" ; -

;;; DEBUG - TODO: cheating - change!!!
;;; TODO: write in CODE
        DF _printd,46,"_PRNUM" ; . - print num

        DO _undef              ; / - TOOD: macro: div
        DO _digit              ; 0
        DO _digit              ; 1
        DO _digit              ; 2
        DO _digit              ; 3
        DO _digit              ; 4
        DO _digit              ; 5
        DO _digit              ; 6
        DO _digit              ; 7
        DO _digit              ; 8
        DO _digit              ; 9 
        DF _colon,  58,"_COLON"; :
        DF _exit,   59,"_EXIT" ; ;
        DO _lessthan           ; < - lt
        DO _eq                 ; =   : = -U ; # 4
        DO _undef              ; > - gt
        DO _undef              ; ? - is atom? if?
        DF _load,   64,"_LOAD" ; @ car
        DO _undef              ; A - assoc/alloc
;;; TODO: one byte zerobyte skip, and () skip forward
;;;   during compile ; immediate
        DF _zbranch,66,"_IF"   ; B
        DF _cons,   67,"_CONS" ; C
        DF _cdr,    68,"_CDR"  ; D
        DF _eor,    69,"_EOR"  ; E
        DO _undef              ; F - follow/iter/forth ext?
        DO _undef              ; G - 
        DO _undef              ; H -
        DF _inc,    73,"_INC"  ; I
        DF _dec,    74,"_DEC"  ; J
        DF _key,    75,"_KEY"  ; K
        DO _undef              ; L -
        DO _undef              ; M - mem/mapcar/minus
        DO _undef              ; N - number?
        DF _out,     83,"_OUT" ; O
        DO _undef              ; P - print
        DO _undef              ; Q - equal
        DO _undef              ; R - recurse
        DF _setvar,  87,"_SET" ; S - Sa setvar?
        DF _terpri,  88,"_TERPRI" ; T
        DF _null,    89,"_NULL"; U
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
        DF _or,     124,"_OR"  ; |
        DF _div2,   125,"_DIV2"; }
        DO _undef              ; ~ - not
        DO _undef              ; DEL - 

.assert (endtrans-_transtable)=128, error, "Transtable not right size"

.endif ; MINIMAL
FUNC "endtrans"

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

FUNC "_END"

endaddr:
.byte "<AFTER"

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
        SET (endtrans-_transtable)
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
        

;;; at end of code (and tests)
LOWMEM: 





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
