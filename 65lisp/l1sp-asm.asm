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

.macro DROP
        inx
        inx
.endmacro

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
;;; 8 + 8

.zeropage
ipy:      .res 1

lowcons:  .res 2
envvar:   .res 2
.code

;;; more efficent init? memcpy?
        lda #<LOWCONSSTART
        sta lowcons
        lda #>LOWCONSSTART
        sta lowcons+1
        
        ;; set things to nil
        ldy #<__nil
        lda #>__nil

        sty envvar
        sta envvar+1

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
        DROP
        jmp setlYhA

ATOM "cons", _cons, "__eq"      ; ... + 119
;;;                          (+ 76 8 4 8 24) .. 127

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
ret:
        rts

;;;                                         127

;;; - stack tools                ; + 61    =181

_dup:   
;;; 2 !
        txa
        tay
;;; TODO: basically it's a COPYreg from y to x-2!!
;;; TODO: _pick?
_pushZPY:
;;; 12
        lda 1,y                 ; hi
        pha
        lda 0,y                 ; lo
        tay
pushlYhA:       
        dex
        dex
setlYhPLA:
        pla
        jmp setlYhA

_swap:  
;;; 14
        dex
        jsr _byteswap
        inx
_byteswap:       
        lda 1,x
        ldy 3,x
        sty 1,x
        sta 3,x
        rts

_nip:   
;;; 6
        jsr _swap
        DROP
        rts

_atomkeep:
;;; TODO: can do in less?
;;; 7
        lda 0,x
        and #3
        cmp #1
        rts

;;; "Zull" - Z=1 if _nil
;;; NOTE: modifies C (no use)
_nullkeep:
;;; 9
;;; TODO: is there a getlYhA ?
        lda 256-2,x             ; neg addressing!
        cmp #<__nil
        lda 256-1,x             ; neg addressing!
        sbc #>__nil
;;; is Z=1 if equal? or just if last byte == ???
        rts

;;;                                 .... 181
        
ATOM "cond", _cond, "__cons"    ; ... = 131 (3 pad)


;;; _exit_
supret:
;;; 3
        pla
        pla
        rts
        
;;; returns whatever isn't cons
_retnotcons:
;;; 9
        lda 0,x
        lsr
        bcc supret
        lsr
        bcc supret
        rts

;;; ItCurrent
_dupcar:        
;;; 6
        jsr _dup
        jmp _car
;;; ItNext
_dropcdr:       
;;; 5
        inx
        inx
        jmp _cdr

_cond:
;;; 33 [15]
        jsr _nullkeep
        beq ret
        ;; have value ( (expr progn) ...)
        jsr _dupcar
        ;; (expr progn)
        jsr _dupcar
        jsr _eval
        jsr _nullkeep
        beq @fail
        jsr _dropcdr
;;; TODO: if null, then want to return what we
;;;   just dropped!
        jmp _progn
@fail:
        DROP
        jsr _cdr
        jmp _cond
;;;                                        ....= 197

_eval:
;;; 36 B  [11? tokens]
;;; RetIfNullOrNUmber_jIfSymbol_StayIfCons 3 tokens
;;; (8) [3]
        jsr _nullkeep
        beq ret
        jsr _atomkeep
        beq atomlookup
evalcons:
;;; (26) [8]
        jsr _dupcar
        jsr _eval
        ;; if no function no progn!
;;; implicit cond!
        jsr _nullkeep
        beq @fail
        ;; now have function
        jsr _swap
;;; TODO: special forms (apart from ip)
;;; TODO: setq (define)
;;; TODO: cond
        jsr evallist
        jmp _apply
@fail:
;       jmp nip
nip:
        jsr _swap
        DROP
rett:   
        rts

_progn:
        ;; TODO: almost same as...
evallist:
;;; 23 - lots...
        jsr _nullkeep
        beq rett
        jsr _dupcar
        jsr _eval
        jsr _swap
        jsr _cdr
        jsr evallist
        jmp _cons               ; !

;;; 34 [12]
atomlookup:     
        jsr _envvar
assoc:  
        jsr dupcar
        jsr _dup
        jsr _car
        jsr _pick4
        jsr _eq
        jsr _zbranch (nextass)
        jsr _nip2
        rts

nextass:        
        jsr _drop
        jsr dropcdr_DropRetIfNotCons
        jmp assoc
        


atomlookup:
;;; (+ 3 3 3 16) = 25 BIG!!!
;;; OR... (+ 3 3 3 3) = 12 ...
        jsr _dup
        ldy #envvar
        jsr _pushZPY
        jsr _assoc
        
;;; if assoc returned atom seached when fail
;;; instead of NIL and IFF
;;; CDR of atom was value....
;;; we could just:
;;; 
;;; 3
;;;     jmp cdr

;;; 16
        jsr _nullkeep
        bne @fail
        jsr _cdr
        jmp _nip
@fail:
        DROP
        ;; get global value!
        jmp _car

;;;                                           333 :-(

;;; How about a really tight offset interpreter?
;;; all within one page (so only push 1B!)
        
;;; exec
;;; 
;;; (+ 3 19 5) = 27 !

.ifnblank
_exec:  
        lda 0,x
        dex
        dex
        pha
.endif

_semis: 
;;; 3
        pla
        sta ipy
next:   
;;; 19
        ;; next token
        inc ipy
        ldy ipy
        lda _start,y

;;; TODO: atoms could be self pushing? (if at end)
;;; (10 B but only __nll __T __lambda ... so...)
        cmp #<offbytecode
        bcs enter
        
        sta call+1
call:   jsr call
        jmp next

enter:  
;;; 5
        ;; Y=ip A=new to interpret
        sta ipy
        tya
        pha
        bne next
        
;;; from here on, only use for bytecode routines!
offbytecode:    

;;;                                  .. +29 = 362
.ifnblank


ATOM "print", _print, "__cond"
ATOM "read", _read, "__print"
ATOM "lambda", _lambda, "__read"
ATOM "quote", _quote, "__lambda"
ATOM "T", .ident("__T"), "__quote"
.endif

_print: 
_read:  
_lambda:        
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

;;; nil:   8
;;; car:   8 17
;;; cdr:   8  3
;;; eq:    8 21
;;; cons: 12 24
;;; print:12
;;; read: 12
;;; lambda:12
;;; quote:12
;;; T:     8
;;; (+ 8 8 17 8 3 8 21 12 24 12 12 12 12 8) = 165

;;; readatom    20
;;; printz      12
;;; - bytecode
;;; eval       (39)  11
;;; assoc      (34)  12
;;; apply       10
;;; (+ 20 12 11 12 10) = 65

;;; inc/2 10  inc inc2
;;; exec  29  semis next enter (+ 3 19 5)
;;; stack 34  dup pushZPY swap nip (+ 2 12 14 6)
;;; test  16  atomkeep nullkeep (+ 7 9)
;;; iter  23  supret retnotcons dupcar dropcdr (+ 3 9 6 5)
;;; (+ 10 29 34 16 23) = 112

;;; (+ 165 65 112) = 342
;;; 
;;; so... need two pages?



