#xfc = 252 bytes

objects by size
097c (026a) : printf, NATIVE_CODE:code
0c2a (011b) : nformi, NATIVE_CODE:code
0880 (00fc) : main, NATIVE_CODE:code
0dcd (00ce) : crt_malloc, NATIVE_CODE:code
0d48 (0085) : divmod, NATIVE_CODE:code
0801 (0052) : startup, NATIVE_CODE:startup
0bee (003c) : puts, NATIVE_CODE:code
9fba (0032) : buff, BSS:printf@stack
9fec (0010) : buffer, BSS:nformi@stack
0be6 (0008) : puts@proxy, NATIVE_CODE:code
9fb2 (0008) : si, BSS:printf@stack
0ea2 (0004) : HeapNode, DATA:bss
9ffc (0004) : sstack, STACK:sstack
0e9c (0002) : n, DATA:bss
0e9e (0002) : c, DATA:bss
0ea0 (0002) : i, DATA:bss
0e9b (0001) : spentry, DATA:data
00f7 (0000) : ZeroStart, START:zeropage
00f7 (0000) : ZeroEnd, END:zeropage
0e9c (0000) : BSSStart, START:bss
0ea6 (0000) : BSSEnd, END:bss
0ea8 (0000) : HeapStart, START:heap
9000 (0000) : HeapEnd, END:heap
9fb2 (0000) : StackEnd, END:stack



; Compiled with 1.32.266
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
080e : 8e 9b 0e STX $0e9b ; (spentry + 0)
0811 : a2 0e __ LDX #$0e
0813 : a0 9c __ LDY #$9c
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
082a : c0 a6 __ CPY #$a6
082c : d0 f9 __ BNE $0827 ; (startup + 38)
082e : a9 00 __ LDA #$00
0830 : a2 f7 __ LDX #$f7
0832 : d0 03 __ BNE $0837 ; (startup + 54)
0834 : 95 00 __ STA $00,x 
0836 : e8 __ __ INX
0837 : e0 f7 __ CPX #$f7
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

0880 : a9 00 __ LDA #$00
0882 : 8d 9c 0e STA $0e9c ; (n + 0)
0885 : 8d 9d 0e STA $0e9d ; (n + 1)
;  11, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;;
;;; -   flag= malloc(m);

0888 : 85 1b __ STA ACCU + 0 
088a : a9 20 __ LDA #$20
088c : 85 1c __ STA ACCU + 1 
088e : 20 cd 0d JSR $0dcd ; (crt_malloc + 0)
0891 : a5 1b __ LDA ACCU + 0 
0893 : 85 51 __ STA T4 + 0 
0895 : a5 1c __ LDA ACCU + 1 
0897 : 85 52 __ STA T4 + 1 
.l5:
;  13, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     c=0;
;;; 

0899 : a9 00 __ LDA #$00
089b : 8d 9e 0e STA $0e9e ; (c + 0)
089e : 8d 9f 0e STA $0e9f ; (c + 1)
;  14, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     i=0; do flag[i++]= 1; while(i<m);
;;; 

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
08bd : e6 50 __ INC T1 + 1 
08bf : d0 f0 __ BNE $08b1 ; (main.l13 + 0)
.s6:
;  15, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     i=0; do {
;;; 

08c1 : 8e a0 0e STX $0ea0 ; (i + 0)
08c4 : 8e a1 0e STX $0ea1 ; (i + 1)
;  14, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"
08c7 : 8a __ __ TXA
.l7:
;  16, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -       if (flag[i]) {
;;; 

08c8 : 85 44 __ STA T0 + 1 
08ca : 18 __ __ CLC
08cb : a5 51 __ LDA T4 + 0 
08cd : 6d a0 0e ADC $0ea0 ; (i + 0)
08d0 : 85 4f __ STA T1 + 0 
08d2 : a5 52 __ LDA T4 + 1 
08d4 : 65 44 __ ADC T0 + 1 
08d6 : 85 50 __ STA T1 + 1 
08d8 : a0 00 __ LDY #$00
08da : ae a0 0e LDX $0ea0 ; (i + 0)
08dd : b1 4f __ LDA (T1 + 0),y 
08df : f0 46 __ BEQ $0927 ; (main.s9 + 0)
.s8:
;  17, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         p= i+i+3;
;;; 

08e1 : 8a __ __ TXA
08e2 : 0a __ __ ASL
08e3 : a8 __ __ TAY
08e4 : a5 44 __ LDA T0 + 1 
08e6 : 2a __ __ ROL
08e7 : 85 50 __ STA T1 + 1 
08e9 : 98 __ __ TYA
08ea : 18 __ __ CLC
08eb : 69 03 __ ADC #$03
08ed : 85 4f __ STA T1 + 0 
08ef : 90 03 __ BCC $08f4 ; (main.s19 + 0)
.s18:
08f1 : e6 50 __ INC T1 + 1 
;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -          flag[k]= 0;
;;; 

08f3 : 18 __ __ CLC
.s19:
08f4 : 8a __ __ TXA
08f5 : 65 4f __ ADC T1 + 0 
08f7 : a8 __ __ TAY
08f8 : a5 44 __ LDA T0 + 1 
08fa : 65 50 __ ADC T1 + 1 
08fc : 85 46 __ STA T2 + 1 
;  22, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         ++c;
;;; 

08fe : ee 9e 0e INC $0e9e ; (c + 0)
0901 : d0 03 __ BNE $0906 ; (main.s21 + 0)
.s20:
0903 : ee 9f 0e INC $0e9f ; (c + 1)
.s21:
;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -         k=i+p; while(k<m) {
;;; 

0906 : c9 20 __ CMP #$20
0908 : b0 1d __ BCS $0927 ; (main.s9 + 0)
.s15:
;  19, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -           flag[k]= 0;
;;; 

090a : a5 51 __ LDA T4 + 0 
090c : 85 47 __ STA T3 + 0 
.l22:
090e : a5 52 __ LDA T4 + 1 
0910 : 65 46 __ ADC T2 + 1 
0912 : 85 48 __ STA T3 + 1 
0914 : a9 00 __ LDA #$00
0916 : 91 47 __ STA (T3 + 0),y 
;  20, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -           k+=p;

0918 : 98 __ __ TYA
0919 : 18 __ __ CLC
091a : 65 4f __ ADC T1 + 0 
091c : a8 __ __ TAY
091d : a5 46 __ LDA T2 + 1 
091f : 65 50 __ ADC T1 + 1 
0921 : 85 46 __ STA T2 + 1 
;  18, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -        k=i+p; while(k<m) {
;;; 

0923 : c9 20 __ CMP #$20
0925 : 90 e7 __ BCC $090e ; (main.l22 + 0)
.s9:
;  24, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -       ++i;
;;; 

0927 : 8a __ __ TXA
0928 : 18 __ __ CLC
0929 : 69 01 __ ADC #$01
092b : 8d a0 0e STA $0ea0 ; (i + 0)
092e : a5 44 __ LDA T0 + 1 
0930 : 69 00 __ ADC #$00
0932 : 8d a1 0e STA $0ea1 ; (i + 1)
;  25, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     } while(i<m);
;;; 

0935 : c9 20 __ CMP #$20
0937 : 90 8f __ BCC $08c8 ; (main.l7 + 0)
.s10:
;  26, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     printf("%u", c);
;;; 

0939 : ad 9e 0e LDA $0e9e ; (c + 0)
093c : 85 4f __ STA T1 + 0 
093e : 8d fe 9f STA $9ffe ; (sstack + 2)
0941 : a9 45 __ LDA #$45
0943 : 8d fc 9f STA $9ffc ; (sstack + 0)
0946 : a9 0d __ LDA #$0d
0948 : 8d fd 9f STA $9ffd ; (sstack + 1)
094b : ad 9f 0e LDA $0e9f ; (c + 1)
094e : 85 50 __ STA T1 + 1 
0950 : 8d ff 9f STA $9fff ; (sstack + 3)
0953 : 20 7c 09 JSR $097c ; (printf.s4 + 0)
;  27, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -     ++n;
;;; 

0956 : ad 9c 0e LDA $0e9c ; (n + 0)
0959 : 18 __ __ CLC
095a : 69 01 __ ADC #$01
095c : 8d 9c 0e STA $0e9c ; (n + 0)
095f : ad 9d 0e LDA $0e9d ; (n + 1)
0962 : 69 00 __ ADC #$00
0964 : 8d 9d 0e STA $0e9d ; (n + 1)
;  28, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -  } while(n<10);
;;; 

0967 : d0 0a __ BNE $0973 ; (main.s11 + 0)
.s12:
0969 : ad 9c 0e LDA $0e9c ; (n + 0)
096c : c9 0a __ CMP #$0a
096e : b0 03 __ BCS $0973 ; (main.s11 + 0)
0970 : 4c 99 08 JMP $0899 ; (main.l5 + 0)
.s11:
;  29, "/data/data/com.termux/files/home/GIT/simple6502js/65lisp/Input/byte-sieve-malloc.c"

;;; 
;;; -   return c;
;;; 

0973 : a5 4f __ LDA T1 + 0 
0975 : 85 1b __ STA ACCU + 0 
0977 : a5 50 __ LDA T1 + 1 
0979 : 85 1c __ STA ACCU + 1 
.s3:
097b : 60 __ __ RTS
--------------------------------------------------------------------


printf: ; printf(const u8*)->void
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.s4:
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
097c : ad fc 9f LDA $9ffc ; (sstack + 0)
097f : 85 4a __ STA T4 + 0 
0981 : a9 fe __ LDA #$fe
0983 : 85 48 __ STA T2 + 0 
0985 : a9 9f __ LDA #$9f
0987 : 85 49 __ STA T2 + 1 
; 356, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0989 : a9 00 __ LDA #$00
098b : 85 4e __ STA T7 + 0 
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
098d : ad fd 9f LDA $9ffd ; (sstack + 1)
0990 : 85 4b __ STA T4 + 1 
.l5:
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0992 : a0 00 __ LDY #$00
0994 : b1 4a __ LDA (T4 + 0),y 
0996 : d0 0c __ BNE $09a4 ; (printf.s6 + 0)
.s62:
; 543, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0998 : a6 4e __ LDX T7 + 0 
099a : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 544, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
099d : 8a __ __ TXA
099e : d0 01 __ BNE $09a1 ; (printf.s63 + 0)
.s3:
; 559, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a0 : 60 __ __ RTS
.s63:
; 547, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a1 : 4c e6 0b JMP $0be6 ; (puts@proxy + 0)
.s6:
; 361, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a4 : c9 25 __ CMP #$25
09a6 : f0 28 __ BEQ $09d0 ; (printf.s7 + 0)
.s60:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a8 : a6 4e __ LDX T7 + 0 
09aa : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ad : e6 4a __ INC T4 + 0 
09af : d0 02 __ BNE $09b3 ; (printf.s83 + 0)
.s82:
09b1 : e6 4b __ INC T4 + 1 
.s83:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b3 : e8 __ __ INX
09b4 : 86 4e __ STX T7 + 0 
; 530, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b6 : e0 28 __ CPX #$28
09b8 : 90 d8 __ BCC $0992 ; (printf.l5 + 0)
.s61:
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ba : a9 ba __ LDA #$ba
09bc : 85 0d __ STA P0 
09be : a9 9f __ LDA #$9f
09c0 : 85 0e __ STA P1 
; 534, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c2 : 98 __ __ TYA
09c3 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
.s52:
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c6 : 20 ee 0b JSR $0bee ; (puts.l4 + 0)
; 539, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c9 : a9 00 __ LDA #$00
.s68:
09cb : 85 4e __ STA T7 + 0 
09cd : 4c 92 09 JMP $0992 ; (printf.l5 + 0)
.s7:
; 363, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d0 : a5 4e __ LDA T7 + 0 
09d2 : f0 0c __ BEQ $09e0 ; (printf.s9 + 0)
.s8:
09d4 : aa __ __ TAX
; 367, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d5 : 98 __ __ TYA
09d6 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 368, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09d9 : 20 e6 0b JSR $0be6 ; (puts@proxy + 0)
; 372, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09dc : a9 00 __ LDA #$00
09de : 85 4e __ STA T7 + 0 
.s9:
; 380, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e0 : 8d b7 9f STA $9fb7 ; (si.sign + 0)
; 381, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e3 : 8d b8 9f STA $9fb8 ; (si.left + 0)
; 382, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e6 : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09e9 : a0 01 __ LDY #$01
09eb : b1 4a __ LDA (T4 + 0),y 
; 379, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ed : a2 20 __ LDX #$20
09ef : 8e b2 9f STX $9fb2 ; (si.fill + 0)
; 377, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f2 : a2 00 __ LDX #$00
09f4 : 8e b3 9f STX $9fb3 ; (si.width + 0)
; 378, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f7 : ca __ __ DEX
09f8 : 8e b4 9f STX $9fb4 ; (si.precision + 0)
; 376, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09fb : a2 0a __ LDX #$0a
09fd : 8e b6 9f STX $9fb6 ; (si.base + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a00 : aa __ __ TAX
0a01 : a9 02 __ LDA #$02
0a03 : d0 07 __ BNE $0a0c ; (printf.l10 + 0)
.s12:
; 396, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a05 : a0 00 __ LDY #$00
0a07 : b1 4a __ LDA (T4 + 0),y 
0a09 : aa __ __ TAX
0a0a : a9 01 __ LDA #$01
.l10:
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a0c : 18 __ __ CLC
0a0d : 65 4a __ ADC T4 + 0 
0a0f : 85 4a __ STA T4 + 0 
0a11 : 90 02 __ BCC $0a15 ; (printf.s73 + 0)
.s72:
0a13 : e6 4b __ INC T4 + 1 
.s73:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a15 : 8a __ __ TXA
0a16 : e0 2b __ CPX #$2b
0a18 : d0 07 __ BNE $0a21 ; (printf.s13 + 0)
.s11:
; 387, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a1a : a9 01 __ LDA #$01
0a1c : 8d b7 9f STA $9fb7 ; (si.sign + 0)
0a1f : d0 e4 __ BNE $0a05 ; (printf.s12 + 0)
.s13:
; 388, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a21 : c9 30 __ CMP #$30
0a23 : d0 06 __ BNE $0a2b ; (printf.s15 + 0)
.s14:
; 389, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a25 : 8d b2 9f STA $9fb2 ; (si.fill + 0)
0a28 : 4c 05 0a JMP $0a05 ; (printf.s12 + 0)
.s15:
; 390, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a2b : c9 23 __ CMP #$23
0a2d : d0 07 __ BNE $0a36 ; (printf.s17 + 0)
.s16:
; 391, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a2f : a9 01 __ LDA #$01
0a31 : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
0a34 : d0 cf __ BNE $0a05 ; (printf.s12 + 0)
.s17:
; 392, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a36 : c9 2d __ CMP #$2d
0a38 : d0 07 __ BNE $0a41 ; (printf.s19 + 0)
.s18:
; 393, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a3a : a9 01 __ LDA #$01
0a3c : 8d b8 9f STA $9fb8 ; (si.left + 0)
0a3f : d0 c4 __ BNE $0a05 ; (printf.s12 + 0)
.s19:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a41 : 85 4c __ STA T5 + 0 
; 399, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a43 : c9 30 __ CMP #$30
0a45 : 90 31 __ BCC $0a78 ; (printf.s25 + 0)
.s20:
0a47 : c9 3a __ CMP #$3a
0a49 : b0 5e __ BCS $0aa9 ; (printf.s31 + 0)
.s21:
; 401, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a4b : a9 00 __ LDA #$00
0a4d : 85 46 __ STA T1 + 0 
.l22:
; 404, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a4f : a5 46 __ LDA T1 + 0 
0a51 : 0a __ __ ASL
0a52 : 0a __ __ ASL
0a53 : 18 __ __ CLC
0a54 : 65 46 __ ADC T1 + 0 
0a56 : 0a __ __ ASL
0a57 : 18 __ __ CLC
0a58 : 65 4c __ ADC T5 + 0 
0a5a : 38 __ __ SEC
0a5b : e9 30 __ SBC #$30
0a5d : 85 46 __ STA T1 + 0 
; 405, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a5f : a0 00 __ LDY #$00
0a61 : b1 4a __ LDA (T4 + 0),y 
0a63 : 85 4c __ STA T5 + 0 
0a65 : e6 4a __ INC T4 + 0 
0a67 : d0 02 __ BNE $0a6b ; (printf.s81 + 0)
.s80:
0a69 : e6 4b __ INC T4 + 1 
.s81:
; 402, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a6b : c9 30 __ CMP #$30
0a6d : 90 04 __ BCC $0a73 ; (printf.s24 + 0)
.s23:
0a6f : c9 3a __ CMP #$3a
0a71 : 90 dc __ BCC $0a4f ; (printf.l22 + 0)
.s24:
; 407, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a73 : a6 46 __ LDX T1 + 0 
0a75 : 8e b3 9f STX $9fb3 ; (si.width + 0)
.s25:
; 410, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a78 : c9 2e __ CMP #$2e
0a7a : d0 2d __ BNE $0aa9 ; (printf.s31 + 0)
.s26:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a7c : a9 00 __ LDA #$00
0a7e : f0 0e __ BEQ $0a8e ; (printf.l27 + 0)
.s29:
; 416, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a80 : a5 43 __ LDA T0 + 0 
0a82 : 0a __ __ ASL
0a83 : 0a __ __ ASL
0a84 : 18 __ __ CLC
0a85 : 65 43 __ ADC T0 + 0 
0a87 : 0a __ __ ASL
0a88 : 18 __ __ CLC
0a89 : 65 4c __ ADC T5 + 0 
0a8b : 38 __ __ SEC
0a8c : e9 30 __ SBC #$30
.l27:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a8e : 85 43 __ STA T0 + 0 
; 417, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a90 : a0 00 __ LDY #$00
0a92 : b1 4a __ LDA (T4 + 0),y 
0a94 : 85 4c __ STA T5 + 0 
0a96 : e6 4a __ INC T4 + 0 
0a98 : d0 02 __ BNE $0a9c ; (printf.s75 + 0)
.s74:
0a9a : e6 4b __ INC T4 + 1 
.s75:
; 414, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a9c : c9 30 __ CMP #$30
0a9e : 90 04 __ BCC $0aa4 ; (printf.s30 + 0)
.s28:
0aa0 : c9 3a __ CMP #$3a
0aa2 : 90 dc __ BCC $0a80 ; (printf.s29 + 0)
.s30:
; 419, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aa4 : a6 43 __ LDX T0 + 0 
0aa6 : 8e b4 9f STX $9fb4 ; (si.precision + 0)
.s31:
; 422, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aa9 : c9 64 __ CMP #$64
0aab : f0 0c __ BEQ $0ab9 ; (printf.s32 + 0)
.s34:
0aad : c9 44 __ CMP #$44
0aaf : f0 08 __ BEQ $0ab9 ; (printf.s32 + 0)
.s35:
0ab1 : c9 69 __ CMP #$69
0ab3 : f0 04 __ BEQ $0ab9 ; (printf.s32 + 0)
.s36:
0ab5 : c9 49 __ CMP #$49
0ab7 : d0 11 __ BNE $0aca ; (printf.s37 + 0)
.s32:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ab9 : a0 00 __ LDY #$00
0abb : b1 48 __ LDA (T2 + 0),y 
0abd : 85 11 __ STA P4 
0abf : c8 __ __ INY
0ac0 : b1 48 __ LDA (T2 + 0),y 
0ac2 : 85 12 __ STA P5 
0ac4 : 98 __ __ TYA
.s69:
0ac5 : 85 13 __ STA P6 
0ac7 : 4c c3 0b JMP $0bc3 ; (printf.s33 + 0)
.s37:
; 426, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aca : c9 75 __ CMP #$75
0acc : f0 04 __ BEQ $0ad2 ; (printf.s38 + 0)
.s39:
0ace : c9 55 __ CMP #$55
0ad0 : d0 0f __ BNE $0ae1 ; (printf.s40 + 0)
.s38:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ad2 : a0 00 __ LDY #$00
0ad4 : b1 48 __ LDA (T2 + 0),y 
0ad6 : 85 11 __ STA P4 
0ad8 : c8 __ __ INY
0ad9 : b1 48 __ LDA (T2 + 0),y 
0adb : 85 12 __ STA P5 
0add : a9 00 __ LDA #$00
0adf : f0 e4 __ BEQ $0ac5 ; (printf.s69 + 0)
.s40:
; 430, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae1 : c9 78 __ CMP #$78
0ae3 : f0 04 __ BEQ $0ae9 ; (printf.s41 + 0)
.s42:
0ae5 : c9 58 __ CMP #$58
0ae7 : d0 1e __ BNE $0b07 ; (printf.s43 + 0)
.s41:
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae9 : a0 00 __ LDY #$00
0aeb : 84 13 __ STY P6 
; 433, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aed : a9 10 __ LDA #$10
0aef : 8d b6 9f STA $9fb6 ; (si.base + 0)
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0af2 : b1 48 __ LDA (T2 + 0),y 
0af4 : 85 11 __ STA P4 
0af6 : c8 __ __ INY
0af7 : b1 48 __ LDA (T2 + 0),y 
0af9 : 85 12 __ STA P5 
; 432, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0afb : a5 4c __ LDA T5 + 0 
0afd : 29 e0 __ AND #$e0
0aff : 09 01 __ ORA #$01
0b01 : 8d b5 9f STA $9fb5 ; (si.cha + 0)
0b04 : 4c c3 0b JMP $0bc3 ; (printf.s33 + 0)
.s43:
; 472, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b07 : c9 73 __ CMP #$73
0b09 : f0 2d __ BEQ $0b38 ; (printf.s44 + 0)
.s53:
0b0b : c9 53 __ CMP #$53
0b0d : f0 29 __ BEQ $0b38 ; (printf.s44 + 0)
.s54:
; 518, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b0f : c9 63 __ CMP #$63
0b11 : f0 12 __ BEQ $0b25 ; (printf.s55 + 0)
.s57:
0b13 : c9 43 __ CMP #$43
0b15 : f0 0e __ BEQ $0b25 ; (printf.s55 + 0)
.s58:
; 522, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b17 : aa __ __ TAX
0b18 : d0 03 __ BNE $0b1d ; (printf.s59 + 0)
0b1a : 4c 92 09 JMP $0992 ; (printf.l5 + 0)
.s59:
; 524, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b1d : 8d ba 9f STA $9fba ; (buff[0] + 0)
.s56:
0b20 : a9 01 __ LDA #$01
0b22 : 4c cb 09 JMP $09cb ; (printf.s68 + 0)
.s55:
; 520, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b25 : a0 00 __ LDY #$00
0b27 : b1 48 __ LDA (T2 + 0),y 
0b29 : 8d ba 9f STA $9fba ; (buff[0] + 0)
0b2c : a5 48 __ LDA T2 + 0 
0b2e : 69 01 __ ADC #$01
0b30 : 85 48 __ STA T2 + 0 
0b32 : 90 ec __ BCC $0b20 ; (printf.s56 + 0)
.s79:
0b34 : e6 49 __ INC T2 + 1 
0b36 : b0 e8 __ BCS $0b20 ; (printf.s56 + 0)
.s44:
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b38 : a0 00 __ LDY #$00
; 476, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b3a : 84 4d __ STY T6 + 0 
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b3c : b1 48 __ LDA (T2 + 0),y 
0b3e : 85 46 __ STA T1 + 0 
0b40 : c8 __ __ INY
0b41 : b1 48 __ LDA (T2 + 0),y 
0b43 : 85 47 __ STA T1 + 1 
0b45 : a5 48 __ LDA T2 + 0 
0b47 : 69 01 __ ADC #$01
0b49 : 85 48 __ STA T2 + 0 
0b4b : 90 02 __ BCC $0b4f ; (printf.s78 + 0)
.s77:
0b4d : e6 49 __ INC T2 + 1 
.s78:
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b4f : ad b3 9f LDA $9fb3 ; (si.width + 0)
0b52 : f0 0d __ BEQ $0b61 ; (printf.s46 + 0)
.s70:
0b54 : a0 00 __ LDY #$00
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b56 : b1 46 __ LDA (T1 + 0),y 
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b58 : f0 05 __ BEQ $0b5f ; (printf.s71 + 0)
.l45:
; 480, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b5a : c8 __ __ INY
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b5b : b1 46 __ LDA (T1 + 0),y 
0b5d : d0 fb __ BNE $0b5a ; (printf.l45 + 0)
.s71:
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b5f : 84 4d __ STY T6 + 0 
.s46:
; 483, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b61 : ad b8 9f LDA $9fb8 ; (si.left + 0)
0b64 : 85 4c __ STA T5 + 0 
0b66 : d0 07 __ BNE $0b6f ; (printf.s47 + 0)
.s50:
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b68 : a4 4d __ LDY T6 + 0 
0b6a : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b6d : 90 2a __ BCC $0b99 ; (printf.s51 + 0)
.s47:
; 500, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b6f : a5 46 __ LDA T1 + 0 
0b71 : 85 0d __ STA P0 
0b73 : a5 47 __ LDA T1 + 1 
0b75 : 85 0e __ STA P1 
0b77 : 20 ee 0b JSR $0bee ; (puts.l4 + 0)
; 509, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b7a : a5 4c __ LDA T5 + 0 
0b7c : f0 9c __ BEQ $0b1a ; (printf.s58 + 3)
.s48:
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b7e : a4 4d __ LDY T6 + 0 
0b80 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b83 : b0 95 __ BCS $0b1a ; (printf.s58 + 3)
.s49:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b85 : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0b88 : a2 00 __ LDX #$00
.l66:
0b8a : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0b8d : e8 __ __ INX
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b8e : c8 __ __ INY
0b8f : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b92 : 90 f6 __ BCC $0b8a ; (printf.l66 + 0)
.s64:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b94 : 86 4e __ STX T7 + 0 
0b96 : 4c 92 09 JMP $0992 ; (printf.l5 + 0)
.s51:
; 487, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b99 : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0b9c : a2 00 __ LDX #$00
.l67:
0b9e : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0ba1 : e8 __ __ INX
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ba2 : c8 __ __ INY
0ba3 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0ba6 : 90 f6 __ BCC $0b9e ; (printf.l67 + 0)
.s65:
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ba8 : a9 ba __ LDA #$ba
0baa : 85 0d __ STA P0 
0bac : a9 9f __ LDA #$9f
0bae : 85 0e __ STA P1 
; 496, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bb0 : a9 00 __ LDA #$00
0bb2 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bb5 : 20 ee 0b JSR $0bee ; (puts.l4 + 0)
; 500, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bb8 : a5 46 __ LDA T1 + 0 
0bba : 85 0d __ STA P0 
0bbc : a5 47 __ LDA T1 + 1 
0bbe : 85 0e __ STA P1 
0bc0 : 4c c6 09 JMP $09c6 ; (printf.s52 + 0)
.s33:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bc3 : a9 ba __ LDA #$ba
0bc5 : 85 0f __ STA P2 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bc7 : a9 9f __ LDA #$9f
0bc9 : 85 0e __ STA P1 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bcb : a9 9f __ LDA #$9f
0bcd : 85 10 __ STA P3 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bcf : a9 b2 __ LDA #$b2
0bd1 : 85 0d __ STA P0 
0bd3 : 20 2a 0c JSR $0c2a ; (nformi.s4 + 0)
0bd6 : 85 4e __ STA T7 + 0 
0bd8 : 18 __ __ CLC
0bd9 : a5 48 __ LDA T2 + 0 
0bdb : 69 02 __ ADC #$02
0bdd : 85 48 __ STA T2 + 0 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bdf : 90 b5 __ BCC $0b96 ; (printf.s64 + 2)
.s76:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0be1 : e6 49 __ INC T2 + 1 
0be3 : 4c 92 09 JMP $0992 ; (printf.l5 + 0)
--------------------------------------------------------------------
puts@proxy: ; puts@proxy
0be6 : a9 ba __ LDA #$ba
0be8 : 85 0d __ STA P0 
0bea : a9 9f __ LDA #$9f
0bec : 85 0e __ STA P1 
--------------------------------------------------------------------
puts: ; puts(const u8*)->void
;  12, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.l4:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bee : a0 00 __ LDY #$00
0bf0 : b1 0d __ LDA (P0),y ; (str + 0)
0bf2 : d0 01 __ BNE $0bf5 ; (puts.s5 + 0)
.s3:
;  20, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bf4 : 60 __ __ RTS
.s5:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bf5 : 85 43 __ STA T0 + 0 
0bf7 : e6 0d __ INC P0 ; (str + 0)
0bf9 : d0 02 __ BNE $0bfd ; (puts.s12 + 0)
.s11:
0bfb : e6 0e __ INC P1 ; (str + 1)
.s12:
; 206, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0bfd : c9 0a __ CMP #$0a
0bff : d0 0c __ BNE $0c0d ; (puts.s8 + 0)
.s6:
; 207, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c01 : a9 0d __ LDA #$0d
0c03 : 85 43 __ STA T0 + 0 
.s7:
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c05 : a5 43 __ LDA T0 + 0 
0c07 : 20 d2 ff JSR $ffd2 
0c0a : 4c ee 0b JMP $0bee ; (puts.l4 + 0)
.s8:
; 208, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c0d : c9 09 __ CMP #$09
0c0f : d0 f4 __ BNE $0c05 ; (puts.s7 + 0)
.s9:
; 413, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c11 : a5 d3 __ LDA $d3 
; 210, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c13 : 29 03 __ AND #$03
0c15 : 85 43 __ STA T0 + 0 
; 212, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c17 : a9 20 __ LDA #$20
0c19 : 85 44 __ STA T1 + 0 
.l10:
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c1b : a5 44 __ LDA T1 + 0 
0c1d : 20 d2 ff JSR $ffd2 
; 213, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0c20 : e6 43 __ INC T0 + 0 
0c22 : a5 43 __ LDA T0 + 0 
0c24 : c9 04 __ CMP #$04
0c26 : 90 f3 __ BCC $0c1b ; (puts.l10 + 0)
0c28 : b0 c4 __ BCS $0bee ; (puts.l4 + 0)
--------------------------------------------------------------------
nformi: ; nformi(const struct sinfo*,u8*,i16,bool)->u8
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
.s4:
;  85, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c2a : a9 00 __ LDA #$00
0c2c : 85 43 __ STA T5 + 0 
;  82, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c2e : a0 04 __ LDY #$04
0c30 : b1 0d __ LDA (P0),y ; (si + 0)
0c32 : 85 44 __ STA T6 + 0 
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c34 : a5 13 __ LDA P6 ; (s + 0)
;  87, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c36 : f0 13 __ BEQ $0c4b ; (nformi.s7 + 0)
.s5:
0c38 : 24 12 __ BIT P5 ; (v + 1)
0c3a : 10 0f __ BPL $0c4b ; (nformi.s7 + 0)
.s6:
;  90, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c3c : 38 __ __ SEC
0c3d : a9 00 __ LDA #$00
0c3f : e5 11 __ SBC P4 ; (v + 0)
0c41 : 85 11 __ STA P4 ; (v + 0)
0c43 : a9 00 __ LDA #$00
0c45 : e5 12 __ SBC P5 ; (v + 1)
0c47 : 85 12 __ STA P5 ; (v + 1)
;  89, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c49 : e6 43 __ INC T5 + 0 
.s7:
;  93, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c4b : a9 10 __ LDA #$10
0c4d : 85 45 __ STA T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c4f : a5 11 __ LDA P4 ; (v + 0)
0c51 : 05 12 __ ORA P5 ; (v + 1)
0c53 : f0 33 __ BEQ $0c88 ; (nformi.s12 + 0)
.s8:
;  99, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c55 : a5 11 __ LDA P4 ; (v + 0)
0c57 : 85 1b __ STA ACCU + 0 
0c59 : a5 12 __ LDA P5 ; (v + 1)
0c5b : 85 1c __ STA ACCU + 1 
.l9:
0c5d : a5 44 __ LDA T6 + 0 
0c5f : 85 03 __ STA WORK + 0 
0c61 : a9 00 __ LDA #$00
0c63 : 85 04 __ STA WORK + 1 
0c65 : 20 48 0d JSR $0d48 ; (divmod + 0)
;  96, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c68 : a5 05 __ LDA WORK + 2 
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c6a : c9 0a __ CMP #$0a
0c6c : b0 04 __ BCS $0c72 ; (nformi.s10 + 0)
.s34:
0c6e : a9 30 __ LDA #$30
0c70 : 90 06 __ BCC $0c78 ; (nformi.s11 + 0)
.s10:
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c72 : a0 03 __ LDY #$03
0c74 : b1 0d __ LDA (P0),y ; (si + 0)
0c76 : e9 0a __ SBC #$0a
.s11:
0c78 : 18 __ __ CLC
0c79 : 65 05 __ ADC WORK + 2 
;  98, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c7b : a6 45 __ LDX T7 + 0 
0c7d : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c80 : c6 45 __ DEC T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c82 : a5 1b __ LDA ACCU + 0 
0c84 : 05 1c __ ORA ACCU + 1 
0c86 : d0 d5 __ BNE $0c5d ; (nformi.l9 + 0)
.s12:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c88 : a0 02 __ LDY #$02
0c8a : b1 0d __ LDA (P0),y ; (si + 0)
0c8c : c9 ff __ CMP #$ff
0c8e : d0 04 __ BNE $0c94 ; (nformi.s13 + 0)
.s33:
0c90 : a9 0f __ LDA #$0f
0c92 : d0 05 __ BNE $0c99 ; (nformi.s39 + 0)
.s13:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c94 : 38 __ __ SEC
0c95 : a9 10 __ LDA #$10
0c97 : f1 0d __ SBC (P0),y ; (si + 0)
.s39:
0c99 : a8 __ __ TAY
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9a : c4 45 __ CPY T7 + 0 
0c9c : b0 0d __ BCS $0cab ; (nformi.s15 + 0)
.s14:
; 105, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9e : a9 30 __ LDA #$30
.l40:
0ca0 : a6 45 __ LDX T7 + 0 
0ca2 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0ca5 : c6 45 __ DEC T7 + 0 
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ca7 : c4 45 __ CPY T7 + 0 
0ca9 : 90 f5 __ BCC $0ca0 ; (nformi.l40 + 0)
.s15:
; 107, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cab : a0 07 __ LDY #$07
0cad : b1 0d __ LDA (P0),y ; (si + 0)
0caf : f0 1c __ BEQ $0ccd ; (nformi.s18 + 0)
.s16:
0cb1 : a5 44 __ LDA T6 + 0 
0cb3 : c9 10 __ CMP #$10
0cb5 : d0 16 __ BNE $0ccd ; (nformi.s18 + 0)
.s17:
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb7 : a0 03 __ LDY #$03
0cb9 : b1 0d __ LDA (P0),y ; (si + 0)
0cbb : a8 __ __ TAY
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cbc : a9 30 __ LDA #$30
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cbe : a6 45 __ LDX T7 + 0 
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cc0 : ca __ __ DEX
0cc1 : ca __ __ DEX
0cc2 : 86 45 __ STX T7 + 0 
0cc4 : 9d ec 9f STA $9fec,x ; (buffer[0] + 0)
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cc7 : 98 __ __ TYA
0cc8 : 69 16 __ ADC #$16
0cca : 9d ed 9f STA $9fed,x ; (buffer[0] + 1)
.s18:
; 118, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ccd : a9 00 __ LDA #$00
0ccf : 85 1b __ STA ACCU + 0 
; 113, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cd1 : a5 43 __ LDA T5 + 0 
0cd3 : f0 0c __ BEQ $0ce1 ; (nformi.s31 + 0)
.s19:
; 114, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cd5 : a9 2d __ LDA #$2d
.s20:
0cd7 : a6 45 __ LDX T7 + 0 
0cd9 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cdc : c6 45 __ DEC T7 + 0 
0cde : 4c eb 0c JMP $0ceb ; (nformi.s21 + 0)
.s31:
; 115, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ce1 : a0 05 __ LDY #$05
0ce3 : b1 0d __ LDA (P0),y ; (si + 0)
0ce5 : f0 04 __ BEQ $0ceb ; (nformi.s21 + 0)
.s32:
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ce7 : a9 2b __ LDA #$2b
0ce9 : d0 ec __ BNE $0cd7 ; (nformi.s20 + 0)
.s21:
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ceb : a0 06 __ LDY #$06
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ced : a6 45 __ LDX T7 + 0 
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cef : b1 0d __ LDA (P0),y ; (si + 0)
0cf1 : d0 2b __ BNE $0d1e ; (nformi.s22 + 0)
.l26:
; 128, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cf3 : 8a __ __ TXA
0cf4 : 18 __ __ CLC
0cf5 : a0 01 __ LDY #$01
0cf7 : 71 0d __ ADC (P0),y ; (si + 0)
0cf9 : b0 04 __ BCS $0cff ; (nformi.s27 + 0)
.s30:
0cfb : c9 11 __ CMP #$11
0cfd : 90 0a __ BCC $0d09 ; (nformi.s28 + 0)
.s27:
; 129, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cff : a0 00 __ LDY #$00
0d01 : b1 0d __ LDA (P0),y ; (si + 0)
0d03 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0d06 : ca __ __ DEX
0d07 : b0 ea __ BCS $0cf3 ; (nformi.l26 + 0)
.s28:
; 130, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d09 : e0 10 __ CPX #$10
0d0b : b0 0e __ BCS $0d1b ; (nformi.s41 + 0)
.s29:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d0d : 88 __ __ DEY
.l37:
0d0e : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0d11 : 91 0f __ STA (P2),y ; (str + 0)
0d13 : c8 __ __ INY
0d14 : e8 __ __ INX
0d15 : e0 10 __ CPX #$10
0d17 : 90 f5 __ BCC $0d0e ; (nformi.l37 + 0)
.s38:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d19 : 84 1b __ STY ACCU + 0 
.s41:
; 134, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d1b : a5 1b __ LDA ACCU + 0 
.s3:
0d1d : 60 __ __ RTS
.s22:
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d1e : e0 10 __ CPX #$10
0d20 : b0 1a __ BCS $0d3c ; (nformi.l24 + 0)
.s23:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d22 : a0 00 __ LDY #$00
.l35:
0d24 : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0d27 : 91 0f __ STA (P2),y ; (str + 0)
0d29 : c8 __ __ INY
0d2a : e8 __ __ INX
0d2b : e0 10 __ CPX #$10
0d2d : 90 f5 __ BCC $0d24 ; (nformi.l35 + 0)
.s36:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d2f : 84 1b __ STY ACCU + 0 
0d31 : b0 09 __ BCS $0d3c ; (nformi.l24 + 0)
.s25:
; 124, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d33 : 88 __ __ DEY
0d34 : b1 0d __ LDA (P0),y ; (si + 0)
0d36 : a4 1b __ LDY ACCU + 0 
0d38 : 91 0f __ STA (P2),y ; (str + 0)
0d3a : e6 1b __ INC ACCU + 0 
.l24:
; 123, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0d3c : a5 1b __ LDA ACCU + 0 
0d3e : a0 01 __ LDY #$01
0d40 : d1 0d __ CMP (P0),y ; (si + 0)
0d42 : 90 ef __ BCC $0d33 ; (nformi.s25 + 0)
0d44 : 60 __ __ RTS
--------------------------------------------------------------------
0d45 : __ __ __ BYT 25 75 00                                        : %u.
--------------------------------------------------------------------
divmod: ; divmod
0d48 : a5 1c __ LDA ACCU + 1 
0d4a : d0 31 __ BNE $0d7d ; (divmod + 53)
0d4c : a5 04 __ LDA WORK + 1 
0d4e : d0 1e __ BNE $0d6e ; (divmod + 38)
0d50 : 85 06 __ STA WORK + 3 
0d52 : a2 04 __ LDX #$04
0d54 : 06 1b __ ASL ACCU + 0 
0d56 : 2a __ __ ROL
0d57 : c5 03 __ CMP WORK + 0 
0d59 : 90 02 __ BCC $0d5d ; (divmod + 21)
0d5b : e5 03 __ SBC WORK + 0 
0d5d : 26 1b __ ROL ACCU + 0 
0d5f : 2a __ __ ROL
0d60 : c5 03 __ CMP WORK + 0 
0d62 : 90 02 __ BCC $0d66 ; (divmod + 30)
0d64 : e5 03 __ SBC WORK + 0 
0d66 : 26 1b __ ROL ACCU + 0 
0d68 : ca __ __ DEX
0d69 : d0 eb __ BNE $0d56 ; (divmod + 14)
0d6b : 85 05 __ STA WORK + 2 
0d6d : 60 __ __ RTS
0d6e : a5 1b __ LDA ACCU + 0 
0d70 : 85 05 __ STA WORK + 2 
0d72 : a5 1c __ LDA ACCU + 1 
0d74 : 85 06 __ STA WORK + 3 
0d76 : a9 00 __ LDA #$00
0d78 : 85 1b __ STA ACCU + 0 
0d7a : 85 1c __ STA ACCU + 1 
0d7c : 60 __ __ RTS
0d7d : a5 04 __ LDA WORK + 1 
0d7f : d0 1f __ BNE $0da0 ; (divmod + 88)
0d81 : a5 03 __ LDA WORK + 0 
0d83 : 30 1b __ BMI $0da0 ; (divmod + 88)
0d85 : a9 00 __ LDA #$00
0d87 : 85 06 __ STA WORK + 3 
0d89 : a2 10 __ LDX #$10
0d8b : 06 1b __ ASL ACCU + 0 
0d8d : 26 1c __ ROL ACCU + 1 
0d8f : 2a __ __ ROL
0d90 : c5 03 __ CMP WORK + 0 
0d92 : 90 02 __ BCC $0d96 ; (divmod + 78)
0d94 : e5 03 __ SBC WORK + 0 
0d96 : 26 1b __ ROL ACCU + 0 
0d98 : 26 1c __ ROL ACCU + 1 
0d9a : ca __ __ DEX
0d9b : d0 f2 __ BNE $0d8f ; (divmod + 71)
0d9d : 85 05 __ STA WORK + 2 
0d9f : 60 __ __ RTS
0da0 : a9 00 __ LDA #$00
0da2 : 85 05 __ STA WORK + 2 
0da4 : 85 06 __ STA WORK + 3 
0da6 : 84 02 __ STY $02 
0da8 : a0 10 __ LDY #$10
0daa : 18 __ __ CLC
0dab : 26 1b __ ROL ACCU + 0 
0dad : 26 1c __ ROL ACCU + 1 
0daf : 26 05 __ ROL WORK + 2 
0db1 : 26 06 __ ROL WORK + 3 
0db3 : 38 __ __ SEC
0db4 : a5 05 __ LDA WORK + 2 
0db6 : e5 03 __ SBC WORK + 0 
0db8 : aa __ __ TAX
0db9 : a5 06 __ LDA WORK + 3 
0dbb : e5 04 __ SBC WORK + 1 
0dbd : 90 04 __ BCC $0dc3 ; (divmod + 123)
0dbf : 86 05 __ STX WORK + 2 
0dc1 : 85 06 __ STA WORK + 3 
0dc3 : 88 __ __ DEY
0dc4 : d0 e5 __ BNE $0dab ; (divmod + 99)
0dc6 : 26 1b __ ROL ACCU + 0 
0dc8 : 26 1c __ ROL ACCU + 1 
0dca : a4 02 __ LDY $02 
0dcc : 60 __ __ RTS
--------------------------------------------------------------------
crt_malloc: ; crt_malloc
0dcd : 18 __ __ CLC
0dce : a5 1b __ LDA ACCU + 0 
0dd0 : 69 05 __ ADC #$05
0dd2 : 29 fc __ AND #$fc
0dd4 : 85 03 __ STA WORK + 0 
0dd6 : a5 1c __ LDA ACCU + 1 
0dd8 : 69 00 __ ADC #$00
0dda : 85 04 __ STA WORK + 1 
0ddc : ad a4 0e LDA $0ea4 ; (HeapNode.end + 0)
0ddf : d0 26 __ BNE $0e07 ; (crt_malloc + 58)
0de1 : a9 00 __ LDA #$00
0de3 : 8d aa 0e STA $0eaa 
0de6 : 8d ab 0e STA $0eab 
0de9 : ee a4 0e INC $0ea4 ; (HeapNode.end + 0)
0dec : a9 a8 __ LDA #$a8
0dee : 09 02 __ ORA #$02
0df0 : 8d a2 0e STA $0ea2 ; (HeapNode.next + 0)
0df3 : a9 0e __ LDA #$0e
0df5 : 8d a3 0e STA $0ea3 ; (HeapNode.next + 1)
0df8 : 38 __ __ SEC
0df9 : a9 00 __ LDA #$00
0dfb : e9 02 __ SBC #$02
0dfd : 8d ac 0e STA $0eac 
0e00 : a9 90 __ LDA #$90
0e02 : e9 00 __ SBC #$00
0e04 : 8d ad 0e STA $0ead 
0e07 : a9 a2 __ LDA #$a2
0e09 : a2 0e __ LDX #$0e
0e0b : 85 1d __ STA ACCU + 2 
0e0d : 86 1e __ STX ACCU + 3 
0e0f : 18 __ __ CLC
0e10 : a0 00 __ LDY #$00
0e12 : b1 1d __ LDA (ACCU + 2),y 
0e14 : 85 1b __ STA ACCU + 0 
0e16 : 65 03 __ ADC WORK + 0 
0e18 : 85 05 __ STA WORK + 2 
0e1a : c8 __ __ INY
0e1b : b1 1d __ LDA (ACCU + 2),y 
0e1d : 85 1c __ STA ACCU + 1 
0e1f : f0 20 __ BEQ $0e41 ; (crt_malloc + 116)
0e21 : 65 04 __ ADC WORK + 1 
0e23 : 85 06 __ STA WORK + 3 
0e25 : b0 14 __ BCS $0e3b ; (crt_malloc + 110)
0e27 : a0 02 __ LDY #$02
0e29 : b1 1b __ LDA (ACCU + 0),y 
0e2b : c5 05 __ CMP WORK + 2 
0e2d : c8 __ __ INY
0e2e : b1 1b __ LDA (ACCU + 0),y 
0e30 : e5 06 __ SBC WORK + 3 
0e32 : b0 0e __ BCS $0e42 ; (crt_malloc + 117)
0e34 : a5 1b __ LDA ACCU + 0 
0e36 : a6 1c __ LDX ACCU + 1 
0e38 : 4c 0b 0e JMP $0e0b ; (crt_malloc + 62)
0e3b : a9 00 __ LDA #$00
0e3d : 85 1b __ STA ACCU + 0 
0e3f : 85 1c __ STA ACCU + 1 
0e41 : 60 __ __ RTS
0e42 : a5 05 __ LDA WORK + 2 
0e44 : 85 07 __ STA WORK + 4 
0e46 : a5 06 __ LDA WORK + 3 
0e48 : 85 08 __ STA WORK + 5 
0e4a : a0 02 __ LDY #$02
0e4c : a5 07 __ LDA WORK + 4 
0e4e : d1 1b __ CMP (ACCU + 0),y 
0e50 : d0 15 __ BNE $0e67 ; (crt_malloc + 154)
0e52 : c8 __ __ INY
0e53 : a5 08 __ LDA WORK + 5 
0e55 : d1 1b __ CMP (ACCU + 0),y 
0e57 : d0 0e __ BNE $0e67 ; (crt_malloc + 154)
0e59 : a0 00 __ LDY #$00
0e5b : b1 1b __ LDA (ACCU + 0),y 
0e5d : 91 1d __ STA (ACCU + 2),y 
0e5f : c8 __ __ INY
0e60 : b1 1b __ LDA (ACCU + 0),y 
0e62 : 91 1d __ STA (ACCU + 2),y 
0e64 : 4c 84 0e JMP $0e84 ; (crt_malloc + 183)
0e67 : a0 00 __ LDY #$00
0e69 : b1 1b __ LDA (ACCU + 0),y 
0e6b : 91 07 __ STA (WORK + 4),y 
0e6d : a5 07 __ LDA WORK + 4 
0e6f : 91 1d __ STA (ACCU + 2),y 
0e71 : c8 __ __ INY
0e72 : b1 1b __ LDA (ACCU + 0),y 
0e74 : 91 07 __ STA (WORK + 4),y 
0e76 : a5 08 __ LDA WORK + 5 
0e78 : 91 1d __ STA (ACCU + 2),y 
0e7a : c8 __ __ INY
0e7b : b1 1b __ LDA (ACCU + 0),y 
0e7d : 91 07 __ STA (WORK + 4),y 
0e7f : c8 __ __ INY
0e80 : b1 1b __ LDA (ACCU + 0),y 
0e82 : 91 07 __ STA (WORK + 4),y 
0e84 : a0 00 __ LDY #$00
0e86 : a5 05 __ LDA WORK + 2 
0e88 : 91 1b __ STA (ACCU + 0),y 
0e8a : c8 __ __ INY
0e8b : a5 06 __ LDA WORK + 3 
0e8d : 91 1b __ STA (ACCU + 0),y 
0e8f : 18 __ __ CLC
0e90 : a5 1b __ LDA ACCU + 0 
0e92 : 69 02 __ ADC #$02
0e94 : 85 1b __ STA ACCU + 0 
0e96 : 90 02 __ BCC $0e9a ; (crt_malloc + 205)
0e98 : e6 1c __ INC ACCU + 1 
0e9a : 60 __ __ RTS
--------------------------------------------------------------------
spentry:
0e9b : __ __ __ BYT 00                                              : .
--------------------------------------------------------------------
n:
0e9c : __ __ __ BSS	2
--------------------------------------------------------------------
c:
0e9e : __ __ __ BSS	2
--------------------------------------------------------------------
i:
0ea0 : __ __ __ BSS	2
--------------------------------------------------------------------
HeapNode:
0ea2 : __ __ __ BSS	4
