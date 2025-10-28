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
FUNC _inlineputs
;;; 2+8 B (8 in next function)
        sec
        SKIPONE
FUNC _inlineputz
;;; 19 (+ 8) B
        clc
        ;; lo
        pla
        tay
        ;; hi
        pla
        tax
        iny
        bne :+
        inx
:       
        tya
        ;; save C flag, lol
        php
        jsr axputz
        plp
        ;; if C set newline! (puts)
        bcc :+
        jsr nl
:       
        ;; hi
        lda tos+1
        pha
        ;; lo
        lda tos
        pha
        ;; perfect (at 0, next is next instruction!)
        ;; return to location after 0
        rts
.endif ; INLINEPUTZOPT

FUNC _stdioend
