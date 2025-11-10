;;; mulx.asm - collection of multiply by 10
;;; 
;;; Soma may be used by MeteoriC-compiler
;;; 
;;; 2025 (>) Jonas S Karlsson





.ifdef FASTERMULX
;;; AX => AX

;;; (+ 8 3 21) = 32 B (+2 B on each call MUL10,MUL5)
;;; (+ 17 7 37) = 61c
;;; mul5: +2B 59c  mul10: +2B 52c  mul40: 73c     32 B

;;; tradeoff not clear ... this doesn't have routines...

.macro MUL10
;;; 5 15c (+ 15 44) = 59c
        stx savex
        jsr _xmul10
.endmacro

.macro MULT5
;;; 5 15c (+ 15 37) = 52c
        stx savex
        jsr _xmul5

FUNC MUL40
;;; 8 17c (+ 17 44) = 61c +12= 73c
        stx savex
_xmul40:        
        ;; double
        asl
        rol savex
        ;; double
        asl
        rol savex

FUNC _xmul10
;;; 3 7c (+ 7 37) = 44c (24 B (+ 3 21))
        ;; double
        asl
        rol savex

FUNC _mul5
;;; 21 37c 
        sta tos
        stx tos+1
        ;; double
        asl
        rol savex
        ;; double
        asl
        rol savex
        
        ;; add 1+4
        clc
        adc tos
        tay
        lda savex
        adc tos+1
        tax
        tya

        rts

.else ; !FASTERMULX
;;; TOS => TOS

;;; (+ 8 4 23) = 35 B
;;; (+ 20 10 42) = 72c

;;;(mul5: +2B 59c  mul10: +2B 52c  mul40: 73c     32 B )
;;; mul5:     54c  mul10:     64c  mul40: 84c     35 B

;;; (/ 1000000 100)

FUNC _mul40
;;; 8 20c (+ 20 52) = 72  +12= 84c
        ;; double
        asl tos
        rol tos+1
        ;; double
        asl tos
        rol tos+1

FUNC _mul10                     
;;; 4 10c (+ 42 10) = 52c   +12= 64c   27 B
        ;; double
        asl tos
        rol tos+1

FUNC _mul5
;;; 23 42c   +12= 54c
        lda tos
        ldx tos+1
        ;; double
        asl tos
        rol tos+1
        ;; double
        asl tos
        rol tos+1

        clc
        adc tos
        sta tos
        txa
        adc tos+1
        sta tos+1
        rts

.endif ; !FASTERMULX

