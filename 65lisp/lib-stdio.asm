;;; lib-stdio.asm
;;; 
;;; Part of library for parse CC02 C-compiler


;;; -------- <stdio.h> - LOL
;;; 
;;; TODO: ... fix...
;;; --- basis for PRINTF modular
;;; 20 - puth, put4h, put2h
;;; 13 - plaprinth (to reverse)
;;; 22 - axputz==printz, writez tos+Y
;;; 37 - voidputu takes AX stores in tmp1 (voidprinttmp1d 33)
;;; 13 - xputu saves A,X prints tos
;;;      (todo cleanup printn,putu does jmp _drop, lol
;;;  7 - axputu
;;;  7 - axputh
;;; (7)- axputd 
;;; ========
;;; 119 B - too much!  (+ 20 13 22 37 13 7 7)
;;; 
;;; 127 B according to info() ?
;;; 
;;; TODO:messy code: cleanup, rewrite

;;; simulate files?
;;; - fopen
;;; - fclose
;;; - fseek
;;; - fread
;;; - fwrite

;;; TODO:
;;; - puts axputz w nl, lol
;;; - printf
;;; - (sprintf)
;;; 
;;; - stdin, stdout - vars, lol
;;; - stderr - write on screen with INVERSE? lol

;;; - readline - LOL - allocates string
;;; - getline - TODO: allocates string
;;; - fgets - DONE: see below, uses existing buffer
;;; - gets - unsafe ... (Hmmm) - DON'T DO!

;;; - fprintf(STDOUT, 
;;; - fprintf(STDERR,
;;; - getc(FILE)
;;; - ungetc(FILE)
;;; - feof(FILE)
;;; - ffflush(FILE)
;;; - TYPE: size_t == int, lol

;;; TODO: somehow should be able to put BEFORE begin.asm
;;;    but not get error, just doesn't work! (hang)
;;;    or AFTER 




;;; from "print.asm" but simplified

;;; compat with print.asm
PRINTER=1
PRINTINCLUDED=1

PRINTHEX=1

.ifdef PRINTHEX


;;; print4h: print hex from AX
;;; 
;;; (+ 6 8 1 8 3) = 26
;;; 
;;; TODO: doesn't it feel like a generic
;;;       div BASE printer would be same?

;;; TODO: optional?
;;; (+ 7 26) = 33
;;; 
FUNC _printh
FUNC _printdollar4h
;;; 7
        pha
        lda #'$'
        jsr putchar
        pla
FUNC _print4h        
;;; 6
        pha
        txa
        jsr _print2h
        pla
FUNC _print2h
;;; 8
        pha
        ;; hi
        ror
        ror
        ror
        ror
        jsr _print1h
        ;; fall-through
.endif ; PRINTHEX

plaprint1h:     
;;; 1 B
        pla
FUNC _print1h
.ifblank
;;; 6502 "ideom" convert 0-f => '0'..'F' !
;;; ! - http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/some-veryshort-code-bits/
;;; 8 B !

;;; WARNING: if this get's interrrupted IRQ routine may...

;;; "Though there is one problem: It works with invalid
;;;  BCD digits and might not work on emulators." !!!

        and #$f
        SED
        CMP #$0A
        ADC #'0'
        CLD
.else
;;; 10 B "normal"
        and #$0f
        ora #$30
        cmp #'9'+1
        bcc :+
        adc #6
:       
.endif
;;; 3 B
        jmp putchar

;;; printu: print a decimal value from AX
;;; (+Y trashed)
;;; 
;;; 35 B
;;; 
;;; _posprintu
;;; 31B - this is a very "minimal" sized routine
;;;       slow, one loop per bit/16
;;; 
;;; ~554c = (+ (* 26 16) (* 5 24) 6 6 6)
;;;       (not include time to print digits)
;;; 
;;; Based on DecPrint 6502 by Mike B 7/7/2017
;;; Optimized by J. Brooks & qkubma 7/8/2017
;;; This implementation by jsk@yesco.org 2025-06-08

;;; Kindof early C "standard"
;FUNC _printn

LIBFUN _printu
;;; 4
        sta pos
        stx pos+1
        
;;; Cannot use in codegen
FUNC _posprintu
;;; 31
.scope
digit:  
        lda #0
        tay
        ldx #16
;;; TODO: can this be generalized
;;;       for any (even) BASE?
div10:  
        cmp #10/2
        bcc under10
        sbc #10/2
        iny
under10:
        rol pos
        rol pos+1
        rol

        dex
        bne div10

        ;; push delay print => reverses order!
        ;; 7 B
        pha
        lda #>(plaprint1h-1)
        pha
        lda #<(plaprint1h-1)
        pha

        dey
        bpl digit

        rts
.endscope


;;; TDDO: ???
.ifdef BYTECODE

.proc _putu
;;; 14 B
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
.endif

LIBENDFUN _printu


;;; TODO:  remove?
.ifdef PRINTBASE

FUNC _printu
;;; print decimal
;;; 
;;; 29 B + 14 B (plaprint1h)

BASE=10

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

.endif ; PRINTBASE




.ifdef INLINEPRINTZ
;;; (+ 11 7) = 19 B
;;; +19 B  each usage saves 7 B
;;;        compared to: puts("foo\n")

FUNC _iprints
        jsr _iprintz
        jmp nl

FUNC _iprintz
;;; 11
        pla
        sta pos
        pla
        sta pos+1
        ;; skip first char
        ldy #0
        jsr _incposYprintz
        ;; fall-through
FUNC _posRTS
;;; 7
        ;; return to byte after \0
        lda pos+1
        pha
        lda pos
        pha
        rts

  .macro PRINTZ msg
        ;; 3 B
        jsr _iprintz
        .byte msg,0
  .endmacro

.else
;;; TODO: sometimes fails?
;;;   (label pollution?)
  .macro PRINTZ msg
    .scope

  .data
  @data:       
        .byte msg,0
  .code
        ;; 7 B
        lda #<@data
        ldx #>@data
        jsr _printz

    .endscope
  .endmacro

.endif ; INLINEPRINTZ


;;; (+ 19 4 6) = 29 B
;;; 
;;; 29 B gives _printz _prints

FUNC _prints
;;; 6
        jsr _printz
        jmp nl

FUNC _printz
;;; 4
        sta pos
        stx pos+1

;;; X= number of chars printed (if < 256)
FUNC _posprintz
;;; 18
        ldy #0
        ldx #0
FUNC _posYprintz
        lda (pos),y
        beq endprint
        jsr putchar
        inx
FUNC _incposYprintz
        ;; we rely on this for iprintz
        inc pos
        bne :+
        inc pos+1
:       
        ;; always jmp
        bne _posYprintz

endprint:
        ;; Y= number of chars printed?
        rts


popprintyTOSz:
        pla
        tay
        ;; fall-through
        
;;; print Y=0 print till \0 or Y char
;;;   pos= address
;;; Result
;;;   X= number of chars printed (if < 256)
;;; 
;;; 27 B
printyPOSz:        
        cpy #0
        beq _posprintz
        ;; print Y chars
        sty savey
        ldy #0
:       
        lda (pos),y
        beq :+
        jsr putchar
        iny
        cpy savey
        bne :-
:       
        tya
        tax
        rts


stackputu:
        sta tos
        stx tos+1
        ;; store RTS address
        pla                     ; lo
        tya
        pla
        iny
        bne :+
:       

;;; TODO: call new printu

        ;; "RTS"
        jmp (dos)



LIBFUN printfx
        jsr _printh
LIBENDFUN printfx


;;; TODO: math library?

FUNC _negate
;;; 12 b
        sec
        eor #$ff
        adc #0
        tay
        txa
        eor #$ff
        tax
        tya
        rts


LIBFUN printfd
;;; 15 b
        stx savex
        cpx #0
        bpl :+

        jsr _negate
:       
        jsr stackputu

        ldx savex
        bpl :+
        
        ;; push a '-' in front of all digits
        lda #'-'
        pha
:       
;;; TODO: library calling library...
        jmp printfs

LIBENDFUN printfd


;;; Y number of chars printed
LIBFUN printu
;;; 16 B
        jsr stackputu
        ldy #$ff
:       
        iny
        pla
        beq :+
        jsr putchar
        jmp :-
:       
        rts
LIBENDFUN printu


LIBFUN printfu
;;; 14 B
        sty savey
        jsr stackputu

        ;; AX = point to string on stack!
        tsx
        txa
        ldx #1
        
        ;; TODO: handle negative precision
        ;; (push more zeros?)

        ldy savey

;;; TODO: library calling library...
        jmp printfs

LIBENDFUN printfu



.zeropage

;;; TODO: reuse some other?
.export precision
precision:      .res 1

.code



;;; 82 (was 55?) B
;;; print formatted string
;;;   Y= width
;;;   precision (zp) 1B
;;; Returns:
;;;   TODO: AX number of chars printed?
LIBFUN printfs
        sty savex

        ;; store string to print
        sta pos
        stx pos+1

        tya
        bpl @right
@left:
        ldy precision
        jsr printyPOSz
        ;; X= number of chars printed (if < 256)
        txa
        jmp @calc
@right:
        ;; just calculate X (how many chars will print)

        ;; lol, we just put it there!
        lda pos
        ldx pos+1
        ;; TODO: uses AX
        jsr strlen
        ;; A=length.lo
 
;;; TODO: simplify
        ;; if (L<=precision) A=L
        cmp precision
        beq :+
        bcc :+
        ;; if (!precision) then A== L
        ldy precision
        beq :+

        ;; else A= precision
        tya
        jmp :+

;;; TODO: > 256 ...
        ;; then A= L
        cpx #0
        beq :+
        ;; else A= 255
        ;; TODO: no effect ?
        lda #1
:       

        ;; A= length of string to print
@calc:
        ;; TODO: zero pad

        ;; space pad
        ;; - calculate after pad n= width-X
        ldy savex
        bmi :+

        sec
        eor #255
;;; TODO: negative width
        adc savex
        jmp :++
:       
        clc
        adc savex
        eor #255
        adc #1
:       

        ;; pad (if Y<128 (no overflow))
        tay
        bmi :+
        jsr spaces
:       
        ;; if left-justified
        ldy savex
        bmi :+
        
        ldy precision
        jsr printyPOSz
:       
        ;; print constant string after call
        jmp _iprintz
        ;; and it has returned!
LIBENDFUN printfs        
        


;;; TODO: printf!
.ifdef PRINTFHELPERS
;;; These are helpers for printf

;;; TODO: compile printf("%-08.5u bytes\n", 4711);
;;; 
;;; Idea: AX contains data value/string pointer
;;;       C flag set if has extra formatting
;;;       Y set to length (%-08)
;;; 
;;; need to capture:
;;;   W: min width of field (can be neg=left just)
;;;   Z: leading zeroes
;;;   M: maxlen of data (after .) (min for %d?)
;;;   S: space (left blank for +)
;;;   P: +/- always printed
;;;   
;;; probably not:
;;;   #: prefix 0 for octal 0x for hex
;;;      jsk: so for %s could quote "!
;;;   ': grouping character!
;;;   *: take paramter as W or M value

;;; lda #<4711
;;; ldx #>4711
;;; 
;;; sec
;;; jsr _iputuz
;;; .byte $ff-8,5
;;; .byte " bytes\n",0

;;; TODO: make _iputufz (formatted)
;;; - https:  //github.com/agn453/HI-TECH-Z80-C/blob/master/gen%2FPNUM.C


FUNC _iputuz: 
        jsr axputu
        jmp iputz

.ifdef SIGNED
FUNC _iputdz 
        jsr axputu
        jmp iputz
.endif ; SIGNED

FUNC _iputhz 
        jsr axputh
        jmp iputz

FUCN _iputzz
        jsr axputz
        jmp iputz
.endif ; PRINTFHELPERS

;;; getline(char*,int*,stdio) => nchars
FUNC _getline
        ;; TODO:
        rts

;;; fgets_stdin(char*,int,stdio) => char*
;;;   tos: char* buffer
;;;   AX : word  bufflen (ignore A)
;;;     NOTE: X is ignred
;;; Returns
;;;   AX: NULL if no chars, otherwise buffer
;;; Note: for stdin it never returns NULL
;;; 
;;; TODO: haven't I written a smaller one?

;;; TODO: rename as FUNC _editline ?



;;; BUG: TODO: somehow make string 0?


;;; TODO: LIBFUN
;;;   problem is _fgets_edit needs _fgets
;;; a) make two independent functions
;;;    make generated code call both (in one case)
;;; b) _fgets generates LDA #0/STA tos/JSR _edit

;;; tos= line to edit
FUNC _fgets_edit
;;; 57 B + CURSOR_ON/OFF
        tax
        ldy #$ff
        bne @start
@count:       
        jsr putchar
@start:       
        ;; move to end of string
        dex
        iny
        lda (tos),y
        bne @count
        ;; X= bytes left
        ;; Y= number of bytes
        ;; stands on \0

        inx
        txa                     ; LOL
        SKIPTWO
;;; Edits an empty line
;;; tos= memory where to store input
FUNC _fgets
        ldy #0

        ;; X= bytes left
        ;; need 1 byte for zero termination
        tax
        dex
        stx savex

        CURSOR_ON
@next:
        ;; zero terminate after current
        lda #0
        sta (tos),y
        ;; read key
        jsr getchar
;        beq @done               ; 0 ?? ? TODO:

        ;; return
        ;; 
        ;; TODO: add LF for some platform?
        ;;   (or does it depend on stty?)
        cmp #13                 ; CR
        beq @done

        cmp #127                ; DEL
        beq @del

        ;; BS/DEL
.ifdef __ATMOS__
.else
;        cmp #8                  ; BS (CTRL-H)
;        beq @del
.endif 
        ;; ignore other CTRL (< ' ')
        cmp #' '
        bcc @next

        ;; store normal char
        dec savex
        bmi @full
        sta (tos),y
        iny
        ;; echo
        jsr putchar
        ;; always
        bne @next

@del:
        ;; -> have anything to delete?
        tya
        beq @next

        dey
        ;; delete on screen
.ifdef __ATMOS__
        putc 127
.else
;        PRINTZ {8,' ',8}
        putc 8
        jsr spc
        putc 8
.endif

@full:
        ;; ignore key
        inc savex
        bpl @next


@done:
        CURSOR_OFF

        lda tos
        ldx tos+1

        rts
