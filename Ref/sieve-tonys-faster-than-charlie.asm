	FASTER THAN CHARLIE

Is this the last word on prime number generation?

I modified Charles Putney's program from the February issue, and cut the time from 330 milliseconds down to 183 milliseconds! Here is what I did:

I sped up the zero-memory loop by putting more STA's within the loop.
I removed the CLC from the main loop. After all, why CLC within the loop if you're looping on a BCC condition?
I removed the LDA #$FF from the main loop. It was there to be sure a non-zero value gets stored in non-prime slots, but why LDA #$FF if the accumulator never contains $00 within the loop?
I changed the way squares of primes are computed. Charlie did it using a quick 8-bit by 8-bit multiply. I took advantage of a little number theory, and shaved off some time.
The method I use for squaring may appear very round-about, but it actually is faster in this case. Look at the following table:

    Odd #'s  square   neat formula
       1       1       0 * 8 + 1
       3       9       1 * 8 + 1
       5      25       3 * 8 + 1
       7      49       6 * 8 + 1
       9      81      10 * 8 + 1
The high byte of the changing factor in the "neat formula" is stored in the LDA instruction at line 1550, and the low byte in the ADC instruction at line 1900. The factor is the sum of the numbers from 1 to n: 1+2=3, 1+2+3=6, 1+2+3+4=10, etc. In all, 31 primes are squared, and the total time for all the squaring is less than 3 milliseconds.

Here is a driver in Applesoft to load the program and then print out primes from the data array.

     10  REM DRIVER FOR TONY'S FAST PRIME FINDER
     20  PRINT CHR$ (4)"BLOAD B.TONY'S SUPER-FAST PRIMES"
     30  HOME : PRINT "HIT ANY KEY TO START"
     40  GET A$: PRINT " GENERATING PRIMES . . ."
     50  CALL 32768
     60  FOR A = 8195 TO 24576 STEP 2
     70  IF  PEEK (A) = 0 THEN  PRINT A - 8192;" ";
     80  NEXT
A few more cycles can probably still be shaved.... Any takers?

 1000  *SAVE S.TONY'S SUPER-FAST PRIMES
 1010         .OR $8000    SAFELY OUT OF WAY
 1020         .TF B.TONY'S SUPER-FAST PRIMES
 1030  *---------------------------------
 1040  BASE   .EQ $2000    BASE OF PRIME ARRAY
 1050  BEEP   .EQ $FF3A    BEEP THE SPEAKER
 1060  *--------------------------------
 1070         .MA ZERO
 1080         STA ]1+$001,X
 1090         STA ]1+$101,X
 1100         STA ]1+$201,X
 1110         STA ]1+$301,X
 1120         STA ]1+$401,X
 1130         STA ]1+$501,X
 1140         STA ]1+$601,X
 1150         STA ]1+$701,X
 1160         .DO ]1<$5800
 1170         >ZERO ]1+$800
 1180         .FIN
 1190         .EM
 1200  *---------------------------------
 1210  *      MAIN CALLING ROUTINE
 1220  *
 1230  MAIN   LDA #100     DO 100 TIMES SO WE CAN MEASURE
 1240         STA COUNT    THE TIME IT TAKES
 1250         JSR BEEP     ANNOUNCE START
 1260  .1     JSR PRIME
 1270         DEC COUNT    CHECK COUNT
 1280         BNE .1       DONE ?
 1290         JMP BEEP     SAY WE'RE DONE
 1300  *---------------------------------
 1310  *      PRIME ROUTINE
 1320  *      SETS ARRAY STARTING AT BASE
 1330  *      TO $FF IF NUMBER IS NOT PRIME
 1340  *      CHECKS ONLY ODD NUMBERS > 3
 1350  *      INC = INCREMENT OF KNOCKOUT
 1360  *      N = KNOCKOUT VARIABLE
 1370  *--------------------------------
 1380  PRIME
 1390         LDX #1
 1400         STX SHCNT+1  STARTING MULTIPLIER FOR SQUARE
 1410         STX MULT+1
 1420         DEX
 1430         STX SQUARE+1
 1440         TXA          CLEAR WORKING ARRAY
 1450  .1     >ZERO BASE
 1460         INX          EVERY ODD LOCATION
 1470         INX
 1480         BEQ .2
 1490         JMP .1       NOT FINISHED CLEARING
 1500  *--------------------------------
 1510  .2     LDA #3
 1520         STA START+1
 1530  MAINLP ASL          INC = START * 2
 1540         STA INC+1
 1550  SQUARE LDA #*-*     MOVE MULT TO N
 1560         STA N+2
 1570         LDA MULT+1
 1580         ASL          MULTIPLY BY 8
 1590         ROL N+2
 1600         ASL
 1610         ROL N+2
 1620         ASL
 1630         ROL N+2
 1640         TAX
 1650         INX          AND ADD 1
 1660         BNE .1
 1670         INC N+2
 1680  .1     CLC          ADD BASE TO N
 1690         LDA N+2
 1700         ADC /BASE
 1710         STA N+2
 1720         TAY
 1730         TXA
 1740  LOOP
 1750  N      STA $FF00,X  REMEMBER THAT N IS REALLY AT N+2
 1760  INC    ADC #*-*     N = N + INC
 1770         TAX
 1780         BCC LOOP     DONT'T BOTHER TO ADD, NO CARRY
 1790         INY          INC HIGH ORDER
 1800         STY N+2
 1810         CPY /BASE+$4000  IF IS GREATER THAN $6000
 1820         BCC LOOP     NO, REPEAT 
 1830  START  LDX #*-*     GET OUR NEXT KNOCKOUT 
 1840  NEXT   INX
 1850         INX          START = START + 2
 1860         BMI END      WE'RE DONE IF X>$7F
 1870         INC SHCNT+1  INCREMENT SQUARE MULTIPLIER
 1880  SHCNT  LDA #*-*     AND ADD TO MULTIPLIER
 1890         CLC
 1900  MULT   ADC #*-*
 1910         STA MULT+1
 1920         BCC .1
 1930         INC SQUARE+1
 1940  .1     LDA BASE,X   GET A POSSIBLE PRIME
 1950         BNE NEXT     THIS ONE HAS BEEN KNOCKED OUT
 1960         STX START+1
 1970         TXA
 1980         BNE MAINLP   ...ALWAYS
 1990  END    RTS 
 2000  *--------------------------------
 2010  COUNT  .DA #*-*     COUNT FOR 100 TIMES LOOP
