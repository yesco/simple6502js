;;; math-library for 6502
;;; 
;;; basically mul16 div16(mod?)



;;; jsk: haha!
zp_num1 = -2
zp_num2 = -4
zp_result = -6

.proc mul16

;;; wheler
;;; - https:  //dwheeler.com/6502/a-lang.txt

;;; A mul161616 instruction
;;; (if not used via subroutine)
;;; with the frame in the X register,
;;; offsets as -n from x and non-rereferenced
;;; variables would therefore be:


;;; 33B
LDA zp_num1,x                   ; 2 Low byte - used for addition so may as well keep in A
loop:   
LSR zp_num2+1,x                 ; 4
ROR zp_num2                     ; 6
BCC no_add                      ; 8
PHA                             ; 9
CLC                             ; 10
ADC zp_result,x                 ; 12
STA zp_result,x                 ; 14
LDA zp_num1+1,x                 ; 16
ADC zp_result+1,x               ; 18
STA zp_result+1,x               ; 20
PLA                             ; 21
no_add: 
BNE not_done                    ; 23
LDY zp_num2+1,x                 ; 25    check hi byte for also zero
BEQ done                        ; 27
not_done:       
ASL                             ; 28
ROL zp_num1+1,x                 ; 30
BCC loop                        ; 32 Always

rts

;;; That's 32 bytes to multiply 2 memory
;;; locations giving a third which, I think,
;;; would give the 68000 a run for its money
;;; even if it does have more memory. It also
;;; shaves off a clock cycle per instruction
;;; which should also put something in the bank
;;; ready for the occasional banking overhead.
.endproc

;;; TODO: 29% faster! (ok 5 bytes more...)
;;; choose mul16x16->16 CMD64 Kernal 38B 159c


;;; mul16x16->16 BBC
;;; from - https://github.com/TobyLobster/multiply_test/blob/main/tests/omult16.a
;;; 16 bit x 16 bit multiply, 16 bit result (low bytes)
;;; (carry set if overflow?)
;;; 
;;; -> 16 bits: X:hi, Y:lo

;;; 33B 223.69c
.proc mul16
        ldx #0
        ldy #0
loop:   
        ;; least sign bit of multiplicand
        lsr ptr1+1
        ror ptr1
        bcc skip        
        ;; Add the multiplier to the accumulator
        clc
        tya
        adc ptr2
        tay
        txa
        adc ptr2+1
        tax

        bcs overflow
skip:   
        ;; multiplier mul2
        asl ptr2
        rol ptr2+1

        ;; do while multiplicand not zero
        lda ptr1
        ora ptr1+1
        bne loop

        clc                     ; tobY: no overflow?

        ;; Save the accumulator as the answer
        ;;     sty multiplier
        ;;     stx multiplier+1
        ;; Exit

overflow:       
        rts
.endproc

;;; div16/16 - 40 Bytes
;;; - http://forum.6502.org/viewtopic.php?f=2&t=6258


;;; div16/8 divide ptr1 16-bits by ptr2 8-bits, result in ptr1
;;; 
;;; by strat @ nesdev forum ; 21B
;;; 
;;; out: A: remainder; X: 0; Y: unchanged
;;; 
;;; 40B
.proc div16_8_8
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  cmp ptr2
  bcc @no_sub
  sbc ptr2
  inc ptr1
@no_sub:
  dex
  bne @divloop

  rts
.endproc

;;; 16div16 => 16 ??? works?
;;; 
;;; 37B
.proc div16_16
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  ;; hi-byte cmp
  tay
  lda ptr1+1
  cmp ptr2+1        
  bcc @no_sub                   ; one off?
  tya

  ;; lo-byte cmp
  cmp ptr2
  bcc @no_sub

  ;; lo-byte sub
  sbc ptr2
  inc ptr1

  ;; hi-byte sub
  tay
  lda ptr1+1
  sbc ptr2+1
  sta ptr1+1
  tya
  
@no_sub:
  dex
  bne @divloop

  rts
.endproc
