.zeropage

savea:  .res 1
savex:  .res 1
savey:  .res 1
savez:  .res 1                  ; lol!

tos:    .res 2
snd:    .res 2
trd:    .res 2

tmp1:   .res 2

;;; ========================================
.code

.include "bios.asm"

PRINTHEX=1
;;; dummy
_drop:   rts

PRINTDECFAST=1
.include "print.asm"

.include "oric-timer.asm"

;;; ========================================






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

.data

anum:   .byte 1,0
        .res 256
bnum:   .byte 1,3
        .res 256
cnum:   .byte 1,1
        .res 256

zero:           .byte 1,0
one:            .byte 1,1
two:            .byte 1,2
overflow:       .byte 0

.code

.export _initlisp
_initlisp:

.ifnblank
        lda #'&'
        jsr putchar
halt2:  jmp halt2
.endif

        TOS anum
        jsr _bigprint
        NEWLINE

        TOS bnum
        jsr _bigprint
        NEWLINE

        TOS cnum
        jsr _bigprint
        NEWLINE
        
.ifnblank
        TOS bnum
        SND bnum
double: 
        jsr _bigprint
        NEWLINE
        
;        jsr _bigadd
        jsr _bigshl
        jmp double
.endif

        
mul:    
.ifnblank
        ;; b = b + a
        TOS bnum
        SND one
        jsr _bigadd
        jsr _bigprint
        PUTC ':'
.endif

;;; TODO: 
;;; 
;;; BUG: $0100 ^2 == $ff0000 ???? LOL
        PUTC 'c'
        TOS bnum
        PUTC '>'

        ;; Multiplication a = b * b
        TOS anum
        SND bnum
        TRD bnum

        jsr _resettime
        jsr _bigmul
        jsr _reporttime
        jsr _bigprint
        NEWLINE

;        jsr getchar

;;; TODO: hmmm, this makes "it work"
;;;  cleaning out garabare because
;;;  see TODO in add (different lengths)

        ;; B = A
        ldy #0
        lda anum,y
        tay
bcopy:   
        lda anum,y
        sta bnum,y
        dey
        bpl bcopy

.ifnblank
        ;; C = A
        ldy #0
        lda anum,y
        tay
ccopy:   
        lda anum,y
        sta cnum,y
        dey
        bpl ccopy
.endif

        jmp mul

        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'

halt:   jmp halt

;;; ========================================
;;;               B I G N U M S

;;; TODO: negatives

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

        ;; print size in bytes
        jsr bignum
        sty tmp1
        lda #0
        sta tmp1+1
        jsr _voidprinttmp1d

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

;;; writes zeroes
.proc _bigzero
        pha
        tya
        pha

;;; TODO: remove once "add" knows when to "stop"
        ldy #0
        tya
zeroa:   
        sta anum,y
        iny
        bne zeroa

        lda #0
        ldy #1
        sta (tos),y

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
        txa
        pha

        ldy #0
        lda (tos),y
        sta savea

;        jsr print2h

        clc
        tax
next:   
        iny
        lda (tos),y
        adc (tos),y
        sta (tos),y
        dex
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
        tax
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
        txa
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
        tax
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
        jsr _bigzero

        ;; Y= length bytes of factor 2
        ldy #0
        lda (trd),y
        tay

        ;; loop y times for y bytes
nextbyte:   
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
;        PUTC '.'
        dex
        bne nextbit

;        PUTC ' '

        dey
        bne nextbyte
        
        pla
        tay
        pla
        rts
.endproc

;;; 1 byte 2 digits
; (+ (* 9 16) 9) = 153        


;;; (* 99 99) = 9801 (/ 9801 256) = 38


        
