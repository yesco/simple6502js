;;; DUMMY: for testing/prototype

;;; LOL uppercase WORD matches literary!

;;; TODO: _RECURSIVE  ???


        .byte "|WORD","%N(a,b,c,d)"

;;; TODO: cleanup, don't use globals

.export params,stargs

.zeropage

;;; params used as registers for recursive (copying SAFE)
params:          .res NPARAMS*2
;;; STatic ARGumentS used fro dedicated static
;;; addresses for arguments for functions that
;;; *DON'T* overlap!
;;; TODO:
stargs:          .res NSTARGS*2

.code

;;; TODO: don't use a..z, not correct


.ifdef TESTDISASM
      .byte "["
        lda $1234,x
;;; causes parse error eor = $5d
;        eor $1234,x
        and $1234,x
        ora $1234,x
        adc $1234,x
        sta $1234,x
        nop
        lda $1234,y
        eor $1234,y
        adc $1234,y
        sta $1234,y
        nop
        nop

        ldy $1234,x
        nop
        nop
;;; prints ldx $1234,x !!! lol
        ldx $1234,y
        nop
        nop
        nop
      .byte "]"
.endif ; TESTDISASM


;;; 1810247 PARAM4 compilation
;;; 1869561 PARAM4 run 22 (23 calls)
;;; (- 1869561 1810247) = 59314 c 
;;; (/ 59314 23) = 2578 c per call!
;;; 
;;; 2393375 10x calls
;;; (/ (- 2393375 1810247) 10 23) = 2535

;;; looking at generated asm = Play/4param-recurs.c.cc02.asm
;;; F() function cost
;;; (+ 235   30  65     96     12   36   235) = 709
;;; using restore instead of DOSWAP
;;; (+ 235   30  65     96     12   36   124) = 598
;;;    swap  if  a+b..  params jsr  pop swap
;;; 
;;; actual work in func: (+ 30 65 96 12 36) = 239c

;;; we're seing 4x the cost???
;;; 
;;; stupid calling method (pop by caller)
;;; 282 bytes (235 B counting F() and main())
;;; 267 bytes (removed P(), reversed if)
;;; 
;;; Bytes
;;; (+ 23    25  42     52     3    10  8  23   4) = 190
;;;    swap                             r  swap  r
;;; 
;;; (+ 190 (* 7 4) 3 3 10 1) = 235

;;; 1810247
;;; 1868576 (/ (- 1868576 1810247) 23) = 2536
;;; 1869561 (/ (- 1869561 1810247) 23) = 2578

;;; 1809840


;;; no P(), no: if(!)
;;; 999512 (/ (- 999512 943912) 23) = 2417c / call

;;; REVERSE=1 using ,x for swap is slower?
;;; 1877671 (/ (- 1877671 1809840) 23) = 2949 (> 2578?)

;;; REVERSE=1 using ,y for swap is FASTER!
;;; 1869561 WTF????  (/ (- 1869567 1877671) 23)
;;;  352 ??? cycles per call? wtfwtfwtwfwtwfwtwfwt?


;;; 1809279
;;; 1868576 ;; DOSWAP=1  is more expensive, finanly!
;;;      (/ (- 1868576 1865200) 23) = 146 !!!

;;;    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
;;;  (/ (- 1865200 1809276) 23) = 2431    BEST!!!!
;;;    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;;; (* 13 8) = 104c saved
;;; cost: (+ 15 (* 13 8) 5) = 124

;;; 1865200 ;; DOSWAP not, is slower????
;;; 1865197 ;; using y, 3c faster??? LOL

;;; 943788
;;; (- 983850 943788) 40062 ??? 1 call?
;;; (- 732569 692453) 40116 ??? 1 call
;;; (- 642428 598475) 43953 ??? 


;;; ---------- VBCC  xxxx      (242 Bytes prog)
;;; 
;;; ---------- CC65  356 Bytes (125 Bytes prog + LIBS)
;;; 11359 cc65, lol DIFF! (/ 11359 23)= 493
;;; 
;;; OK, so we have some overhead!

;;;  813657 compile no prepost
;;; 1042678 (/ (- 1042678 813657) 1000) = 229



;;; Just to test overhead
;
PRELUDE=1
;



.ifdef OPTJSK_CALLING
;POSTLUDE=1
.else
POSTLUDE=1
.endif




.ifdef PRELUDE
      .byte "["

.ifdef JSK_CALLING

.ifdef CALLSWAP8

        jsr swap8
        
.else ; !CALLSWAP8

.ifblank
;;;  // TEST
        ldy #8
        jsr swapY
        
.else
;;; 21 B (smaller and faster!)
        tsx
        stx savex
        ldy #8
;;; 26c / byte
:       
        ;; swap byte
	;; TODO: use ,x to do zero addressing!
        ;;      save bytes?
        ;;   (somehow goes slower??? hmmm)
        ldx params-1,y
        pla
        sta params-1,y
        txa
        pha
        ;; step up
        pla                     ; s-- !
        dey
        bne :-
        ;; restore stack pointer!
        ldx savex
        txs
.endif ; blank

.endif ; CALLSWAP8


;;; This creates a deferred call to cleanup
;;; after the function does an RTS

.ifdef OPTJSK_CALLING
        ;; defer: restore(8)
;putc '!'
.ifnblank
;;; 6 B
;;; TODO: code that generates specific caLL
        lda #>(restore8-1)
        pha
        lda #<(restore8-1)
        pha
.else
;;; 9 B
        lda #8
        pha
        lda #>(restoreY-1)
        pha
        lda #<(restoreY-1)
        pha
.endif

.endif ; OPTJSK_CALLING        


.else ; !JSK_CALLING

;;; 28 B (smaller and faster!)

        ;; swap stack w registers!
        ;; (reverse byte order)
        ;; (sadly on both - not needed)
        tsx
        stx savex
        ldy #8                  ; bytes
        ;; skip JSR
;;; TODO: with jsk-calling remove these...
        pla
        pla
:       
        ;; (trying to be clever
        ;;  - rewriting the stack!)
        ;; swap byte
;;; TODO: use ,x to do zero addressing! save bytes
        ldx params-1,y
        pla
        sta params-1,y
        txa
        pha
        ;; step up
        pla                     ; s-- !
        dey
        bne :-
        ;; restore stack pointer!
        ldx savex
        txs
.endif ; !JSK_CALLING
      .byte "]"
.endif ; PRELUDE

        .byte _B

      .byte "["

.ifdef POSTLUDE

        ;; postlude
        ;; restore register bytes from stack
        ;; (doesn't care order)

        ;; save ax
        sta savea
;;; TODO: maybe no need saving?
        stx savey

.ifdef JSK_CALLING
;;; RESTORE!
;;; 9 B
        ldy #8
;;; 13 c ok, it's faster...
;;; could generate a long sequence and jump middle
;;; wquld be 6c faster/byte! (8 => 42c!)
:       
        pla
        sta params-1,y
        dey
        bne :-
.else
;;; TODO: only need restore...
;;; DOSWAP is 146c slower!
;DOSWAP=1 ;
.ifdef DOSWAP
;putc 'R'

        tsx
        stx savex
        ldy #8                  ; bytes
        pla
        pla
;;; 26c
:       
        ;; (trying to be clever
        ;;  - rewriting the stack!)
        ;; swap byte
        ldx params-1,y
        pla
        sta params-1,y
        txa
        pha
        ;; step up
        pla                     ; s-- !
        dey
        bne :-

        ;; restore stack pointer!
        ldx savex
        txs
.else
;putc 'r'
;;; 12 B
        tsx
        stx savex
        pla
        pla

        ldy #8
;;; 13 c ok, it's faster...
:       
        pla
        sta params-1,y
        dey
        bne :-

        ldx savex
        txs
.endif ; DOSWAP
.endif ; !JSK_CALLING




;;; NOBODY else can currently return
;;;   we just need to keep AX safe...
        lda savea
        ldx savey

.endif ; POSTLUDE

        rts

      .byte "]"
        .byte TAILREC
