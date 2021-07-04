Charlie is a long-time friend and subscriber in Ireland ]

Bob, I wanted to answer your challenge in the October 1981 AAL for some time, but this is the first chance I had. You sifted out the primes in 690 milliseconds, and challenged readers to beat your time. I did it!

I increased the speed by using a faster algorithm, and by using some self-modifying code in the loops. I know self-modifying code is dangerous, and a NO-NO, but it amounts to about 50 milliseconds improvement.

The algorithm changes are an even greater factor. The main ideas for the sieve are:

Only check odd numbers
Get next increment from the prime array. This means you only knock out primes.
Start knocking out at P^2. That is, if prime found is 3, start at 9.
Increment the knock-out index by 2*P. This avoids knocking out even numbers.
Stop at the square-root of the maximum number.
Your algorithm did all the above except 3 and 4.

With these routines, a generation takes 330 milliseconds. This is over twice as fast as yours!

You could still shave a little time off by optimizing the square routine, and even including it inline since it is only called from one place.

I'll grant you that this is not the same algorithm, but the goal is to find primes fast. I know throw down the glove for the next challenger!

   13  TEXT : HOME :
       PRINT "CHARLES PUTNEY'S FASTER PRIME GENERATOR 
              ---------------------------------------"
   20  VTAB 10: HTAB 15: PRINT "LOADING . . ."
   30  HGR : TEXT 
   40 D$ =  CHR$ (4): PRINT D$"BLOAD B.PUTNEY'S PRIMES"
   50  HOME : VTAB 10: HTAB 10: PRINT "HIT ANY KEY TO START"
   60  POKE 49168,0: GET A$: POKE 49168,0
   80  POKE 49232,0: POKE 49239,0
   90  CALL 32768
   95  TEXT : FOR A = 8195 TO 24576 STEP 2:
       IF  PEEK (A) = 0 THEN  PRINT A - 8192;" ";
   98  NEXT 
  100  REM   PRIME TESTER
  110  REM   CHARLES H. PUTNEY
  120  REM   18 QUINNS ROAD
  130  REM   SHANKILL
  140  REM   CO. DUBLIN
  150  REM   IRELAND
  160  REM   TIME FOR 100 RUNS = 42 SECONDS
 1000         .OR $8000    SAFELY OUT OF WAY
 1010         .TF B.PUTNEY'S PRIMES
 1020  *---------------------------------
 1030  BASE   .EQ $2000    BASE OF PRIME ARRAY
 1040  BEEP   .EQ $FF3A    BEEP THE SPEAKER
 1050  *---------------------------------
 1060  *      MAIN CALLING ROUTINE
 1070  *
 1080  MAIN   LDA #100     DO 100 TIMES SO WE CAN MEASURE
 1090         STA COUNT    THE TIME IT TAKES
 1100         JSR BEEP     ANNOUNCE START
 1110  .1     JSR ZERO     CLEAR ARRAY  
 1120         LDA #$03
 1130         STA START    SET STARTING VALUE
 1140         JSR PRIME
 1150         DEC COUNT    CHECK COUNT
 1160         BNE .1       DONE ?
 1170         JSR BEEP     SAY WE'RE DONE
 1180         RTS
 1190  *---------------------------------
 1200  *      ROUTINE TO ZERO MEMORY
 1210  *      FROM $2000 TO $6000
 1220  *
 1230  ZERO   LDA #BASE+1  START AT $2001
 1240         STA .1+1     MODIFY OUR STORE
 1250         LDA /BASE+1
 1260         STA .1+2
 1270         LDA #$00     GET A ZERO
 1280         TAX          SET INDEX
 1290         LDY #$40     NUMBER OF PAGES
 1300  .1     STA $FFFF,X  MODIFIED AS WE GO  
 1310         INX          EVERY ODD LOCATION
 1320         INX
 1330         BNE .1       NOT DONE
 1340         INC .1+2     NEXT PAGE
 1350         DEY
 1360         BNE .1       NOT YET
 1370         RTS
 1380  *---------------------------------
 1390  *      PRIME ROUTINE
 1400  *      SETS ARRAY STARTING AT BASE
 1410  *      TO $FF IF NUMBER IS NOT PRIME
 1420  *      CHECKS ONLY ODD NUMBERS > 3
 1430  *      INC = INCREMENT OF KNOCKOUT
 1440  *      N = KNOCKOUT VARIABLE
 1450  *
 1460  PRIME  LDA START
 1470         ASL          INC = START * 2
 1480         STA INC
 1490         JSR SQUARE   SET N = N * N
 1500         CLC          ADD BASE TO N
 1510         LDA N+1
 1520         ADC #BASE
 1530         TAX          KEEP LOW ORDER PART IN X
 1540         LDA #0       N+1 TO ZERO
 1550         STA N+1
 1560         LDA N+2
 1570         ADC /BASE
 1580         STA N+2
 1590         TAY
 1600  LOOP   LDA #$FF     FLAG AS NOT PRIME 
 1610  N      STA $FFFF,X  REMEMBER THAT N IS REALLY AT N+1 
 1620         CLC          N = N + INC
 1630         TXA          N=N+INC
 1640         ADC INC
 1650         TAX
 1660         BCC LOOP     DONT'T BOTHER TO ADD, NO CARRY
 1670         INY          INC HIGH ORDER
 1680         STY N+2
 1690         CPY /BASE+$4000  IF IS GREATER THAN $6000
 1700         BCC LOOP     NO, REPEAT 
 1710         LDX START    GET OUR NEXT KNOCKOUT 
 1720  .1     INX
 1730         INX          START = START + 2
 1740         BMI .2       WE'RE DONE IF X>$7F
 1750         LDA BASE,X   GET A POSSIBLE PRIME
 1760         BNE .1       THIS ONE HAS BEEN KNOCKED OUT
 1770         STX START
 1780         BEQ PRIME    ...ALWAYS
 1790  .2     RTS 
 1800  *---------------------------------
 1810  *      SQUARE ROUTINE
 1820  *      TAKES SQUARE OF NUMBER
 1830  *      IN START (ONE BYTE) AND
 1840  *      PUTS RESULT IN N+1 (LOW)
 1850  *      AND N+2 (HIGH)
 1860  *
 1870  SQUARE LDA #$00
 1880         STA N+1      CLEAR N
 1890         STA N+2
 1900         STA MULT+1   AND MULTIPLIER HIGH
 1910         LDA START
 1920         STA MULT     MULT LOW = START
 1930         STA SHCNT    SHIFT COUNTER
 1940         LDX #$08     EIGHT SHIFTS 
 1950  .1     ROR SHCNT    GET LS BIT IN CARRY
 1960         BCC .2       DON'T ADD THIS TIME 
 1970         CLC          N = N + MULT
 1980         LDA N+1
 1990         ADC MULT
 2000         STA N+1
 2010         LDA N+2
 2020         ADC MULT+1
 2030         STA N+2
 2040  .2     CLC          SHIFT MULT (BOTH BYTES) 
 2050         ROL MULT 
 2060         ROL MULT+1
 2070         DEX
 2080         BNE .1       MORE BITS ?
 2090         RTS
 2100  START  .DA #*-*     STARTING KNOCKOUT
 2110  INC    .DA #*-*     INCREMENT FOR KNOCKOUT
 2120  COUNT  .DA #*-*     COUNT FOR 100 TIMES LOOP
 2130  MULT   .DA *-*      MULTIPIER 
 2140  SHCNT  .DA #*-*     SHIFT COUNT MULTIPLIER
