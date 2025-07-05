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
ip:       .res 2
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

        ;; set IP - point to read-eval!
        lda #<_readeval
        sta ip
        lda #>_readeval
        sta ip+1

        ldy #0
        sty ipy

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
.ifnblank
cdr:    
        DO _inc
        DO _inc
        DO _car
        DO _semis
.endif
ATOM "eq", _eq, "__cdr"         ; ... = 76
_eq: 
;;; 15
        ldy #0
        lda 3,x
        cmp 1,x
        beq @neq
@eq:
        dey
@neq:
;;; 6
popsetYY:       
        tya
popsetlYhA:
        DROP
        jmp setlYhA

ATOM "cons", _cons, "__eq"      ; ... + 119
;;;                          (+ 76 8 4 8 24) .. 127

_cons: 
.ifnblank
        ;; writing forward (10)
        DO _swap
        LIT lowcons
        DO _load
        DO _comma
        DO _comma
        LIT lowcons
        DO _save
        DO _semis

        ;; assuming reverse comma (9)
        LIT lowcons
        DO _load
        DO _rcomma
        DO _rcomma
        LIT lowcons
        DO _store
        DO _semis
.endif

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
        jsr wordstore
        ;; store car
wordstore: 
        ;; lo
        jsr bytestore
        ;; hi
bytestore: 
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

;;;                                           226 :-(

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
        

;;;                                  .. +29 = 255

;;; maybe keep names at "offset from atomaddr?"
;;; (could pack them in and no fillers!)

ATOM "print", _print, "__cond"
ATOM "read", _read, "__print"
ATOM "lambda", _lambda, "__read"
ATOM "quote", _quote, "__lambda"
ATOM "T", .ident("__T"), "__quote"

;;;                                          = 312
;;; (+ 255 12 12 12 12 8) = 311

.ifnblank
.endif

_quote: 
_cond:
_readeval:      
_print: 
_read:  
_lambda:        
_apply: 
_assoc: 
        rts

;;; from here on, only use for bytecode routines!
offbytecode:    

;;; ==================================================
;;;                  B Y T E C O D E

.ifnblank
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


.endif

;PRINTHEX=1                     
;PRINTDEC=1
.include "print.asm"

;;;                  M A I N
;;; ========================================

.include "end.asm"

.end

;;; bytes:
;;;     atoms bytecode
;;;               machinecode 
;;; nil:   8           
;;; car:   8        17 
;;; cdr:   8   (5)   3 
;;; eq:    8        15 
;;; cons: 12   (6)  24
;;; cond: 12  (23)  33     TODO: look at _cond byte code 15?
;;; progn:    (12)   ?
;;; print:12 
;;; read: 12 
;;; lambda:12          
;;; quote:12           
;;; T:     8           
;;; names: (+ 8 8 8 8 12 12 12 12 12 12 8) = 112
;;; (+ 8 8 17 8 3 8 21 12 24 12 12 12 12 8) = 165
;;; OFFSET: (+ (* 8 10) -1 1 2 1 3  2 -2  17 3 21 24)= 151

;;; --- TODO:
;;; read:      (48)  20???
;;; (readatom                 (8+15) )
;;; (rdlist                   (20)   )
;;; getatomc   (15) ??? TOOD:
;;; print      (28)  15
;;; (printatom        5         (9)
;;; printz            9

;;; (prlist          30         (19)
;;; - bytecode
;;; eval       (27)  36 
;;; eavllist   (23)
;;; assoc      (12)  34
;;; (apply                       10)
;;; 
;;; (+ 20 20 10 12 20 11 12 10) = 115

;;; bytecodes: (+ 5 6 23 12 48 28 27 23 12) = 184
;;; havetoasm: (+ 17 15) = 32
;;; onlymc:    (+ 17 3 15 24 33 30 20 24 20 15 20 5 9 36 25 34 10) = 348
;;; 
;;; lisp: bytecodes+havto = (+ 184 32) = 216
;;; 
;;;    atomnames = 112
;;; 
;;; basic VM ops? +++ 

;;; LISP BYTES: (+ 216 112) = 328
;;; 
;;;  VM routines used: 25 only1
;;; 
;;; exec/next/enter/semis        (+ 38)          = 38
;;; ( drop drop2 dup nip swap  ; (+ 3 2 11 3 14) = 33 
;;;   car cdr load store         (+ 3 17 11 14)  = 45 
;;; TODO: ccomma comma rcomma    (+ 10 5 15) ??? = 30
;;;   eq null zero               (+ 3 8 6)       = 17
;;;   inc plus                   (+ 7 4 14) ???  = 25
;;;   semis JZ JP                (+ 0 18 3)      = 21
;;; TODO: jump                   (+ 12)     ???  = 12
;;;   putc getc                  (+ 6 5)         = 11
;;; TODO: getatomchar peekc      (+ 15 10)       = 25
;;;  )
;;; 
;;; (+ 38 33 45 30 17 25 21 12 11 25) = 257
;;;       HUH   ..... ?????

;;; We define:
;;; ( assoc cons dropcdr dupcar eval evparams progn
;;; TODO:  isstrictfun atom islambda
;;;   print printatom read readlist )
;;; 
;;; TODO: apply_lambda 

;;; if we only count: 
;;; "savings"?  (+ 18 10 15 5 10 7 5 11 9 10 22) = 122

;;; (- 348 122) =  226 ok.... makes sense




;;; branch 
;;; inc/2 10  inc inc2
;;; exec  29  semis next enter (+ 3 19 5)
;;; stack 34  dup pushZPY swap nip (+ 2 12 14 6)
;;; test  16  atomkeep nullkeep (+ 7 9)
;;; iter  23  supret retnotcons dupcar dropcdr (+ 3 9 6 5)
;;; (+ 10 29 34 16 23) = 112

;;; (+ 151 115 112) = 378
;;; 
;;; so... need two pages?



;;; write as many lisp functions as possibly in byte code!
.ifnblank

ATOM "nil", .ident("__nil"), "__nil"

ATOM "cdr", _cdr, "__nil"
;;; 5
        LIT 2
        DO _plus
        DO _load
        DO _semis

ATOM "car", _load, "__cdr"

ATOM "cons", _cons, "__car"
;;; 6
        DO _swap
;;; TODO: how to say use lowcons???
;;; to ptr1?
        DO _comma
        DO _comma
        DO _semis

;;; ATOM "null", _null, "__car"
;;; TODO: if nil was at address 0 ...
;        LIT __nil
ATOM "eq", _eq, "__cons"


;;; ATOM "eval", _eval, __
;;; (+ 12 15) = 27

;;; 12 - atoms
        DO _atom
        JZ evalcons
        ;; atom
        DO _envptr
;;; special assoc, returns: (sought . value)
;;;     or if fail return: sought
        DO _assoc
        DO _atom
        JZ foundvar
notfound:       
        ;; look up global value
;;; TODO: what if value was in cdr!!! 
;;;    would ave 2 bytes here!
        DO _car
        DO _semis
foundvar:       
        DO _cdr
        DO _semis

evalcons:
;;; (+ 8 4 3) = 15
        ;; we have (fun params...)
        DO _dupcar
        ;; eval fun
        DO _eval
        DO _dup
        DO _isstricfun
        JZ evalapply
evalapply:
;;; (4)
        ;; stack: (fun params...) funaddr
        DO _swap
        DO _evparams
        DO _swap
nlambda:        
;;; (3)
        ;; nlambdas
        DO _load
        DO _jump                
        DO _jump
        ;; doesn't return (?) (have DO _call)

ATOM "cond", _cond, "__eq"
;;; (+ 6 9 4 4) = 23 

;;; (6)
        ;; L= ( F=(test1 progn1) G=...)
        DO _dupcar              ; L F
        ;; (test1 progn1)
        DO _dupcar              ; L F test1
        DO _eval                ; L F res
        DO _dup                 ; L F res res
        ;; jmp if nil = clause failed
        JZ _cnext               ; L F res
        ;; true
;;; (9)
        DO _swap                ; L res F
        DO _cdr                 ; L res progn1
        DO _dup                 ; L res progn1 progn1
        DO _null                ; L res progn1 0/true  
        JZ haveprogn            ; L res progn1
        ;; no progn - just return res
        DO _drop                ; L res
        DO _nip                 ; res
        DO _semis
haveprogn:      
;;; (4)
        ;;                      ; L res progn1
        DO _nip
        DO _nip
;;; TODO: tail calls?
        DO _progn
        DO _semis

cnext:
;;; (4)
        ;;                      ; L F res
        DO _drop                ; L F
        ;; go next
        DO _dropcdr             ; G
        JP _cond

;; ATOM "progn", _progn, "...
;;;  P= (a Q=...)
;;; 12
        DO _dupcar              ; P a
        DO _eval                ; P v
        DO _swap                ; v P
pnext:   
        DO _cdr                 ; v Q   
        DO _dup                 ; v Q Q
        JZ patend               ; v Q
        ;; have more
        DO _nip                 ; Q
        JP _progn

patend: 
        DO _drop                ; v
        DO _semis
        

ATOM "lambda", _lambda, "__cond"
        ;; TODO: needs to have access to itself
        ;; self-quoting, or applying? hmmmm
        ;; but would then need to have special support
        ;; in apply, or put something else on stack!

ATOM "print", _print, "__lambda"
;;; (+ 9 19) = 28
pratom: 
;;; (9)
        DO _dup
        DO _atom
        JZ prcons
        DO _printatom
        LIT ' '
        DO _putc
        DO _semis

prcons: 
;;; (19)
        LIT '('
        DO _putc
prlist: 
        DO _dupcar
        DO _print
        DO _cdr
        DO _atom
        JZ prlist
pratend:        
        ;; if cdr<>nil print atom; putc ')'
        DO _dup
        JZ prend
        ;; . atom
        LIT '.'
        DO _putc
prend:
        LIT ')
        DO _putc
        DO _semis

ATOM "read", _read, "__print"
;;; (+ 5 15 8 20) = 48

;;; (5)
        DO _getatomchar
        DO _dup
        JZ readlist
createatom:     
;;; (15)
        LIT here

        ;; set car
        LIT __nil
        ;; TODO: how to say use here?
        ;; to ptr1?
        DO _comma
        DO _drop2

        ;; set cdr: next atom link
        LIT _T
        DO _cdr
        DO _comma

        ;; link this one in
        DUP _here
        LIT _T
        DO _store
        
        DO _swap
rdatom: 
;;; (8)
        ;; save char to 
        DO _ccomma

        DO _getatomchar
        DO _dup
        JZ rdatom

rdatomend:      
        ;; create atom
        DO _zero
        DO _ccomma
        DO _semis

readlist:
;;; (20)
        DO _dup
        LIT ')'
        DO _eq
        JZ readlist2
rdlend:  
        LIT __nil
        DO _semis

readlist2:      
        LIT '('
        DO _eq
        JZ rderr
rdlstart:
        DO _read
        DO _readlist
;;; tail call?
        DO _cons
        DO _semis

rderr:  
        LIT __nil
        DO _semis
        
getatomc:       
        DO _peekc
        DO _
...

ATOM "quote", _quote, "__read"
        ;; TODO: needs to have access to itself

ATOM "T", .ident("__T"), "__quote"

.endif
