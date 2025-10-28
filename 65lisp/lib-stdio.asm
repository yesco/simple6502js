;;; lib-stdio.asm
;;; 
;;; Part of library for parse CC02 C-compiler




FUNC _stdiostart
;;; -------- <stdio.h> - LOL
;;; 
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
;;; - getline
;;; - gets

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

PUTDEC=1
PUTHEX=1
.include "print.asm"

.ifdef INLINEPUTZOPT
;;; Put zero terminated string directly
;;; after jsr _inlineputz!
;;; 
;;; TODO: be used by:
;;;    printf("foo %d bar %s fie %x fum")
;;; 
;;; 7 bytes saved per call of putz("foo"); & puts
;;; 
;;; 29 bytes total putz puts

;;; (+ 10 19)= 29 B (+ 29 22)=51 (iputz+putz)
FUNC _iputs
;;; 
;;; (+ 2 1 7) = 10
;;; 2
        sec
        SKIPONE
FUNC _iputz
;;; (+ 4 4 4 7)= 19
;;; 4+1=5
        clc
        ;; lo
        pla
        tay
        ;; hi
        pla
        tax
        ;; inc YX
;;; 4
        iny
        bne :+
        inx
:       
;;; 4+7=11
        tya
        ;; save C flag, lol
        php
        jsr axputz              ; 22 !
        plp
        ;; if C set newline! (puts)
        bcc :+
        jsr nl
:       

TOSRTS: 
;;; 7 B
        ;; hi
        lda tos+1
        pha
        ;; lo
        lda tos
        pha
        ;; perfect (at 0, next is next instruction!)
        ;; return to location after 0
        rts

.ifdef PRINTFHELPERS
;;; These are helpers for printf

;;; TODO: compile printf("%-08.5u bytes\n", 4711);
;;; 
;;; lda #<4711
;;; ldx #>4711
;;; 
;;; sec
;;; jsr _iputuz
;;; .byte $ff-8,5
;;; .byte " bytes\n",0

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


.endif ; INLINEPUTZOPT

FUNC _stdioend
