Sifting Primes Faster and Faster
	Bob Sander-Cederlof

Benchmark programs are sometimes useful for selecting between various processors. Quite a few articles have been published which compare and rank the various Z-80, 8080, 6800, and 6502 systems based on the speed with which they execute a given BASIC program. Some of us cannot resist the impulse to show them up by recoding the benchmark in our favorite language on our favorite processor, using our favorite secret tricks for trimming microseconds.

"A High-Level Language Benchmark" (by Jim Gilbreath, BYTE, September, 1981, pages 180-198) is just such an article. Jim compared execution time in Assembly, Forth, Basic, Fortran, COBOL, PL/I, C, and other languages; he used all sorts of computers, including the above four, the Motorola 68000, the DEC PDP 11/70, and more. He used a short program which finds the 1899 primes between 3 and 16384 by means of a sifting algorithm (Sieve of Eratosthenes).

His article includes table after table of comparisons. Some of the key items of interest to me were:

     Language and Machine                    Seconds

     Assembly Language 68000 (8 MHz)            1.12
     Assembly Language Z80                      6.80
     Digital Research PL/I (Z80)               14.0
     Microsoft BASIC Compiler (Z80)            18.6
     FORTH 6502                               265.
     Apple UCSD Pascal                        516.
     Apple Integer BASIC                     2320.
     Applesoft BASIC                         2806.
     Microsoft COBOL Version 2.2 (Z80)       5115.
There is a HUGE error in the data above; I don't know if it is the only one or not. The time I measured for the Apple Integer BASIC version was only 188 seconds, not 2320 seconds! How could he be so far off? His data is obviously wrong, because Integer BASIC in his data is too close to the same speed as Applesoft.

I also don't know why they neglected to show what the 6502 could do with an assembly language version. Or maybe I do....were they ashamed?

William Robert Savoie, an Apple owner from Tennessee, sent me a copy of the article along with his program. He "hand-compiled" the BASIC version of the benchmark program, with no special tricks at all. His program runs in only 1.39 seconds! That is almost as fast as the 8 MHz Motorola 68000 system! The letter that accompanied his program challenged anyone to try to speed up his program.

How could I pass up a challenge like that? I wrote my own version of the program, and cut the time to 0.93 seconds! Then I made one small change to the algorithm, and produced exactly the same results in only 0.74 seconds!

Looking back at Jim Gilbreath's article, he concludes that efficient, powerful high-level languages are THE way to go. He eschews the use of assembly language for any except the most drastic requirements, because he could not see a clear speed advantage. He points out the moral that a better algorithm is superior to a faster CPU. (Note that his algorithm is by no means the fastest one, by the way.)

Here is Gilbreath's algorithm, in Integer BASIC:

     >LIST
        10 S=8190: DIM F(8191): N=0
        20 FOR I=0 TO S: F(I)=1: NEXT I
        30 FOR I=0 TO S: IF F(I)=0 THEN 80
        40 P=I+I+3: K=I+P
        50 IF K>S THEN 70
        60 F(K)=0: K=K+P: GOTO 50
        70 N=N+1: REM PRINT P;" ";
        80 NEXT I
        90 PRINT: PRINT N;" PRIMES": END
The REM tagged onto the end of line 70, if changed to a real PRINT statement, will print the list of prime numbers as they are generated. Of course printing them was not included in any of the time measurements. According to my timing, printing adds 12 seconds to the program.

I modified the algorithm to take advantage of some more prior knowledge about sifting: There is no need to go through the loop in lines 50 and 60 if P is greater than 127 (the largest prime no bigger than the square root of 16384). This means changing line 40 to read:

     40 P=I+I+3 : IF P>130 THEN 70 : K=I+P
This change cut the time for the program from 188 seconds to 156 seconds. My assembly language version of the original algorithm ran in 0.93 seconds, or 202 times faster; the better algorithm ran in 0.74 seconds, or almost 211 times faster.

William Savoie has done a magnificent job in hand-compiling the first program. He ran the program 100 times in a loop, so that he could get an accurate time using his Timex watch. Here is the listing of his program.

 1000         .LIF
 1010  *---------------------------------
 1020  *      SIEVE PROGRAM:
 1030  *      CALCULATES FIRST 1899 PRIMES IN 1.39 SECONDS!
 1040  *
 1050  *      INSPIRED BY JIM GILBREATH, BYTE, 9/81
 1060  *
 1070  *      WRITTEN BY WILLIAM ROBERT SAVOIE
 1080  *                 4405 DELASHMITT RD. APT 15
 1090  *                 HIXSON, TENN  37343
 1100  *---------------------------------
 1110  BUFF   .EQ $3500    START OF BUFFER (#BUFF=0)
 1120  SIZE   .EQ 8189     SIZE OF FLAG ARRAY
 1130  *---------------------------------
 1140  *      PAGE-ZERO VARIABLES
 1150  *---------------------------------
 1160  INDEX  .EQ $06      PAGE ZERO INDEX (LOCATION FOR I)
 1170  PRIME  .EQ $08      PRIME LOCATION
 1180  KVAR   .EQ $19      K VARIABLE 
 1190  CVAR   .EQ $1B      COUNT OF PRIME
 1200  ARRAY  .EQ $1D      ARRAY POINTER
 1210  SAVE   .EQ $1F      COUNT LOOP
 1220  *---------------------------------
 1230  *      ROM ROUTINES
 1240  *---------------------------------
 1250  HOME   .EQ $FC58    CLEAR VIDEO
 1260  CR     .EQ $FD8E    CARRIAGE RETURN
 1270  LINE   .EQ $FD9E    PRINT "-"
 1280  PRINTN .EQ $F940    PRINT 2 BYTE NUMBER IN HEX
 1290  BELL   .EQ $FBE2    SOUND BELL WHEN DONE
 1300  *---------------------------------
 1310  * RUN PROGRAM 100 TIMES FOR ACCURATE TIME MEASUREMENTS!
 1320  *---------------------------------
 1330  START  JSR HOME     CLEAR SCREEN
 1340         JSR CR       CARRIAGE RETURN
 1350         LDA #100     LOOP 100 TIMES
 1360         STA SAVE     SET COUNTER
 1370  .01    JSR GO       RUN PRIME
 1380         DEC SAVE     DECREASE SAVE
 1390         BNE .01      LOOP
 1400         JSR PRINT    PRINT COUNT
 1410         JSR BELL     READ WATCH!
 1420         RTS
 1430  *---------------------------------
 1440  *      RESET VARIABLES
 1450  *---------------------------------
 1460  GO     LDY #00      CLEAR INDEX
 1470         STY CVAR     CLEAR COUNT VARIABLE
 1480         STY CVAR+1   HI BYTE TOO
 1490         STY INDEX    CLEAR INDEX
 1500         STY INDEX+1  HI BYTE TOO
 1510         STY ARRAY    LOW BYTE OF ARRAY
 1520         LDA /BUFF    GET BUFFER LOCATION
 1530         STA ARRAY+1  SET ARRAY POINTER
 1540         LDA #$01     LOAD WITH ONE
 1550         LDX /SIZE    LOAD STOP BYTE
 1560         INX          MAKE PAGE LARGER
 1570  *---------------------------------
 1580  *      SET EACH ELEMENT IN ARRAY TO ONE
 1590  *---------------------------------
 1600  SET    STA (ARRAY),Y  SET MEMORY
 1610         DEY          NEXT LOCATION
 1620         BNE SET      GO 256 TIMES
 1630         INC ARRAY+1  MOVE ARRAY INDEX
 1640         DEX          TEST END
 1650         BNE SET      GO TELL END
 1660  
 1670  * SET ARRAY INDEX AT START OF BUFFER
 1680         LDA #BUFF    SET BUFFER LOCATION
 1690         STA ARRAY    IN ARRAY POINTER LOW
 1700         LDA /BUFF    SET BUFFER LOCATION
 1710         STA ARRAY+1  IN ARRAY POINTER
 1720         JMP FORIN    ENTER SIEVE ALGORITHM
 1730  
 1740  * SCAN ENTIRE ARRAY AND PROBAGATE LAST PRIME
 1750  FORNXT INC INDEX    INCREASE LOW BYTE
 1760         BNE FORIN    GO IF < 256
 1770         INC INDEX+1  INCREASE HI BYTE
 1780  FORIN  LDA INDEX    GET INDEX TO ARRAY
 1790         CLC          READY ADD
 1800         STA ARRAY    SAVE LOW BYTE
 1810         LDA INDEX+1  GET HI BYTE
 1820         ADC /BUFF    ADD BUFFER LOCATION
 1830         STA ARRAY+1  SET POINTER
 1840         LDY #00      CLEAR Y REGISTER
 1850         LDA (ARRAY),Y  GET ARRAY VALUE 
 1860         BEQ FORNXT   GO IF FLAG=0 SINCE NOT PRIME
 1870  * CALCULATE NEXT PRIME NUMBER WITH P=I+I+3
 1880         LDA INDEX    MAKE P=I+3
 1890         ADC #03      ADD THREE
 1900         STA PRIME
 1910         LDA INDEX+1
 1920         ADC #00      ADD CARRY
 1930         STA PRIME+1
 1940  * NOW P=I+3
 1950         LDA PRIME
 1960         ADC INDEX    MAKE P=P+I 
 1970         STA PRIME
 1980         LDA PRIME+1
 1990         ADC INDEX+1  ADD HI BYTE
 2000         STA PRIME+1  SAVE P
 2010  
 2020  * NOW CALCULATE K=I+PRIME (CLEAR BEYOND PRIME)
 2030         LDA INDEX    ADD I TO P
 2040         ADC PRIME
 2050         STA KVAR     SAVE IN K
 2060         LDA INDEX+1
 2070         ADC PRIME+1  ADD HI BYTE TOO
 2080         STA KVAR+1   SAVE K VALUE
 2090  
 2100  * SEE IF K > SIZE AND MODIFY ARRAY IF NOT
 2110  .02    LDA KVAR     GET K VAR
 2120         SEC          SET CARRY FOR SUB
 2130         SBC #SIZE    SUBTRACT SIZE
 2140         LDA KVAR+1   GET HI BYTE
 2150         SBC /SIZE    SUBTRACT TOO
 2160         BCS .03      GO IF K < SIZE
 2170  * ASSIGN ARRAY(K)=0 SINCE PRIME CAN BE ADDED TO MAKE NUMBER
 2180  * THEREFORE THIS CANNOT BE PRIME! (PROBAGATE THROUGH ARRAY)
 2190         LDA KVAR     GET INDEX TO ARRAY
 2200         STA ARRAY    SAVE LOW BYTE
 2210         LDA KVAR+1   GET HI BYTE
 2220         ADC /BUFF    ADD BUFFER OFFSET
 2230         STA ARRAY+1  SAVE ARRAY INDEX
 2240         LDA #00      CLEAR A
 2250         TAY          AND Y REGISTER
 2260         STA (ARRAY),Y  CLEAR ARRAY LOCATION
 2270  * CREATE NEW K FROM K=K+PRIME (MOVE THROUGH ARRAY)
 2280         LDA KVAR     GET K LOW
 2290         ADC PRIME    ADD PRIME
 2300         STA KVAR     SAVE K
 2310         LDA KVAR+1   NOW ADD HI BYTES
 2320         ADC PRIME+1
 2330         STA KVAR+1
 2340         JMP .02      LOOP TELL ARRAY DONE
 2350  * NOW COUNT PRIMES FOUND  (C=C+1)
 2360  .03
 2370  * --NOTE-- DELETE NEXT LINE TO TIME PROGRAM (JSR PRINTP)
 2380         JSR PRINTP   PRINT PRIME
 2390         INC CVAR     ADD ONE
 2400         BNE .04      GO IF NO OVERFLOW
 2410         INC CVAR+1   HI BYTE COUNTER
 2420  .04    LDA INDEX    GET INDEX
 2430  * TEST TO SEE IF WE HAVE INDEXED THROUGH ENTIRE ARRAY
 2440         SBC #SIZE    SUBTRACT SIZE
 2450         LDA INDEX+1  GET HI BYTE TOO
 2460         SBC /SIZE    SUBTRACT HI BYTE
 2470         BCC FORNXT   CONTINUE?
 2480         RTS
 2490  *---------------------------------
 2500  * PRINT THE NUMBER OF PRIMES FOUND
 2510  *---------------------------------
 2520  PRINT  LDY CVAR+1   GET HI BYTE OF COUNT
 2530         LDX CVAR
 2540         JSR PRINTN   PRINT PRIMES FOUND
 2550         RTS          JOB DONE, RETURN
 2560  *---------------------------------
 2570  *      PRINT THE PRIME NUMBER (OPTIONAL)
 2580  *---------------------------------
 2590  PRINTP LDY PRIME+1  HI BYTE 
 2600         LDX PRIME
 2610         JSR PRINTN
 2620         JSR LINE     VIDEO "-" OUT
 2630         SEC
 2640         RTS
Here is a listing of my fastest version.
 1000  *---------------------------------
 1010  * SIEVE PROGRAM:
 1020  * CALCULATES FIRST 1899 PRIMES IN .74 SECONDS!
 1030  *
 1040  * INSPIRED BY JIM GILBREATH
 1050  *   (SEE BYTE MAGAZINE, 9/81, PAGES 180-198.)
 1060  * AND BY WILLIAM ROBERT SAVOIE
 1070  *   4405 DELASHMITT RD. APT 15
 1080  *   HIXSON, TENN  37343
 1090  *---------------------------------
 1100  ARRAY  .EQ $3500    FLAG BYTE ARRAY
 1110  SIZE   .EQ 8192     SIZE OF FLAG ARRAY
 1120  *---------------------------------
 1130  * PAGE-ZERO VARIABLES
 1140  *---------------------------------
 1150  A.PNTR .EQ $06,07   POINTER TO FLAG ARRAY FOR OUTER LOOP
 1160  B.PNTR .EQ $08,09   POINTER TO FLAG ARRAY FOR INNER LOOP
 1170  PRIME  .EQ $1B,1C   LATEST PRIME NUMBER
 1180  COUNT  .EQ $1D,1E   # OF PRIMES SO FAR
 1190  TIMES  .EQ $1F      COUNT LOOP
 1200  *---------------------------------
 1210  * APPLE ROM ROUTINES USED
 1220  *---------------------------------
 1230  PRINTN .EQ $F940    PRINT 2 BYTE NUMBER FROM MONITOR
 1240  HOME   .EQ $FC58    CLEAR VIDEO
 1250  CR     .EQ $FD8E    CARRIAGE RETURN
 1260  LINE   .EQ $FD9E    PRINT "-"
 1270  BELL   .EQ $FBE2    SOUND BELL WHEN DONE
 1280  *---------------------------------
 1290  * RUN PROGRAM 100 TIMES FOR ACCURATE TIME MEASUREMENTS!
 1300  *---------------------------------
 1310  START  JSR HOME     CLEAR SCREEN
 1320         LDA #100     LOOP 100 TIMES
 1330         STA TIMES    SET COUNTER
 1340  .1     JSR GENERATE.PRIMES
 1350         LDA $400     TOGGLE SCREEN FOR VISIBLE INDICATOR
 1360         EOR #$80     OF ACTION
 1370         STA $400
 1380         DEC TIMES
 1390         BNE .1       LOOP
 1400         JSR BELL     READ WATCH!
 1410         LDY COUNT+1  GET HI BYTE OF COUNT
 1420         LDX COUNT
 1430         JSR PRINTN   PRINT PRIMES FOUND
 1440         RTS
 1450  *---------------------------------
 1460  *      GENERATE THE PRIMES
 1470  *---------------------------------
 1480  GENERATE.PRIMES
 1490         LDY #0       CLEAR INDEX
 1500         STY COUNT    CLEAR COUNT VARIABLE
 1510         STY COUNT+1
 1520         STY A.PNTR   SET UP POINTER FOR OUTER LOOP
 1530         LDA /ARRAY
 1540         STA A.PNTR+1
 1550         LDA #1       LOAD WITH ONE
 1560         LDX /SIZE      NUMBER OF PAGES TO STORE IN
 1570  *---------------------------------
 1580  * SET EACH ELEMENT IN ARRAY TO ONE
 1590  *---------------------------------
 1600  .1     STA (A.PNTR),Y  SET FLAG TO 1
 1610         INY          NEXT LOCATION
 1620         BNE .1       GO 256 TIMES
 1630         INC A.PNTR+1 POINT AT NEXT PAGE
 1640         DEX          NEXT PAGE
 1650         BNE .1       MORE PAGES
 1660  *---------------------------------
 1670  * SCAN ENTIRE ARRAY, LOOKING FOR A PRIME
 1680  *---------------------------------
 1690         LDA /ARRAY   SET A.PNTR TO BEGINNING AGAIN
 1700         STA A.PNTR+1
 1710  .2     LDY #0       CLEAR INDEX
 1720         LDA (A.PNTR),Y  LOOK AT NEXT FLAG
 1730         BEQ .6       NOT PRIME, ADVANCE POINTER
 1740  *---------------------------------
 1750  * CALCULATE CURRENT INDEX INTO FLAG ARRAY
 1760  *---------------------------------
 1770         SEC
 1780         LDA A.PNTR+1
 1790         SBC /ARRAY
 1800         TAX          SAVE HI-BYTE OF INDEX
 1810         LDA A.PNTR   LO-BYTE OF INDEX
 1820  *---------------------------------
 1830  * CALCULATE NEXT PRIME NUMBER WITH P=I+I+3
 1840  *---------------------------------
 1850         ASL          DOUBLE THE INDEX
 1860         TAY
 1870         TXA          HI-BYTE OF INDEX
 1880         ROL
 1890         TAX
 1900         TYA          NOW ADD 3
 1910         ADC #3
 1920         STA PRIME
 1930         BCC .3
 1940         INX
 1950  .3     STX PRIME+1
 1960  *---------------------------------
 1970  * FOLLOWING 4 LINES CHANGE ALGORITHM SLIGHTLY
 1980  * TO SPEED IT UP FROM .93 TO .74 SECONDS
 1990  *---------------------------------
 2000         TXA          TEST HIGH BYTE
 2010         BNE .5       PRIME > SQRT(16384)
 2020         CPY #127
 2030         BCS .5       PRIME > SQRT(16384)
 2040  *---------------------------------
 2050  * NOW CLEAR EVERY P-TH ENTRY AFTER P
 2060  *---------------------------------
 2070         LDY #0
 2080         LDA A.PNTR   USE CURRENT OUTER POINTER FOR INNER POINTER
 2090         STA B.PNTR
 2100         LDA A.PNTR+1
 2110         STA B.PNTR+1
 2120         CLC          BUMP ARRAY POINTER BY P
 2130  .4     LDA B.PNTR   BUMP TO NEXT SLOT
 2140         ADC PRIME
 2150         STA B.PNTR
 2160         LDA B.PNTR+1
 2170         ADC PRIME+1
 2180         STA B.PNTR+1
 2190         CMP /ARRAY+SIZE     SEE IF BEYOND END OF ARRAY
 2200         BCS .5       YES, FINISHED CLEARING
 2210         TYA          NO, CLEAR ENTRY IN ARRAY
 2220         STA (B.PNTR),Y
 2230         BEQ .4       ...ALWAYS
 2240  *---------------------------------
 2250  * NOW COUNT PRIMES FOUND  (C=C+1)
 2260  *---------------------------------
 2270  .5
 2280  *      JSR PRINTP   PRINT PRIME
 2290         INC COUNT
 2300         BNE .6 
 2310         INC COUNT+1
 2320  *---------------------------------
 2330  * ADVANCE OUTER POINTER AND TEST IF FINISHED
 2340  *---------------------------------
 2350  .6     INC A.PNTR
 2360         BNE .7
 2370         INC A.PNTR+1
 2380  .7     LDA A.PNTR+1
 2390         CMP /ARRAY+SIZE
 2400         BCC .2
 2410         RTS
 2420  *---------------------------------
 2430  * OPTIONAL PRINT PRIME SUBROUTINE
 2440  *---------------------------------
 2450  PRINTP LDY PRIME+1  HI BYTE 
 2460         LDX PRIME
 2470         JSR PRINTN   PRINT DECIMAL VAL
 2480         JSR LINE     VIDEO "-" OUT
 2490         RTS
Michael R. Laumer, of Carrollton, Texas, has been working for about a year on a full-scale compiler for the Integer BASIC language. He has it nearly finished now, so just for fun he used it to compile the algorithm from Gilbreath's article. Mike used a slightly different form of the Integer BASIC program than I did, which took 238 seconds to execute. But the compiled version ran in only 20 seconds! If you are interested in compiling Integer BASIC programs, you can write to Mike at Laumer Research, 1832 School Road, Carrollton, TX 75006.

If you want to, you can easily cut the time of my program from 0.74 to about .69 seconds. Lines 1600-1650 in my program set each byte in ARRAY to $01. If I don't mind the extra program length, I can rewrite this loop to run in about 42 milliseconds instead of the over 90 it now takes. Here is how I would do it:

     .1     STA ARRAY,Y
            STA ARRAY+$100,Y
            STA ARRAY+$200,Y
            STA ARRAY+$300,Y          TOTAL OF 32
             .                       LINES LIKE THESE
             .
             .
            STA ARRAY+$1E00,Y
            STA ARRAY+$1F00,Y
            INY
            BNE .1
If you can find a way to implement the same program in less than 0.69 seconds, you are hereby challenged to do so!
