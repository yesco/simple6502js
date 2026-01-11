;;; support RECURSION, has RUNTIME code overhead
;;; of about 63 B for optimizing restore and make
;;; function exit using RTS.
;;; 
;;; Alternative cost is (+ 21 12) == 33 B !
;;; overhead per recursive function!
;

.ifdef RECURSION

;;; restory                       13 B
;;;       (but calling overhead 9 B)
;;;       (only improvement is RTS in user code
;;;        and no jmp "end" function to do cleanup)

;;;               OR

;;; (+ 24     27       12         ) = 63 ~ 69 B
;;;    swapY  restore8 r6,r4,r2

;;; Implementing support for recursion in cc02
;;; (see Play/4params.c for example)
;;; 
;;;        F+main
;;; cc65:  125 B  475c/call ( 356.sim 440.tap )
;;; vbcc:  242 B
;;; MeoC: ~138 B            (estimate using _X rule
;;;        255 B            (+33 B loop)
;;;        255 B  709c !    WORKS: enter+exit==swap
;;;               554c      enter=swap, exit=restore
;;;                            12.4 % slower than cc65
;;;               503c      restoryY
;;;        23x B  496c      JSK_CALLING (save 10B/call)
;;;        22x B  503c      OPTJSK_CALLING (19 calls)
;;;        17x B  436c      restore8 (RUNTIME: + 27 B)
;;;                             3 calls saves 30 B
;;;                           8.2% faster than cc65
;;;        174 B  456c      swapY: 24 B (204-30 loop)
;;;                           saved itself!
;;; 
;;;    (maybe not worth it, the last ...)
;;;        172 B  407c      swap8    (RUNTIME: + 97 B)
;;;                            +2 calls saves cost
;;;                           14% faster than cc65
;;;                             RUNTIME==160 B :-(
;;; 

;
JSK_CALLING=1

;;; make cleanup happen automatic after JSR!
;;; (push addr of cleanup, & number 8)
;;; Smaller code as well as faster!
;
OPTJSK_CALLING=1

;;; adds +97 B, improves PARAM4 436c => 407c
;;; maybe NOT WORKTH IT
;;; (14% faster than cc65)
;CALLSWAP8=1



.ifdef JSK_CALLING
;;; must be part of RUNTIME for these optimizations


;;; 1078241
;;; 12507300 (/ (- 12507300 1078241) 1000 23) = 496
;;; using JSK_CALLING! 267 => 279 bytes?
;;; uses extra 6c (+6B jumps) but saves

;;; OPTJSK_CALLING
;;; 1076977
;;; 10755024  (/ (- 10755024 1076877) 1000 19)
;;;    509c / call (+ 13c)
;;;    
;;; 937422
;;; 10279469 (/ (- 10279469 937422) 1000 19) = 491
;;;    491c / calll (net -5c!)
;;;  WRONGWONGWOGNOWGNOWGNOWGNWOGNWOGN

;;; restoreY (pha 8)
;;; (/ (- 10508495 937422) 1000 19) = 503

;;; for RECURSIVE functions... (do we care?)
;;; 
;;; 279 B before incl OPTJSK_CALLING
;;; 
;;; 258 B doing restore8:  (- 21 B)
;;;    3 function calls saves in +27 B restore8
;;; 
;;; 240 B doing swap8: (- 18 B)
;;;    6 function calls saves in +97 B swap8
;;; BUT: => 14% faster than cc65...
;;; 
 
;;; restore8 !!! (+ 27 B) (incl restore6,4,2)
;;; 9235009 (/ (- 9235009 937422) 1000 19) = 436

;;; swap8:  ! (+ 97 B)
;;; 8681299 (/ (- 8681299 937422) 1000 19) = 407 !!
;;; 
;;; cc65: 475 c / call
;;; 
;;; (/ 407 475.0) => 14 % faster than cc65



;;; 22 max: (* 22 (+ 8 2)) = 220 !
;        .byte "  r= F(22, 0, 1, 65535);",10
;        .byte "  r= F(3, 0, 1, 65535);",10

;;;  43953 c overhead/start
;;; 692453 compile
;;; 732569 (- 732569 692453 43953) 1x
;;; 

;;;    0                 1           10      100
;;; 791254 compile    820571       820695    820942
;;; 834224 run 0      860660       865860   1424480
;;; 
;;; (/ (- 1424480 820942) 100) = 6035c !!!!????

;;;  1065057
;;;  1695899 (/ (- 1695899 1065057) 1000) = 630
;;; 13821630 (/ (- 13821630 1065057) 1000 23) = 554!!!
;;; 
;;; 554! cycles, so ok (/ 554 493.0) =
;;;       12.4% slower than cc65
;;;  1072631
;;; 13821624 (/ (- 13821624 1072631) 1000 23) = 554

.ifdef FUNCALL

.ifdef CALLSWAP8

.macro SWAP nn
;;; 8 B  19c
        ldx params-1+nn
        pla
        sta params-1+nn
        txa
        pha
        pla
.endmacro

;;; (+ 8 8 8 5 64 4) = 97 B
swap2:  
;;; 8 B
        tsx
        stx savex
        ;; discount call here
        pla
        pla
        jmp sw2
swap4:  
;;; 8 B
        tsx
        stx savex
        ;; discount call here
        pla
        pla
        jmp sw4
swap6:  
;;; 8 B
        tsx
        stx savex
        ;; discount call here
        pla
        pla
        jmp sw6
swap8:  
;;; 5 B
        tsx
        stx savex
        ;; discount call here
        pla
        pla

;;; (* 8 8) = 64
        SWAP 8
        SWAP 7
sw6:    
        SWAP 6
        SWAP 5
sw4:    
        SWAP 4
        SWAP 3
sw2:    
        SWAP 2
        SWAP 1

;;; 4 B
        ldx savex
        txs
        rts

.else ; !CALLSWAP8

;;; Y bytes to swap
swapY:  
;;; 22 B (smaller and faster!)
;;;      (faster than what?)

;;; (+ 13 5 6) => 24 +6rts + 28*bytes =>
;;; n => 86 n=2 => 142c

;;; 13c
        tsx
        stx savex
        ;; skip call here
        pla
        pla
:       
        ;; swap byte
        ;; TODO: use ,x to do zero, save bytes
;;; 28c x bytes
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
;;; 5+6c
        ldx savex
        txs

        rts
.endif ; !CALLSWAP8






;;; 634690
;;; 69 B - SWAPY !RESTORY
;;; 9313634   (/ (- 9313694 634690) 1000 19)  = 456
;;; 36 B - SWAPY RESTORY
;;; 10452843  (/ (- 10452843 634690) 1000 19) = 516

;;; --> +33 B => 10% faster RECURSION

;;; save RUNTIME memory
RESTORY=1
.ifdef RESTORY

restoreY:
;putc '?'
;;; RESTORE!
;;; 14 B
        sta savea
        pla
        tay
:       
        pla
        sta params-1,y
        dey
        bne :-

        lda savea
        rts

.else

;;; ^^^=== 13 c ok, it's faster...
;;; 
;;; long sequence and jump middle
;;; would be 6c faster/byte! (8 => 42c!)
;;; (see PLOP restor8 below... + 27 B)


;;; (+ 27 4 4 4) = 39 B
;;; overall recursive function 10% faster than cc65!

.macro PLOP nn
        pla
        sta params-1+nn
.endmacro



restore8:       
;;; (+ 1 1 1 (* 8 (+ 1 2))) = 27 B
        tay
        PLOP 8
        PLOP 7
rest6:  
        PLOP 6
        PLOP 5
rest4:  
        PLOP 4
        PLOP 3
rest2:  
        PLOP 2
        PLOP 1
        tya
        rts

restore6:       
;;; +4 B
        tay
        jmp rest6
restore4:       
;;; +4 B
        tay
        jmp rest4
restore2:       
;;; loop (+ 3 4 2 3 (* 2 (+ 4 4 2 3))) = 38c

;;; (+ 2 3 2 (* 2 (+ 4 3))) = 21c (overhead 3c)
;;; 4 B (+ 3c)
        tay
        jmp rest2

;;; +5 B  saves  3c => not worth it!
;;; (+ 2 2 (* 2 (+ 4 3))) = 18c
;;; 9 B = 18c
.ifnblank
        tay
        PLOP 2
        PLOP 1
        tya
        rts
.endif

.endif ; !RESTORY


.endif ; JSK_CALLING

.endif ; RECURSION

.endif ; FUNCALL

