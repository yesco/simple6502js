;;; math-library for 6502
;;; 
;;; basically mul16 div16(mod?)


;;; 9 ops from _MUL16 macro in
;;; - https://atariwiki.org/wiki/Wiki.jsp?page=6502%20Coding%20Algorithms%20Macro%20Library
;;; 
;;; top= A*B (A is trashed, B remains, both are popped)
;;; 
;;; 0x0: 11, $33x$164: 14 (rev 14), $ffff^2: 25 (25 same as mulx)
;;; 
;;; 32 B
        ;; top= 0 (push 0 => stack: A B 0 ; A,B in "memstack")
.proc _mulx
        jsr _zero

        ;; loop 16
        ldy #16
        sty savey
loop:   
        ;; result = result*2
        jsr _mul2

        ;; A *= 2 => carry
        asl stack+2,x          
        rol stack+2+1,x
        bcc noadd

        ;; tos += B (perfect it stays there)
        jsr _plus
        dex
        dex
noadd:  
        dec savey
        bne loop

        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts
.endproc


;;; 38 - more efficent if second number is small
;;;    ( 6 byte more ...)
;;; 0x0: 2, $33x$164: 8 (rev: 10), $ffff^2: 25 (25 same as mulx)
.proc _muly
        jsr _zero
loop:   
        ;; done when B is 0
        lda stack+2,x
        ora stack+2+1,x
        beq done

        ;; A *= 2 => carry
        lsr stack+2+1,x
        ror stack+2,x
        bcc noadd

        ;; tos += B (perfect it stays there)
        jsr _plus
        dex
        dex
noadd:  
        ;; A *= 2
        asl stack,x
        rol stack+1,x
        jmp loop

done:   
        ;; drop A,B (top remains)
inx4rts:        
        inx
        inx
        inx
        inx
        rts
.endproc

_mul=_mulx
;_mul=_muly


;;; (- (* 6 256) 1379) = 157 bytes before page boudary



;;; jsk: mydiv (S D -> S/D)
;;; 
;;; 2025-06-28
;;; 
;;; TOOD: - how is different from jskVL02
;;; 
;;; 100x => 35-39cs
;;; 
;;; 39 B - does work! (3: 1 clc needed - verified, 2 bne)
.proc _divmodx   
        jsr _zero
;;; TODO: if 16 it hangs - why?
;;;   (yes 17 is correct as we want to move in last bit)
        ldy #17                 ; avoid first clc!
        sty savey

next:   
        ;; shift in one bit result into S
        rol stack+2,x
        rol stack+2+1,x

        ;; done?
        dec savey
        beq done

        ;; shift in one hi bit from S into tos
        rol tos
        rol tos+1

        ;; tos -= D (reverse _minus)
        jsr _rminus
        dex
        dex

        ;; C=1 if subtract ok (?)
        bcs next

        ;; no, too big

        ;; add B back, lol
        jsr _plus
        dex
        dex
        clc
        ;; carry must be clear (why isn't?)
        ;; (to be shifted in)
        ;; loop Z=0 always
;;; TODO: jskVL02 does the loop differently
        bne next

done:   
        inx
        inx
        ;; tos= remainder stack: quotient
        rts
.endproc


;;; 100x => 13cs ! (_divmodx => 23-39cs)
;;; 
;;; 44 B (_divmodx => 39 B)
.proc _divmody
        jsr _zero
        ldy #17                 ; avoid first clc!
        sty savey

next:   
        ;; shift in one bit result into S
        rol stack+2,x
        rol stack+2+1,x

        ;; done?
        dec savey
        beq done

        ;; shift in one hi bit from S into tos
        rol tos
        rol tos+1

        lda tos
        sec
        sbc stack,x
        tay
        lda tos+1
        sbc stack+1,x

        bcc next
        ;; ok - store new
        sta tos+1
        sty tos

        bcs next

done:   
        inx
        inx
        ;; tos= remainder stack: quotient
        rts
.endproc


_divmod=_divmodx
;_divmod=_divmody





;--------------------------------------------------
;;;  OLD STUFF OF COLLECTED MUL16 and DIV16
;;; 
;;;        I G N O R E !
;;; 

.ifnblank


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

.endif
