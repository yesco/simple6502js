;;; This is edited generated code from CC02
;;; try to run

;;; TODO: it's not correct??? 00000 instead of 18991899...
bytesieve:
        jmp bmain
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
        sta $7d
;;;      A while(n<10 C 
while1: 
        lda #$0a
        ldx #$00
;;;      D  E )
        cpx $7d
        bne :+
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
        lda #$00
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
        ldx #$00
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
        ldx #$00
;;;      D  E )
        tay 
        bne :+
        txa 
        bne :+
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
        tax 
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
        bne :+
        inc $7d
        :       
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
        lda #$00
        tax 
        rts
;;;      P 
