;;; lib-string.asm
;;; 
;;; possibly:
;;; 
;;; Part of library for parse CC02 C-compiler
;;; 
;;; #x66 = 102 bytes



;;;               W A R N I N G  !



;;; This code is unrested, and mostly just written
;;; to see how much coded would be needed to support
;;; the minimal %d %u %x %s %c... and it's about
;;; 100+ Bytes!

;;; Not sure it's going to be implemented.

;;; I prefer if the compiler just generated code
;;; with calls according to expected type and
;;; formatting commands; interesting enough,
;;; that may generate much less or about the same
;;; amount of code as a regular call to printf.
;;; 
;;; But then you have slow code, and "big library"
;;; Adding printf to cc65 compiled program
;;; adds about 1900 bytes! (or so)


.zeropage
tos:    .res 2
pos:    .res 2
savex:  .res 1
savea:  .res 1
savey:  .res 1
.code

;;; dummies
_incT:  
putchar:        
putz:
putx:   
putd:   
putu:   
        rts

.export _printf
_printf:        
;;; according to printf.c minimal *restricted*
;;; implementation (no .7 max limit) the 
;;; cc65 - printf will "include" funs giving
;;; - a total of +1870 B
;;; - a replace  +1701 B (many support funcs)
;;;   where      ( 765 B ) is simplified impl in C

;;; here we strive for a compiling printf as:
;;; 
;;; printf("foo %d bar %-8s fie %c fum %07.4x\n",...
;;; 
;;; TO:
.ifnblank
;;; (+ -4 +0 -4 +3 -4 -4 +8) == -5 B
;;; compared to cc65 (estimate) save 5B and
;;; no need large function at runtime!
;;; BUT: no printf(var, ....) !!!!

        ;; "foo " (-4 B loading ax)
        jsr hereputz
        .byte "foo ",0

        ;; %d     (+0 B as otherwise jsr pushax)
        ... value in AX
        jsr axputd

        ;; " bar " (-4 B)
        jsr hereputz
        .byte " bar ",0

        ;; %-8s (+ 3 B cmp jsr pushax)
        ... value in AX
        ldy #256-8              ; negative value!
        clc
        jsr axputzF

        ;; "fie" (- 4 B)
        jsr hereputz
        .byte " fie ",0

        ;; %c
        ... value in A
        jsr putchar

        ;; " fum " (-4 B)
        jsr hereputz
        .byte " fum ",0
        
        ;; %07.4x" (+ 8 B for parameters)
        ... value in AX
        ;; - dot value ".4"
        sed                     ; WOW: d= means dot value
        ldy #4
        sty dos
        ;; - len 07
        sec                     ; leading 0
        ldy #7                 
        jsr axputhF
;;; 

.endif


;;; (+ 8 12 26 3 2 9 3 3 31) = 97
;;; just: "foo %d bar %c fish %x gurk %s kork"

        ;; it's on the hardware stack
        ;; Y contains number of bytes pushed
        ;; (Y/2 is no of arguments)
        ;; lda (101),x points to 

;;; 8
        sty savey
        tsx
        txa
        clc
        adc savey
        tax
        ;; - load first argument==format - I hope!
;;; 12
        lda $101,x
        sta pos
        lda $102,x
        sta pos+1
        stx savex
        ;; - pos points to the format string

        ;; parse format string
;;; 26
        ldy #0
@nextc:       
        lda (pos),y
        jsr _incT
        ;; \ quoted
        cmp #'\'
;        cmp #92                 ; \
        bne :+
        jsr _incT
        bne @printchar
:       
        ;; %formatchar
        cmp #'%'
        bne @printchar
        jsr processarg
        jmp @nextc
@printchar:
        ;; - otherwise print!
;;; 3
        jsr putchar
        ;; - (zero will terminated (after printed!))
;;; 2
        bne :-

        ;; pop all args!
        ;; - save return address
;;; 9
        pla
        sta tos+1
        pla
        sta tos
        jsr _incT               ; +1 !
        ;; - drop !
;;; 3
        ldx savex
        tsx
.ifnblank
        ldy savey
:       
        pla
        dey
        bpl :-
.endif
        ;; - finally return!
;;; 3
        jmp (tos)

processarg:
;;; 31
        ;; - save char after % in Y
        tay
        ;; - TODO: process "%[[-]45]d"
        ;; - get next argument
        ldx savex
        dex
        dex
        lda $102,x             ; hi
        tax
        lda $101,x             ; lo
        ;; AX is argument, Y is type char

@dispatch:
;;; TODO: put all this routines/trampoiles NEAR!
        ;; tail-calls!
        cpy #'u'
        beq putu
        cpy #'d'
        beq putd
        cpy #'x'
        beq putx
        cpy #'s'
        beq putz
        cpy #'c'
        bne :+
        jmp putchar
:       
        ;; fail to match type char
        rts
