;;; lib-math.asm
;;; 
;;; Part of library for parse CC02 C-compiler





;;; --------------- <math.h>
;;;
;;; - * mul16
;;; - / div16
;;; - (div in stdlib?!)
;;; - nothing, it'sl all float/double? 


;;; Variant of BBC BASIC 2 ROM,
; - https://archive.org/details/BBCMicroCompendium/page/302/mode/1up?q=9236
;;; 
;;; jsk: TOS * DOS => AX (lo,hi)
;;; 
;;; smaller value in DOS more efficient (?)
;;; 
;;; 30 bytes 16x16=>16

;tos:            .res 2
;dos:            .res 2


;;; TODO: LIBFUN
;;;   -- problem is fallthroughs!
;;;   if Y=0 skip sta tos/sty dos? lol

FUNC _mulAXyAX
        sta tos
        stx tos+1
FUNC _mulTOSyAX
        sty dos
        ldy #0
        sty dos+1

;;; pos x dos => AX
;;; 31
FUNC _mul
        ldx #0
        ldy #0

loop:   
        ;; get lol bit from DOS (ODS /= 2)
        lsr dos+1
        ror dos
        bcc skip

        ;; add YA += TOS
        clc

        tya
        adc tos
        tay

        txa
        adc tos+1
        tax

skip:   
        ;; TOS *= 2
        asl tos
        rol tos+1

        ;; done if zero
        lda dos
        ora dos+1
        bne loop

        ;; no overflow
        ;; OPTIONAL
        ; clc

        ;; results in lo y, hi x (C if overflow)
        tya

        rts


