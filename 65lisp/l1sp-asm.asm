;;; l1sp = Lisp 1 Stack Page
;;; 
;;; Yet another start, possibly using off-vm.asm
;;; which is a simple library of 19 stack primitives
;;; implemented in 134 bytes!

;;; ========================================
;;; Initial functions requirement for
;;; template/begin.asm

.zeropage

tos:    .res 2
tmp1:   .res 2

.code

;;; set's TOS to num
;;; (change this depending on impl
.macro SETNUM num
        lda #<num
        sta tos
        lda #>num
        sta tos+1
.endmacro

.macro SUBTRACT num
        sec

        lda tos
        sbc #<num
        sta tos

        lda tos+1
        sbc #>num
        sta tos+1
.endmacro

;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"

.zeropage

.code

;;; ========================================
;;;                  M A I N

;;; CONFIG

ATOMSPACESIZE= 1024
CONSSPACESIZE= 1024*32

LOWCONSSTART= ((endaddr+ATOMSPACESIZE+CONSSPACESIZE)/4)*4

;;; START
.export _start
_start:
.ifnblank
        putc 'L'
        putc '1'
        putc 's'
        putc 'p'
        NEWLINE
.endif

;;; INIT
;;; 4

.zeropage
lowcons:  .res 2
.code

;;; more efficent init? memcpy?
        lda #<LOWCONSSTART
        sta lowcons
        lda #>LOWCONSSTART
        sta lowcons+1

;;; END

.ifnblank
        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'
.endif
        rts

.macro MISALIGN base,off
        .assert base<=4,error,"%% MISALIGN: base too big"

        .if (* .mod base)<>off
          .res 1
        .endif
        .if (* .mod base)<>off
          .res 1
        .endif
        .if (* .mod base)<>off
          .res 1
        .endif
.endmacro

.macro ATOM name,val,prev
.ident(.concat("__", name)) :
        MISALIGN 4,1
        .word val, .ident(prev)
        .byte name, 0
.endmacro

;;; Just the names and no impl: 85 bytes!
;;; 10 entries, 35 chars, 10 \0, 10x2 words
;;; and because names.len > 3 => 13 bytes align!
;;; (+ 35 10 40) = 85   + 13 ==> 98 .. + 2 rts dummys
ATOM "nil", .ident("__nil"), "__nil" ; 2+ 8 = 10
ATOM "car", _car, "__nil"            ;+8+27 = 45
_cdr:   
;;; 3
        jsr _inc2
_car:   
;;; 17
        lda (0,x)
        tay

        jsr _inc
        lda (0,x)
setlYhA:        
        sta (1,x)
        tya
        sta (0,x)
        rts
        
_inc2:  
;;; 10
        jsr _inc
_inc:    
        inc 0,x
        bne @noinc
        inc 1,x
@noinc:
        rts

ATOM "cdr", _cdr, "__car"       ; ... = 54
ATOM "eq", _eq, "__cdr"         ; ... = 76
_eq: 
;;; 15
        ldy #0
        lda 3,x
        cmp 1,x
        beq @eq
        dey
@eq:
;;; 6
popsetYY:       
        tya
popsetlYhA:
        dex
        dex
        jmp setlYhA

ATOM "cons", _cons, "__eq"      ; ... + 119
;;;                          (+ 76 8 4 8 24) .. 120

_cons:  
;;; TODO: too big!

;;; (+ 9 15) = 24
        ;; lowcons -= 4
;;; (9)
        lda lowcons
        sec
        sbc #4
        bcs @nodec
        dec lowcons+1
@nodec:

;;; (15)
        ldy #0
        ;; store cdr
        jsr popstore
        ;; store car
popstore:       
        ;; lo
        jsr bytepopstore
        ;; hi
bytepopstore:   
        lda 0,x
        sta (lowcons),y
        iny
        inx

        rts

ATOM "cond", _cond, "__cons"    ; ... = 131 (3 pad)
_cond:

.ifnblank
ATOM "print", _print, "__cond"
ATOM "read", _read, "__print"
ATOM "lambda", _lambda, "__read"
ATOM "T", .ident("__T"), "__cond"
.endif

_print: 
_read:  
_lambda:        
_eval:
_apply: 
_assoc: 
        rts

;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

.include "end.asm"

.end
