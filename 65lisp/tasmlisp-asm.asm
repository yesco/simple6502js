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

; enable this for size test
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
ipx:    .res 1                  ; stack frame
ipp:    .res 1                  ; n params

endframe:

;;; saved
quitS:  .res 1

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

_quit:  
_reset:
_initlisp:      
        cld
        ldx #ff
        txs
        ldy #0

        jmp running
;;; TODO: fallthrough

_exec:  
        jmp interpret

;;; (number of \)-1 stored in ipp(arams)
_lambda:        
;;; 11 B
        jsr nexttoken
        cmp #'\\'
        bne ret
        inc ipp
        bne _lambda             ; always true

;;; value to return is in TOP
;;; if we had \\ parameters,
;;; from ipx we need to pop ipp==1
_return:
;;; 8 B
        lda ipx
        clc
        sbc ipp
        sta sidx
        rts

_pushaddr:      
        jsr push
        lda ip
        ldy ip+1
;;; TODO: can one make a pushay?
;;;    (but, "push" will clobber)
setay:
        sta tos
        sty tos+1
        rts

_undef: 
_error: 
        ;; write .? - for undefined
        ldy ipy
        lda (ip),y
        jsr putchar
        putc '?'
        jmp _quit

;;; lit moves lo to hi in TOS and sets lo to next byte
;;; tos= (tos<<8) + (char*)ip[y];
;;; 
;;; To load a
;;;    LITERAL $beef
;;; do:
;;;    lit $be lit $ef
;;; 
;;; NOTE: to just load one char,may need to do
;;; 
;;;    'A == lit 0 lit 65
;;; or
;;;    0 lit 65

;;; TODO: unclear what usage or what is good!

nexttoken:      
        inc ipy
        ldy ipy
        lda (ip),y
        rts


;;; 18 B

;;; tos= t1
_quote: 
        jsr _zero
        jsr nexttoken
        sta tos
        rts
;;; tos= t2t1
_literal:       
        jsr _quote              ; lo
        jsr nexttoken           ; 
        sta tos+1               ; hi
        rts


;;; ----------------------------------------
;;; memory


;;; 3B !
_cdr:   
        ldy #2
        ;; bit hack to skip 2 bytes
        .byte $2c
_car:    
_load:      
;;; 17 B
        ldy #0
cYr:    
        lda (top),y
        sta savea

        iny
        lda (top),y
        sta top+1
        lda savea
        sta top

        rts

;;; comma
;;; used to implement ! store

;;; 17 B
_comma:
        jsr _ccomma
_ccomma:
        ldy #0
        lda stack,x
        sta (top),y
        inx

.proc _inc
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc


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


;;; 8 B
_store: 
        jsr comma

pop2:   inx
        inx
        jmp pop

;;; memory
;;; ----------------------------------------

;;; 5B : T #10 O ; # 4
_terpri:
        jsr push
        lda #10
        ;; fall-through
_putc:  
        jsr putchar
        jmp pop
_getc:         
;;; 9
        jsr zero
        jsr getchar
        sta top
        rts
        
_zbranch:        
;;; 17 B
        lda tos,x
        ora tos+1,x
        bne pop
        ;; zero so branch relative
        jsr nexttoken
        clc
        adc ipy
        sta ipy
        jmp pop
;;; TODO: put befor pop?

_null:
;;; 8 B
        lda tos,x
        ora tos+1,x
        beq settrue
        bne setfalse

;;; 11+10+7=28 hmmm
;;; 10 B
        lda tos,x
        bne setzero
        lda tos+1,x
        bne setzero
        jmp settrue

_true:  
        jsr push
settrue:       
        lda #$ff
bothset:
        tay
        jmp setay               ; save 1 byte!
_zero:
        jsr push
setzero:       
        lda #0
        beq bothset
        
;;; --------- MATH

;;; 38B for _adc _and _eor _ora _sbc _pop
;;; 
;;; (+ 13 15 27) = 55 using macro !
;;;
;;; X must contain stack pointer always
;;; 
;;; using ...AX mode

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

_eor:
        ;; EOR stack,x
        lda #$5d
        bne mathop
_ora:
        ;; AND stack,x
        lda #$1d
        bne mathop

_sbc:   
        ;; SBC stack,x
        sec
        ldy #$fd
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
;;; 18B
mathop: 
        sty op
        ldy #0
        
        jsr genop
        ;; - fallthrough for hibyte Y=1
genop:  
        lda tos,y
op:     adc stack,x
        sta tos,y
        iny
        inx
        rts

;;; : % 'D @ 'A ! 'T @ 'D ! 'A @ 'D ! ;
;;; # 20
_swap:  
;;; TDOO: if we could assume Y=0...
        ldy #0
        jsr _bswap

_bswap: lda tos,y
        sta savea
        lda stack,x
        sta tos,y
        tya
        sta stack,x
        
        rts

;;; TODO: remove old artifact
;;; (this was an alt if ^|& etc are expensive) 
.ifnblank
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
        jsr putchar
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
        jsr getchar

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
        jsr getchar
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
        jsr _atomread
        bcs readlist

        ;; ATOM
parseatom:      
;;; TODO: possibly empty string? not clear
;;;    maybe for ()  - TEST!

        jsr findatom
createatom:
        ...

readlist:
        ;;')' => retnil!
        ;; (is this accurate test? lol)
        ;; (TODO: does this work? ;-)
        bne retnil

        ;; continuation tail, LOL
        ;; car
        jsr read
;;; read sets Zero on '(' and Carry for '(' and ')'
        ;; cdr
        jsr readlist

;;; TODO: different cons in town these days...
        jmp cons

.endproc
        


_shl:   
;;; 5B (but technically not needed)
        asl top
        rol top+1
        rts

.endif ; MINIMAL


_number:        
.ifdef NUMBERS
        jsr bytecode
        .byte 0
.endif ; NUMBERS

_exit:  
;;; TODO: fix?
        sta savea
        pla
        pla
        lda savea
_ret:    
        rts

;;; quit exec dup drop 
;;; cons car cdr null atom
;;; zero true inc plus halve nand
;;; putc getc
;;; /17 = 127 ... 224
;;;       161 ... 357 ;; car/cdr inline
;;;       207     346 ;; inline all cons
;;;      (- 346 207 64) = 75 for exec
;;;       234     419 ;; complicatd exec
;;;       256     455 ;; TRACE
;;;       236     422 ;; MINIMAL
;;;       256     473 ;; TRACE !MINIMAL
;;;       254     463 ;; no RPUSH in exec,jsr nxttok
;;;       226     476 ;; Quit that resets,nofix BUG!
;;;       221     445 ;; TRACE prompt
;;; crash after 29 '.'
;;; not when using (before) these
;;; changes - 362c974..06473df

;;; tasmlisp: NEW GAME IN TOW
;;; 
;;; TOS, X points to stack, always retained
;;; A and Y always free to use

;;; math:      38   + - & | E dup - 6 op - 6.3 B/op !
;;;   NOT: (null:      28   U 0 Lffff )
;;; NULL:      14   macros: 0 U true
;;;   - macro:   - 14 B !
;;; mem:       64   D @ ,I r,J 2drop (+ 3 17 17 19 8) = 64
;;; interpret: 35   X interpret
;;; io:        20   T O K   (+ 5 6 9)
;;; write:     12   W
;;; lit:       25   Lbeef nextchar 'A
;;; if:        17   zBranch
;;; read:      54   brk_skps_rdatom R (+ 11 7 20 16) 
;;; \ lambda:  19   \ ^

;;; STATS

;;;  math NULL mem exe io wrt lit if read \
;;; (+ 38   28  64  35 20 12   25 17  54  19)
;;; 
;;;                         = 312
;;;                          + 57 byte sym NAMES
;;;                         = 369
;;; 
;;;       (- 512 (+ 312 57)  )
;;; 
;;;             143 left for impl lisp!
;;;                  using CODE, lol
;;; 
;;;    (- 143 66) === 77 (new names, see below)
;;; 


;;; TODO: PRINT COND LAMBDA EQ
;;;   need EVAL APPLY ASSOC


;;; T NIL ?QUOTE READ ?PRINT ?COND CONS CAR CDR
;;; ATOM ?LAMBDA ?EQ
;;; 
;;; TODO: PRINT COND LAMBDA EQ

;;; 44 chars + 13 atoms (+ 44 13) = 57 minimal?

;;; more symbols for all?
;;; 
;;; AND + * & | ^ , KEY PUTC TERPRI NULL EVAL APPLY INC DEC DIV2 MUL2
;;; 
;;; -- 66 chars including spaces


;;; TOO BIG!
;;; - no space left for ???
;;; P - print lisp
;;; Y - read atom
;;; R - read lisp
;;; 

;;; -- extras
;;; V - x10 lol : V "{{+{ ; # 5
;;; 1-9 -  read num



;;; OLD
;;; code outside...
;;;
;;; TOTAL 
;;;    jmptable transl cons bytecode exec vars
;;; (+ 234      64 4   57   8        33   22) = 422

;;; ----------------------------------------
;;; CODE
;;; 
;;; from here on, it's just strings that
;;; will be interpreted as bytecode!

codestart:      

;;; what does cons do?
;;; 
;;;   *--lowcons =  *stack--  ; cdr
;;;   *--lowcons =  *stack--  ; car

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


;;; NULL: 14 B
_TRUE:  
;;; 4 B
        .byte "L"
        .word $ffff
        .byte 0
_ZERO:  
;;; 4 B
        .byte "L"
        .word $0000
        .byte 0
_NULL:
;;; 6 B
        .byte "B",+2
        .DO _true
        .byte 0
        .DO _zero
        .byte 0

       
endtable:       

.assert (endtable-jmptable)<=256, error, "Table too big"


transtable:     
.macro DO name
        .byte <(name-jmptable)
.endmacro

;;; > !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~ <
        DO _store              ; !
        DO _undef              ; " - dup (MINT)
        DO _lit                ; # - lit?numberp?
        DO _swap               ; $ - swap (MINT)
        DO _undef              ; % - over (MINT)
        DO _and                ; &
        DO _quote              ; ' - quote BUT: drop (MINT)
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
        DO _undef              ; B - ZBRANCH memBer?
        DO _cons               ; C
        DO _cdr                ; D
        DO _eor                ; E
        DO _undef              ; F - forth ext?
        DO _undef              ; G - 
        DO _undef              ; H - (h) append
        DO _inc                ; I
        DO _dec                ; J
        DO _getc               ; K
        DO _literal            ; L
        DO _undef              ; M - mapcar
        DO _undef              ; N - number?nth?/not?/null?
        DO _putc               ; O
        DO _undef              ; P - print
        DO _reset              ; Q - equal???
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

        DO _undef              ; { - : { "+ ; 
        DO _ora                ; |
        DO _shr                ; }
        DO _undef              ; ~ - not
endtrans:       

;;; 24 functions!

.assert (*-transtable)=64+4, error, "Transtable not right size"

;;; ----------------------------------------
;;;              U S E R C O D E
;;;                 (overflow)
;;; usercode

;;; comes here from _initlisp
running:        
        ;; TODO: remove (3 bytes)
        ;; (for now prints some info)

        jsr _test
        
        ;; cons ptr
        SET (TOPMEM-1)
        sta lowcons
        stx lowcons+1
        
        ;; zero stuff
        lda #0

        ;; AX = 0;
        tax

;;; TODO: eval read
rdloop:   
        jmp call1
call1x: 
;        RPUSH
        pha

.ifdef TRACE
        putc 10
        putc '>'
.endif
        jsr _getc

.ifdef TRACE
        jsr trace
.endif ; TRACE

        ;; exec one char
        jsr nexta
        jmp 
        jmp rdloop
;;; TODO: if _quit then "will" return to basic


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

popret: 
        RPOP
        rts

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

;;; execute byte code after JSR (or use BRK?)
;;; - either routines exit by rts
;;; - or ... jmp next
;;; NOTE: to invoke use "jsr bytecode"
;;;       BUT, it never returns thus no update
;;;       to of PC needed, use CONT-CALLING, if need

;;; TODO: remove, anything > CODEstart
bytecode:       
;;; 8B
        pla                     ; lo
        tay
        pla                     ; hi
        tax
        tya
        ;; address on stack (w jsr) points
        ;; on last byte of jsr-instruction
;;; TODO: use BRK to get here, no need inc?
        jsr _inc
        jsr printd
        jmp _exec
        

;;; 33B jsr-loop
exec:   
        ldy #$ff
        sty ipy
loop:
        jsr next
        jmp loop

;;; WARNING: Don't jmp next!!!
;;; this isn't forth
;;; TODO: still valid? lol
next:   
        jsr nexttoken
        ;; at end of string
        beq nret

;;; TODO: enable
;        sta token

nexta:  
        jsr translate

.ifdef TRACE
        PUTC 'o'
        ldx #0
        jsr printd

        NEWLINE
.endif

        ;; if offset > codestart
        ;;   then its time to interpret
        cmp #(codestart-jmptable)
        bcs interpret
        ;; save in "jmp jmptable" low byte!
        sta call+1
        
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

;;; X points to the data stack entry (don't modify)
call:   jmp jmptable


;;; 35B 72c - relative expensive (?)
proc interpret

enter:  
        ;; save what we're calling
;;; TODO: is is expected in A?
;        sta savea 

        ;; push current stack frame
        ldy #(endframe-startframe)
nxt1:   
        lda ip-1.y ; x would be cheaper (3B now)
        pha
        dey
        bne nxt1
        
        ;; this value is modified by \ and ^
        ;; to pop parameters orderly!

subr: 

        ;; set new IP
        lda savea
        sta ip
        lda #>jmptable
        sta ip+1
;;; TODO: can this be moved into exec?
;;;   (maybe some problem with Ztail/Recurse?
        lda #0
        sta ipp

        jsr exec
        
subrexit:
        ;; pop to current stack frame
        ldy #0
nxt2:   
        pla
        sta ip,y
        iny
        cpy #(endframe-startframe)
        bne nxt2

        rts
.endproc

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


endaddr:

;;; end usercode
;;; ========================================

;;; testing data

.macro CODE str
        jsr bytecode
        .byte str,0
.endmacro


;;; 31B
consz:  
        CODE "'CAJJ'CS'CAS 'CAJJ'CS'CAS 'CA"
;;; 13B
        CODE "'C; 'C; 'CA"




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
