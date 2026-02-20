#x7b= 123 B       861,946,225   includes C xorshift!
  no print(sum)    22,619,142   132 B (incl xorshift)

mine: 134 B     1,709,830,292
  no print(sum)    34,990,442    96 B (no print at end, using rand())
  xorshift in C   136,089,546   174 B (incl xorshift)
    opt <<7 >>9    50,907,895   157 B      - " -
  jsr               3,932,160

TOTAL             861,946,225   inlined C xorshift
   0 : divmod :   466,452,180
   1 : nformi :   166,881,600
   2 : printf :    90,110,625
   3 : putpch :    50,601,015
   4 : puts :      49,234,785
   5 : main :      35,389,151
   6 : puts@proxy : 3,276,750
   7 : startup : 119
-rw-------. 1 u0_a239 u0_a239 35475 Feb 20 17:00 Play/random.asm
-rw-------. 1 u0_a239 u0_a239  1362 Feb 20 17:00 Play/random.prg

objects by size
08fb (0263) : printf, NATIVE_CODE:code
0bab (011b) : nformi, NATIVE_CODE:code
0cc9 (0085) : divmod, NATIVE_CODE:code
0880 (007b) : main, NATIVE_CODE:code
0801 (0052) : startup, NATIVE_CODE:startup
0b79 (0032) : putpch, NATIVE_CODE:code
9fba (0032) : buff, BSS:printf@stack
0b66 (0013) : puts, NATIVE_CODE:code
9fec (0010) : buffer, BSS:nformi@stack
0b5e (0008) : puts@proxy, NATIVE_CODE:code
9fb2 (0008) : si, BSS:printf@stack
9ffc (0004) : sstack, STACK:sstack
00f7 (0002) : j, DATA:zeropage
00f9 (0002) : i, DATA:zeropage
0d4f (0002) : xs, DATA:data
0d4e (0001) : spentry, DATA:data
00f7 (0000) : ZeroStart, START:zeropage
00fb (0000) : ZeroEnd, END:zeropage
0d51 (0000) : BSSStart, START:bss
0d51 (0000) : BSSEnd, END:bss
9fb2 (0000) : StackEnd, END:stack
; Compiled with 1.32.266
--------------------------------------------------------------------
j:
00f7 : __ __ __ BYT 00 00                                           : ..
--------------------------------------------------------------------
i:
00f9 : __ __ __ BYT 00 00                                           : ..
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
080e : 8e 4e 0d STX $0d4e ; (spentry + 0)
0811 : a2 0d __ LDX #$0d
0813 : a0 51 __ LDY #$51
0815 : a9 00 __ LDA #$00
0817 : 85 19 __ STA IP + 0 
0819 : 86 1a __ STX IP + 1 
081b : e0 0d __ CPX #$0d
081d : f0 0b __ BEQ $082a ; (startup + 41)
081f : 91 19 __ STA (IP + 0),y 
0821 : c8 __ __ INY
0822 : d0 fb __ BNE $081f ; (startup + 30)
0824 : e8 __ __ INX
0825 : d0 f2 __ BNE $0819 ; (startup + 24)
0827 : 91 19 __ STA (IP + 0),y 
0829 : c8 __ __ INY
082a : c0 51 __ CPY #$51
082c : d0 f9 __ BNE $0827 ; (startup + 38)
082e : a9 00 __ LDA #$00
0830 : a2 f7 __ LDX #$f7
0832 : d0 03 __ BNE $0837 ; (startup + 54)
0834 : 95 00 __ STA $00,x 
0836 : e8 __ __ INX
0837 : e0 fb __ CPX #$fb
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
;  18, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
.s4:
;  19, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
0880 : a9 00 __ LDA #$00
0882 : 85 f7 __ STA $f7 ; (j + 0)
0884 : 85 f8 __ STA $f8 ; (j + 1)
.l5:
0886 : a5 f7 __ LDA $f7 ; (j + 0)
0888 : 18 __ __ CLC
0889 : 69 01 __ ADC #$01
088b : 85 4e __ STA T3 + 0 
088d : 85 f7 __ STA $f7 ; (j + 0)
;  20, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
088f : a9 01 __ LDA #$01
0891 : 85 f9 __ STA $f9 ; (i + 0)
0893 : a9 00 __ LDA #$00
0895 : 85 fa __ STA $fa ; (i + 1)
;  19, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
0897 : a5 f8 __ LDA $f8 ; (j + 1)
0899 : 69 00 __ ADC #$00
089b : 85 4f __ STA T3 + 1 
089d : 85 f8 __ STA $f8 ; (j + 1)
.l6:
;   9, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
089f : ad 50 0d LDA $0d50 ; (xs + 1)
08a2 : 4a __ __ LSR
;  21, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08a3 : a9 c6 __ LDA #$c6
08a5 : 8d fc 9f STA $9ffc ; (sstack + 0)
08a8 : a9 0c __ LDA #$0c
08aa : 8d fd 9f STA $9ffd ; (sstack + 1)
;   9, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08ad : ad 4f 0d LDA $0d4f ; (xs + 0)
08b0 : 6a __ __ ROR
08b1 : aa __ __ TAX
08b2 : a9 00 __ LDA #$00
08b4 : 6a __ __ ROR
08b5 : 4d 4f 0d EOR $0d4f ; (xs + 0)
08b8 : 85 43 __ STA T0 + 0 
08ba : 8a __ __ TXA
08bb : 4d 50 0d EOR $0d50 ; (xs + 1)
08be : 85 44 __ STA T0 + 1 
;  10, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08c0 : 4a __ __ LSR
08c1 : 45 43 __ EOR T0 + 0 
;  21, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08c3 : 8d fe 9f STA $9ffe ; (sstack + 2)
;  11, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08c6 : 8d 4f 0d STA $0d4f ; (xs + 0)
08c9 : 45 44 __ EOR T0 + 1 
;  21, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08cb : 8d ff 9f STA $9fff ; (sstack + 3)
;  11, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08ce : 8d 50 0d STA $0d50 ; (xs + 1)
;  21, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08d1 : 20 fb 08 JSR $08fb ; (printf.s4 + 0)
;   8, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
08d4 : a9 0a __ LDA #$0a
08d6 : 20 79 0b JSR $0b79 ; (putpch.s4 + 0)
;  20, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08d9 : a5 f9 __ LDA $f9 ; (i + 0)
08db : 18 __ __ CLC
08dc : 69 01 __ ADC #$01
08de : 85 f9 __ STA $f9 ; (i + 0)
08e0 : a5 fa __ LDA $fa ; (i + 1)
08e2 : 69 00 __ ADC #$00
08e4 : 85 fa __ STA $fa ; (i + 1)
08e6 : 05 f9 __ ORA $f9 ; (i + 0)
08e8 : d0 b5 __ BNE $089f ; (main.l6 + 0)
.s7:
;  19, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08ea : a5 4f __ LDA T3 + 1 
08ec : d0 06 __ BNE $08f4 ; (main.s8 + 0)
.s9:
08ee : a5 4e __ LDA T3 + 0 
08f0 : c9 05 __ CMP #$05
08f2 : 90 92 __ BCC $0886 ; (main.l5 + 0)
.s8:
;  18, "/data/data/com.termux/files/home/GIT/65lisp/65lisp/Play/random.c"
08f4 : a9 00 __ LDA #$00
08f6 : 85 1b __ STA ACCU + 0 
08f8 : 85 1c __ STA ACCU + 1 
.s3:
08fa : 60 __ __ RTS
--------------------------------------------------------------------
printf: ; printf(const u8*)->void
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.s4:
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
08fb : ad fc 9f LDA $9ffc ; (sstack + 0)
08fe : 85 4a __ STA T4 + 0 
0900 : a9 fe __ LDA #$fe
0902 : 85 48 __ STA T2 + 0 
0904 : a9 9f __ LDA #$9f
0906 : 85 49 __ STA T2 + 1 
; 356, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0908 : a9 00 __ LDA #$00
090a : 85 4c __ STA T7 + 0 
; 558, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
090c : ad fd 9f LDA $9ffd ; (sstack + 1)
090f : 85 4b __ STA T4 + 1 
.l5:
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0911 : a0 00 __ LDY #$00
0913 : b1 4a __ LDA (T4 + 0),y 
0915 : d0 0c __ BNE $0923 ; (printf.s6 + 0)
.s61:
; 543, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0917 : a6 4c __ LDX T7 + 0 
0919 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 544, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
091c : 8a __ __ TXA
091d : d0 01 __ BNE $0920 ; (printf.s62 + 0)
.s3:
; 559, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
091f : 60 __ __ RTS
.s62:
; 547, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0920 : 4c 5e 0b JMP $0b5e ; (puts@proxy + 0)
.s6:
; 361, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0923 : c9 25 __ CMP #$25
0925 : f0 28 __ BEQ $094f ; (printf.s7 + 0)
.s59:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0927 : a6 4c __ LDX T7 + 0 
0929 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 359, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
092c : e6 4a __ INC T4 + 0 
092e : d0 02 __ BNE $0932 ; (printf.s82 + 0)
.s81:
0930 : e6 4b __ INC T4 + 1 
.s82:
; 529, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0932 : e8 __ __ INX
0933 : 86 4c __ STX T7 + 0 
; 530, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0935 : e0 28 __ CPX #$28
0937 : 90 d8 __ BCC $0911 ; (printf.l5 + 0)
.s60:
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0939 : a9 ba __ LDA #$ba
093b : 85 0e __ STA P1 
093d : a9 9f __ LDA #$9f
093f : 85 0f __ STA P2 
; 534, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0941 : 98 __ __ TYA
0942 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 535, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0945 : 20 66 0b JSR $0b66 ; (puts.l4 + 0)
; 539, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0948 : a9 00 __ LDA #$00
.s67:
; 524, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
094a : 85 4c __ STA T7 + 0 
094c : 4c 11 09 JMP $0911 ; (printf.l5 + 0)
.s7:
; 363, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
094f : a5 4c __ LDA T7 + 0 
0951 : f0 0c __ BEQ $095f ; (printf.s9 + 0)
.s8:
0953 : aa __ __ TAX
; 367, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0954 : 98 __ __ TYA
0955 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 368, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0958 : 20 5e 0b JSR $0b5e ; (puts@proxy + 0)
; 372, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
095b : a9 00 __ LDA #$00
095d : 85 4c __ STA T7 + 0 
.s9:
; 380, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
095f : 8d b7 9f STA $9fb7 ; (si.sign + 0)
; 381, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0962 : 8d b8 9f STA $9fb8 ; (si.left + 0)
; 382, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0965 : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0968 : a0 01 __ LDY #$01
096a : b1 4a __ LDA (T4 + 0),y 
; 379, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
096c : a2 20 __ LDX #$20
096e : 8e b2 9f STX $9fb2 ; (si.fill + 0)
; 377, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0971 : a2 00 __ LDX #$00
0973 : 8e b3 9f STX $9fb3 ; (si.width + 0)
; 378, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0976 : ca __ __ DEX
0977 : 8e b4 9f STX $9fb4 ; (si.precision + 0)
; 376, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
097a : a2 0a __ LDX #$0a
097c : 8e b6 9f STX $9fb6 ; (si.base + 0)
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
097f : aa __ __ TAX
0980 : a9 02 __ LDA #$02
0982 : d0 07 __ BNE $098b ; (printf.l10 + 0)
.s12:
; 396, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0984 : a0 00 __ LDY #$00
0986 : b1 4a __ LDA (T4 + 0),y 
0988 : aa __ __ TAX
0989 : a9 01 __ LDA #$01
.l10:
; 374, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
098b : 18 __ __ CLC
098c : 65 4a __ ADC T4 + 0 
098e : 85 4a __ STA T4 + 0 
0990 : 90 02 __ BCC $0994 ; (printf.s72 + 0)
.s71:
0992 : e6 4b __ INC T4 + 1 
.s72:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0994 : 8a __ __ TXA
0995 : e0 2b __ CPX #$2b
0997 : d0 07 __ BNE $09a0 ; (printf.s13 + 0)
.s11:
; 387, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0999 : a9 01 __ LDA #$01
099b : 8d b7 9f STA $9fb7 ; (si.sign + 0)
099e : d0 e4 __ BNE $0984 ; (printf.s12 + 0)
.s13:
; 388, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a0 : c9 30 __ CMP #$30
09a2 : d0 06 __ BNE $09aa ; (printf.s15 + 0)
.s14:
; 389, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09a4 : 8d b2 9f STA $9fb2 ; (si.fill + 0)
09a7 : 4c 84 09 JMP $0984 ; (printf.s12 + 0)
.s15:
; 390, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09aa : c9 23 __ CMP #$23
09ac : d0 07 __ BNE $09b5 ; (printf.s17 + 0)
.s16:
; 391, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ae : a9 01 __ LDA #$01
09b0 : 8d b9 9f STA $9fb9 ; (si.prefix + 0)
09b3 : d0 cf __ BNE $0984 ; (printf.s12 + 0)
.s17:
; 392, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b5 : c9 2d __ CMP #$2d
09b7 : d0 07 __ BNE $09c0 ; (printf.s19 + 0)
.s18:
; 393, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09b9 : a9 01 __ LDA #$01
09bb : 8d b8 9f STA $9fb8 ; (si.left + 0)
09be : d0 c4 __ BNE $0984 ; (printf.s12 + 0)
.s19:
; 386, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c0 : 85 45 __ STA T5 + 0 
; 399, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09c2 : c9 30 __ CMP #$30
09c4 : 90 31 __ BCC $09f7 ; (printf.s25 + 0)
.s20:
09c6 : c9 3a __ CMP #$3a
09c8 : b0 5e __ BCS $0a28 ; (printf.s31 + 0)
.s21:
; 401, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ca : a9 00 __ LDA #$00
09cc : 85 46 __ STA T1 + 0 
.l22:
; 404, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ce : a5 46 __ LDA T1 + 0 
09d0 : 0a __ __ ASL
09d1 : 0a __ __ ASL
09d2 : 18 __ __ CLC
09d3 : 65 46 __ ADC T1 + 0 
09d5 : 0a __ __ ASL
09d6 : 18 __ __ CLC
09d7 : 65 45 __ ADC T5 + 0 
09d9 : 38 __ __ SEC
09da : e9 30 __ SBC #$30
09dc : 85 46 __ STA T1 + 0 
; 405, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09de : a0 00 __ LDY #$00
09e0 : b1 4a __ LDA (T4 + 0),y 
09e2 : 85 45 __ STA T5 + 0 
09e4 : e6 4a __ INC T4 + 0 
09e6 : d0 02 __ BNE $09ea ; (printf.s80 + 0)
.s79:
09e8 : e6 4b __ INC T4 + 1 
.s80:
; 402, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ea : c9 30 __ CMP #$30
09ec : 90 04 __ BCC $09f2 ; (printf.s24 + 0)
.s23:
09ee : c9 3a __ CMP #$3a
09f0 : 90 dc __ BCC $09ce ; (printf.l22 + 0)
.s24:
; 407, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f2 : a6 46 __ LDX T1 + 0 
09f4 : 8e b3 9f STX $9fb3 ; (si.width + 0)
.s25:
; 410, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09f7 : c9 2e __ CMP #$2e
09f9 : d0 2d __ BNE $0a28 ; (printf.s31 + 0)
.s26:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09fb : a9 00 __ LDA #$00
09fd : f0 0e __ BEQ $0a0d ; (printf.l27 + 0)
.s29:
; 416, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
09ff : a5 43 __ LDA T0 + 0 
0a01 : 0a __ __ ASL
0a02 : 0a __ __ ASL
0a03 : 18 __ __ CLC
0a04 : 65 43 __ ADC T0 + 0 
0a06 : 0a __ __ ASL
0a07 : 18 __ __ CLC
0a08 : 65 45 __ ADC T5 + 0 
0a0a : 38 __ __ SEC
0a0b : e9 30 __ SBC #$30
.l27:
; 412, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a0d : 85 43 __ STA T0 + 0 
; 417, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a0f : a0 00 __ LDY #$00
0a11 : b1 4a __ LDA (T4 + 0),y 
0a13 : 85 45 __ STA T5 + 0 
0a15 : e6 4a __ INC T4 + 0 
0a17 : d0 02 __ BNE $0a1b ; (printf.s74 + 0)
.s73:
0a19 : e6 4b __ INC T4 + 1 
.s74:
; 414, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a1b : c9 30 __ CMP #$30
0a1d : 90 04 __ BCC $0a23 ; (printf.s30 + 0)
.s28:
0a1f : c9 3a __ CMP #$3a
0a21 : 90 dc __ BCC $09ff ; (printf.s29 + 0)
.s30:
; 419, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a23 : a6 43 __ LDX T0 + 0 
0a25 : 8e b4 9f STX $9fb4 ; (si.precision + 0)
.s31:
; 422, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a28 : c9 64 __ CMP #$64
0a2a : f0 0c __ BEQ $0a38 ; (printf.s32 + 0)
.s34:
0a2c : c9 44 __ CMP #$44
0a2e : f0 08 __ BEQ $0a38 ; (printf.s32 + 0)
.s35:
0a30 : c9 69 __ CMP #$69
0a32 : f0 04 __ BEQ $0a38 ; (printf.s32 + 0)
.s36:
0a34 : c9 49 __ CMP #$49
0a36 : d0 11 __ BNE $0a49 ; (printf.s37 + 0)
.s32:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a38 : a0 00 __ LDY #$00
0a3a : b1 48 __ LDA (T2 + 0),y 
0a3c : 85 11 __ STA P4 
0a3e : c8 __ __ INY
0a3f : b1 48 __ LDA (T2 + 0),y 
0a41 : 85 12 __ STA P5 
0a43 : 98 __ __ TYA
.s68:
0a44 : 85 13 __ STA P6 
0a46 : 4c 3b 0b JMP $0b3b ; (printf.s33 + 0)
.s37:
; 426, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a49 : c9 75 __ CMP #$75
0a4b : f0 04 __ BEQ $0a51 ; (printf.s38 + 0)
.s39:
0a4d : c9 55 __ CMP #$55
0a4f : d0 0f __ BNE $0a60 ; (printf.s40 + 0)
.s38:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a51 : a0 00 __ LDY #$00
0a53 : b1 48 __ LDA (T2 + 0),y 
0a55 : 85 11 __ STA P4 
0a57 : c8 __ __ INY
0a58 : b1 48 __ LDA (T2 + 0),y 
0a5a : 85 12 __ STA P5 
0a5c : a9 00 __ LDA #$00
0a5e : f0 e4 __ BEQ $0a44 ; (printf.s68 + 0)
.s40:
; 430, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a60 : c9 78 __ CMP #$78
0a62 : f0 04 __ BEQ $0a68 ; (printf.s41 + 0)
.s42:
0a64 : c9 58 __ CMP #$58
0a66 : d0 1e __ BNE $0a86 ; (printf.s43 + 0)
.s41:
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a68 : a0 00 __ LDY #$00
0a6a : 84 13 __ STY P6 
; 433, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a6c : a9 10 __ LDA #$10
0a6e : 8d b6 9f STA $9fb6 ; (si.base + 0)
; 434, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a71 : b1 48 __ LDA (T2 + 0),y 
0a73 : 85 11 __ STA P4 
0a75 : c8 __ __ INY
0a76 : b1 48 __ LDA (T2 + 0),y 
0a78 : 85 12 __ STA P5 
; 432, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a7a : a5 45 __ LDA T5 + 0 
0a7c : 29 e0 __ AND #$e0
0a7e : 09 01 __ ORA #$01
0a80 : 8d b5 9f STA $9fb5 ; (si.cha + 0)
0a83 : 4c 3b 0b JMP $0b3b ; (printf.s33 + 0)
.s43:
; 472, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a86 : c9 73 __ CMP #$73
0a88 : f0 2d __ BEQ $0ab7 ; (printf.s44 + 0)
.s52:
0a8a : c9 53 __ CMP #$53
0a8c : f0 29 __ BEQ $0ab7 ; (printf.s44 + 0)
.s53:
; 518, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a8e : c9 63 __ CMP #$63
0a90 : f0 12 __ BEQ $0aa4 ; (printf.s54 + 0)
.s56:
0a92 : c9 43 __ CMP #$43
0a94 : f0 0e __ BEQ $0aa4 ; (printf.s54 + 0)
.s57:
; 522, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a96 : aa __ __ TAX
0a97 : d0 03 __ BNE $0a9c ; (printf.s58 + 0)
0a99 : 4c 11 09 JMP $0911 ; (printf.l5 + 0)
.s58:
; 524, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0a9c : 8d ba 9f STA $9fba ; (buff[0] + 0)
.s55:
0a9f : a9 01 __ LDA #$01
0aa1 : 4c 4a 09 JMP $094a ; (printf.s67 + 0)
.s54:
; 520, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aa4 : a0 00 __ LDY #$00
0aa6 : b1 48 __ LDA (T2 + 0),y 
0aa8 : 8d ba 9f STA $9fba ; (buff[0] + 0)
0aab : a5 48 __ LDA T2 + 0 
0aad : 69 01 __ ADC #$01
0aaf : 85 48 __ STA T2 + 0 
0ab1 : 90 ec __ BCC $0a9f ; (printf.s55 + 0)
.s78:
0ab3 : e6 49 __ INC T2 + 1 
0ab5 : b0 e8 __ BCS $0a9f ; (printf.s55 + 0)
.s44:
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ab7 : a0 00 __ LDY #$00
; 476, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ab9 : 84 4d __ STY T8 + 0 
; 474, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0abb : b1 48 __ LDA (T2 + 0),y 
0abd : 85 46 __ STA T1 + 0 
0abf : c8 __ __ INY
0ac0 : b1 48 __ LDA (T2 + 0),y 
0ac2 : 85 47 __ STA T1 + 1 
0ac4 : a5 48 __ LDA T2 + 0 
0ac6 : 69 01 __ ADC #$01
0ac8 : 85 48 __ STA T2 + 0 
0aca : 90 02 __ BCC $0ace ; (printf.s77 + 0)
.s76:
0acc : e6 49 __ INC T2 + 1 
.s77:
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ace : ad b3 9f LDA $9fb3 ; (si.width + 0)
0ad1 : f0 0d __ BEQ $0ae0 ; (printf.s46 + 0)
.s69:
0ad3 : a0 00 __ LDY #$00
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ad5 : b1 46 __ LDA (T1 + 0),y 
; 477, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ad7 : f0 05 __ BEQ $0ade ; (printf.s70 + 0)
.l45:
; 480, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ad9 : c8 __ __ INY
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ada : b1 46 __ LDA (T1 + 0),y 
0adc : d0 fb __ BNE $0ad9 ; (printf.l45 + 0)
.s70:
; 479, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ade : 84 4d __ STY T8 + 0 
.s46:
; 483, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae0 : ad b8 9f LDA $9fb8 ; (si.left + 0)
0ae3 : d0 28 __ BNE $0b0d ; (printf.s47 + 0)
.s50:
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ae5 : a4 4d __ LDY T8 + 0 
0ae7 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0aea : b0 21 __ BCS $0b0d ; (printf.s47 + 0)
.s51:
; 487, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0aec : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0aef : a2 00 __ LDX #$00
.l66:
0af1 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0af4 : e8 __ __ INX
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0af5 : c8 __ __ INY
0af6 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0af9 : 90 f6 __ BCC $0af1 ; (printf.l66 + 0)
.s64:
; 485, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0afb : 84 4d __ STY T8 + 0 
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0afd : a9 ba __ LDA #$ba
0aff : 85 0e __ STA P1 
0b01 : a9 9f __ LDA #$9f
0b03 : 85 0f __ STA P2 
; 496, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b05 : a9 00 __ LDA #$00
0b07 : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
; 497, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b0a : 20 66 0b JSR $0b66 ; (puts.l4 + 0)
.s47:
; 500, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b0d : a5 46 __ LDA T1 + 0 
0b0f : 85 0e __ STA P1 
0b11 : a5 47 __ LDA T1 + 1 
0b13 : 85 0f __ STA P2 
0b15 : 20 66 0b JSR $0b66 ; (puts.l4 + 0)
; 509, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b18 : ad b8 9f LDA $9fb8 ; (si.left + 0)
0b1b : d0 03 __ BNE $0b20 ; (printf.s48 + 0)
0b1d : 4c 11 09 JMP $0911 ; (printf.l5 + 0)
.s48:
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b20 : a4 4d __ LDY T8 + 0 
0b22 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b25 : b0 f6 __ BCS $0b1d ; (printf.s47 + 16)
.s49:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b27 : ad b2 9f LDA $9fb2 ; (si.fill + 0)
0b2a : a2 00 __ LDX #$00
.l65:
0b2c : 9d ba 9f STA $9fba,x ; (buff[0] + 0)
0b2f : e8 __ __ INX
; 511, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b30 : c8 __ __ INY
0b31 : cc b3 9f CPY $9fb3 ; (si.width + 0)
0b34 : 90 f6 __ BCC $0b2c ; (printf.l65 + 0)
.s63:
; 513, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b36 : 86 4c __ STX T7 + 0 
0b38 : 4c 11 09 JMP $0911 ; (printf.l5 + 0)
.s33:
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b3b : a9 ba __ LDA #$ba
0b3d : 85 0f __ STA P2 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b3f : a9 9f __ LDA #$9f
0b41 : 85 0e __ STA P1 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b43 : a9 9f __ LDA #$9f
0b45 : 85 10 __ STA P3 
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b47 : a9 b2 __ LDA #$b2
0b49 : 85 0d __ STA P0 
0b4b : 20 ab 0b JSR $0bab ; (nformi.s4 + 0)
0b4e : 85 4c __ STA T7 + 0 
0b50 : 18 __ __ CLC
0b51 : a5 48 __ LDA T2 + 0 
0b53 : 69 02 __ ADC #$02
0b55 : 85 48 __ STA T2 + 0 
; 424, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b57 : 90 df __ BCC $0b38 ; (printf.s63 + 2)
.s75:
; 428, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b59 : e6 49 __ INC T2 + 1 
0b5b : 4c 11 09 JMP $0911 ; (printf.l5 + 0)
--------------------------------------------------------------------
puts@proxy: ; puts@proxy
0b5e : a9 ba __ LDA #$ba
0b60 : 85 0e __ STA P1 
0b62 : a9 9f __ LDA #$9f
0b64 : 85 0f __ STA P2 
--------------------------------------------------------------------
puts: ; puts(const u8*)->void
;  12, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.h"
.l4:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b66 : a0 00 __ LDY #$00
0b68 : b1 0e __ LDA (P1),y ; (str + 0)
0b6a : d0 01 __ BNE $0b6d ; (puts.s5 + 0)
.s3:
;  20, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b6c : 60 __ __ RTS
.s5:
;  18, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b6d : e6 0e __ INC P1 ; (str + 0)
0b6f : d0 02 __ BNE $0b73 ; (puts.s7 + 0)
.s6:
0b71 : e6 0f __ INC P2 ; (str + 1)
.s7:
;  19, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0b73 : 20 79 0b JSR $0b79 ; (putpch.s4 + 0)
0b76 : 4c 66 0b JMP $0b66 ; (puts.l4 + 0)
--------------------------------------------------------------------
putpch: ; putpch(u8)->void
;  69, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.h"
.s4:
; 206, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b79 : c9 0a __ CMP #$0a
0b7b : d0 0a __ BNE $0b87 ; (putpch.s6 + 0)
.s5:
; 207, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b7d : a9 0d __ LDA #$0d
0b7f : 85 43 __ STA T0 + 0 
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b81 : a5 43 __ LDA T0 + 0 
0b83 : 20 d2 ff JSR $ffd2 
.s3:
; 214, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b86 : 60 __ __ RTS
.s6:
; 208, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b87 : c9 09 __ CMP #$09
0b89 : f0 08 __ BEQ $0b93 ; (putpch.s7 + 0)
.s9:
0b8b : 85 0d __ STA P0 ; (c + 0)
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b8d : a5 0d __ LDA P0 ; (c + 0)
0b8f : 20 d2 ff JSR $ffd2 
0b92 : 60 __ __ RTS
.s7:
; 413, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b93 : a5 d3 __ LDA $d3 
; 210, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b95 : 29 03 __ AND #$03
0b97 : 85 43 __ STA T0 + 0 
; 212, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b99 : a9 20 __ LDA #$20
0b9b : 85 44 __ STA T1 + 0 
.l8:
; 193, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0b9d : a5 44 __ LDA T1 + 0 
0b9f : 20 d2 ff JSR $ffd2 
; 213, "/data/data/com.termux/files/home/GIT/oscar64/include/conio.c"
0ba2 : e6 43 __ INC T0 + 0 
0ba4 : a5 43 __ LDA T0 + 0 
0ba6 : c9 04 __ CMP #$04
0ba8 : 90 f3 __ BCC $0b9d ; (putpch.l8 + 0)
0baa : 60 __ __ RTS
--------------------------------------------------------------------
nformi: ; nformi(const struct sinfo*,u8*,i16,bool)->u8
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
.s4:
;  85, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bab : a9 00 __ LDA #$00
0bad : 85 43 __ STA T5 + 0 
;  82, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0baf : a0 04 __ LDY #$04
0bb1 : b1 0d __ LDA (P0),y ; (si + 0)
0bb3 : 85 44 __ STA T6 + 0 
;  79, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bb5 : a5 13 __ LDA P6 ; (s + 0)
;  87, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bb7 : f0 13 __ BEQ $0bcc ; (nformi.s7 + 0)
.s5:
0bb9 : 24 12 __ BIT P5 ; (v + 1)
0bbb : 10 0f __ BPL $0bcc ; (nformi.s7 + 0)
.s6:
;  90, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bbd : 38 __ __ SEC
0bbe : a9 00 __ LDA #$00
0bc0 : e5 11 __ SBC P4 ; (v + 0)
0bc2 : 85 11 __ STA P4 ; (v + 0)
0bc4 : a9 00 __ LDA #$00
0bc6 : e5 12 __ SBC P5 ; (v + 1)
0bc8 : 85 12 __ STA P5 ; (v + 1)
;  89, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bca : e6 43 __ INC T5 + 0 
.s7:
;  93, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bcc : a9 10 __ LDA #$10
0bce : 85 45 __ STA T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bd0 : a5 11 __ LDA P4 ; (v + 0)
0bd2 : 05 12 __ ORA P5 ; (v + 1)
0bd4 : f0 33 __ BEQ $0c09 ; (nformi.s12 + 0)
.s8:
;  99, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bd6 : a5 11 __ LDA P4 ; (v + 0)
0bd8 : 85 1b __ STA ACCU + 0 
0bda : a5 12 __ LDA P5 ; (v + 1)
0bdc : 85 1c __ STA ACCU + 1 
.l9:
0bde : a5 44 __ LDA T6 + 0 
0be0 : 85 03 __ STA WORK + 0 
0be2 : a9 00 __ LDA #$00
0be4 : 85 04 __ STA WORK + 1 
0be6 : 20 c9 0c JSR $0cc9 ; (divmod + 0)
;  96, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0be9 : a5 05 __ LDA WORK + 2 
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0beb : c9 0a __ CMP #$0a
0bed : b0 04 __ BCS $0bf3 ; (nformi.s10 + 0)
.s34:
0bef : a9 30 __ LDA #$30
0bf1 : 90 06 __ BCC $0bf9 ; (nformi.s11 + 0)
.s10:
;  97, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bf3 : a0 03 __ LDY #$03
0bf5 : b1 0d __ LDA (P0),y ; (si + 0)
0bf7 : e9 0a __ SBC #$0a
.s11:
0bf9 : 18 __ __ CLC
0bfa : 65 05 __ ADC WORK + 2 
;  98, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0bfc : a6 45 __ LDX T7 + 0 
0bfe : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c01 : c6 45 __ DEC T7 + 0 
;  94, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c03 : a5 1b __ LDA ACCU + 0 
0c05 : 05 1c __ ORA ACCU + 1 
0c07 : d0 d5 __ BNE $0bde ; (nformi.l9 + 0)
.s12:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c09 : a0 02 __ LDY #$02
0c0b : b1 0d __ LDA (P0),y ; (si + 0)
0c0d : c9 ff __ CMP #$ff
0c0f : d0 04 __ BNE $0c15 ; (nformi.s13 + 0)
.s33:
0c11 : a9 0f __ LDA #$0f
0c13 : d0 05 __ BNE $0c1a ; (nformi.s39 + 0)
.s13:
; 102, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c15 : 38 __ __ SEC
0c16 : a9 10 __ LDA #$10
0c18 : f1 0d __ SBC (P0),y ; (si + 0)
.s39:
0c1a : a8 __ __ TAY
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c1b : c4 45 __ CPY T7 + 0 
0c1d : b0 0d __ BCS $0c2c ; (nformi.s15 + 0)
.s14:
; 105, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c1f : a9 30 __ LDA #$30
.l40:
0c21 : a6 45 __ LDX T7 + 0 
0c23 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c26 : c6 45 __ DEC T7 + 0 
; 104, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c28 : c4 45 __ CPY T7 + 0 
0c2a : 90 f5 __ BCC $0c21 ; (nformi.l40 + 0)
.s15:
; 107, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c2c : a0 07 __ LDY #$07
0c2e : b1 0d __ LDA (P0),y ; (si + 0)
0c30 : f0 1c __ BEQ $0c4e ; (nformi.s18 + 0)
.s16:
0c32 : a5 44 __ LDA T6 + 0 
0c34 : c9 10 __ CMP #$10
0c36 : d0 16 __ BNE $0c4e ; (nformi.s18 + 0)
.s17:
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c38 : a0 03 __ LDY #$03
0c3a : b1 0d __ LDA (P0),y ; (si + 0)
0c3c : a8 __ __ TAY
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c3d : a9 30 __ LDA #$30
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c3f : a6 45 __ LDX T7 + 0 
; 110, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c41 : ca __ __ DEX
0c42 : ca __ __ DEX
0c43 : 86 45 __ STX T7 + 0 
0c45 : 9d ec 9f STA $9fec,x ; (buffer[0] + 0)
; 109, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c48 : 98 __ __ TYA
0c49 : 69 16 __ ADC #$16
0c4b : 9d ed 9f STA $9fed,x ; (buffer[0] + 1)
.s18:
; 118, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c4e : a9 00 __ LDA #$00
0c50 : 85 1b __ STA ACCU + 0 
; 113, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c52 : a5 43 __ LDA T5 + 0 
0c54 : f0 0c __ BEQ $0c62 ; (nformi.s31 + 0)
.s19:
; 114, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c56 : a9 2d __ LDA #$2d
.s20:
0c58 : a6 45 __ LDX T7 + 0 
0c5a : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c5d : c6 45 __ DEC T7 + 0 
0c5f : 4c 6c 0c JMP $0c6c ; (nformi.s21 + 0)
.s31:
; 115, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c62 : a0 05 __ LDY #$05
0c64 : b1 0d __ LDA (P0),y ; (si + 0)
0c66 : f0 04 __ BEQ $0c6c ; (nformi.s21 + 0)
.s32:
; 116, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c68 : a9 2b __ LDA #$2b
0c6a : d0 ec __ BNE $0c58 ; (nformi.s20 + 0)
.s21:
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c6c : a0 06 __ LDY #$06
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c6e : a6 45 __ LDX T7 + 0 
; 119, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c70 : b1 0d __ LDA (P0),y ; (si + 0)
0c72 : d0 2b __ BNE $0c9f ; (nformi.s22 + 0)
.l26:
; 128, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c74 : 8a __ __ TXA
0c75 : 18 __ __ CLC
0c76 : a0 01 __ LDY #$01
0c78 : 71 0d __ ADC (P0),y ; (si + 0)
0c7a : b0 04 __ BCS $0c80 ; (nformi.s27 + 0)
.s30:
0c7c : c9 11 __ CMP #$11
0c7e : 90 0a __ BCC $0c8a ; (nformi.s28 + 0)
.s27:
; 129, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c80 : a0 00 __ LDY #$00
0c82 : b1 0d __ LDA (P0),y ; (si + 0)
0c84 : 9d eb 9f STA $9feb,x ; (buff[0] + 49)
0c87 : ca __ __ DEX
0c88 : b0 ea __ BCS $0c74 ; (nformi.l26 + 0)
.s28:
; 130, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c8a : e0 10 __ CPX #$10
0c8c : b0 0e __ BCS $0c9c ; (nformi.s41 + 0)
.s29:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c8e : 88 __ __ DEY
.l37:
0c8f : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0c92 : 91 0f __ STA (P2),y ; (str + 0)
0c94 : c8 __ __ INY
0c95 : e8 __ __ INX
0c96 : e0 10 __ CPX #$10
0c98 : 90 f5 __ BCC $0c8f ; (nformi.l37 + 0)
.s38:
; 131, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9a : 84 1b __ STY ACCU + 0 
.s41:
; 134, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9c : a5 1b __ LDA ACCU + 0 
.s3:
0c9e : 60 __ __ RTS
.s22:
; 121, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0c9f : e0 10 __ CPX #$10
0ca1 : b0 1a __ BCS $0cbd ; (nformi.l24 + 0)
.s23:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0ca3 : a0 00 __ LDY #$00
.l35:
0ca5 : bd ec 9f LDA $9fec,x ; (buffer[0] + 0)
0ca8 : 91 0f __ STA (P2),y ; (str + 0)
0caa : c8 __ __ INY
0cab : e8 __ __ INX
0cac : e0 10 __ CPX #$10
0cae : 90 f5 __ BCC $0ca5 ; (nformi.l35 + 0)
.s36:
; 122, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb0 : 84 1b __ STY ACCU + 0 
0cb2 : b0 09 __ BCS $0cbd ; (nformi.l24 + 0)
.s25:
; 124, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cb4 : 88 __ __ DEY
0cb5 : b1 0d __ LDA (P0),y ; (si + 0)
0cb7 : a4 1b __ LDY ACCU + 0 
0cb9 : 91 0f __ STA (P2),y ; (str + 0)
0cbb : e6 1b __ INC ACCU + 0 
.l24:
; 123, "/data/data/com.termux/files/home/GIT/oscar64/include/stdio.c"
0cbd : a5 1b __ LDA ACCU + 0 
0cbf : a0 01 __ LDY #$01
0cc1 : d1 0d __ CMP (P0),y ; (si + 0)
0cc3 : 90 ef __ BCC $0cb4 ; (nformi.s25 + 0)
0cc5 : 60 __ __ RTS
--------------------------------------------------------------------
0cc6 : __ __ __ BYT 25 75 00                                        : %u.
--------------------------------------------------------------------
divmod: ; divmod
0cc9 : a5 1c __ LDA ACCU + 1 
0ccb : d0 31 __ BNE $0cfe ; (divmod + 53)
0ccd : a5 04 __ LDA WORK + 1 
0ccf : d0 1e __ BNE $0cef ; (divmod + 38)
0cd1 : 85 06 __ STA WORK + 3 
0cd3 : a2 04 __ LDX #$04
0cd5 : 06 1b __ ASL ACCU + 0 
0cd7 : 2a __ __ ROL
0cd8 : c5 03 __ CMP WORK + 0 
0cda : 90 02 __ BCC $0cde ; (divmod + 21)
0cdc : e5 03 __ SBC WORK + 0 
0cde : 26 1b __ ROL ACCU + 0 
0ce0 : 2a __ __ ROL
0ce1 : c5 03 __ CMP WORK + 0 
0ce3 : 90 02 __ BCC $0ce7 ; (divmod + 30)
0ce5 : e5 03 __ SBC WORK + 0 
0ce7 : 26 1b __ ROL ACCU + 0 
0ce9 : ca __ __ DEX
0cea : d0 eb __ BNE $0cd7 ; (divmod + 14)
0cec : 85 05 __ STA WORK + 2 
0cee : 60 __ __ RTS
0cef : a5 1b __ LDA ACCU + 0 
0cf1 : 85 05 __ STA WORK + 2 
0cf3 : a5 1c __ LDA ACCU + 1 
0cf5 : 85 06 __ STA WORK + 3 
0cf7 : a9 00 __ LDA #$00
0cf9 : 85 1b __ STA ACCU + 0 
0cfb : 85 1c __ STA ACCU + 1 
0cfd : 60 __ __ RTS
0cfe : a5 04 __ LDA WORK + 1 
0d00 : d0 1f __ BNE $0d21 ; (divmod + 88)
0d02 : a5 03 __ LDA WORK + 0 
0d04 : 30 1b __ BMI $0d21 ; (divmod + 88)
0d06 : a9 00 __ LDA #$00
0d08 : 85 06 __ STA WORK + 3 
0d0a : a2 10 __ LDX #$10
0d0c : 06 1b __ ASL ACCU + 0 
0d0e : 26 1c __ ROL ACCU + 1 
0d10 : 2a __ __ ROL
0d11 : c5 03 __ CMP WORK + 0 
0d13 : 90 02 __ BCC $0d17 ; (divmod + 78)
0d15 : e5 03 __ SBC WORK + 0 
0d17 : 26 1b __ ROL ACCU + 0 
0d19 : 26 1c __ ROL ACCU + 1 
0d1b : ca __ __ DEX
0d1c : d0 f2 __ BNE $0d10 ; (divmod + 71)
0d1e : 85 05 __ STA WORK + 2 
0d20 : 60 __ __ RTS
0d21 : a9 00 __ LDA #$00
0d23 : 85 05 __ STA WORK + 2 
0d25 : 85 06 __ STA WORK + 3 
0d27 : 84 02 __ STY $02 
0d29 : a0 10 __ LDY #$10
0d2b : 18 __ __ CLC
0d2c : 26 1b __ ROL ACCU + 0 
0d2e : 26 1c __ ROL ACCU + 1 
0d30 : 26 05 __ ROL WORK + 2 
0d32 : 26 06 __ ROL WORK + 3 
0d34 : 38 __ __ SEC
0d35 : a5 05 __ LDA WORK + 2 
0d37 : e5 03 __ SBC WORK + 0 
0d39 : aa __ __ TAX
0d3a : a5 06 __ LDA WORK + 3 
0d3c : e5 04 __ SBC WORK + 1 
0d3e : 90 04 __ BCC $0d44 ; (divmod + 123)
0d40 : 86 05 __ STX WORK + 2 
0d42 : 85 06 __ STA WORK + 3 
0d44 : 88 __ __ DEY
0d45 : d0 e5 __ BNE $0d2c ; (divmod + 99)
0d47 : 26 1b __ ROL ACCU + 0 
0d49 : 26 1c __ ROL ACCU + 1 
0d4b : a4 02 __ LDY $02 
0d4d : 60 __ __ RTS
--------------------------------------------------------------------
spentry:
0d4e : __ __ __ BYT 00                                              : .
--------------------------------------------------------------------
xs:
0d4f : __ __ __ BYT 01 00                                           : ..
