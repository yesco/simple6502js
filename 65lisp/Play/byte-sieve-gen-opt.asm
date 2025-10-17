;;; This is edited generated code from CC02
;;; try to run

;;; 10x 10 = 2.1
;;; 259.384571
;;; 251.274321
;;; (- 259.384571 251.274321) = 8.11s
;;; (/ 8.11 259.384571)  3.12% faster

;;; 00162Er 2               bytesieve:
;;; 001746r 2               bytesieveend:
;;; (- #x1746 #x162e) = 280 bytes !!!

bytesieve:
;;; TODO: -3 B
;        jmp bmain
;;;      word T m N  O ain().{.m=8192 C 
bmain:   
        lda #$00
        ldx #$20
;;;      D  E .; S 
        sta $7a
        stx $7b
;;;      A a=malloc( X m C 
        lda $7a
        ldx $7b
;;;      D  E  X ) X  C 
        jsr _malloc
;;;      D  E .; S 
        sta $62
        stx $63
;;;      A n=0; S 
        lda #$00
        sta $7c
; TODO: remove this instruction BYTE and ./rrasm crashes...
;;;  hhmmmmmm
;;; and now opposite....!
;        sta $7d
;;;      A while(n<10 C 
while1: 
        lda #$0a
;;; remove this save -2 takes 1.4s longer!!!! WTF?
        ldx #$00
;;; BYTE -6 -4 (later)
;;;      D  E )
;        cpx $7d
;        bne :+
        cmp $7c
        beq :++
        :       
        bcs :++
        :       
        jmp end1
        :       
;;;     .{.c=0. S 
;;; ALSO uses tos, lol
;jsr nl
;lda $7c
;ldx $7d
;jsr axputu

        lda #$00
        sta $66
        sta $67
;;;      A  S 
;;; TODO: keep track of 0
;;;  save -2 
;        lda #$00
        sta $72
        sta $73
;;;      A  C 
while2: 
        lda $7a
        ldx $7b
;;;      D  E 
        cpx $73
        bne :+
        cmp $72
        beq :++
        :       
        bcs :++
        :       
        jmp end2
        :       
;;;    .. C 
        lda $62
        ldx $63
        clc 
        adc $72
        tay 
        txa 
        adc $73
        tax 
        tya 
;;;      D  D  E  G 
        sta $00
        stx $01
        lda #$01
;;; TODO: byte context -2
;;        ldx #$00
;;;      C 
        ldy #$00
        sta ($00),y
;;;      D  E  S  A ++i.; S 
        inc $72
        bne :+
        inc $73
;;;      A  U  C  D  E .} S  S 
        :       
        jmp while2
end2:   
;;;      A i=0; S 
        lda #$00
        sta $72
        sta $73
;;;      A while(i<m C 
while3: 
;;; TODO: if we knew we had it in AA, ahum -7B
        lda $7a
        ldx $7b
;;;      D  E )
        cpx $73
        bne :+
        cmp $72
        beq :++
        :       
        bcs :++
        :       
        jmp end3
;;;     .{.if(peek(a+ C 
        :       
        lda $62
        ldx $63
;;;     i
        clc 
        adc $72
        tay 
        txa 
        adc $73
        tax 
        tya 
;;;      D  D  E ) C 
        sta $00
        stx $01
        ldy #$00
        lda ($00),y
;;; BYTE - 5 B
;        ldx #$00
;;;      D  E )
        tay 
        bne :+
;        txa 
;        bne :+
        jmp if1
:       
;;;      .{.p=i C 
        lda $72
        ldx $73
;;;     *2
        asl 
        tay 
        txa 
        rol 
        tax 
        tya 
;;;      D +3
        clc 
        adc #$03
        bcc :+
        inx 
:       
;;;      D  D  E .; S 
        sta $80
        stx $81
;; also uses tos
;jsr spc
;lda $80
;ldx $81
;jsr axputu    
;jsr spc
;;;      A k=i+ C 
;;;   again, if kept track of variable, would save 4?
        lda $72
        ldx $73
;;;     p
        clc 
        adc $80
        tay 
        txa 
        adc $81
        tax 
        tya 
;;;      D  D  E ; S 
        sta $76
        stx $77
;;;      A while(k<m C 
while4: 
        lda $7a
        ldx $7b
;;;      D  E )
        cpx $77
        bne :+
        cmp $76
        beq :++
        :       
        bcs :++
        :       
        jmp end4
        :       
;;;     .{.poke(a+ C 
        lda $62
        ldx $63
;;;     k
        clc 
        adc $76
        tay 
        txa 
        adc $77
        tax 
        tya 
;;;      D  D  E ,0 G 
        sta $00
        stx $01
;;; ALSO uses tos, lol
;lda $00
;ldx $01
;jsr axputu

        lda #$00
;        tax 
;;; TODO: poke expects byte -1 
;;;     ) C 
        ldy #$00
        sta ($00),y
;;;      D  E .; S  A k+=p C 
        lda $80
        ldx $81
;;;      D  E .; S 
        clc 
        adc $76
        sta $76
        txa 
        adc $77
        sta $77
;;;      A  U  C  D  E .} S  S 
        jmp while4
end4:   
;;;      A ++c.; S 
        inc $66
        bne :+
        inc $67
        :       
;;;      A  U  C  D  E .} S  S 
        lda #$ff
if1:    
;;;      A ++i.; S 
        inc $72
        bne :+
        inc $73
        :       
;;;      A  U  C  D  E .} S  S 
        jmp while3
end3:   
;;;      A putu(c C 
        lda $66
        ldx $67
;;;      D  E ) C 
        jsr axputu
;;;      D  E .; S  A ++n.; S 
        inc $7c
;        bne :+
;        inc $7d
;        :       
;;;      A  U  C  D  E . S  S 
        jmp while1
end1:   
;;;      A  X  C 
        lda $62
        ldx $63
;;;      D  E  X  X  C 
        jsr _free
;;;      D  E . S  A  C 
        lda $66
        ldx $67
;;;      D  E . S 
        rts
;;;      A  U  C  D  E  B  P 
;;; ;; save if have return and know it? -4
;        lda #$00
;        tax 
;        rts
;;;      P 
bytesieveend:   
