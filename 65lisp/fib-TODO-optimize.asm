  OK 286 Bytes (libs +605 bios +26)
  
;; TODO: savings TODO

;; (+ 12 10 6   3   1 2   1 12  6 6   1  6 6   1) = 73
;;;   P  < one  &=          P   oneone  oneone
;;; 
;;; one: fixed 6 B one param calls opt!
;; (+ 12 10 3 1 2 1 12 1 1) = 43


;;; GOAL
;; (- 286 73) = 213

;; cc65: 190 B :-( lol


     57AB jmp $58a8

; printh

;; prelude 17 B - save (- 17 5) 12 B!
     57AE tay 
     57AF lda $29
     57B1 pha 
     57B2 sty $29
     57B4 lda $2a
     57B6 pha 
     57B7 stx $2a
     57B9 lda #$10
     57BB pha 
     57BC lda #$32  '2'
     57BE pha 

; if (15<n) .... 27 B (if added optrule 17B) save 10?
     57BF lda #$0f
     57C1 ldx #$00
     57C3 ldy #$ff
     57C5 cpx $2a
     57C7 bne +2	=> $57CB
     57C9 cmp $29
     57CB bcc +1	=> $57CE
     57CD iny 
     57CE tya 
     57CF tax 
     57D0 tay 
     57D1 bne +7	=> $57DA
     57D3 txa 
     57D4 bne +4	=> $57DA
     57D6 clc 
     57D7 jmp $57f8
;;; TODO: one argument, can do straight jsr save 6 B!
; printh()
     57DA jmp $57f4
;;; cc65 3 B (jsr)
; n>>4
     57DD lda $29
     57DF ldx $2a
     57E1 stx $06
     57E3 lsr $06
     57E5 ror 
     57E6 lsr $06
     57E8 ror 
     57E9 lsr $06
     57EB ror 
     57EC lsr $06
     57EE ror 
     57EF ldx $06
; call printh
     57F1 jmp $57ae
     57F4 jsr $57dd
; then end - not needed as no else
     57F7 sec 
;;;  cc65: 11 B (jsr)
; n&= 15;    13 B if %d rule => 10 save 3 B
     57F8 lda #$0f
     57FA ldx #$00
     57FC and $29
     57FE sta $29
     5800 txa 
     5801 and $2a
     5803 sta $2a

;;; cc65: 18 B ! 
;;;   knows n<15 and no overflow possible!
;;; mc02: 32 B .... :-( lol
;;; if (n<10) putchar(n+'0');

;; cc65: 4 B ! it knows n<15 already!
;;  (but then it loads AX again, lol)
; if (n<10)
     5805 lda #$0a
     5807 ldx #$00
     5809 cpx a
     580C bne +4	=> $5812
     580E cmp $29
     5810 beq +2	=> $5814
     5812 bcs +3	=> $5817
     5814 jmp $5826
;;; TODO: (char) cast could save 5 B!
;; then: putchar(n+'0')
     5817 lda $29
     5819 ldx $2a
     581B clc 
     581C adc #$30  '0'
     581E bcc +1	=> $5821
     5820 inx 
     5821 jsr $0fb6
; could/should optimize 1 B
     5824 rts
; then end, not needed
     5825 sec 


;  (again char cast 5 B)
; putchar(n+'7')
     5826 lda $29
     5828 ldx $2a
     582A clc 
     582B adc #$37  '7'
     582D bcc +1	=> $5830
     582F inx 
     5830 jsr $0fb6
;; also save 1 B
     5833 rts
; added for safety 3 B (maybe could just rts? 2 B saved

;; why just an ldx ???? BUG  -- 2 B
     5834 ldx #$00
     5836 rts

;; cc65: 26 B
;; mc02: 20 B!

;; word add(a,b)
     5837 ldy #$02
     5839 jsr $0fe3

     583C lda $29
     583E ldx $2a
     5840 clc 
     5841 adc $2b
     5843 tay 
     5844 txa 
     5845 adc $2c
     5847 tax 
     5848 tya 
     5849 rts
; fun { return ...} should save 1 B!
     584A rts

;;; fib (2 param fun)

;prelude  17 B could save (- 17 5) 12 bytes!
     584B tay 
     584C lda $29
     584E pha 
     584F sty $29
     5851 lda $2a
     5853 pha 
     5854 stx $2a
     5856 lda #$10
     5858 pha 
     5859 lda #$32  '2'
     585B pha 
; cc65: 26 B (incl return/goto)
; cc02: 22 B !
; if (n<2) ...   17B ("optimal 14 B) ??? TODO?
     585C lda #$02
     585E ldx #$00
     5860 cpx a
     5863 bne +4	=> $5869
     5865 cmp $29
     5867 beq +2	=> $586B
     5869 bcs +3	=> $586E
     586B jmp $5874
;  return n;
     586E lda $29
     5870 ldx $2a
     5872 rts


; return add( fib(n-1) , fib(n-2) )
     5873 sec 

;; LOL, looks funny! jmp jmp
; sets up add call (2 args)
     5874 jmp $58a3
; sets up fib call (not needed) - save 6 B
     5877 jmp $5887
     587A lda $29
     587C ldx $2a
     587E sec 
     587F sbc #$01
     5881 bcs +1	=> $5884
     5883 dex 
     5884 jmp $584b
     5887 jsr $587a

; push first arg to add!
     588A pha 
     588B txa 
     588C pha 

; fib(n-2) ..........  TODO: save 6 B
     588D jmp $589d
     5890 lda $29
     5892 ldx $2a
     5894 sec 
     5895 sbc #$02
     5897 bcs +1	=> $589A
     5899 dex 
     589A jmp $584b
     589D jsr $5890

     58A0 jmp $5837
     58A3 jsr $5877
; should tail jmp intead of rts TODO: save 1 B
     58A6 rts
; one not needed here - 1 B
     58A7 rts

;;; printh(0x4321);  - one arg save 6 B!
     58A8 jmp $58b2
     58AB lda #$21  '!'
     58AD ldx #$43
     58AF jmp $57ae
     58B2 jsr $58ab

;;; return fib(24); - save 6 B
     58B5 jmp $58bf
     58B8 lda #$18
     58BA ldx #$00
     58BC jmp $584b
     58BF jsr $58b8
; tail call save 1 B
     58C2 rts

;;; WHAT?????           - save 2 B?
     58C3 ldx #$00

     58C5 lda #$00
     58C7 tax 
     58C8 rts
   
  
  5536825 cycles
  --- EXIT=0 ---
  



seconds simulated time
~/GIT/simple6502js/65lisp $ ;; cc65: 26 B!
bash: syntax error near unexpected token `;;'
~/GIT/simple6502js/65lisp $ ;; TODO: save 
bash: syntax error near unexpected token `;;'
~/GIT/simple6502js/65lisp $ 
