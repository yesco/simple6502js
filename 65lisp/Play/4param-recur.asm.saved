.zeropage
		sp: .res 1
		r0: .res 1
		r1: .res 1
		r2: .res 1
		r3: .res 1
		r4: .res 1
		r5: .res 1
		r6: .res 1
		r7: .res 1
		r8: .res 1
		r9: .res 1
		r10: .res 1
		r11: .res 1
		r12: .res 1
		r13: .res 1
		r14: .res 1
		r15: .res 1
		r16: .res 1
		r17: .res 1
		r18: .res 1
		r19: .res 1
		r20: .res 1
		r21: .res 1
		r22: .res 1
		r23: .res 1
		r24: .res 1
		r25: .res 1
		r26: .res 1
		r27: .res 1
		r28: .res 1
		r29: .res 1
		r30: .res 1
		r31: .res 1
		btmp0: .res 1
		btmp1: .res 1
		btmp2: .res 1
		btmp3: .res 1
.code

_fun:
	sec
	lda	sp
	sbc	#8
	sta	sp
	bcs	l10
	dec	sp+1
l10:
	lda	r1
	ldy	#1
	sta	(sp),y
	lda	r0
	dey
	sta	(sp),y
	lda	r3
	ldy	#3
	sta	(sp),y
	lda	r2
	dey
	sta	(sp),y
	lda	r5
	ldy	#5
	sta	(sp),y
	lda	r4
	dey
	sta	(sp),y
	lda	r7
	ldy	#7
	sta	(sp),y
	lda	r6
	dey
	sta	(sp),y
	ldy	#0
	lda	(sp),y
	iny
	ora	(sp),y
	beq	l4
l3:
	lda	#0
	sta	r3
	lda	#2
	sta	r2
	ldy	#7
	lda	(sp),y
	sta	r1
	dey
	lda	(sp),y
	sta	r0
;	jsr	___divint16
        jsr     $ffff
	sta	r6
	stx	r7
	ldy	#5
	lda	(sp),y
	tax
	dey
	lda	(sp),y
	stx	r31
	asl
	rol	r31
	ldx	r31
	sta	r4
	stx	r5
	dey
	lda	(sp),y
	tax
	dey
	lda	(sp),y
	clc
	adc	#1
	bcc	l11
	inx
l11:
	sta	r2
	stx	r3
	dey
	lda	(sp),y
	tax
	dey
	lda	(sp),y
	sec
	sbc	#1
	bcs	l12
	dex
l12:
	sta	r0
	stx	r1
	jsr	_fun
	jmp	l5
l4:
	ldy	#0
	lda	(sp),y
	clc
	ldy	#2
	adc	(sp),y
	sta	r0
	dey
	lda	(sp),y
	ldy	#3
	adc	(sp),y
	sta	r1
	lda	r0
	clc
	iny
	adc	(sp),y
	sta	r0
	lda	r1
	iny
	adc	(sp),y
	sta	r1
	lda	r0
	clc
	iny
	adc	(sp),y
	pha
	lda	r1
	iny
	adc	(sp),y
	tax
	pla
l5:
l1:
	sta	r31
	clc
	lda	sp
	adc	#8
	sta	sp
	bcc	l13
	inc	sp+1
l13:
	lda	r31
	rts
; stacksize=0+??
;	section	text
;	global	_main
_main:
	lda	#255
	sta	r7
	sta	r6
	lda	#0
	sta	r5
	lda	#1
	sta	r4
	lda	#0
	sta	r3
	sta	r2
	sta	r1
	sta	r0
	jsr	_fun
l14:
	rts
; stacksize=0+??
;	global	___divint16
