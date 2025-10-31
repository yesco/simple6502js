       52C9 jmp $0000

;;;  P() removed from listing 67 B

;;; F() function cost
;;; (+ 235   30  65     96     12   36   235) = 709
;;;    swap  if  a+b..  params jsr  pop swap

;;; Bytes
;;; (+ 23    25  42     52     3    10  8  23   4) = 190
;;;    swap                             r  swap  r
;;; 
;;; (+ 190 (* 7 4) 3 3 10 1) = 235


;;; Enter: SWAP
;;; (+ 7 13 3) = 23 B
;;; (+ 15 216 4) = 235 c

;;; (7 B)
;;; (15c)
       530C tsx 
       530D stx $0e
       530F ldy #$08
       5311 pla 
       5312 pla 
;;; (13 B)
;;; (27c * 8 = (* 27 8) = 216)
       5313 ldx $0069,x   `+1
       5316 pla 
       5317 sta $0069,y   `+1
       531A txa 
       531B pha 
       531C pla 
       531D dey 
       531E bne -13	=> $5313
;;; (3 B)
;;; (4c)
       5320 ldx $0e
       5322 txs 

     ;  if(!a)r=a+b+c+d;  C  D  E  C  D  E 
;;; TODO: optimize (or reverse !)
;;; IF

;;; (25 B)
;;; 30c
       5323 lda $6a   a
       5325 ldx $6b   a+1
       5327 ldy #$00
       5329 cmp #$00
       532B bne +4	=> $5331
       532D txa 
       532E bne +1	=> $5331
       5330 dey 
       5331 tya 
       5332 tax 
       5333 tay 
       5334 bne +6	=> $533C
       5336 txa 
       5337 bne +3	=> $533C
       5339 jmp $0000

     ;  r=a+b+c+d;  C  D  D  D  D  E  S  S  A 

;;; (42 B)
;;; 65c
       533C lda $6a   a
       533E ldx $6b   a+1
       5340 clc 
       5341 adc $6c   b
       5343 tay 
       5344 txa 
       5345 adc $6d   b+1
       5347 tax 
       5348 tya 
       5349 clc 
       534A adc $6e   c
       534C tay 
       534D txa 
       534E adc $6f   c+1
       5350 tax 
       5351 tya 
       5352 clc 
       5353 adc $70   d
       5355 tay 
       5356 txa 
       5357 adc $71   d+1
       5359 tax 
       535A tya 
       535B sta $8c   r
       535D stx $8d   r+1
       535F lda #$ff  ''

     ;  elser=F(a-1,b+1,d*2,c/2); 

;;; (96 B) lol?
;;; (+ 3 21 21 24 26) = 96c parameters
       5361 beq +3	=> $5366
       5363 jmp $0000
     ;  r=F(a-1,b+1,d*2,c/2);  C  D  D  E  W  W  C  D  D  E  W  W  C  D  D  E  W  W  C  D  D  E  W , W  C . D  E  S  S  A 
;;; (21c)
       5366 lda $6a   a
       5368 ldx $6b   a+1
       536A sec 
       536B sbc #$01
       536D bcs +1	=> $5370
       536F dex 
       5370 pha 
       5371 txa 
       5372 pha 
;;; (21c)
       5373 lda $6c   b
       5375 ldx $6d   b+1
       5377 clc 
       5378 adc #$01
       537A bcc +1	=> $537D
       537C inx 
       537D pha 
       537E txa 
       537F pha 
;;; (24c)
       5380 lda $70   d
       5382 ldx $71   d+1
       5384 asl 
       5385 tay 
       5386 txa 
       5387 rol 
       5388 tax 
       5389 tya 
       538A pha 
       538B txa 
       538C pha 
;;; (26c)
       538D lda $6e   c
       538F ldx $6f   c+1
       5391 tay 
       5392 txa 
       5393 lsl 
       5394 tax 
       5395 tya 
       5396 ror 
       5397 pha 
       5398 txa 
       5399 pha 

;;; (3 B)
;;; (12c)
       539A jsr $530c

;;; (10 B)
;;; (36c)
       539D tya 
       539E pla 
       539F pla 
       53A0 pla 
       53A1 pla 
       53A2 pla 
       53A3 pla 
       53A4 pla 
       53A5 pla 
       53A6 tya 

;;; (+ 6 6       6)
;;; (6)
       53A7 sta $8c   r
       53A9 stx $8d   r+1
     ;  r; ,,,, C . D  E , S  A  A 
;;; (6)
       53AB lda $8c   r
       53AD ldx $8d   r+1
     ;  }  B  N  N  O .

;;; swap === 235c
       53AF sta $0d
       53B1 stx $0f
       53B3 tsx 
       53B4 stx $0e
       53B6 ldy #$08
       53B8 pla 
       53B9 pla 
       53BA ldx $0069,x   `+1
       53BD pla 
       53BE sta $0069,y   `+1
       53C1 txa 
       53C2 pha 
       53C3 pla 
       53C4 dey 
       53C5 bne -13	=> $53BA
       53C7 ldx $0e
       53C9 txs 
       53CA lda $0d
       53CC ldx $0f
       53CE rts

     ;  a=4660;  C . D  E  S  A 
       53CF lda #$34  '4'
       53D1 ldx #$12
       53D3 sta $6a   a
       53D5 stx $6b   a+1
     ;  b=22136;  C . D  E  S  A 
       53D7 lda #$78  'x'
       53D9 ldx #$56
       53DB sta $6c   b
       53DD stx $6d   b+1
     ;  c=4386;  C . D  E  S  A 
       53DF lda #$22  '"'
       53E1 ldx #$11
       53E3 sta $6e   c
       53E5 stx $6f   c+1
     ;  d=13124;  C . D  E  S  A 
       53E7 lda #$44  'D'
       53E9 ldx #$33
       53EB sta $70   d
       53ED stx $71   d+1
     ;  e=0; , S  A 
       53EF lda #$00
       53F1 sta $72   e
       53F3 sta $73   e+1
     ;  r=F(22,0,1,65535);  W  W  W  C  D  E  W , W  C . D  E  S  A 
       53F5 lda #$16
       53F7 pha 
       53F8 lda #$00
       53FA pha 
       53FB lda #$00
       53FD pha 
       53FE pha 
       53FF lda #$01
       5401 pha 
       5402 lda #$00
       5404 pha 
       5405 lda #$ff  ''
       5407 ldx #$ff
       5409 pha 
       540A txa 
       540B pha 
       540C jsr $530c
       540F tya 
       5410 pla 
       5411 pla 
       5412 pla 
       5413 pla 
       5414 pla 
       5415 pla 
       5416 pla 
       5417 pla 
       5418 tya 
       5419 sta $8c   r
       541B stx $8d   r+1
     ;  returnr; , C . D  E , S  A  A 
       541D lda $8c   r
       541F ldx $8d   r+1
       5421 rts
     ;  }  B 
       5422 lda #$00
       5424 tax 
       5425 rts
     ;    P  P 
    
    
    OK 349  Bytes
