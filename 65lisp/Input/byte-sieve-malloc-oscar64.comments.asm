#xfc = 252 bytes -Os
#xf3 = 243 bytes -Oz -Os === this file

(- #x972 #x880) = 242 !!!

objects by size
0973 (026a) : printf, NATIVE_CODE:code
0c21 (011b) : nformi, NATIVE_CODE:code
0880 (00f3) : main, NATIVE_CODE:code
0dc4 (00ce) : crt_malloc, NATIVE_CODE:code
0d3f (0085) : divmod, NATIVE_CODE:code
0801 (0052) : startup, NATIVE_CODE:startup
0be5 (003c) : puts, NATIVE_CODE:code
9fba (0032) : buff, BSS:printf@stack
9fec (0010) : buffer, BSS:nformi@stack
0bdd (0008) : puts@proxy, NATIVE_CODE:code
9fb2 (0008) : si, BSS:printf@stack
0e97 (0004) : HeapNode, DATA:bss
9ffc (0004) : sstack, STACK:sstack
00f7 (0002) : i, DATA:zeropage
0e93 (0002) : n, DATA:bss
0e95 (0002) : c, DATA:bss
0e92 (0001) : spentry, DATA:data
00f7 (0000) : ZeroStart, START:zeropage
00f9 (0000) : ZeroEnd, END:zeropage
0e93 (0000) : BSSStart, START:bss
0e9b (0000) : BSSEnd, END:bss
0ea0 (0000) : HeapStart, START:heap
9000 (0000) : HeapEnd, END:heap
9fb2 (0000) : StackEnd, END:stack


; Compiled with 1.32.266
--------------------------------------------------------------------
i:
00f7 : __ __ __ BYT 00 00                                           : ..
--------------------------------------------------------------------
startup: ; startup
0801 : 0b __ __ INV
0802 : 08 __ __ PHP
0803 : 0a __ __ ASL
0804 : 00 __ __ BRK
0805 : 9e __ __ INV
0806 : 32 __ __ INV
0807 : 30 36 __ BMI $083f ; (startup + 62)
0809 : 31 00 __ AND ($00),y 
080b : 00 __ __ BRK
080c : 00 __ __ BRK
080d : ba __ __ TSX
080e : 8e 92 0e STX $0e92 ; (spentry + 0)
0811 : a2 0e __ LDX #$0e
0813 : a0 93 __ LDY #$93
0815 : a9 00 __ LDA #$00
0817 : 85 19 __ STA IP + 0 
0819 : 86 1a __ STX IP + 1 
081b : e0 0e __ CPX #$0e
081d : f0 0b __ BEQ $082a ; (startup + 41)
081f : 91 19 __ STA (IP + 0),y 
0821 : c8 __ __ INY
0822 : d0 fb __ BNE $081f ; (startup + 30)
0824 : e8 __ __ INX
0825 : d0 f2 __ BNE $0819 ; (startup + 24)
0827 : 91 19 __ STA (IP + 0),y 
0829 : c8 __ __ INY
082a : c0 9b __ CPY #$9b
082c : d0 f9 __ BNE $0827 ; (startup + 38)
082e : a9 00 __ LDA #$00
0830 : a2 f7 __ LDX #$f7
0832 : d0 03 __ BNE $0837 ; (startup + 54)
0834 : 95 00 __ STA $00,x 
0836 : e8 __ __ INX
0837 : e0 f9 __ CPX #$f9
0839 : d0 f9 __ BNE $0834 ; (startup + 51)
083b : a9 b0 __ LDA #$b0
083d : 85 23 __ STA SP + 0 
083f : a9 9f __ LDA #$9f
0841 : 85 24 __ STA SP + 1 
0843 : 20 80 08 JSR $0880 ; (main.s4 + 0)
0846 : a9 4c __ LDA #$4c
0848 : 85 54 __ STA $54 
084a : a9 00 __ LDA #$00
084c : 85 13 __ STA P6 
084e : a9 19 __ LDA #$19
0850 : 85 16 __ STA P9 
0852 : 60 __ __ RTS
--------------------------------------------------------------------
main: ; main()->i16



;   9, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"
.s4:



;  12, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -   n=0; do {
;;; 

;;; O vs MC : +2 zp

0880 : a9 00 __ LDA #$00
0882 : 8d 93 0e STA $0e93 ; (n + 0)
0885 : 8d 94 0e STA $0e94 ; (n + 1)



;  11, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;;
;;; -   flag= malloc(m);
;;; 

;;; O vs MC : -2 reusing, sta+sta +4
0888 : 85 1b __ STA ACCU + 0 
088a : a9 20 __ LDA #$20
088c : 85 1c __ STA ACCU + 1 
088e : 20 c4 0d JSR $0dc4 ; (crt_malloc + 0)

;;; O vs MC : +4 read
0891 : a5 1b __ LDA ACCU + 0 
0893 : 85 51 __ STA T4 + 0 
0895 : a5 1c __ LDA ACCU + 1 
0897 : 85 52 __ STA T4 + 1 
.l5:



;  13, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     c=0;
;;; 

;;; O vs MC : +2 no zp
0899 : a9 00 __ LDA #$00
089b : 8d 95 0e STA $0e95 ; (c + 0)
089e : 8d 96 0e STA $0e96 ; (c + 1)



;  14, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     i=0; do flag[i++]= 1; while(i<m);
;;; 

;;; O vs MC : inline memset? == 32 B
08a1 : a5 51 __ LDA T4 + 0 
08a3 : 85 43 __ STA T0 + 0 

08a5 : a5 52 __ LDA T4 + 1 
08a7 : 85 44 __ STA T0 + 1 

08a9 : a9 e0 __ LDA #$e0
08ab : 85 50 __ STA T1 + 1 
08ad : a2 00 __ LDX #$00
08af : a0 00 __ LDY #$00
.l13:
08b1 : a9 01 __ LDA #$01
08b3 : 91 43 __ STA (T0 + 0),y 
08b5 : c8 __ __ INY
08b6 : d0 02 __ BNE $08ba ; (main.s17 + 0)
.s16:
08b8 : e6 44 __ INC T0 + 1 
.s17:
08ba : e8 __ __ INX
08bb : d0 f4 __ BNE $08b1 ; (main.l13 + 0)
.s14:



;  14, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;;
;;; -   i=0; do flag[i++]= 1; while(i<m);
;;;

;;; O vs MC : maybe it prepared T1 before?
08bd : e6 50 __ INC T1 + 1 
08bf : d0 f0 __ BNE $08b1 ; (main.l13 + 0)
.s6:



;  15, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     i=0; do {
;;; 

08c1 : 86 f7 __ STX $f7 ; (i + 0)
08c3 : 86 f8 __ STX $f8 ; (i + 1)



;  16, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -       if (flag[i]) {
;;; 

;;; 
08c5 : 18 __ __ CLC
.l7:
08c6 : a5 51 __ LDA T4 + 0 
08c8 : 65 f7 __ ADC $f7 ; (i + 0)
08ca : 85 4f __ STA T1 + 0 
08cc : a5 52 __ LDA T4 + 1 
08ce : 65 f8 __ ADC $f8 ; (i + 1)
08d0 : 85 50 __ STA T1 + 1 
08d2 : a0 00 __ LDY #$00
;;; ???
08d4 : a6 f7 __ LDX $f7 ; (i + 0)
08d6 : b1 4f __ LDA (T1 + 0),y 
;;; O vs MC : -3 local/small jmp
08d8 : f0 46 __ BEQ $0920 ; (main.s9 + 0)
.s8:



;  17, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         p= i+i+3;
;;; 

;;; O vs MC : i+i => i*2 = 9 B (add = 13) -4 B!
08da : 8a __ __ TXA
08db : 0a __ __ ASL
08dc : a8 __ __ TAY
08dd : a5 f8 __ LDA $f8 ; (i + 1)
08df : 2a __ __ ROL
08e0 : 85 50 __ STA T1 + 1 
08e2 : 98 __ __ TYA

;;; same 9 B (tay/inc/inc/inc/cmp2/bcc ./ = 10)
08e3 : 18 __ __ CLC
08e4 : 69 03 __ ADC #$03
08e6 : 85 4f __ STA T1 + 0 
08e8 : 90 03 __ BCC $08ed ; (main.s19 + 0)
.s18:
08ea : e6 50 __ INC T1 + 1 



;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -          flag[k]= 0;
;;; 

;;; already k ? in register?
08ec : 18 __ __ CLC
.s19:
08ed : 8a __ __ TXA
08ee : 65 4f __ ADC T1 + 0 
08f0 : a8 __ __ TAY
08f1 : a5 f8 __ LDA $f8 ; (i + 1)
08f3 : 65 50 __ ADC T1 + 1 
08f5 : 85 46 __ STA T2 + 1 



;  22, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         ++c;
;;; 

;;; same
08f7 : ee 95 0e INC $0e95 ; (c + 0)
08fa : d0 03 __ BNE $08ff ; (main.s21 + 0)
.s20:
08fc : ee 96 0e INC $0e96 ; (c + 1)
.s21:



;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         k=i+p; while(k<m) {
;;; 

;;; O vs MC : only 4 bytes?
08ff : c9 20 __ CMP #$20
0901 : b0 1d __ BCS $0920 ; (main.s9 + 0)
.s15:



;  19, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -           flag[k]= 0;
;;; 

;;; O vs MC : hmmm? reuse some value? (from if?)
;;;              -2 reusing Y 
0903 : a5 51 __ LDA T4 + 0 
0905 : 85 47 __ STA T3 + 0 
.l22:
0907 : a5 52 __ LDA T4 + 1 
0909 : 65 46 __ ADC T2 + 1 
090b : 85 48 __ STA T3 + 1 
090d : a9 00 __ LDA #$00
090f : 91 47 __ STA (T3 + 0),y 



;  20, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -           k+=p;
;;; 

;;; O vs MC : k/p already in reg -4 (add 13 B)
;;;     == 11 B not storing lo? keep in Y
0911 : 98 __ __ TYA
0912 : 18 __ __ CLC
0913 : 65 4f __ ADC T1 + 0 
0915 : a8 __ __ TAY
0916 : a5 46 __ LDA T2 + 1 
0918 : 65 50 __ ADC T1 + 1 
091a : 85 46 __ STA T2 + 1 



;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -        k=i+p; while(k<m) {
;;; 

;;;  hmmm, it inlined m and NOT test lo byte!
;;;   saves -6 B (?)
091c : c9 20 __ CMP #$20
091e : 90 e7 __ BCC $0907 ; (main.l22 + 0)
.s9:



;  24, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -       ++i;
;;; 

;;; LOL, why ? not saved == 12
0920 : 8a __ __ TXA
0921 : 18 __ __ CLC
0922 : 69 01 __ ADC #$01
0924 : 85 f7 __ STA $f7 ; (i + 0)
0926 : a5 f8 __ LDA $f8 ; (i + 1)
0928 : 69 00 __ ADC #$00
092a : 85 f8 __ STA $f8 ; (i + 1)
;;;  but equiv? 8 B (save 4!)
        inx
        sta $f7
        bne :+
        inc $f8
:       
        txa


;  25, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     } while(i<m);
;;; 

;;; clever loop recognize low byte == 0 at test!
092c : c9 20 __ CMP #$20
092e : 90 96 __ BCC $08c6 ; (main.l7 + 0)
.s10:



;  26, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     printf("%u", c);
;;; 

;;; ???
0930 : ad 95 0e LDA $0e95 ; (c + 0)
0933 : 85 4f __ STA T1 + 0 
0935 : 8d fe 9f STA $9ffe ; (sstack + 2)

;;; O vs MC : 21 B - too much! MC: 13 
;;;      actually just: lda/ldx/jsr putu == 7 B
;;; 
;;;   O waste + 14 B!!!

;;; "%u"
0938 : a9 3c __ LDA #$3c
093a : 8d fc 9f STA $9ffc ; (sstack + 0)
093d : a9 0d __ LDA #$0d
093f : 8d fd 9f STA $9ffd ; (sstack + 1)

;;; ,c 
0942 : ad 96 0e LDA $0e96 ; (c + 1)
0945 : 85 50 __ STA T1 + 1 
0947 : 8d ff 9f STA $9fff ; (sstack + 3)

094a : 20 73 09 JSR $0973 ; (printf.s4 + 0)



;  27, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     ++n;
;;; 

;;; O vs MC : 17 B - alot! MC 6B => + 11 B !!!!
094d : ad 93 0e LDA $0e93 ; (n + 0)
0950 : 18 __ __ CLC
0951 : 69 01 __ ADC #$01
0953 : 8d 93 0e STA $0e93 ; (n + 0)
0956 : ad 94 0e LDA $0e94 ; (n + 1)
0959 : 69 00 __ ADC #$00
095b : 8d 94 0e STA $0e94 ; (n + 1)



;  28, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -  } while(n<10);
;;; 

;;; O 12 vs MC 11 : just sta no ldx save -2
;;;  but  ... +3    =>  +1 B !
095e : d0 0a __ BNE $096a ; (main.s11 + 0)
.s12:
0960 : ad 93 0e LDA $0e93 ; (n + 0)
0963 : c9 0a __ CMP #$0a
0965 : b0 03 __ BCS $096a ; (main.s11 + 0)
0967 : 4c 99 08 JMP $0899 ; (main.l5 + 0)
.s11:



;  29, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -   return c;
;;; 

;;; O 9B vs MC 5+ 4 (default ret 0) == same!
096a : a5 4f __ LDA T1 + 0 
096c : 85 1b __ STA ACCU + 0 
096e : a5 50 __ LDA T1 + 1 
0970 : 85 1c __ STA ACCU + 1 
.s3:
0972 : 60 __ __ RTS



--------------------------------------------------------------------
printf: ; printf(const u8*)->void
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.s4:
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0973 : ad fc 9f LDA $9ffc ; (sstack + 0)
0976 : 85 4a __ STA T4 + 0 
0978 : a9 fe __ LDA #$fe
097a : 85 48 __ STA T2 + 0 
097c : a9 9f __ LDA #$9f
097e : 85 49 __ STA T2 + 1 
; 356, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0980 : a9 00 __ LDA #$00
0982 : 85 4e __ STA T7 + 0 
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0984 : ad fd 9f LDA $9ffd ; (sstack + 1)
0987 : 85 4b __ STA T4 + 1 
.l5:
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0989 : a0 00 __ LDY #$00
098b : b1 4a __ LDA (T4 + 0),y 
098d : d0 0c __ BNE $099b ; (printf.s6 + 0)
.s62:
; 543, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
098f : a6 4e __ LDX T7 + 0 
0991 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 544, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0994 : 8a __ __ TXA
0995 : d0 01 __ BNE $0998 ; (printf.s63 + 0)
.s3:
; 559, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0997 : 60 __ __ RTS
.s63:
; 547, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0998 : 4c dd 0b JMP $0bdd ; (puts@proxy + 0)
.s6:
; 361, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
099b : c9 25 __ CMP #$25
099d : f0 28 __ BEQ $09c7 ; (printf.s7 + 0)
.s60:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
099f : a6 4e __ LDX T7 + 0 
09a1 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a4 : e6 4a __ INC T4 + 0 
09a6 : d0 02 __ BNE $09aa ; (printf.s83 + 0)
.s82:
09a8 : e6 4b __ INC T4 + 1 
.s83:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09aa : e8 __ __ INX
09ab : 86 4e __ STX T7 + 0 
; 530, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ad : e0 28 __ CPX #$28
09af : 90 d8 __ BCC $0989 ; (printf.l5 + 0)
.s61:
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b1 : a9 ba __ LDA #$ba
09b3 : 85 0d __ STA P0 
09b5 : a9 9f __ LDA #$9f
09b7 : 85 0e __ STA P1 
; 534, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b9 : 98 __ __ TYA
09ba : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
.s52:
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09bd : 20 e5 0b JSR $0be5 ; (puts.l4 + 0)
; 539, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c0 : a9 00 __ LDA #$00
.s68:
09c2 : 85 4e __ STA T7 + 0 
09c4 : 4c 89 09 JMP $0989 ; (printf.l5 + 0)
.s7:
; 363, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c7 : a5 4e __ LDA T7 + 0 
09c9 : f0 0c __ BEQ $09d7 ; (printf.s9 + 0)
.s8:
09cb : aa __ __ TAX
; 367, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09cc : 98 __ __ TYA
09cd : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 368, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d0 : 20 dd 0b JSR $0bdd ; (puts@proxy + 0)
; 372, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d3 : a9 00 __ LDA #$00
09d5 : 85 4e __ STA T7 + 0 
.s9:
; 380, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d7 : 8d b7 9f STA $9fb7 ; (si.sign + 0)
; 381, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09da : 8d b8 9f STA $9fb8 ; (si.left + 0)
; 382, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09dd : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e0 : a0 01 __ LDY #$01
09e2 : b1 4a __ LDA (T4 + 0),y 
; 379, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e4 : a2 20 __ LDX #$20
09e6 : 8e b2 9f STX $9fb2 ; (si.fill + 0)
; 377, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e9 : a2 00 __ LDX #$00
09eb : 8e b3 9f STX $9fb3 ; (si.width + 0)
; 378, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ee : ca __ __ DEX
09ef : 8e b4 9f STX $9fb4 ; (si.precision + 0)
; 376, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f2 : a2 0a __ LDX #$0a
09f4 : 8e b6 9f STX $9fb6 ; (si.base + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f7 : aa __ __ TAX
09f8 : a9 02 __ LDA #$02
09fa : d0 07 __ BNE $0a03 ; (printf.l10 + 0)
.s12:
; 396, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09fc : a0 00 __ LDY #$00
09fe : b1 4a __ LDA (T4 + 0),y 
0a00 : aa __ __ TAX
0a01 : a9 01 __ LDA #$01
.l10:
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a03 : 18 __ __ CLC
0a04 : 65 4a __ ADC T4 + 0 
0a06 : 85 4a __ STA T4 + 0 
0a08 : 90 02 __ BCC $0a0c ; (printf.s73 + 0)
.s72:
0a0a : e6 4b __ INC T4 + 1 
.s73:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a0c : 8a __ __ TXA
0a0d : e0 2b __ CPX #$2b
0a0f : d0 07 __ BNE $0a18 ; (printf.s13 + 0)
.s11:
; 387, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a11 : a9 01 __ LDA #$01
0a13 : 8d b7 9f STA $9fb7 ; (si.sign + 0)
0a16 : d0 e4 __ BNE $09fc ; (printf.s12 + 0)
.s13:
; 388, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a18 : c9 30 __ CMP #$30
0a1a : d0 06 __ BNE $0a22 ; (printf.s15 + 0)
.s14:
; 389, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a1c : 8d b2 9f STA $9fb2 ; (si.fill + 0)
0a1f : 4c fc 09 JMP $09fc ; (printf.s12 + 0)
.s15:
; 390, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a22 : c9 23 __ CMP #$23
0a24 : d0 07 __ BNE $0a2d ; (printf.s17 + 0)
.s16:
; 391, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a26 : a9 01 __ LDA #$01
0a28 : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
0a2b : d0 cf __ BNE $09fc ; (printf.s12 + 0)
.s17:
; 392, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a2d : c9 2d __ CMP #$2d
0a2f : d0 07 __ BNE $0a38 ; (printf.s19 + 0)
.s18:
; 393, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a31 : a9 01 __ LDA #$01
0a33 : 8d b8 9f STA $9fb8 ; (si.left + 0)
0a36 : d0 c4 __ BNE $09fc ; (printf.s12 + 0)
.s19:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a38 : 85 4c __ STA T5 + 0 
; 399, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a3a : c9 30 __ CMP #$30
0a3c : 90 31 __ BCC $0a6f ; (printf.s25 + 0)
.s20:
0a3e : c9 3a __ CMP #$3a
0a40 : b0 5e __ BCS $0aa0 ; (printf.s31 + 0)
.s21:
; 401, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a42 : a9 00 __ LDA #$00
0a44 : 85 46 __ STA T1 + 0 
.l22:
; 404, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a46 : a5 46 __ LDA T1 + 0 
0a48 : 0a __ __ ASL
0a49 : 0a __ __ ASL
0a4a : 18 __ __ CLC
0a4b : 65 46 __ ADC T1 + 0 
0a4d : 0a __ __ ASL
0a4e : 18 __ __ CLC
0a4f : 65 4c __ ADC T5 + 0 
0a51 : 38 __ __ SEC
0a52 : e9 30 __ SBC #$30
0a54 : 85 46 __ STA T1 + 0 
; 405, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a56 : a0 00 __ LDY #$00
0a58 : b1 4a __ LDA (T4 + 0),y 
0a5a : 85 4c __ STA T5 + 0 
0a5c : e6 4a __ INC T4 + 0 
0a5e : d0 02 __ BNE $0a62 ; (printf.s81 + 0)
.s80:
0a60 : e6 4b __ INC T4 + 1 
.s81:
; 402, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a62 : c9 30 __ CMP #$30
0a64 : 90 04 __ BCC $0a6a ; (printf.s24 + 0)
.s23:
0a66 : c9 3a __ CMP #$3a
0a68 : 90 dc __ BCC $0a46 ; (printf.l22 + 0)
.s24:
; 407, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a6a : a6 46 __ LDX T1 + 0 
0a6c : 8e b3 9f STX $9fb3 ; (si.width + 0)
.s25:
; 410, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a6f : c9 2e __ CMP #$2e
0a71 : d0 2d __ BNE $0aa0 ; (printf.s31 + 0)
.s26:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a73 : a9 00 __ LDA #$00
0a75 : f0 0e __ BEQ $0a85 ; (printf.l27 + 0)
.s29:
; 416, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a77 : a5 43 __ LDA T0 + 0 
0a79 : 0a __ __ ASL
0a7a : 0a __ __ ASL
0a7b : 18 __ __ CLC
0a7c : 65 43 __ ADC T0 + 0 
0a7e : 0a __ __ ASL
0a7f : 18 __ __ CLC
0a80 : 65 4c __ ADC T5 + 0 
0a82 : 38 __ __ SEC
0a83 : e9 30 __ SBC #$30
.l27:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a85 : 85 43 __ STA T0 + 0 
; 417, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a87 : a0 00 __ LDY #$00
0a89 : b1 4a __ LDA (T4 + 0),y 
0a8b : 85 4c __ STA T5 + 0 
0a8d : e6 4a __ INC T4 + 0 
0a8f : d0 02 __ BNE $0a93 ; (printf.s75 + 0)
.s74:
0a91 : e6 4b __ INC T4 + 1 
.s75:
; 414, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a93 : c9 30 __ CMP #$30
0a95 : 90 04 __ BCC $0a9b ; (printf.s30 + 0)
.s28:
0a97 : c9 3a __ CMP #$3a
0a99 : 90 dc __ BCC $0a77 ; (printf.s29 + 0)
.s30:
; 419, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a9b : a6 43 __ LDX T0 + 0 
0a9d : 8e b4 9f STX $9fb4 ; (si.precision + 0)
.s31:
; 422, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aa0 : c9 64 __ CMP #$64
0aa2 : f0 0c __ BEQ $0ab0 ; (printf.s32 + 0)
.s34:
0aa4 : c9 44 __ CMP #$44
0aa6 : f0 08 __ BEQ $0ab0 ; (printf.s32 + 0)
.s35:
0aa8 : c9 69 __ CMP #$69
0aaa : f0 04 __ BEQ $0ab0 ; (printf.s32 + 0)
.s36:
0aac : c9 49 __ CMP #$49
0aae : d0 11 __ BNE $0ac1 ; (printf.s37 + 0)
.s32:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ab0 : a0 00 __ LDY #$00
0ab2 : b1 48 __ LDA (T2 + 0),y 
0ab4 : 85 11 __ STA P4 
0ab6 : c8 __ __ INY
0ab7 : b1 48 __ LDA (T2 + 0),y 
0ab9 : 85 12 __ STA P5 
0abb : 98 __ __ TYA
.s69:
0abc : 85 13 __ STA P6 
0abe : 4c ba 0b JMP $0bba ; (printf.s33 + 0)
.s37:
; 426, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ac1 : c9 75 __ CMP #$75
0ac3 : f0 04 __ BEQ $0ac9 ; (printf.s38 + 0)
.s39:
0ac5 : c9 55 __ CMP #$55
0ac7 : d0 0f __ BNE $0ad8 ; (printf.s40 + 0)
.s38:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ac9 : a0 00 __ LDY #$00
0acb : b1 48 __ LDA (T2 + 0),y 
0acd : 85 11 __ STA P4 
0acf : c8 __ __ INY
0ad0 : b1 48 __ LDA (T2 + 0),y 
0ad2 : 85 12 __ STA P5 
0ad4 : a9 00 __ LDA #$00
0ad6 : f0 e4 __ BEQ $0abc ; (printf.s69 + 0)
.s40:
; 430, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ad8 : c9 78 __ CMP #$78
0ada : f0 04 __ BEQ $0ae0 ; (printf.s41 + 0)
.s42:
0adc : c9 58 __ CMP #$58
0ade : d0 1e __ BNE $0afe ; (printf.s43 + 0)
.s41:
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae0 : a0 00 __ LDY #$00
0ae2 : 84 13 __ STY P6 
; 433, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae4 : a9 10 __ LDA #$10
0ae6 : 8d b6 9f STA $9fb6 ; (si.base + 0)
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae9 : b1 48 __ LDA (T2 + 0),y 
0aeb : 85 11 __ STA P4 
0aed : c8 __ __ INY
0aee : b1 48 __ LDA (T2 + 0),y 
0af0 : 85 12 __ STA P5 
; 432, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0af2 : a5 4c __ LDA T5 + 0 
0af4 : 29 e0 __ AND #$e0
0af6 : 09 01 __ ORA #$01
0af8 : 8d b5 9f STA $9fb5 ; (si.cha + 0)
0afb : 4c ba 0b JMP $0bba ; (printf.s33 + 0)
.s43:
; 472, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0afe : c9 73 __ CMP #$73
0b00 : f0 2d __ BEQ $0b2f ; (printf.s44 + 0)
.s53:
0b02 : c9 53 __ CMP #$53
0b04 : f0 29 __ BEQ $0b2f ; (printf.s44 + 0)
.s54:
; 518, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b06 : c9 63 __ CMP #$63
0b08 : f0 12 __ BEQ $0b1c ; (printf.s55 + 0)
.s57:
0b0a : c9 43 __ CMP #$43
0b0c : f0 0e __ BEQ $0b1c ; (printf.s55 + 0)
.s58:
; 522, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b0e : aa __ __ TAX
0b0f : d0 03 __ BNE $0b14 ; (printf.s59 + 0)
0b11 : 4c 89 09 JMP $0989 ; (printf.l5 + 0)
.s59:
; 524, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b14 : 8d ba 9f STA $9fba ; (buff[0] + 0)
.s56:
0b17 : a9 01 __ LDA #$01
0b19 : 4c c2 09 JMP $09c2 ; (printf.s68 + 0)
.s55:
; 520, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b1c : a0 00 __ LDY #$00
0b1e : b1 48 __ LDA (T2 + 0),y 
0b20 : 8d ba 9f STA $9fba ; (buff[0] + 0)
0b23 : a5 48 __ LDA T2 + 0 
0b25 : 69 01 __ ADC #$01
0b27 : 85 48 __ STA T2 + 0 
0b29 : 90 ec __ BCC $0b17 ; (printf.s56 + 0)
.s79:
0b2b : e6 49 __ INC T2 + 1 
0b2d : b0 e8 __ BCS $0b17 ; (printf.s56 + 0)
.s44:
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b2f : a0 00 __ LDY #$00
; 476, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b31 : 84 4d __ STY T6 + 0 
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b33 : b1 48 __ LDA (T2 + 0),y 
0b35 : 85 46 __ STA T1 + 0 
0b37 : c8 __ __ INY
0b38 : b1 48 __ LDA (T2 + 0),y 
0b3a : 85 47 __ STA T1 + 1 
0b3c : a5 48 __ LDA T2 + 0 
0b3e : 69 01 __ ADC #$01
0b40 : 85 48 __ STA T2 + 0 
0b42 : 90 02 __ BCC $0b46 ; (printf.s78 + 0)
.s77:
0b44 : e6 49 __ INC T2 + 1 
.s78:
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b46 : ad b3 9f LDA $9fb3 ; (si.width + 0)
0b49 : f0 0d __ BEQ $0b58 ; (printf.s46 + 0)
.s70:
0b4b : a0 00 __ LDY #$00
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b4d : b1 46 __ LDA (T1 + 0),y 
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b4f : f0 05 __ BEQ $0b56 ; (printf.s71 + 0)
.l45:
; 480, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b51 : c8 __ __ INY
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b52 : b1 46 __ LDA (T1 + 0),y 
0b54 : d0 fb __ BNE $0b51 ; (printf.l45 + 0)
.s71:
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b56 : 84 4d __ STY T6 + 0 
.s46:
; 483, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b58 : ad b8 9f LDA $9fb8 ; (si.left + 0)
0b5b : 85 4c __ STA T5 + 0 
0b5d : d0 07 __ BNE $0b66 ; (printf.s47 + 0)
.s50:
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b5f : a4 4d __ LDY T6 + 0 
0b61 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b64 : 90 2a __ BCC $0b90 ; (printf.s51 + 0)
.s47:
; 500, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b66 : a5 46 __ LDA T1 + 0 
0b68 : 85 0d __ STA P0 
0b6a : a5 47 __ LDA T1 + 1 
0b6c : 85 0e __ STA P1 
0b6e : 20 e5 0b JSR $0be5 ; (puts.l4 + 0)
; 509, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b71 : a5 4c __ LDA T5 + 0 
0b73 : f0 9c __ BEQ $0b11 ; (printf.s58 + 3)
.s48:
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b75 : a4 4d __ LDY T6 + 0 
0b77 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b7a : b0 95 __ BCS $0b11 ; (printf.s58 + 3)
.s49:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b7c : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0b7f : a2 00 __ LDX #$00
.l66:
0b81 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0b84 : e8 __ __ INX
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b85 : c8 __ __ INY
0b86 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b89 : 90 f6 __ BCC $0b81 ; (printf.l66 + 0)
.s64:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b8b : 86 4e __ STX T7 + 0 
0b8d : 4c 89 09 JMP $0989 ; (printf.l5 + 0)
.s51:
; 487, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b90 : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0b93 : a2 00 __ LDX #$00
.l67:
0b95 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0b98 : e8 __ __ INX
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b99 : c8 __ __ INY
0b9a : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b9d : 90 f6 __ BCC $0b95 ; (printf.l67 + 0)
.s65:
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b9f : a9 ba __ LDA #$ba
0ba1 : 85 0d __ STA P0 
0ba3 : a9 9f __ LDA #$9f
0ba5 : 85 0e __ STA P1 
; 496, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ba7 : a9 00 __ LDA #$00
0ba9 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bac : 20 e5 0b JSR $0be5 ; (puts.l4 + 0)
; 500, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0baf : a5 46 __ LDA T1 + 0 
0bb1 : 85 0d __ STA P0 
0bb3 : a5 47 __ LDA T1 + 1 
0bb5 : 85 0e __ STA P1 
0bb7 : 4c bd 09 JMP $09bd ; (printf.s52 + 0)
.s33:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bba : a9 ba __ LDA #$ba
0bbc : 85 0f __ STA P2 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bbe : a9 9f __ LDA #$9f
0bc0 : 85 0e __ STA P1 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bc2 : a9 9f __ LDA #$9f
0bc4 : 85 10 __ STA P3 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bc6 : a9 b2 __ LDA #$b2
0bc8 : 85 0d __ STA P0 
0bca : 20 21 0c JSR $0c21 ; (nformi.s4 + 0)
0bcd : 85 4e __ STA T7 + 0 
0bcf : 18 __ __ CLC
0bd0 : a5 48 __ LDA T2 + 0 
0bd2 : 69 02 __ ADC #$02
0bd4 : 85 48 __ STA T2 + 0 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bd6 : 90 b5 __ BCC $0b8d ; (printf.s64 + 2)
.s76:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bd8 : e6 49 __ INC T2 + 1 
0bda : 4c 89 09 JMP $0989 ; (printf.l5 + 0)
--------------------------------------------------------------------
puts@proxy: ; puts@proxy
0bdd : a9 ba __ LDA #$ba
0bdf : 85 0d __ STA P0 
0be1 : a9 9f __ LDA #$9f
0be3 : 85 0e __ STA P1 
--------------------------------------------------------------------
puts: ; puts(const u8*)->void
;  12, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.l4:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0be5 : a0 00 __ LDY #$00
0be7 : b1 0d __ LDA (P0),y ; (str + 0)
0be9 : d0 01 __ BNE $0bec ; (puts.s5 + 0)
.s3:
;  20, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0beb : 60 __ __ RTS
.s5:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bec : 85 43 __ STA T0 + 0 
0bee : e6 0d __ INC P0 ; (str + 0)
0bf0 : d0 02 __ BNE $0bf4 ; (puts.s12 + 0)
.s11:
0bf2 : e6 0e __ INC P1 ; (str + 1)
.s12:
; 206, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0bf4 : c9 0a __ CMP #$0a
0bf6 : d0 0c __ BNE $0c04 ; (puts.s8 + 0)
.s6:
; 207, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0bf8 : a9 0d __ LDA #$0d
0bfa : 85 43 __ STA T0 + 0 
.s7:
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0bfc : a5 43 __ LDA T0 + 0 
0bfe : 20 d2 ff JSR $ffd2 
0c01 : 4c e5 0b JMP $0be5 ; (puts.l4 + 0)
.s8:
; 208, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c04 : c9 09 __ CMP #$09
0c06 : d0 f4 __ BNE $0bfc ; (puts.s7 + 0)
.s9:
; 413, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c08 : a5 d3 __ LDA $d3 
; 210, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c0a : 29 03 __ AND #$03
0c0c : 85 43 __ STA T0 + 0 
; 212, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c0e : a9 20 __ LDA #$20
0c10 : 85 44 __ STA T1 + 0 
.l10:
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c12 : a5 44 __ LDA T1 + 0 
0c14 : 20 d2 ff JSR $ffd2 
; 213, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c17 : e6 43 __ INC T0 + 0 
0c19 : a5 43 __ LDA T0 + 0 
0c1b : c9 04 __ CMP #$04
0c1d : 90 f3 __ BCC $0c12 ; (puts.l10 + 0)
0c1f : b0 c4 __ BCS $0be5 ; (puts.l4 + 0)
--------------------------------------------------------------------
nformi: ; nformi(const struct sinfo*,u8*,i16,bool)->u8
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
.s4:
;  85, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c21 : a9 00 __ LDA #$00
0c23 : 85 43 __ STA T5 + 0 
;  82, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c25 : a0 04 __ LDY #$04
0c27 : b1 0d __ LDA (P0),y ; (si + 0)
0c29 : 85 44 __ STA T6 + 0 
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c2b : a5 13 __ LDA P6 ; (s + 0)
;  87, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c2d : f0 13 __ BEQ $0c42 ; (nformi.s7 + 0)
.s5:
0c2f : 24 12 __ BIT P5 ; (v + 1)
0c31 : 10 0f __ BPL $0c42 ; (nformi.s7 + 0)
.s6:
;  90, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c33 : 38 __ __ SEC
0c34 : a9 00 __ LDA #$00
0c36 : e5 11 __ SBC P4 ; (v + 0)
0c38 : 85 11 __ STA P4 ; (v + 0)
0c3a : a9 00 __ LDA #$00
0c3c : e5 12 __ SBC P5 ; (v + 1)
0c3e : 85 12 __ STA P5 ; (v + 1)
;  89, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c40 : e6 43 __ INC T5 + 0 
.s7:
;  93, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c42 : a9 10 __ LDA #$10
0c44 : 85 45 __ STA T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c46 : a5 11 __ LDA P4 ; (v + 0)
0c48 : 05 12 __ ORA P5 ; (v + 1)
0c4a : f0 33 __ BEQ $0c7f ; (nformi.s12 + 0)
.s8:
;  99, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c4c : a5 11 __ LDA P4 ; (v + 0)
0c4e : 85 1b __ STA ACCU + 0 
0c50 : a5 12 __ LDA P5 ; (v + 1)
0c52 : 85 1c __ STA ACCU + 1 
.l9:
0c54 : a5 44 __ LDA T6 + 0 
0c56 : 85 03 __ STA WORK + 0 
0c58 : a9 00 __ LDA #$00
0c5a : 85 04 __ STA WORK + 1 
0c5c : 20 3f 0d JSR $0d3f ; (divmod + 0)
;  96, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c5f : a5 05 __ LDA WORK + 2 
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c61 : c9 0a __ CMP #$0a
0c63 : b0 04 __ BCS $0c69 ; (nformi.s10 + 0)
.s34:
0c65 : a9 30 __ LDA #$30
0c67 : 90 06 __ BCC $0c6f ; (nformi.s11 + 0)
.s10:
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c69 : a0 03 __ LDY #$03
0c6b : b1 0d __ LDA (P0),y ; (si + 0)
0c6d : e9 0a __ SBC #$0a
.s11:
0c6f : 18 __ __ CLC
0c70 : 65 05 __ ADC WORK + 2 
;  98, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c72 : a6 45 __ LDX T7 + 0 
0c74 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c77 : c6 45 __ DEC T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c79 : a5 1b __ LDA ACCU + 0 
0c7b : 05 1c __ ORA ACCU + 1 
0c7d : d0 d5 __ BNE $0c54 ; (nformi.l9 + 0)
.s12:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c7f : a0 02 __ LDY #$02
0c81 : b1 0d __ LDA (P0),y ; (si + 0)
0c83 : c9 ff __ CMP #$ff
0c85 : d0 04 __ BNE $0c8b ; (nformi.s13 + 0)
.s33:
0c87 : a9 0f __ LDA #$0f
0c89 : d0 05 __ BNE $0c90 ; (nformi.s39 + 0)
.s13:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c8b : 38 __ __ SEC
0c8c : a9 10 __ LDA #$10
0c8e : f1 0d __ SBC (P0),y ; (si + 0)
.s39:
0c90 : a8 __ __ TAY
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c91 : c4 45 __ CPY T7 + 0 
0c93 : b0 0d __ BCS $0ca2 ; (nformi.s15 + 0)
.s14:
; 105, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c95 : a9 30 __ LDA #$30
.l40:
0c97 : a6 45 __ LDX T7 + 0 
0c99 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c9c : c6 45 __ DEC T7 + 0 
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9e : c4 45 __ CPY T7 + 0 
0ca0 : 90 f5 __ BCC $0c97 ; (nformi.l40 + 0)
.s15:
; 107, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ca2 : a0 07 __ LDY #$07
0ca4 : b1 0d __ LDA (P0),y ; (si + 0)
0ca6 : f0 1c __ BEQ $0cc4 ; (nformi.s18 + 0)
.s16:
0ca8 : a5 44 __ LDA T6 + 0 
0caa : c9 10 __ CMP #$10
0cac : d0 16 __ BNE $0cc4 ; (nformi.s18 + 0)
.s17:
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cae : a0 03 __ LDY #$03
0cb0 : b1 0d __ LDA (P0),y ; (si + 0)
0cb2 : a8 __ __ TAY
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb3 : a9 30 __ LDA #$30
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb5 : a6 45 __ LDX T7 + 0 
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb7 : ca __ __ DEX
0cb8 : ca __ __ DEX
0cb9 : 86 45 __ STX T7 + 0 
0cbb : 9d ec 9f STA $9fec,x ; (buffer[0] + 0)
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cbe : 98 __ __ TYA
0cbf : 69 16 __ ADC #$16
0cc1 : 9d ed 9f STA $9fed,x ; (buffer[0] + 1)
.s18:
; 118, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cc4 : a9 00 __ LDA #$00
0cc6 : 85 1b __ STA ACCU + 0 
; 113, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cc8 : a5 43 __ LDA T5 + 0 
0cca : f0 0c __ BEQ $0cd8 ; (nformi.s31 + 0)
.s19:
; 114, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ccc : a9 2d __ LDA #$2d
.s20:
0cce : a6 45 __ LDX T7 + 0 
0cd0 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cd3 : c6 45 __ DEC T7 + 0 
0cd5 : 4c e2 0c JMP $0ce2 ; (nformi.s21 + 0)
.s31:
; 115, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cd8 : a0 05 __ LDY #$05
0cda : b1 0d __ LDA (P0),y ; (si + 0)
0cdc : f0 04 __ BEQ $0ce2 ; (nformi.s21 + 0)
.s32:
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cde : a9 2b __ LDA #$2b
0ce0 : d0 ec __ BNE $0cce ; (nformi.s20 + 0)
.s21:
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ce2 : a0 06 __ LDY #$06
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ce4 : a6 45 __ LDX T7 + 0 
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ce6 : b1 0d __ LDA (P0),y ; (si + 0)
0ce8 : d0 2b __ BNE $0d15 ; (nformi.s22 + 0)
.l26:
; 128, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cea : 8a __ __ TXA
0ceb : 18 __ __ CLC
0cec : a0 01 __ LDY #$01
0cee : 71 0d __ ADC (P0),y ; (si + 0)
0cf0 : b0 04 __ BCS $0cf6 ; (nformi.s27 + 0)
.s30:
0cf2 : c9 11 __ CMP #$11
0cf4 : 90 0a __ BCC $0d00 ; (nformi.s28 + 0)
.s27:
; 129, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cf6 : a0 00 __ LDY #$00
0cf8 : b1 0d __ LDA (P0),y ; (si + 0)
0cfa : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0cfd : ca __ __ DEX
0cfe : b0 ea __ BCS $0cea ; (nformi.l26 + 0)
.s28:
; 130, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d00 : e0 10 __ CPX #$10
0d02 : b0 0e __ BCS $0d12 ; (nformi.s41 + 0)
.s29:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d04 : 88 __ __ DEY
.l37:
0d05 : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0d08 : 91 0f __ STA (P2),y ; (str + 0)
0d0a : c8 __ __ INY
0d0b : e8 __ __ INX
0d0c : e0 10 __ CPX #$10
0d0e : 90 f5 __ BCC $0d05 ; (nformi.l37 + 0)
.s38:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d10 : 84 1b __ STY ACCU + 0 
.s41:
; 134, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d12 : a5 1b __ LDA ACCU + 0 
.s3:
0d14 : 60 __ __ RTS
.s22:
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d15 : e0 10 __ CPX #$10
0d17 : b0 1a __ BCS $0d33 ; (nformi.l24 + 0)
.s23:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d19 : a0 00 __ LDY #$00
.l35:
0d1b : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0d1e : 91 0f __ STA (P2),y ; (str + 0)
0d20 : c8 __ __ INY
0d21 : e8 __ __ INX
0d22 : e0 10 __ CPX #$10
0d24 : 90 f5 __ BCC $0d1b ; (nformi.l35 + 0)
.s36:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d26 : 84 1b __ STY ACCU + 0 
0d28 : b0 09 __ BCS $0d33 ; (nformi.l24 + 0)
.s25:
; 124, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d2a : 88 __ __ DEY
0d2b : b1 0d __ LDA (P0),y ; (si + 0)
0d2d : a4 1b __ LDY ACCU + 0 
0d2f : 91 0f __ STA (P2),y ; (str + 0)
0d31 : e6 1b __ INC ACCU + 0 
.l24:
; 123, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d33 : a5 1b __ LDA ACCU + 0 
0d35 : a0 01 __ LDY #$01
0d37 : d1 0d __ CMP (P0),y ; (si + 0)
0d39 : 90 ef __ BCC $0d2a ; (nformi.s25 + 0)
0d3b : 60 __ __ RTS
--------------------------------------------------------------------
0d3c : __ __ __ BYT 25 75 00                                        : %u.
--------------------------------------------------------------------
divmod: ; divmod
0d3f : a5 1c __ LDA ACCU + 1 
0d41 : d0 31 __ BNE $0d74 ; (divmod + 53)
0d43 : a5 04 __ LDA WORK + 1 
0d45 : d0 1e __ BNE $0d65 ; (divmod + 38)
0d47 : 85 06 __ STA WORK + 3 
0d49 : a2 04 __ LDX #$04
0d4b : 06 1b __ ASL ACCU + 0 
0d4d : 2a __ __ ROL
0d4e : c5 03 __ CMP WORK + 0 
0d50 : 90 02 __ BCC $0d54 ; (divmod + 21)
0d52 : e5 03 __ SBC WORK + 0 
0d54 : 26 1b __ ROL ACCU + 0 
0d56 : 2a __ __ ROL
0d57 : c5 03 __ CMP WORK + 0 
0d59 : 90 02 __ BCC $0d5d ; (divmod + 30)
0d5b : e5 03 __ SBC WORK + 0 
0d5d : 26 1b __ ROL ACCU + 0 
0d5f : ca __ __ DEX
0d60 : d0 eb __ BNE $0d4d ; (divmod + 14)
0d62 : 85 05 __ STA WORK + 2 
0d64 : 60 __ __ RTS
0d65 : a5 1b __ LDA ACCU + 0 
0d67 : 85 05 __ STA WORK + 2 
0d69 : a5 1c __ LDA ACCU + 1 
0d6b : 85 06 __ STA WORK + 3 
0d6d : a9 00 __ LDA #$00
0d6f : 85 1b __ STA ACCU + 0 
0d71 : 85 1c __ STA ACCU + 1 
0d73 : 60 __ __ RTS
0d74 : a5 04 __ LDA WORK + 1 
0d76 : d0 1f __ BNE $0d97 ; (divmod + 88)
0d78 : a5 03 __ LDA WORK + 0 
0d7a : 30 1b __ BMI $0d97 ; (divmod + 88)
0d7c : a9 00 __ LDA #$00
0d7e : 85 06 __ STA WORK + 3 
0d80 : a2 10 __ LDX #$10
0d82 : 06 1b __ ASL ACCU + 0 
0d84 : 26 1c __ ROL ACCU + 1 
0d86 : 2a __ __ ROL
0d87 : c5 03 __ CMP WORK + 0 
0d89 : 90 02 __ BCC $0d8d ; (divmod + 78)
0d8b : e5 03 __ SBC WORK + 0 
0d8d : 26 1b __ ROL ACCU + 0 
0d8f : 26 1c __ ROL ACCU + 1 
0d91 : ca __ __ DEX
0d92 : d0 f2 __ BNE $0d86 ; (divmod + 71)
0d94 : 85 05 __ STA WORK + 2 
0d96 : 60 __ __ RTS
0d97 : a9 00 __ LDA #$00
0d99 : 85 05 __ STA WORK + 2 
0d9b : 85 06 __ STA WORK + 3 
0d9d : 84 02 __ STY $02 
0d9f : a0 10 __ LDY #$10
0da1 : 18 __ __ CLC
0da2 : 26 1b __ ROL ACCU + 0 
0da4 : 26 1c __ ROL ACCU + 1 
0da6 : 26 05 __ ROL WORK + 2 
0da8 : 26 06 __ ROL WORK + 3 
0daa : 38 __ __ SEC
0dab : a5 05 __ LDA WORK + 2 
0dad : e5 03 __ SBC WORK + 0 
0daf : aa __ __ TAX
0db0 : a5 06 __ LDA WORK + 3 
0db2 : e5 04 __ SBC WORK + 1 
0db4 : 90 04 __ BCC $0dba ; (divmod + 123)
0db6 : 86 05 __ STX WORK + 2 
0db8 : 85 06 __ STA WORK + 3 
0dba : 88 __ __ DEY
0dbb : d0 e5 __ BNE $0da2 ; (divmod + 99)
0dbd : 26 1b __ ROL ACCU + 0 
0dbf : 26 1c __ ROL ACCU + 1 
0dc1 : a4 02 __ LDY $02 
0dc3 : 60 __ __ RTS
--------------------------------------------------------------------
crt_malloc: ; crt_malloc
0dc4 : 18 __ __ CLC
0dc5 : a5 1b __ LDA ACCU + 0 
0dc7 : 69 05 __ ADC #$05
0dc9 : 29 fc __ AND #$fc
0dcb : 85 03 __ STA WORK + 0 
0dcd : a5 1c __ LDA ACCU + 1 
0dcf : 69 00 __ ADC #$00
0dd1 : 85 04 __ STA WORK + 1 
0dd3 : ad 99 0e LDA $0e99 ; (HeapNode.end + 0)
0dd6 : d0 26 __ BNE $0dfe ; (crt_malloc + 58)
0dd8 : a9 00 __ LDA #$00
0dda : 8d a2 0e STA $0ea2 
0ddd : 8d a3 0e STA $0ea3 
0de0 : ee 99 0e INC $0e99 ; (HeapNode.end + 0)
0de3 : a9 a0 __ LDA #$a0
0de5 : 09 02 __ ORA #$02
0de7 : 8d 97 0e STA $0e97 ; (HeapNode.next + 0)
0dea : a9 0e __ LDA #$0e
0dec : 8d 98 0e STA $0e98 ; (HeapNode.next + 1)
0def : 38 __ __ SEC
0df0 : a9 00 __ LDA #$00
0df2 : e9 02 __ SBC #$02
0df4 : 8d a4 0e STA $0ea4 
0df7 : a9 90 __ LDA #$90
0df9 : e9 00 __ SBC #$00
0dfb : 8d a5 0e STA $0ea5 
0dfe : a9 97 __ LDA #$97
0e00 : a2 0e __ LDX #$0e
0e02 : 85 1d __ STA ACCU + 2 
0e04 : 86 1e __ STX ACCU + 3 
0e06 : 18 __ __ CLC
0e07 : a0 00 __ LDY #$00
0e09 : b1 1d __ LDA (ACCU + 2),y 
0e0b : 85 1b __ STA ACCU + 0 
0e0d : 65 03 __ ADC WORK + 0 
0e0f : 85 05 __ STA WORK + 2 
0e11 : c8 __ __ INY
0e12 : b1 1d __ LDA (ACCU + 2),y 
0e14 : 85 1c __ STA ACCU + 1 
0e16 : f0 20 __ BEQ $0e38 ; (crt_malloc + 116)
0e18 : 65 04 __ ADC WORK + 1 
0e1a : 85 06 __ STA WORK + 3 
0e1c : b0 14 __ BCS $0e32 ; (crt_malloc + 110)
0e1e : a0 02 __ LDY #$02
0e20 : b1 1b __ LDA (ACCU + 0),y 
0e22 : c5 05 __ CMP WORK + 2 
0e24 : c8 __ __ INY
0e25 : b1 1b __ LDA (ACCU + 0),y 
0e27 : e5 06 __ SBC WORK + 3 
0e29 : b0 0e __ BCS $0e39 ; (crt_malloc + 117)
0e2b : a5 1b __ LDA ACCU + 0 
0e2d : a6 1c __ LDX ACCU + 1 
0e2f : 4c 02 0e JMP $0e02 ; (crt_malloc + 62)
0e32 : a9 00 __ LDA #$00
0e34 : 85 1b __ STA ACCU + 0 
0e36 : 85 1c __ STA ACCU + 1 
0e38 : 60 __ __ RTS
0e39 : a5 05 __ LDA WORK + 2 
0e3b : 85 07 __ STA WORK + 4 
0e3d : a5 06 __ LDA WORK + 3 
0e3f : 85 08 __ STA WORK + 5 
0e41 : a0 02 __ LDY #$02
0e43 : a5 07 __ LDA WORK + 4 
0e45 : d1 1b __ CMP (ACCU + 0),y 
0e47 : d0 15 __ BNE $0e5e ; (crt_malloc + 154)
0e49 : c8 __ __ INY
0e4a : a5 08 __ LDA WORK + 5 
0e4c : d1 1b __ CMP (ACCU + 0),y 
0e4e : d0 0e __ BNE $0e5e ; (crt_malloc + 154)
0e50 : a0 00 __ LDY #$00
0e52 : b1 1b __ LDA (ACCU + 0),y 
0e54 : 91 1d __ STA (ACCU + 2),y 
0e56 : c8 __ __ INY
0e57 : b1 1b __ LDA (ACCU + 0),y 
0e59 : 91 1d __ STA (ACCU + 2),y 
0e5b : 4c 7b 0e JMP $0e7b ; (crt_malloc + 183)
0e5e : a0 00 __ LDY #$00
0e60 : b1 1b __ LDA (ACCU + 0),y 
0e62 : 91 07 __ STA (WORK + 4),y 
0e64 : a5 07 __ LDA WORK + 4 
0e66 : 91 1d __ STA (ACCU + 2),y 
0e68 : c8 __ __ INY
0e69 : b1 1b __ LDA (ACCU + 0),y 
0e6b : 91 07 __ STA (WORK + 4),y 
0e6d : a5 08 __ LDA WORK + 5 
0e6f : 91 1d __ STA (ACCU + 2),y 
0e71 : c8 __ __ INY
0e72 : b1 1b __ LDA (ACCU + 0),y 
0e74 : 91 07 __ STA (WORK + 4),y 
0e76 : c8 __ __ INY
0e77 : b1 1b __ LDA (ACCU + 0),y 
0e79 : 91 07 __ STA (WORK + 4),y 
0e7b : a0 00 __ LDY #$00
0e7d : a5 05 __ LDA WORK + 2 
0e7f : 91 1b __ STA (ACCU + 0),y 
0e81 : c8 __ __ INY
0e82 : a5 06 __ LDA WORK + 3 
0e84 : 91 1b __ STA (ACCU + 0),y 
0e86 : 18 __ __ CLC
0e87 : a5 1b __ LDA ACCU + 0 
0e89 : 69 02 __ ADC #$02
0e8b : 85 1b __ STA ACCU + 0 
0e8d : 90 02 __ BCC $0e91 ; (crt_malloc + 205)
0e8f : e6 1c __ INC ACCU + 1 
0e91 : 60 __ __ RTS
--------------------------------------------------------------------
spentry:
0e92 : __ __ __ BYT 00                                              : .
--------------------------------------------------------------------
n:
0e93 : __ __ __ BSS	2
--------------------------------------------------------------------
c:
0e95 : __ __ __ BSS	2
--------------------------------------------------------------------
HeapNode:
0e97 : __ __ __ BSS	4
