;;; lib-stdlib.asm
;;; 
;;; Part of library for parse CC02 C-compiler
;;; 
;;; Only functions defined here:
;;; - rand() srand()
;;; - TODO: malloc(), free(), realloc()


;;; -------- <stdlib.h>

;;; same same...
;;; - atoi
;;; 
;;; - rand()
;;; - random()
;;; - srand()
;;; - srandom()

;;; TODO:
;;; - malloc
;;; - free
;;; - realloc
;;; - calloc

;;; - _Exit(int)
;;; - abort()
;;; - exit(int)

;;; - abs
;;; - div

;;; - getenv
;;; - putenv
;;; - setenv

;;; - bsearch
;;; - qsort
;;; - setkey
;;; - encrypt
;;; (inp) => AX, inp points at next (not digit) char
;;; 
;;; TODO: too big! just use parse rules!!!



;;; - https://wimcouwenberg.wordpress.com/2020/11/15/a-fast-24-bit-prng-algorithm-for-the-6502-processor/




;;; 16 bit, maybe wrongly ported? 
;;; - http://www.retroprogramming.com/2017/07/xor

;;; set random seed, can be anything except 0
;;; unsigned xorshift( )
;;; {
;;;     xs ^= xs << 7;
;;;     xs ^= xs >> 9;
;;;     xs ^= xs << 8;
;;;     return xs;    
;;; }
;;; 
;;; There are 60 shift triplets with the maximum
;;; period 216-1. Four triplets pass a series of
;;; lightweight randomness tests including randomly
;;; plotting various n × n matrices using the high
;;; bits, low bits, 

.zeropage
rng:    .res 2
.code

LIBFUN rand

.ifblank
;;; my version

        ;; xs ^= xs << 7;
.ifnblank
;;; 25 B
      ldx rng+1
        lda rng
        lsr
        eor rng+1
        sta rng+1
        lda #0
        ror
        eor rng
        sta rng
      txa
      lsr
      lda #0
      ror
      eor rng+1
      sta rng+1
.else
;;; 19 B (gen from oscar64, lol)
        LDA rng+1
        LSR
        LDA rng
        ROR
;        lsr
        TAX
        LDA #$00
        ROR
        EOR rng
        STA rng
        TXA
        EOR rng+1
        STA rng+1
;;; TODO: doesn't that skip the low bit of
;;;    rng+1, shouldn't it be flipping the hi bit?
.endif

        ;; xs ^= xs >> 9;
        ;lda rng+1
        lsr
        eor rng
        sta rng

        tax
        ;; xs ^= xs << 8;
        ;lda rng
        eor rng+1
        sta rng+1
        
        ;; AX reversed but doesn't matter
        ;; - each value is generated!
        rts

.else
;;; from link - wrong!
        lda rng+1
        lsr
        lda rng
        ror
        eor rng+1
        sta rng+1  ; x ^= x << 7 done
        ror        ; A x >> 9 high bit comes from low
        eor rng
        sta rng    ; x ^= x >> 9 low part of x ^= x << 7

        tay
        
        eor rng+1
        sta rng+1  ; x ^= x << 8 done

        ;; return AX=rng,rng+1
        tax
        tya

        rts
.endif

LIBENDFUN rand


;FUNC _atoiAX
;        sta sos
;        stx sos+1               
;        ldx #sos

.ifdef ATOI

FUNC _atoiXR
        lda #10
FUNC _atoibaseXR
        sta base
        lda #0
        sta tos
        sta tos+1
        ;; base
        sta dos

        ;; 0x 'c' -
        lda (0,x)
        ;; ' - char constant
        cmp #'''
        bne :+
        
        jsr _incXR
        lda (0,x)
        ;; TODO: handle \' \n \b \t ???
        jsr _incXR
        ;; - should be '-' lol
        jsr _incXR
        jmp @retA
:       
        ;; "-" negative
        cmp #'-'
        bne :+

        jsr _incXR
        jsr _atoiXR
        jmp _negate
:       
        ;; "0x" - hex
        cmp #'0'
        bne :+                  ; 1-9
        jsr _incXR
        ora #32
        cmp #'X'
        bne @ret                ; zero! (no octal...)
@hex:    
        lda #16
        sta base

:       
        lda (0,x)
        ;; digit? '0' <= a <= '9'
        sec
        sbc #'0'
        cmp #'9'+1-'0'
        bcs @notdigit
        ;; digit
        sta savea
        lda base
        sta dos
        lda #0
        ;; tos= tos * dos; // mul16 destroys tos&dos
        jsr _mul16bits
        ;; c=0 from cmp
        adc savea
        tay

@ret:
        lda tos
@retA:
        ldx tos+1
        rts
.endif ; ATOI


;;; ------------ HEAP MEMORY MANAGMENT -----------

.zeropage
_heap:    .res 2
.code

;;; Allocate AX bytes
;;; 
;;; NOTE: no error, no limit, just wraps around!
;;; 
;;; Result:
;;;   AX= pointer to allocated bytes
;;;   savea,savex= allocation size
;;; 

;;; TODO: rename to sbrk? LOL?

FUNC _malloc
;;; 21 B  33c! (+ 20 => 41 B)
        sta savea
        stx savex

        ;; move _out forward AX bytes
        clc
        lda _heap
        tay                     ; save _out
        adc savea
        sta _heap

        lda _heap+1
        tax                     ; save _out+1
        adc savex
        sta _heap+1

        ;; overflow heap?
;;; 20 B
        ;; TODO: use a _heapend (for alloca)
        cmp #>ENDOFHEAP
        bne :+
        lda _heap
        cmp #<ENDOFHEAP
:       
        bcs :+
        ;; OK
        tya                     ; restore lo
        rts
:       
        ;; restore _out
        sty _heap
        stx _heap+1
        ;; return 0
        lda #0
        tax
        rts



;;; TODO: lol

FUNC _free
        rts



;;; TODO: combine malloc and xmalloc
;;;   shouldn't need a second test

;;; Xallocate AX bytes
;;; 
;;; if malloc fails, halt and print error
;;; 
;;; Returns same as _malloc
;;;  But never 0!
FUNC _xmalloc
;;; 11+12 = 23 B
        jsr _malloc
        ;; malloc cannot happen on 0 page
        tay
        bne @OK
        cpx #0
        beq @fail
@OK:
        rts
@fail:
        ;; AX == 0
        ;; FAIL

;;; TODO: remove once we have runtimeerrorwdata
        lda savea
        ldx savex
        jsr _printu

        ldy #'M'
        jmp runtimeerror



LIBFUN init_stdlib

;;; 8 B
        ;; heap init
        lda _out
        ldx _out+1
        sta _heap
        stx _heap+1

;;; 7 B
        ;; srand(1) for rand()
        ldx #1
        stx rng
        dex
        stx rng+1

LIBENDFUN init_stdlib
