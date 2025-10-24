;;; lib-ctype.asm
;;; 
;;; Part of library for parse CC02 C-compiler



FUNC _ctypestart
;;; -------- <ctype.h>
;;; 98 Bytes !
;;; 
;;; Inlineable (if no #include <ctype.h>)
;;; - isdigit
;;; - isalpha
;;; - isspace
;;; These are "all-or-nothing"
;;; - isspace
;;; - isxdigit
;;; - isdigit
;;; - isalnum
;;; - isalpha
;;; - isupper
;;; - islower
;;; - ispunct
;;; - tolower
;;; - toupper
;;; 
;;; - (isblank)
;;; - (isgraph)
;;; - (isprint)
;;; - (isascii)
;;; - (iscntrl)
;;; - (toascii)
.ifdef CTYPE

;;; 98 B - 10 functions (- #xf8 #x96)
;;; 
;;; (cheaper than most compilers as they in
;;; addition keep an 128 byte table, and each F is at least 8 bytes)

;;; TODO: trigger inclusion on:
;;; 
;;;   #include <ctype.h>

isxdigit:
;;; 13
        tay
        ora #32
        cmp #'a'
        bcc :+
        cmp #'f'+1
;;; TDOO: cannot be relocated!
        jmp retC
:       
        tya
isdigit:        
;;; 7
        sec
        sbc #'0'
        cmp #'9'-'0'+1
retC:   
        bcs retfalse
rettrue:
;;; 3
;;; TODO: maybe $ff as nobody should rely on 1!
        lda #1
        SKIPTWO
retfalse:
;;; 5
        lda #0
        ldx #0
        rts

isalnum:
;;; 8
        tay
        jsr isdigit
        tax
        bne rettrue
        tya
isalpha:        
;;; 12
        tay
        ;; make all lower case
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
;;; TDOO: cannot be relocated!
        jmp retC

isspace:        
;;; 6
        ;; we take ourselves some freedom of interpreation!
        cmp #' '+1
;;; TDOO: cannot be relocated!
        jmp retC

islower:        
;;; 9
        sec
        sbc #'a'
        cmp #'z'-'a'+1
;;; TDOO: cannot be relocated!
        jmp retC

isupper:        
;;; 9
        sec
        sbc #'A'
        cmp #'Z'-'A'+1
;;; TDOO: cannot be relocated!
        jmp retC

ispunct:        
;;; 12
        jsr isalnum
        bcc retfalse
        ;; still have Y
        tya
        jsr isspace
        ;; reverse others
        bcc retfalse
        bcs rettrue

toupper:        
;;; 9
        jsr isalpha
        tya
        bcs :+
        and #255-32
:       
        rts

tolower:        
;;; 9
        jsr isalpha 
        tya
        bcs :+
        ora #32
:       
        rts
.endif ; CTYPE
FUNC _ctypeend
