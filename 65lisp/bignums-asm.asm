.zeropage

savea:  .res 1
savex:  .res 1
savey:  .res 1
savez:  .res 1                  ; lol!

tos:    .res 2
snd:    .res 2
trd:    .res 2

;;; ========================================
.code

.include "bios.asm"

PRINTHEX=1
.include "print.asm"

;;; ========================================






.data

anum:   .byte 1,0     
        .res 256
bnum:   .byte 1,1
        .res 256
cnum:   .byte 1,2
        .res 256

.code

.macro TOS num
        lda #<num
        sta tos
        lda #>num
        sta tos+1
.endmacro

.macro SND num
        lda #<num
        sta snd
        lda #>num
        sta snd+1
.endmacro

.macro TRD num
        lda #<num
        sta trd
        lda #>num
        sta trd+1
.endmacro

.export _initlisp
_initlisp:

        TOS anum
        jsr _bigprint
        NEWLINE
        
.ifnblank
        TOS bnum
        SND bnum
double: 
        jsr _bigprint
        NEWLINE
        
        jsr _bigadd
        jmp double
.endif

        ;; Multiplication a = b * c
        TOS anum
        SND bnum
        TRD cnum
        
mul:    
        jsr _bigmul
        jsr _bigprint
        NEWLINE

        ;; B = A
        ldy #0
        lda anum,y
        tay
copy:   
        lda anum,y
        sta bnum,y
        dey
        bpl copy

        jmp mul

        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'

halt:   jmp halt

;;; ========================================
;;;               B I G N U M S

.proc bignum 
        ldy #0
        lda (tos),y
        tay
        rts
.endproc

.proc _bigprint
        pha
        tya
        pha

        lda #'$'
        jsr putchar

        jsr bignum
next:   
        lda (tos),y
        jsr print2h
        dey
        bne next
        
        pla
        tay
        pla
        rts
.endproc

;;; uses savea
.proc _bigshl
        pha
        tya
        pha

        ldy #0
        lda (tos),y
        sta savea

;        jsr print2h

        clc
next:   
        iny
        lda (tos),y
        adc (tos),y
        sta (tos),y
        dec savex
        bne next
        
;;; TODO: same in _bigadd
        ;; extend?
        bcc ret

        inc savea
        iny
        
        ;; save carry
        lda #1
        sta (tos),y
ret:
        lda savea
        ldy #0
        sta (tos),y

        pla
        tay
        pla
        rts
.endproc

;;; cool >255 => 0 len == OVERFLOW!!!
;;; uses savey savea
.proc _bigadd
        pha
        tya
        pha

        ;; maxlen(tos, snd)
        ldy #0
        lda (tos),y
        sta savey
        
        lda (snd),y
        cmp savey
        bcc smaller
        sta savey
smaller:        
        lda savey
        sta savea

;        jsr print2h             ; not use y

        clc
next:   
        iny
;;; TODO: if one is out of data
;;;   we should replace by 0?
;;;   LUCKILY: it's all zero padded for now...
        lda (tos),y
        adc (snd),y
        sta (tos),y
        dec savey
        bne next
        
        ;; extend?
        bcc ret

        inc savea
        iny

        ;; save carry
        lda #1
        sta (tos),y
ret:

        lda savea
        ldy #0
        sta (tos),y
        
        pla
        tay
        pla
        rts
.endproc


;; TODO: doesn't handle overflow gracefully

;;; TOS RESULT
;;; SND FACTOR 1
;;; TRD FACTOR 2
;;; uses savez
.proc _bigmul
        pha
        tay
        pha

;;; 25 B !
        ;; todo find out which direction is faster!
        ;; snd < trd or other way around?

        ;; TOS = 0
        lda #1
        tay
        sta (tos),y
        iny
        sta (tos),y

        ldy #0
        lda (trd),y
        sta savez

nextbyte:   
        ldy savez
        lda (trd),y

        ldx #8
nextbit:        
        ;; shl TOS
        jsr _bigshl

        asl
        bcc noadd
        
;        PUTC '+'
        ;; TOS += SND if next high bit set in TRD
        jsr _bigadd

noadd:  
        PUTC '.'

        dex
        bne nextbit

;        PUTC ' '

        dec savez
        bne nextbyte
        
        pla
        tay
        pla
        rts
.endproc

;;; 1 byte 2 digits
; (+ (* 9 16) 9) = 153        


;;; (* 99 99) = 9801 (/ 9801 256) = 38


        
