;;; (jsk: this fil is from here:
;;;   - http://wilsonminesco.com/stacks/StackOps.ASM )

; Appendix A of the stacks treatise at http://wilsonminesco.com/stacks/


;    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;    * *                                                                   * *
;    * *   NOTE:  This file is not finished, but I have not been able      * *
;    * *          to work on it recently and did not want to hold up       * *
;    * *          the publication of the whole stacks treatise any         * *
;    * *          further just for this.  Many of the stack operations     * *
;    * *          are here, but some relating to looping controls, math,   * *
;    * *          and other things are yet to be added.  I'll finish       * *
;    * *          when I can.  The 65816 version (Appendix B), also        * *
;    * *          planned, will have much shorter code since the '816      * *
;    * *          is far more efficient at handling 16-bit quantities.     * *
;    * *          5 stars * * * * * means something there needs more       * *
;    * *          attention from me.                                       * *
;    * *                                                                   * *
;    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *



; You can of course rename things if you like, but the names given here are
; already in common usage, leading right into Forth if you later want to go
; that direction.  Forth names can include almost any character, so things had
; to be spelled out here, for example 2* is called _2STAR here, since
; assemblers don't allow the asterisk to be in a name.

; Routines can be modified too.  For some, you might opt for a different balance
; of length versus speed.

; You may want to trim out parts you don't need.  Just make sure that nothing
; else left jumps or branches to any labels you cut out, and that branches to
; parts of other routines are within branching distance.

; CMOS 65c02 instructions are used.  In some places suggestions for NMOS are
; made, but in others you're on your own.  I have an article on the NMOS-CMOS
; differences at http://wilsonminesco.com/NMOS-CMOSdif/ .

; Labels ending in "$" are for local use only, usually within the same routine.
; Labels here are case-sensitive.  For example, the Macro DO assembles JSR do
; (lower case) flollowed by an address.

; Some macros are used, but are very simple, so there should be no complications
; of translating for different assemblers.

; The material here is much of what you would need to do a subroutine-threaded
; code (STC) Forth.  It has not only the mudane stack operations for simple
; math, logic, memory, strings, etc., but also things like trig, log,
; square-root functions.          * * * * *

; What it is missing for doing a STC Forth is the components for doing its own
; compiling and for interpreting command lines (since there are no headers here
; for WORD to find the addresses of various routines), and compiling the control
; structures.  The material here affords most of the same data-stack operations
; that are included in a Forth kernel, without using Forth.

; ZP data stack cell size throughout is 16 bits, ie, two bytes.  Double-
; precision numbers take 32 bits, or two cells of two bytes each, ie, four bytes
; total.  Characters or bytes still take 16 bits, but the high byte is zeroed.

; For individual cells, byte order is the same as 6502: low byte first.
; For double-precision numbers, the low cell is pushed onto the stack, followed
; by the high cell.  So if you have a double-precision number that's small
; enough to fit in a single cell (without changing the sign), you can convert
; the double to a single with just DROP (in fact, StoD uses the same code).

; Most of these get much shorter on the 65816 since it is far more efficient at
; handling 16-bit quantities.  816StackOps.ASM is another file like this for it.
  
; Stack-effect comments like ( u1 u2 -- addr ) are described about 80% of the
; way down the page at http://wilsonminesco.com/stacks/virtualstacks.html which
; is section 4 of the stacks treatise.

; Have an 8-byte section of ZP called N, for routines' temporary storage.  N-1
; is also used, so don't have something else coming right up to N.  N is
; introduced 80% of the way down the page in section 4 on virtual stacks.



INX2:   MACRO           ; Same as POP macro.
        INX
        INX
        ENDM
 ;--------------

DEX2:   MACRO
        DEX
        DEX
        ENDM
 ;--------------

 ; ======= SOME COMMON CONSTANTS ========

; ZERO                  ; Put 0 on the data stack.      ( -- 0 )
;                       ; (uses the same code as PUSH_FALSE further down)
 ;--------------

ONE:    LDA  #1         ; Put 1 on the data stack.      ( -- 1 )
 o1$:   DEX2
        STA  0,X
        STZ  1,X
        RTS
 ;--------------

TWO:    LDA  #2         ; Put 2 on the data stack.      ( -- 2 )
        BRA  o1$
 ;--------------

THREE:  LDA  #3         ; Put 3 on the data stack.      ( -- 3 )
        BRA  o1$
 ;--------------
        
FOUR:   LDA  #4
        BRA  o1$
 ;--------------

BL:     LDA  #$20       ; Put $20, the blank (space) char, on the data stack.
 bl1$   DEX2
        STA  0,X
        STZ  1,X
        RTS
 ;--------------

; NEG1:                 ; Put -1 on the data stack.  Uses same code as PUSH_TRUE
                        ; which is below, which is why it's commented-out here.
 ;--------------
        

; Depending on the desired trade-off between program memory and execution speed,
; the shorter routines here could be made macros.  A prime example is POP2 below
; which saves only one byte as a subroutine but takes five times as many cycles.

_3DROP:                 ; _3DROP uses the same code as POP3
POP3:   INX2            ; Drops three data stack cells.
; POP2:                 ; (I made POP2 a macro below.)
        INX2
; POP:                  ; (I made POP a macro below.)
        INX2
        RTS
 ;--------------

POP2:   MACRO           ; Drops two data stack cells.  One byte more than doing
        INX             ; it with a subroutine, but only 8 clocks instead of 20.
        INX
        INX
        INX
        ENDM
 ;--------------

_2DROP: MACRO           ; Same as POP2.                        ( n1 n2 -- )
        INX             ; Since it's only 4 bytes and 8 clocks, it probably
        INX             ; makes more sense to have it as a macro than as a
        INX             ; subroutine which would be 3 bytes for the JSR and
        INX             ; 20 clocks.
        ENDM
 ;--------------

POP:    MACRO           ; Drops a stack cell.  One byte shorter than a subroutine
        INX             ; call, and four times as fast.  Same as INX2 macro.
        INX
        ENDM
 ;--------------

DROP:   MACRO           ; Drops a stack cell.  One byte shorter than a subroutine
        INX             ; call, and four times as fast.  Same as POP.
        INX
        ENDM
 ;--------------

 ; C_PUSH is down at RPfetch where it will get used more than in other routines
 ; that jump to it.
 ;--------------

 ; From section 7 of the stacks treatise:  JSR PUSH_LIT is intended to be
 ; followed immediately by the 16-bit number to push, low byte first as usual.
 ; Doing it inlined with LDA#, DEX, STA 0,X twice (once for high byte, and once
 ; for low byte) (typically in a macro) would perform far better but with a
 ; 5-byte penalty for each occurrence.

PUSH_LIT:               ; Make another cell available
        DEX2            ; on the ZP data stack.
        PHX             ; Keep a record of the data-
           TSX          ; stack pointer while we get
           TXA          ; the return-stack pointer
           TAY          ; into Y.
        PLX

        LDA  $102,Y     ; Transfer low byte of data
        STA  0,X        ; address to data stack,
        CLC
        ADC  #2         ; and add 2 to it to get the
        STA  $102,Y     ; updated return address.

        LDA  $103,Y     ; Now transfer the high addr
        STA  1,X        ; byte to the data stack, and
        ADC  #0         ; inc it for the return addr
        STA  $103,Y     ; if low byte rolled over.
                        ; FETCH must be next.

                        ; Fetch the value at the addr pointed to by the top stack cell.
FETCH:  LDA  (0,X)      ; Get the first (ie, low) byte.                 ( addr -- n )
        PHA             ; Save it for later since we still need A & the addr at the top of the stack.
        INC  0,X        ; Increment the low byte of the address we're fetching.
        BNE  1$         ; If that turned it into 00,
        INC  1,X        ; then we have to increment the high byte too.
 1$:    LDA  (0,X)      ; Now get the second (ie, high) byte, and
        BRA  PUT        ; finish up below.

                        ; Push a cell onto the stack.
PUSH:   DEX2            ; Start with high byte in A, and low byte on hardware stack.
                        ; PUT below replaces the contents of the top stack cell.
PUT:    STA  1,X        ; Store the high byte in the high byte of the top-of-stack cell.
        PLA             ; Get the first (ie, low) byte back,
        STA  0,X        ; and store it in the low byte of the top-of-stack cell.
        RTS             ; Since you start and end with the same stack depth, you don't need INX or DEX.
 ;--------------
           
POP3_TRUE:  INX2
POP2_TRUE:  INX2
POP_TRUE:   INX2
            BRA   SET_TRUE      ; NMOS 6502 can use BNE.

TRUE:                           ; TRUE and
NEG1:                           ; -1 (to put the constant -1 on the stack) use
PUSH_TRUE:  DEX2                ; the same code as PUSH_TRUE.
SET_TRUE:   LDA   #$FF
            STA   1,X
            STA   0,X
            RTS
 ;--------------

POP3_FALSE: INX2
POP2_FALSE: INX2
POP_FALSE:  INX2
            BRA   SET_FALSE  ; NMOS 6502 can use BNE.

ZERO:                        ; ZERO and
FALSE:                       ; FALSE (to pu the constant -1 on the stack
PUSH_FALSE: DEX2             ; use the same code as PUSH_FALSE.
SET_FALSE:  STZ   1,X        ; NMOS will need to load A or Y with 0 to store.
            STZ   0,X
            RTS
 ;--------------

SETUP:  STA  N-1        ; Move to N the number of bytes indicated by A.
        LDY  #0         ; Input even numbers only, 2 for 1 cell, 4 for 2, etc..
 su1$:  LDA  0,X        ; These cells get removed from the data stack.
        STA  N,Y
        INX
        INY             ; Note this is not two INX'x here, but INX INY.
        CPY  N-1
        BNE  su1$
        RTS
 ;--------------

TOGGLE: LDA  (2,X)      ; Use b as an XOR mask to toggle bits at addr.  addr is
        EOR  0,X        ; typically in I/O.                     ( addr b -- )
        STA  (2,X)
        POP2
        RTS
 ;--------------

UM_STAR:       ; yet to be added    * * * * *

STAR:   PHY
        STZ  N
        LDY  #0
sta1$:     LSR  3,X
           ROR  2,X
           BCC  sta2$
              CLC
              LDA  N
              ADC  0,X
              STA  N
              TYA
              ADC  1,X
              TAY
sta2$:     ASL  0,X
           ROL  1,X

           LDA  2,X
           ORA  3,X
        BNE  sta1$

        LDA  N
        STA  2,X
        STY  3,X
        INX
        INX
        PLY
        RTS
 ;-------------

PLUS:   CLC             ; add                      ( n1 n2  --  n1+n2 )
        LDA  0,X
        ADC  2,X
        STA  2,X
        LDA  1,X
        ADC  3,X
        STA  3,X
        POP
        RTS
 ;--------------

MINUS:  SEC             ; subtract                  ( n1 n2  --  n1-n2 )
        LDA  2,X
        SBC  0,X
        STA  2,X
        LDA  3,X
        SBC  1,X
        STA  3,X
        POP
 mi1$:  RTS
 ;--------------

_1ADD:  INC  0,X        ; add 1 (single-precision               ( n -- n+1 )
        BNE  _1a$
        INC  1,X
 _1a$:  RTS
 ;--------------

_2ADD:  CLC             ; add two (single-precision)            ( n -- n+2 )
        LDA  0,X
        ADC  #2
        STA  0,X
        BCC  _1a$
        INC  1,X
        RTS
 ;--------------
        
_1SUBTRACT:             ; subtract 1 (single-precision)         ( n -- n-1 )
        DEC  0,X
        LDA  0,X
        CMP  #$FF
        BNE  _1a$
        DEC  1,X
        RTS
 ;--------------

_2SUBTRACT:             ; subtract two (single-precision)       ( n -- n-2 )
        SEC
        LDA  0,X
        SBC  #2
        STA  0,X
        BCS  _1a$
        DEC  1,X
        RTS
 ;--------------

_2STAR: MACRO           ; multiply by two.  (n -- 2*n )
         ASL  0,X
         ROL  1,X
         ENDM
 ;--------------
 
_2SLASH: LDA  1,X       ; divide by two.  ( n -- n/2 )  (sign is preserved)
         ASL  A
         ROR  1,X
         ROR  0,X
         RTS
 ;--------------

D2SLASH: LDA  1,X       ; double-precision divide by two.    ( d -- d/2 )
         ASL  A         ; (sign is preserved)
         ROR  1,X
         ROR  0,X
         ROR  3,X
         ROR  2,X
         RTS
 ;--------------

D2STAR:  ASL  2,X       ; double-precision multiply by two.  ( d -- 2*d )
         ROL  3,X
         ROL  0,X
         ROL  1,X
         RTS
 ;--------------

DPLUS:   CLC            ; double-precision add. ( d1 d2 -- d1+d2 )
         LDA  2,X
         ADC  6,X
         STA  6,X
         LDA  3,X
         ADC  7,X
         STA  7,X
         LDA  0,X
         ADC  4,X
         STA  4,X
         LDA  1,X
         ADC  5,X
         STA  5,X
         POP2
         RTS
 ;--------------

DMINUS:                 ; ( d1 d2 -- d1-d2 )    ; * * * * *  not done yet!

StoD:   LDY  #0         ; Change a single-precision number into a double.
        LDA  1,X        ; To go the other direction (DtoS, just use DROP.)
        BPL  std1$
        DEY
 std1$: TYA
        PHA
        JMP  PUSH
 ;--------------

_AND:   LDA  0,X        ; ( n1 n2 -- n1_AND_n2 )     AND is bitwise,
        AND  2,X        ; like 6502 AND, but 16-bit stack operation.
        STA  2,X        ; The underscore character is added here to
        LDA  1,X        ; keep the label separate from the assembly-
        AND  3,X        ; language AND mnemonic.
        STA  3,X
        POP
        RTS
 ;--------------

OR:     LDA  0,X        ; ( n1 n2 -- n1_OR_n2 )       OR is bitwise,
        ORA  2,X        ; like 6502 ORA, but 16-bit stack operation.
        STA  2,X
        LDA  1,X
        ORA  3,X
        STA  3,X
        POP
        RTS
 ;--------------

XOR:    LDA  0,X        ; ( n1 n2 -- n1_XOR_n2 )     XOR is bitwise,
        EOR  2,X        ; like 6502 XOR, but 16-bit stack operation.
        STA  2,X
        LDA  1,X
        EOR  3,X
        STA  3,X
        POP
        RTS
 ;--------------

NEQ:    JSR  EQ         ; <>    Not equal?     ( n1 n2 -- f )  f=false if n1=n2.
                        ; Follow immediately with NOT.
NOT:    LDA  0,X        ; Flip all bits.  ( n -- NOT_N )     NOT is bitwise,
        EOR  #$FF       ; like 6502 EOR #$FF, but 16-bit stack operation.
        STA  0,X
        LDA  1,X
        EOR  #$FF
        STA  1,X
        RTS
 ;--------------

EQ:     LDA  0,X        ; =      Equal?        ( n1 n2 -- f )  f=true if n1=n2.
        CMP  2,X
        BNE  lt1$
        LDA  1,X
        CMP  3,X
        BNE  lt1$       ; to JMP POP_FALSE
 eq1$:  JMP  POP_TRUE
 ;--------------

GT:     JSR  SWAP       ; >     Greater than?  GT goes right into LT.
                        ;                      ( n1 n2 -- f )  f=true if n1>n2.

LT:     LDA  0,X        ; <     Less than?     ( n1 n2 -- f )  f=true if n1<n2.
        CMP  2,X
        BNE  lt1$
        LDA  1,X
        CMP  3,X
        BEQ  eq1$       ; to JMP POP_TRUE
 lt1$:  JMP  POP_FALSE
 ;--------------

UGT:    JSR  SWAP       ; U>    unsigned greater than?     ( u1 u2 -- f )
                        ; UGT goes right into ULESS.     f=true if u1>u2)

ULT:    LDA  3,X        ; U<    unsigned less than?        ( u1 u2 -- f )
        CMP  1,X        ;                                f=true if u1<u2.
        BNE  ult1$
        LDA  2,X
        CMP  0,X
 ult1$: BCS  lt1$       ; to JMP POP_FALSE
 ult2$: JMP  POP_TRUE
 ;--------------

ZEQ:    LDA  0,X        ; 0=     Zero EQual? (ie, is the number at the
        ORA  1,X        ;                        top of the stack =0?)
        BNE  zlt1$      ; If not, branch to SET_FALSE
 zeq1$: JMP  SET_TRUE   ;                       ( n -- f )  f=true if n=0.
 ;--------------

ZNE:    LDA  0,X        ; 0<>    Zero, Not Equal?    ( n -- f )  f=false if n=0.
        ORA  1,X
        BNE  zeq1$      ; If not equal to zero, jump to SET_TRUE,
        BRA  zlt1$      ; else to SET_FALSE.
 ;--------------

ZLT:    LDA  1,X        ; 0<     Zero, Less Than?     ( n -- f )  f=true if n<0.
        BMI  zeq1$      ; We only need to look at the high bit.
 zlt1$: JMP  SET_FALSE
 ;--------------

ZGT:    LDA  1,X        ; 0>     Zero, Greater Than?  ( n -- f )  f=true if n>0.
        BMI  zlt1$      ; If it's either negative
        ORA  0,X        ; or zero,
        BEQ  zlt1$      ; then branch to the JMP SET_FALSE.
        JMP  SET_TRUE
 ;--------------

D0EQ:   LDA  0,X        ; D0=         Double-precision number equal to 0?
        ORA  1,X        ;                       ( d -- f )  f=true if d=0
        ORA  2,X
        ORA  3,X
        BEQ  ult2$      ; If all bytes are 0, go to JMP POP_TRUE.
 dzq1$: JMP  POP_FALSE
 ;--------------

D0LT:   LDA  1,X        ; D0<        Double-precision number less than 0?
        BPL  dzq1$      ;                       ( d -- f )  f=true if d<0.
        JMP  POP_TRUE
 ;--------------

DEQ:    LDA  0,X        ; D=          Double-precision number equal to 0?
        CMP  4,X        ;                       ( d -- f )  f=true if d=0.
        BNE  deq1$      ; SEE IF THE POP_TRUE, POP3_TRUE ETC IN THIS AREA ARE CORRECT. * * * * *

        LDA  1,X
        CMP  5,X
        BNE  deq1$

        LDA  2,X
        CMP  6,X
        BNE  deq1$

        LDA  3,X
        CMP  7,X
        BNE  deq1$

        JMP  POP3_TRUE
 deq1$: JMP  POP3_FALSE
 ;--------------

DNEQ:   JSR  DEQ        ; D<=  "Dee-not-equal"  Double-precisiong, not equal?
        JMP  NOT        ; JSR, RTS              ( d1 d2 -- f ) f=false if d1=d2
 ;--------------

DGT:    JSR  _2SWAP     ; D>  "Dee-greater"     Double-precision, Greater Than?
                        ; Goes into D<, next.   ( d1 d2 -- f )  f=true if d1>d2
DLT:    JSR  ROT        ; D<  "Dee-less-than"   Double-precision, Less than?
        LDA  0,X
        CMP  2,X
        BNE  dl1$       ; This is definitely not just a translation of common
                        ; Forth D< words since those have an underflow bug.
        LDA  1,X
        CMP  3,X
        BNE  dl1$

        _2DROP
        JMP  ULT        ; JSR, RTS

 dl1$   JSR  GT
        JSR  MINUS_ROT
        _2DROP
        RTS
 ;--------------

DUGT:   LDA  #$80       ; DU> "dee you greater than" ( du1 du2 -- f )
        EOR  1,X        ; Double-precision Unsigned Greater Than?
        LDA  #$80
        EOR  3,X
        BRA  DGT
 ;--------------

LEQ:    JSR  GT         ; <=  "Less than or EQual"      ( n1 n2 -- f )
        JMP  NOT        ; JSR, RTS                      f=true if n1<=n2
 ;--------------
        
GEQ:    JSR  LT         ; >=  "Greater than or EQual"   ( n1 n2 -- f )
        JMP  NOT        ; JSR, RTS                      f=true if n1>=n2
 ;--------------

BETWEEN:                ; ( n LO HI -- f )   f is true if   LO <= n <= HI
        JSR  _2PICK
        JSR  LT
        LDA  0,X
        POP
        CMP  #0
        BEQ  btw1$
        JMP  POP_FALSE  ; (same as 2DROP FALSE)
 btw1$: BRA  GEQ
 ;--------------

SP_FETCH:               ; "[data] Stack Pointer FETCH"   ( -- n )
        TXA             ; Data stack pointer is X, so put it in A,
        BRA  C_PUSH     ; and go to "character push"
 ;--------------

SP_STO: MACRO           ; "[data] Stack Pointer STOre"   ( n -- )
        LDA  0,X
        TAX
        ENDM
 ;--------------

RP_FETCH:               ; "Return [hardware] Stack Pointer FETCH"
        PHX             ;                                ( -- n )
           TSX          ; Put the value of the return (or hardware)
           INX          ;        stack pointer onto the data stack.
           INX2         ; INX past the return address
           TXA          ; places and the PHX.
        PLX             ; C_PUSH must be next.
C_PUSH: DEX2            ; Start with character in A.  High byte will get 0.
        STA  0,X        ; For NMOS 6502 (which doesn't have STZ), you'll have to
        STZ  1,X        ; load A or Y with 0 to store the high byte.
        RTS

 ;--------------

RP_STO: MACRO           ; Note that this one cannot be a subroutine!
        TXA             ; "Return [hardware] Stack Pointer STOre"
        TAY             ; Make the hardware stack pointer (S) to be
        LDA  0,X        ; what the value in the top of the data stack
        TAX             ; says.  Y gets overwritten.         ( n -- )
        TXS
        TYA
        TAX
        INX
        INX
        ENDM
 ;--------------

toR:    PHX             ; ( n -- )   Preserve X for ZP
           TSX          ; data-stack indexing, and get
           TXA          ; return stack pointer in Y for
           TAY          ; return-stack indexing.
        PLX

        LDA  103,Y      ; Here it's 103,X and 102,X instead of
        PHA             ; 102,X and 101,X, because of the PHX, PLX
        LDA  102,Y      ; above.  Return address gets copied to
        PHA             ; new position,

        LDA  1,X        ; and data TOS goes where return addr was.
        STA  103,Y
        LDA  0,X
        STA  102,Y

        POP             ; Drop the data TOS cell since you just
                        ; transferred it to return stack.
        RTS
 ;--------------

 ; toR above is quite long as a subroutine.  Fortunately it is not needed
 ; often.  If you really need more speed for it, you could make it a macro,
 ; taking it from 63 clocks (including JSR & RTS) down to 18:

;toR:   MACRO
;       LDA  1,X        ; Transfer the top data-stack cell to the Return
;       PHA             ; [hardware] stack.                     ( n -- )
;       LDA  0,X
;       PHA
;       POP
;       ENDM
 ;--------------

Rfrom:  DEX2            ; Prepare a cell on the ZP data stack.

        PLA             ; Pull the return address off the return stack
        STA  N          ; and store it temporarily, low byte,
        PLY             ; then high byte.

        PLA             ; Pull the desired cell off the return stack
        STA  0,X        ; and put it on the data stack.
        PLA
        STA  1,X

        PHY             ; Get the return address back, ready for RTS.
        LDA  N
        PHA

        RTS
 ;--------------

 ; Rfrom above is a tad long as a subroutine.  Fortunately it is not needed
 ; often.  If you really need more speed for it, you could make it a macro,
 ; taking it from 52 clocks (including JSR & RTS) down to 20:

;Rfrom: MACRO
;       DEX2            ; Pull a value from the Return [hardware] stack
;       PLA             ; and put it on the data stack.         ( -- n )
;       STA  0,X
;       PLA
;       STA  1,X
;       ENDM
 ;--------------

I:                      ; I (for loop index) and Rfetch are the same.
Rfetch: PHX             ; Preserve X for data-stack pointer
           TSX          ; while getting return-stack pointer into Y
           TXA          ; for indexing.
           TAY
        PLX

        DEX2            ; Prepare a new cell on the ZP data stack.

        LDA  104,Y      ; Read desired cell from return stack
        STA  0,X        ; and put it on the ZP data stack.
        LDA  105,Y
        STA  1,X

        RTS
 ;--------------

 ; I and Rfetch are a tad long as a subroutine.  Fortunately they're not needed
 ; often.  If you need more speed, you can make them macros, taking them down
 ; from 47 clocks (including JSR & RTS) down to 22:

Rfetch: MACRO           ; ( -- n )
        PLA             ; Fetch a copy of what's at the top of the Return
        STA  0,X        ; [hardware] stack and put it on the data stack
        PLY             ; without removing it.
        STY  1,X
        PHY
        PHA
        ENDM
 ;--------------

I:      MACRO           ; If you use the Rfetch macro, use this I also.
        Rfetch          ; If your assembler doesn't allow nested macros,
        ENDM            ; then just straighline this as above.
 ;--------------

_2DUP:  JSR  OVER       ; This is the shorter way, 3 bytes, 64 clocks.  The
                        ; quicker way would take 19 bytes, 48 clocks.  _2DUP
                        ; goes right into OVER.              ( d1 -- d1 d1 )

OVER:   DEX2            ; This could be shortened by a few bytes by using PUSH,
        LDA  4,X        ; but it's used often enough that I think it's worth
        STA  0,X        ; doing this way.                ( n1 n2 -- n1 n2 n1 )
        LDA  5,X        ; It makes a copy of the cell below the top of stack.
        STA  1,X        ; 32 clocks, incl JSR & RTS.
        RTS
 ;--------------

?DUP:   LDA  0,X        ; "querry-doop" Like DUP but DUPlicates (copies) the top
        ORA  1,X        ; stack cell if and only if it is non-zero.
        BEQ  durt$      ; ?DUP goes right into DUP below.

DUP:    DEX2            ; This could be shortened by a few bytes by using PUSH,
        LDA  2,X        ; but it's used often enough that I think it's worth
        STA  0,X        ; doing this way.                       ( n1 -- n1 n1 )
        LDA  3,X        ; It just DUPlicates the top stack cell.
        STA  1,X
 durt$: RTS
 ;--------------

SWAP:   LDA  0,X        ; Swap the top two data-stack cells.  ( n1 n2 -- n2 n1 )
        LDY  2,X
        STA  2,X
        STY  0,X

        LDA  1,X
        LDY  3,X
        STA  3,X
        STY  1,X
        RTS
 ;--------------

_2SWAP: JSR  ROT        ; ( d1 d2 -- d2 d1 )
        JSR  toR
        JSR  ROT
        JSR  Rfrom      ; Do not replace JSR, RTS with JMP in this case.
        RTS             ; Also, do not make it flow right into Rfrom.
 ;--------------

                        ; Pull a value from the Return [hardware] stack
                        ; and put it on the data stack.         ( -- n )
MINUS_ROT:              ; -ROT ("minus-rotate") is opposite of ROT.  Rotate the
        JSR  ROT        ; three top cells, but the top one becomes the 3rd one.
                        ; This is probably not used enough to do it like ROT.
                        ; Goes right into ROT.          ( n1 n2 n3 -- n3 n1 n2 )


ROT:    LDY  0,X        ; ROTate the three top data-stack cells, pulling the one
        LDA  4,X        ; farthest down to the top.     ( n1 n2 n3 -- n2 n3 n1 )
        STA  0,X
        LDA  2,X  
        STA  4,X
        STY  2,X

        LDY  1,X
        LDA  5,X
        STA  1,X
        LDA  3,X
        STA  5,X
        STY  1,X
        RTS
 ;--------------

_2OVER: JSR  _3PICK     ; This is used seldom enough to probably be fine this
                        ; way instead of the longer, faster way.  _2OVER goes
                        ; right into _3PICK.            ( d1 d2 -- d1 d2 d1 )

_3PICK: DEX2            ;                   ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 )
        LDA  #3         ; _3PICK is like 3 PICK, not for triple-precision but
        STA  0,X        ; rather PICKing the #3 (0-based) cell to make a copy
        STZ  1,X        ; of.                    _3PICK goes right into PICK.
     
PICK:   JSR  SP_FETCH   ; describe * * * * *
        JSR  _2ADD
        JSR  SWAP
        JSR  _2STAR
        JSR  PLUS
        JMP  FETCH      ; (JSR, RTS)
 ;--------------

_2ROT:  JSR  _2rt1$     ; "2 ROTate" (for double-precision, ie, 32-bit numbers).
_2rt1$: DEX2            ; ( d1 d2 d3 -- d2 d3 d1 )
        LDA  #5
        STA  0,X
        STZ  1,X        ; _2ROT (actually _2rt1$) goes right into ROLL.



: ROLL         >R R@ PICK  SP@ DUP 2+  R> 1+ 2* QCMOVE>  DROP ;              * * * * * (and keep it right after _2ROT)
: DEPTH        SP@ S0 @ SWAP - 2 / ;


C_FETCH:                ; "See-fetch" or "character fetch"
        LDA  (0,X)      ; (character or single-byte fetch)    ( addr -- b )
        STA  0,X
        STZ  1,X
        RTS
 ;--------------

STORE:  LDA  2,X        ; ( n addr -- )  Store n at addr.
        STA  (0,X)
        INC  0,X
        BNE  st1$
        INC  1,X
 st1$:  LDA  3,X
 st2$:  STA  (0,X)
        POP2
        RTS
 ;--------------

C_STORE:                ; "See-store" or "character store"
        LDA  2,X        ; (character or single-byte store)      ( b addr -- )
        BRA  st2$       ; (Finish up in STORE above.)
 ;--------------

PLUS_STO:               ; Add n to the contents at addr, and leave the result
        LDA  (0,X)      ; at addr.                               ( n adr -- )
        CLC
        ADC  2,X
        STA  (0,X)

        INC  0,X
        BNE  ps1$
        INC  1,X
 ps1$:  LDA  (0,X)
        ADC  3,X
        STA  (0,X)
        POP2
        RTS
 ;--------------

BYTE_SWAP:              ; Called >< in Forth.  $1234 becomes $3412.  ( n1 -- n2 )
        LDA  0,X
        LDY  1,X
        STY  0,X
        STA  1,X
        RTS
 ;--------------




; I plan to add here:

_2fetch:  ; to fetch a double (ie, 32-bit) number   ( addr -- d )
_2store:  ; to store a double (ie, 32-bit) number   ( d addr -- )


( Remember double number goes on stack with high word at TOS.)
( $12345678 is represented in memory, whether stack or variable, as 34 12 78 56,)
( with the variable address pointing to the byte containing the 34.)


DABS:   LDA  1,X        ; Absolute value of a double-precision.  ( d -- |d| )
        BPL  ngt1$      ; BPL to the RTS below.
                        ; DABS goes right into DNEGATE, next

DNEGATE:                ; Change the sign of a double-precision.  ( d -- -d )
        SEC

        LDA  #0
        SBC  2,X
        STA  2,X

        LDA  #0
        SBC  3,X
        STA  3,X

        BRA  NEGATE+1   ; (The +1 is to skip the SEC.)


ABS:    LDA  1,X        ; Take the absolute value.             ( n -- |n| )
        BPL  ngt1$      ; BPL to the RTS below.
                        ; ABS goes right into NEGATE, next.

NEGATE: SEC             ; Change the sign of the input number.  ( n -- -n )

        LDA  #0
        SBC  0,X
        STA  0,X

        LDA  #0
        SBC  1,X
        STA  1,X

 ngt1$: RTS
 ;--------------

MIN:    JSR  _2DUP      ; ( n1 n2 -- n3 )  n3 is the lesser of the two inputs.
        JSR  GT         ; Is n1>n2?  (It leaves a flag on the stack.)
 mx2$:  LDA  0,X
        BMI  mx1$       ; If so, branch down to where we'll NIP n1 and leave n2.
        2DROP           ; Else, DROP the flag and larger top input stack cell.
        RTS

 mx1$:  DROP            ; DROP the flag.         MIN goes right into NIP below.

NIP:    LDA  0,X        ; Like JSR SWAP, JSR DROP but faster.    ( n1 n2 -- n2 )
        STA  2,X
        LDA  1,X
        STA  3,X
        POP
 ni1$:  RTS
 ;--------------

MAX:    JSR  _2DUP      ; ( n1 n2 -- n3 )  n3 is the greater of the two inputs.
        JSR  LT         ; Is n1<n2?  (It leaves a flag on the stack.)
        BRA  mx2$       ; Finish up in MIN.
 ;--------------

DUMIN:  JSR  _2OVER     ; ( du1 du2 -- dmin ) Return the minimum of du1 and du2.
        JSR  _2OVER
        JSR  DUGT
        LDA  0,X
        POP
        CMP  #0
        BEQ  dum1$
        JSR  _2SWAP
 dum1$: POP2
        RTS
 ;--------------

BLANK:  JSR  BL         ; ( addr len -- )  Starting at addr, fill <len> bytes
        BRA  FILL       ; with the blank ($20) character.

ERASE:  JSR  ZERO       ; ( addr len -- )  Starting at addr, erase <len> bytes.
                        ; ERASE moves right into FILL.

FILL:   LDA  2,X        ; ( addr len char -- )  Starting at addr, fill <len>
        ORA  3,X        ; bytes with char.
        BNE  fi1$
 fi4$:  JMP  POP3       ; If both bytes of the length cell are 0, just exit.
                        ; (That includes the situation when we are finished.)
 fi1$:  LDA  0,X        ; Get the byte value to
        STA  (4,X)      ; put in the next memory location.
        INC  4,X        ; Increment the low byte of the pointer.
        BNE  fi2$       ; If that rolled it over to 0,
        INC  5,X        ; then increment the high byte too.
 fi2$:  LDA  2,X        ; See if the low byte of the number left to do is 0;
        BNE  fi3$       ; because if it is, the decrement will make it $FF, and
        DEC  3,X        ; we have to decrement the high byte of the count also.
 fi3$:  DEC  2,X        ; Decrement the low byte of the count.
        BRA  FILL       ; Go back for another.  (65816 does this 6x as fast!)
 ;--------------

MINUS_TRAILING:         ; Remove the trailing spaces from a string.
        CLC             ;                            ( addr len -- addr' len' )
        LDA  2,X        ; On the length, only the low byte is examined, meaning
        ADC  0,X        ; the maximum length is 255 characters, normally plenty.
        STA  N          ; First add the length to the beginning address, to get
                        ; the address of the last character and put it in N.
        LDA  3,X
        ADC  #0
        STA  N+1

 mt1$:  LDA  0,X
        BEQ  ni1$       ; Branch to an RTS (in NIP) if string length is zero.

        LDA  N          ; Move back one position in what we're examining.
        BNE  mt3$       ; High byte handled in case string straddles a
        DEC  N+1        ; page boundary.
 mt3$:  DEC  N

        LDA  (N)        ; Get the character.
        CMP  #$20       ; Is it a space?
        BNE  ni1$       ; If not, we're done.

        DEC  0,X        ; If we found a space above, decrement the length byte
        BRA  mt1$       ; and go back for another loop.
 ;--------------

COUNT:  LDA  (0,X)      ; Take a string with only the addr, whose first byte
        INC  0,X        ; tells the length, and turn it into addr of the first
        BNE  cnt1$      ; actual string byte and another cell to tell the length.
        INC  1,X        ; This involves reading the first byte and then
 cnt1$: JMP  C_PUSH     ; incrementing the address.  ( addr -- addr+1 len )
 ;--------------

SLASH_STRING:           ; /STRING      Take n characters off left end of string.
        JSR  OVER       ;                           ( addr len n -- addr' len' )
        JSR  MIN        ; Take the minimum of n and the length, so we don't
                        ; remove more characters than there are.
        CLC 
        LDA  4,X        ; Get the low byte of the address and
        ADC  0,X        ; increment it by the amount we're removing.
        STA  4,X
        
        BCC  sst1$      ; If the low byte carried,
        INC  5,X        ; increment the high address byte too.  (Strings are
                        ; limited to 255 characers.)
 sst1$: JMP  MINUS      ; Reduce the length by how many we're removing.
 ;--------------
        
CMOVE:  LDA  0,X        ; "See-move" Character (memory) move  ( from to len -- )
        ORA  1,X
        BEQ  fi4$       ; If the length is 0, branch to JMP POP3, in FILL.

 cmo1$: LDA  (4,X)      ; Get a byte and
        STA  (2,X)      ; transfer it.

        INC  4,X
        BNE  cmo2$
        INC  5,X        ; Increment the source addr

 cmo2$: INC  2,X
        BNE  cmo3$
        INC  3,X        ; and the destination addr,

 cmo3$: DEC  0,X        ; decrement the count left,
        LDA  0,X
        CMP  #$FF
        BNE  CMOVE
        DEC  1,X
                        ; and go back up for another loop.  If we're done, that
        BRA  CMOVE      ; fact will get caught in the first three lines.
 ;--------------

; NOTE:  If the ranges overlap, use CMOVE to move bytes down toward address 0.
;        Use CMOVE_UP to move data up toward FFFF if ranges overlap.

; I plan to put CMOVE_UP here.  I was not at all happy with my first try. * * * * *

CMOVE_UP:


 ; QCOMPARE (quick compare) below compares to blocks of memory to see if they are
 ; the same. It is only for blocks up to FF bytes long, but is faster than the
 ; other COMPARE in WONTUSE.FTH, which can be used for blocks of any length.

QSETUP: LDA  2,X        ; This is quicker than the normal setup, but only for
        STA  N          ; copying the 2nd- & 3rd-from-top stack cells to N.
        LDA  3,X
        STA  N+1
        LDA  4,X
        STA  N+2
        LDA  5,X
        STA  N+3
        RTS
 ;--------------

QCOMPARE:               ; ( beg_addr1  beg_addr2  count -- f )
        JSR  QSETUP     ;	         f true if the two blocks are identical.
        LDY  0,X
qcp2$:  DEY
        CPY  #$FF
        BEQ  qcp1$
        LDA  (N),Y
        CMP  (N+2),Y
        BEQ  qcp2$
        JMP  POP2_FALSE
qcp1$:  JMP  POP2_TRUE
 ;--------------        

 ; QCMOVE and QCMOVE> below do the same as CMOVE and CMOVE>, but are much
 ; faster.  They're only for blocks up to FF bytes long.

QCMOVE_UP:              ; QCMOVE> "quick C move up"  ( from_addr to_addr count -- )
        JSR  QSETUP     ; Put "to" addr in N, and "from" addr in N+2.
        LDY  0,X
qcu2$:  DEY
        CPY  #$FF
        BEQ  qcu1$
        LDA  (N+2),Y
        STA  (N),Y
        BRA  qcu2$
qcu1$:  JMP  POP3
 ;--------------

QCMOVE: JSR  QSETUP     ; QCMOVE "quick C move"  ( from_addr to_addr count -- )
        LDY  #0
qcm1$:  TYA
        CMP  0,X
        BEQ  qcu1$      ; (to JMP POP3 above)
        LDA  (N+2),Y
        STA  (N),Y
        INY
        BRA  qcm1$
 ;--------------





















 ;--------------

SHIFT:  LDA  0,X        ; Shift a cell left or right according to the number in
        INX2            ; the top cell.  Use positive #s for left, neg for right.
        TAY             ; We TAY here instead of LDY above, to prepare for B__.
        BEQ  shf2$      ; If the shift distance is 0, just exit.
        BPL  shf3$      ; If it is otherwise positive, branch down to shift left.
                        ; Only lo byte is looked at to determine branch distance.
 shf1$: CLC
        ROR  1,X
        ROR  0,X
        INY
        BNE  shf1$
 shf2$: RTS

 shf3$: ASL  0,X
        ROL  1,X
        DEY
        BNE  shf3$
        RTS
 ;--------------

PERFORM: JSR  FETCH     ; Same as FETCH EXECUTE.  Follow immediately w/ EXECUTE.

EXECUTE: LDA  0,X       ; Execute a JSR to the addr held in the top-of-stack
         STA  N         ; cell.                     ( addr -- )
         LDA  1,X
         STA  N+1
         POP            ; Remove addr from stack.  After routine is executed, it
         JMP  (N)       ; will return to the one that called EXECUTE or PERFORM.
 ;--------------

ON:     LDA  #$FF       ; Store $FFFF at addr.      ( addr -- )
        BRA  off1$

OFF:    LDA  #0         ; Store $0000 at addr.      ( addr -- )
 off1$: STA  (0,X)      ; (There is no STZ(ZP,X) )
        INC  0,X
        BNE  off2$
        INC  1,X
 cof1$  STA  (0,X)
        POP
        RTS
 ;--------------

C_OFF:  LDA  #0         ; C_OFF and C_ON are like OFF and ON but for single
        BRA  cof1$      ; bytes (Character places, hence the C)
 ;--------------

C_ON:   LDA  #$FF
        BRA  cof1$
 ;--------------

COMBINE:                ; Take 2 cells' low bytes and combine then into 1 cell.
        LDA  0,X        ; Opposite of SPLIT, below.      ( b1 b2 -- b1+256*b2 )
        STA  3,X
        POP
        RTS
 ;--------------

SPLIT:  DEX2            ; Split hi & lo bytes into separate cells.  Opposite of
        LDA  3,X        ; COMBINE above.	      ( n  --  LO_BYT  HI_BYT )
        STA  0,X        ; 2,X gets to keep its original value.
        STZ  1,X        ; Zero the high byte of both cells.
        STZ  3,X
        RTS
 ;--------------

 ; In INCR and DECR below, the BNE, INC 1,X in the middle can be removed if all
 ; two-byte variables will by aligened, ie, start on even addresses so they
 ; never straddle a page boundary.

INCR:   LDA  (0,X)      ; INCRement a 2-byte variable at addr by 1.  ( addr -- )
        INC  A          ; (Unfortunately, there's no INC (ZP,X) on '02.)
        STA  (0,X)      ; First do the low byte.
        BNE  inc1$      ; If that didn't make it roll over to 00, you're done.

        INC  0,X        ; If it did, then increment the address low byte,
        BNE  inc2$
        INC  1,X        ; followed by the high byte if the low byte rolled over,
 inc2$: LDA  (0,X)      ; then increment the high byte of the target variable.
        INC  A
        STA  (0,X)

 inc1$: POP
        RTS
 ;--------------

DECR:   LDA  (0,X)      ; DECRement a 2-byte variable at addr by 1.  ( addr -- )
        DEC  A          ; (Unfortunately, there's no DEC (ZP,X) instruction for '02.)
        STA  (0,X)      ; First do the low byte.
        CMP  #$FF
        BNE  dec1$      ; If that didn't make it underflow to FF, you're done.

        INC  0,X        ; If it did, then increment the address low byte,
        BNE  dec2$
        INC  1,X        ; followed by the high byte if the low byte rolled over,
 dec2$: LDA  (0,X)      ; then decrement the high byte of the target variable.
        DEC  A
        STA  (0,X)

 dec1$: POP
        RTS
 ;--------------

; <insert here:       * * * * *

do:
DO:
?do:
loop:
plus_loop:
I:
J:
LEAVE:
?LEAVE:
leave:
?leave:




STR_STO:                ; String store     ( str_adr len dest_adr -- )
        JSR  _2DUP
        JSR  C_STO
        JSR  1ADD
        JSR  SWAP
        JMP  QCMOVE     ; (JSR, RTS)
 ;--------------

STR_ADD:                ; String concatenate ( adr1 len1 adr2 len2  -- adr1 len1+len2 )
        JSR  OVER
        JSR  FOUR
        JSR  PICK                       ; See if this can be shortened since it's in assembly. * * * * *
        JSR  FOUR
        JSR  PICK
        JSR  PLUS
        JSR  _2PICK
        JSR  QCMOVE     ; Concatenate actual string.
        JSR  _2PICK
        JSR  PLUS
        JSR  DUP
        JSR  FOUR
        JSR  PICK
        JSR  _1MINUS
        JSR  C_STO      ; Store new len byte in header of string 1.
        JSR  toR
        _2DROP          ; DROP len1 & adr2.
        JMP  Rfrom      ; (JSR, RTS)
 ;--------------


; I plan to add here things related to output formatting        * * * * *



; "scotws" on the 6502.org forum has a good description on CREATE and DOES> in
; STC Forth in the topic "A Walkthrough of CREATE/DOES in STC Forth for the
; 65c02" at http://forum.6502.org/viewtopic.php?p=36089#p36089.  There's a link
; there to his entire TaliForth STC code, including things like DEFER.

; Last updated Sep 12, 2015
