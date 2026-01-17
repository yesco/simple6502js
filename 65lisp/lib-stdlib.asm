;;; lib-stdlib.asm
;;; 
;;; Part of library for parse CC02 C-compiler
;;; 
;;; Only functions defined here:
;;; - rand() srand()
;;; - TODO: malloc(), free(), realloc()


;;; -------- <stdlib.h>

;;; same same...
;;; - atoi
;;; 
;;; - rand()
;;; - random()
;;; - srand()
;;; - srandom()

;;; TODO:
;;; - malloc
;;; - free
;;; - realloc
;;; - calloc

;;; - _Exit(int)
;;; - abort()
;;; - exit(int)

;;; - abs
;;; - div

;;; - getenv
;;; - putenv
;;; - setenv

;;; - bsearch
;;; - qsort
;;; - setkey
;;; - encrypt
;;; (inp) => AX, inp points at next (not digit) char
;;; 
;;; TODO: too big! just use parse rules!!!



.zeropage
;;; 8-bit seed the generator, write here
seedrand:       .byte 42
.code

;;; new rnadom valuie in AX
FUNC rand
        jsr rand8
        tax
        ;; fall-through for A

;;; Simple 8-bit LFSR
;;; 
;;; The 8-bit LFSR (0–254 range, excluding all-zero),
;;; use a Galois configuration with the primitive
;;; polynomial \(x^8 + x^4 + x^3 + x^2 + 1\)
;;; (mask `#$1D`). This gives a maximum period of 255
;;; before repeating.
;;; 
;;; Consider using Mersenne Twister (?)
FUNC rand8
        lda seedrand
        beq do_xor
        asl
        beq no_xor
        bcc no_xor
        lda seedrand
do_xor:  
        eor #$10
no_xor: 
        sta seedrand
        rts




;FUNC _atoiAX
;        sta sos
;        stx sos+1               
;        ldx #sos

.ifdef ATOI

FUNC _atoiXR
        lda #10
FUNC _atoibaseXR
        sta base
        lda #0
        sta tos
        sta tos+1
        ;; base
        sta dos

        ;; 0x 'c' -
        lda (0,x)
        ;; ' - char constant
        cmp #'''
        bne :+
        
        jsr _incXR
        lda (0,x)
        ;; TODO: handle \' \n \b \t ???
        jsr _incXR
        ;; - should be '-' lol
        jsr _incXR
        jmp @retA
:       
        ;; "-" negative
        cmp #'-'
        bne :+

        jsr _incXR
        jsr _atoiXR
        jmp _negate
:       
        ;; "0x" - hex
        cmp #'0'
        bne :+                  ; 1-9
        jsr _incXR
        ora #32
        cmp #'X'
        bne @ret                ; zero! (no octal...)
@hex:    
        lda #16
        sta base

:       
        lda (0,x)
        ;; digit? '0' <= a <= '9'
        sec
        sbc #'0'
        cmp #'9'+1-'0'
        bcs @notdigit
        ;; digit
        sta savea
        lda base
        sta dos
        lda #0
        ;; tos= tos * dos; // mul16 destroys tos&dos
        jsr _mul16bits
        ;; c=0 from cmp
        adc savea
        tay

@ret:
        lda tos
@retA:
        ldx tos+1
        rts
.endif ; ATOI


.ifdef SIGNED
;;; 31B
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

;;; print signed decimal
FUNC _putd
putd:
;;; 19 b
        cpx #0
        bpl :+
        putc '-'
:       
        ;; negate
        jsr _negate
        
        sta tos
        stx tos+1
        jmp putu

FUNC _dummyd
.endif ; SIGNED
