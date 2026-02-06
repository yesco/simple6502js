;;; - http://forum.6502.org/viewtopic.php?f=2&t=7983&start=0
;;;
;;; To divide by 3, we can multiply by 1/3.
;;; In binary, 1/3 is 0.01010101..., repeating forever
;;; 

;;; - https://www.nesdev.org/wiki/Divide_by_3
;;; 8 bit divide
;;; 
;;; enter with number to be divided in A
;;; answer returned in A
;;; 
;;; no remainder
div3:   
        sta temp
        lsr
        lsr
        adc temp
        ror
        lsr
        adc temp
        ror
        lsr
        adc temp
        ror
        lsr
        adc temp
        ror
        lsr

        rts

;;; - https://forums.nesdev.org/viewtopic.php?t=11336
;;; 
;;; Divide by 3
;;; 18+1 bytes, 30 cycles
div3:   
        sta  temp
        lsr
        adc  #21
        lsr
        adc  temp
        ror
        lsr
        adc  temp
        ror
        lsr
        adc  temp
        ror
        lsr

        rts

;;; Divide by 6
;;; 17 bytes, 30 cycles
;;; jsk; shorter than /3 !
div6:   
        lsr
        sta  temp
        lsr
        lsr
        adc  temp
        ror
        lsr
        adc  temp
        ror
        lsr
        adc  temp
        ror
        lsr

        rts

;;; savea = original value
;;; A = /6 value
;;; => A == %6 value
calcmod:
;;;  10 B  15c
        ;; mul6 === x 110
        sta savex
        asl
        ;; C=0 (/6 value < 40)
        adc savex
        asl
        ;; VAL-6*int(VAL/6)
        eor #$ff
        ;; C=0 (40*6=240 < 256)
        adc savea

        rts
        
;;; jsk

;;; (/ 240 6) => 40 can do with /2 table
;;; (/ 120 3) => 40 < 64 == 6 bits, hmmm

;;; Gives mod and div for A/6
;;; Y= A/6
;;; X= A%6
;;; 
;;; 20 B  30c
moddiv6:   
;;; 10 B  15c
        ;; save original value
        sta savea

        ;; /2 and put /3 in Y
        lsr
        tay
        lda DIV6TABLE,y
        and #63
        tay

calcmod:
;;;  10 B  15c
        ;; mul6 === x 110
        sta savex
        asl
        ;; C=0 (/6 value < 40)
        adc savex
        asl
        ;; VAL-6*int(VAL/6)
        eor #$ff
        ;; C=0 (40*6=240 < 256)
        adc savea

        rts



;;; Not really beneficial being clever!
;;; so cheap calcmod!


;;; mm dddddd
;;; where mm is A%3, dddddd is A/3
DIV6TABLE:      

;;; Gives mod and div for A/6
;;; Y= A/6
;;; X= A%6
;;; 
moddiv6:   
;;; 27 B  44-45c
        ;; save original value
        sta savea

        ;; /2 and put /3 in Y
        lsr
        tay
        lda DIV6TABLE,y
        pha
        and #63
        tay

;;; 17 B  28c ! too expensive!
        ;; get lowest bit of result
        txa
        cmp #120
        bcc :+
        ;; C=1 sub 120
        sbc #120
:       
        ;; now look up 2 bit mod
        tax
        lda DIV6TABLE,x
        ;; put lowest bit of /3 in C
        lsr
        
        ;; move in MM bits
        pla
        rol                     ; C bit
        rol                     ; M
        rol                     ; M

        ;; now have CMM
        tax

        rts


;;; Gives mod and div for A/6
;;; Y= A/6
;;; X= A%6
;;; 
moddiv6:   
;;; 27 B  44-45c
        ;; save original value
        tax

        ;; /2 and put /3 in Y
        lsr
        tay
        lda DIV6TABLE,y
        pha
        and #63
        tay

        ;; get lowest bit of result
        txa
        cmp #120
        bcc :+
        ;; C=1 sub 120
        sbc #120
:       
        ;; now look up 2 bit mod
        tax
        lda DIV6TABLE,x
        ;; put lowest bit of /3 in C
        lsr
        
        ;; move in MM bits
        pla
        rol                     ; C bit
        rol                     ; M
        rol                     ; M

        ;; now have CMM
        tax

        rts
        
        
        
;;; A    /6     %6      /3      %3
;;; 0 => 0	0       0       0
;;; 1 => 0      1       0       1
;;; 2 => 0      2       0       2
;;; 3 => 0      3       1       0
;;; 4 => 0      4       1       1
;;; 5 => 0      5       1       2

;;; 6 => 1      0       2       0
;;; 7 => 1      1       2       1
;;; 8 => 1      2       2       2
;;; 9 => 1      3       3       0
;;;10 => 1      4       3       1
;;;11 => 1      5       3       2

;;;12 => 2	0       4       0
;;;13 => 2      1       4       1
;;;  ...
