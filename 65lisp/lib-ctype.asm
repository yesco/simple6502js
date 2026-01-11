;;; lib-ctype.asm
;;; 
;;; Part of library for parse CC02 C-compiler
;;; 
;;; 98 B
;;; 89 B (code-golf, including added isident!)
;;; 93 ???
;;; 
;;; AX!=0 is true (C=0 is also true!)
;;; AX==0 is false (C=1 typically, except ident?)


;;; -------- <ctype.h>
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

;;; 98 B - 10 functions (- #xf8 #x96)
;;; 89 (+4 isident) ! code golf!
;;; 
;;; (cheaper than most compilers as they in
;;; addition keep an 128 byte table, and each F is at least 8 bytes)

;;; TODO: trigger inclusion on:
;;; 
;;;   #include <ctype.h>

isxdigit:
;;; 11
        tay

        ora #32
        sec
        sbc #'a'
        cmp #'f'-'a'+1
        bcc retC

        tya
isdigit:        
;;; 7
        sec
        sbc #'0'
        cmp #'9'-'0'+1

;;; 9
retC:   
        bcs retfalse
rettrue:   
        lda #$ff
        SKIPTWO
retfalse:   lda #0
        tax
        rts


.ifnblank
;;; 7 smaller but can't use rettrue retfalse
retC:   
        ldx #0
        bcs retF
;;; Don't use as X not init!
retT:        
        dex
;;; Don't use as X not init!
retF:
        txa
        rts
.endif ; nblank



;;; TODO: optional but often needed
;;; (C not value for test, only A(X))
isident:
;;; 4
        cmp #'_'
        beq rettrue
isalnum:
;;; 7
        tay
        jsr isdigit
        bcc rettrue
        tya
isalpha:        
;;; 12
        tay
        ;; make all lower case
        ora #32
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

isspace:        
;;; 6
        ;; we take ourselves some freedom of interpreation!
        cmp #' '+1
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
@retR:
        ldx #0
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
