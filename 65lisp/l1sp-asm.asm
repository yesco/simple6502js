;;; l1sp = Lisp 1 Stack Page
;;; 
;;; Yet another start, possibly using off-vm.asm
;;; which is a simple library of 19 stack primitives
;;; implemented in 134 bytes!

;;; ========================================
;;; Initial functions requirement for
;;; template/begin.asm


;ENFORCE_ONEPAGE=1

;USETHESE=1
;DISABLEINTERRRUPTS

;
BOOT=1

;;; Applies to off-vm.asm
;
IO=1
;
MINIMAL=1

;;; Applies to the "sectorlisp"
;;; (it has no numbers, even == atom, odd == cons)
;
LISP=1
.ifdef LISP
  ATOMMISALIGNMENT=0
  ;
  LISPINIT=1
.endif


;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"


;;; ========================================
;;;                  M A I N

;;; CONFIG

;;; "heap"
HEAPSIZE= 1024
;;; "cons" heap
CONSSPACESIZE= 1024*32

HERESTART= endaddr
LOWCONSSTART= ((endaddr+HEAPSIZE+CONSSPACESIZE)/4)*4

_NOP_=$ea

;;; ========================================

.zeropage

;;; LOL, may not be possible, but makes
;;; _nil_ address==0, using _null, _zero!

.org 0

;;; VVVVVVVVVVV don't modify VVVVVVVVVVVVVV
;;; (this must be congruent with constdata!)
zerovarstart:   

NIL8B:    .res 8
lowcons:  .res 2
envvar:   .res 2
here:     .res 2
ipy:      .res 1

zerovarsend:
;;; ^^^^^^^^^^^^ don't modify ^^^^^^^^^^^^^

;;; put other non-init vars here...

.code

;;; ========================================
;;; START
FUNC _start
.ifnblank
        putc 'L'
        putc '1'
        putc 's'
        putc 'p'
        NEWLINE
.endif

;;; INIT
;;; 22 bytes already, make constants range and memcopy!


.ifnblank
        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'
.endif

;;; Or we could say this is up to the user app?
;;; 
;;; 4 (+1 DIS) (+3 LISPINIT)
.ifdef BOOT
boot:   

        ;; disable interrupts
.ifdef DISABLEINTERRUPTS
        sei
.endif
        ;; init hardware + data stack
        ldx #$ff
        txs

        ;; init your "app"

.ifdef LISPINIT
        jmp _l1spinit
.else

        rts
.endif

.endif ; BOOT

;;; ----------------------------------------
;;;              alternative implementations
;;;        maybe just use off-vm.asm?
;;; 
;;; LOL
; set USETHESE=1 above!

.ifndef USETHESE

  .include "off-vm.asm"


.else

;;; ----------------------------------------

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro

.macro DROP
        inx
        inx
.endmacro

;;; Doesn't consume the value
_nilqkeep:
;;; 17
        lda 0,x
        cmp #<_nil_
        bne @notnil
        lda 1,x
        cmp #>_nil_
        ;; == _nil
@notnil:
        ;; tail calls
        bne _true
        beq _zero
_jnil:
        jsr _nilqkeep
        ;; arrives here with 
        ;; _zero == is nil; _true == is ! not
        ;; -- fall through to _jz
_jz:     
;;; TODO: implement!
        rts

.ifnblank
_duptestelse:
;;; 12
        jsr _dup
        jsr get
        jsr _exec
        jmp _jz
.endif        

;;; TODO: wow so much "msising"
FUNC _printatom     
FUNC _putc
FUNC _getc
FUNC _getatomchar
FUNC _jp
FUNC _null
FUNC _jump
FUNC _lit
FUNC _literal
        rts


FUNC _drop2
        inx
        inx
;;; Notice: jsr/jmp _drop no use!
;;; 
FUNC _drop  
        inx
        inx
        rts

FUNC _cdr
;;; 3
        jsr _inc2
FUNC _car
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
        
FUNC _inc2
;;; 10
        jsr _inc
FUNC _inc
        inc 0,x
        bne @noinc
        inc 1,x
@noinc:
        rts

;;; nice chaining:
FUNC _eq 
;;; 15
        ldy #0
        lda 3,x
        cmp 1,x
        bne @neq
        lda 2,x
        cmp 1,x
        bne @neq
@eq:
        dey
@neq:
;;; 6
popsetYY:
        tya
popsetlYhA:
        DROP
        jmp setlYhA

FUNC _FFFF
_true:  
_neg1:  
;;; 3
        lda #0
        SKIPTWO
FUNC _zero
;;; 8
        lda #0
        tay
        dex
        dex
        jmp setlYhA

;;; TODO: if want pick, not not want pick
;;; could choose different impls

FUNC _dup
;;; 11
        lda 0,x
        ldy 1,x
pushAY:
        dex
        dex
AYtoTOS:
        sta 0,x
        sty 1,x

        rts

.ifnblank
FUNC _dup
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
.endif

FUNC _swap
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

FUNC _nip
;;; 6
;;; TODO: if have mth, use those instead!
        jsr _swap
        DROP
        rts

FUNC _atomkeep
;;; TODO: can do in less?
;;; 7
        lda 0,x
        and #3
        cmp #1
        rts

;;; "Zull" - Z=1 if _nil
;;; NOTE: modifies C (no use)
FUNC _nullkeep
;;; 9
;;; TODO: is there a getlYhA ?
        lda 256-2,x             ; neg addressing!
        cmp #<_nil_
        lda 256-1,x             ; neg addressing!
        sbc #>_nil_
;;; is Z=1 if equal? or just if last byte == ???
        rts

;;;                                 .... 181
        
;;; _exit_
FUNC _supret
;;; 3
        pla
        pla
        rts
        
;;; returns whatever isn't cons
FUNC _retnotcons
;;; 9
        lda 0,x
        lsr
        bcc _supret
        lsr
        bcc _supret
        rts

;;; ItCurrent
FUNC _dupcar
;;; 6
        jsr _dup
        jmp _car
;;; ItNext
FUNC _dropcdr
;;; 5
        inx
        inx
        jmp _cdr

;;; How about a really tight offset interpreter?
;;; all within one page (so only push 1B!)
        
;;; exec
;;; 
;;; (+ 3 19 5) = 27 !

FUNC _exec  
        lda 0,x
        dex
        dex
        pha

FUNC _semis
;;; 3
        pla
        sta ipy
FUNC _next
;;; 19
        ;; next token
        inc ipy
        ldy ipy
        lda _start,y

;;; TODO: atoms could be self pushing? (if at end)
;;; (10 B but only _nll _T _lambda ... so...)
        cmp #<offbytecode
        bcs enter
        
        sta call+1
call:   jsr call
        jmp _next

enter:  
;;; 5
        ;; Y=ip A=new to interpret
        sta ipy
        tya
        pha
        bne _next
        
FUNC _load
FUNC _store
FUNC _comma
FUNC _ccomma
;;; TODO:
FUNC _rcomma
;;; TODO:
        ;; lol
        rts

.endif ; USETHESE


;;; ========================================
;;; enable this to ignore bytecodes
.ifnblank

offbytecode:    
endfirstpage:   

secondpage:
bytecodes:      

;;; We start by offset index here



_readeval:      
_nil_:  

.include "end.asm"


.end

.endif



;;; All "instructions" of our bytecode language
;;; are offsets into the firstpage: _start[instr]
;;; 
;;; Normally, these are machinecode locations for
;;; primtivies.
;;; 
;;; But for "syntesized" bytecode routines, they
;;; are used as an offset to get the offset of
;;; the bytecode routine in page2: bytecodes[offset].

;;; Effectively:
;;; 
;;; next:
;;; 
;;; get:  
;;;    o= bytecodes[ipy]
;;; 
;;;    if o < offbytecode
;;;      JSR _start+o
;;;    else
;;;      PHA ipy
;;;      ipy= _start[o]
;;;    
;;;    goto next

.macro MAPTO bytecodefun
        .assert (bytecodefun-bytecodes)>=0,error,"%% MAPTO only maps to labels in bytecodes page"
        .assert (bytecodefun-bytecodes)<256,error,"%% MAPTO it seems the bytecodes page is full"

        ;; We store offset-1 as we prc-inc in get
        .byte (bytecodefun-bytecodes)-1
.endmacro

;;; experiement
.ifnblank
offbytecode:
_l1spinit:
.ifnblank
        putc '>'
        jsr getchar
        jmp _l1spinit
.endif

        ldy #<foo
        sty ipy
        jmp next

foo:    
        LIT 65
        DO _dup
        DO _emit
        jp foo

.include "end.asm"
.end

.endif


;;; ========================================

;;; TODO: changing this...
.ifnblank
;;; 13 items 13 bytes!

.assert (offbytecode-_start)<256,error,"%% No space left in page 1 for MAPTO"

_cons:          MAPTO bc_cons
_eval:          MAPTO bc_eval
_cond:          MAPTO bc_cond
_atom:          MAPTO bc_atom

_progn:         MAPTO bc_progn
_assoc:         MAPTO bc_assoc
_print:         MAPTO bc_print
_read:          MAPTO bc_read

_readlist:      MAPTO bc_readlist
_evparams:      MAPTO bc_evparams
_isstrictfun:   MAPTO bc_isstrictfun
_readeval:      MAPTO bc_readeval

.endif

;;; ========================================
endfirstpage:   
.ifdef ENFORCE_ONEPAGE
.assert *-_start<=256,error,"%% firstpage is FULL!"
.endif
;;; align ; Not using _NOP_ as this is usable space
.res (256-(* .mod 256)), 0 
;;; ========================================

.macro DO fun
        .assert fun-_start>0,error,"%% DO: cannot call fun at offset 0"
        .assert (fun-_start)<256,error,"%% DO: can only do funs in first page"

        ;; -1 as we pre-inc in "get"
        .byte (fun-_start)
.endmacro


;;; Branch instruction are simplified as we're
;;; only within the same page to set ipy!

.macro OFFSET label
  .assert label-bytecodes>0,error,"%% JP/JZ offset neg"
  .assert label-bytecodes<256,error,"%% JP/JZ offset too big"
        .byte label-bytecodes-1
.endmacro

.macro JP label
        DO _jp
        OFFSET label
.endmacro

.macro GOTO label
        JP label
.endmacro


.macro JZ label
        DO _jz
        OFFSET label
.endmacro

.macro ELSE label
        JZ label
.endmacro

;;; lol
;;; 2x
.macro IF test
        ;; TODO: make this _instruction!
        DO _dup
        DO test
.endmacro

;;; 6 B  can do in 3 B -save 3 B
;;; 1x
.macro IFNOTEQ val, label
        DO _dup
        LIT val
        DO _eq
        ELSE label
.endmacro

;;; 4 B can do it in 3 B save 7 B
;; TODO: make this _instruction!
;;; 7x
.macro IFNOT test, label
        IF test
        ELSE label
.endmacro

;;; TODO: 8 B  do it in 2 B - save: (- 24 6)=18 B to save
;;; 3x                   IFFF we can use 0 instead!
;;; 
;;;         _jnil    (- 24 17) = 7 bytes saved

;;; TODO: if using 0 for NIL then *easy*

.macro IF_NIL_GOTO label
        DO _jnil
        OFFSET label
.endmacro

;;; use only for non-const (variables/addresses)
.macro ADDR lit
        DO _lit
        .byte lit
.endmacro

.macro ADDRESS literal
        DO _literal
        .word literal
.endmacro

;;; prefer this!
.macro LIT lit

  .if .not .const(lit)
        DO _lit
        .byte lit
    .exitmacro
  .endif

  .if (lit=0) 
        DO _zero
    .exitmacro
  .endif

  .if (lit=$ffff) 
        DO _FFFF
    .exitmacro
  .endif

  .if (lit<256)
        DO _lit
        .byte lit
    .exitmacro
  .endif

        ;; fallback
        DO _literal
        .word lit

.endmacro


.macro MISALIGN base,off
  .assert base<=4,error,"%% MISALIGN: base too big"

;;; ONLY 10 bytes lost...
;;; TODO: maybe can move some code around
        .if (* .mod base)<>off
          .res 1,_NOP_
        .endif
        .if (* .mod base)<>off
          .res 1,_NOP_
        .endif
        .if (* .mod base)<>off
          .res 1,_NOP_
        .endif
.endmacro


.macro ATOM name,val,prev

.export .ident(.concat("_", name,"_"))
.ident(.concat("_", name,"_")) :
        MISALIGN 4,ATOMMISALIGNMENT
        .word val, .ident(prev)
        .byte name, 0
.endmacro


secondpage:
bytecodes:
;;; --------------------------------------------------
;;; dispatch offset table (used by _enter)



;;; from here on, you can use bytecode routines
;;; ==================================================
;;;                  B Y T E C O D E


;;; ------- simple experiment

;.ifnblank
_l1spinit:
        putc '>'
        jsr getchar
;        jmp _l1spinit

;;; "exec"
        ldy #<foo-1
        sty ipy
        jmp _next

foo:
        LIT 10
        DO _emit

        LIT 65+32
        DO _dup
        DO _emit
bar:
        LIT '.'
        LIT '?'

        LIT '^'
        DO _emit

        DO _emit
        DO _key
        DO _dup
        DO _emit
        DO _emit
        DO _emit

        LIT 10
        DO _emit

;;; jsk   _inc changes x???? hmmm

;        DO _inc
;        DO _inc
        DO _dup
        DO _emit

        JP bar

.include "end.asm"

.end
.endif










;PRINTHEX=1                     
;PRINTDEC=1
;.include "print.asm"

;;; write as many lisp functions as possibly in byte code!

bc_readeval:

;.byte _start    ; $700
;.byte endfirstpage ; $806
;.byte _read     ; $801
;.byte bytecodes ; $900

        DO _read
        DO _eval
        GOTO bc_readeval

FUNC l1spinit
.scope

;;; Copy initconst area to zero page
        ldx #(initend-initconst)-1
        
next:   
        lda initconst,x
        sta 0,x
        dex
        bpl next


;;; DO some tests

        putc 'a'
        putc 'b'
        putc 'd'



        rts

.endscope

;;; This area is copied to zero page at startup
initconst:      


;;; TODO: shit! _nil_ will be at address 0
;;;   to easy test _nil_ == 0 == _null test
;;;   OK: fine, remember we "don't" have numbers
;;;   in "sectorlisp".

;;; For another extended lisp with numbers, we'd expect
;;;   iii00 = int*2
;;;   aaa01 = atoms
;;;   iii10 = int*2
;;;   ccc11 = cons

ATOM "nil", .ident("_nil_"), "_nil_"
.assert(_nil_=constdata),error,"%% initconst: _nil_ must be first to be copied to address 0"

__lowcons:      .word LOWCONSSTART
__envvar:       .word _nil_
__here:         .word HERESTART
__ipy:          .byte <_readeval

constend:       
.assert (zerovarsend-zerovarsstart=constend-constdata),error,"%% zorovarstart and constdata area sizes don't match"
;;; <<<< don't put anything before except consts!





;;; -------------------------------------
;;; --- added machine VM instructions ---
;;; 
;;; TODO: These need "jmp trampolines"
;;;       in 1st page!

;;; this doesn't consume value on stack
.ifnblank
_nilqkeep:
;;; 17
        lda 0,x
        cmp #<_nil_
        bne @notnil
        lda 1,x
        cmp #>_nil_
        ;; == _nil
@notnil:
        ;; tail calls
        bne _true
        beq _zero
_jnil:
        jsr _nilqkeep
        ;; arrives here with 
        ;; _zero == is nil; _true == is ! not
        ;; -- fall through to _jz
        jmp _jz
.endif

_comma: 
_ccomma:        
_getatomchar:
_jump:  
        ;; TODO:
        rts
;;; ----------------------------------------







ATOM "cdr", _cdr, "_nil_"
;;; smaller in machine code (before _load/_car)
.ifnblank
;;; 5
_cdr:
        LIT 2
        DO _plus
        ;; TODO: tailcall?
        DO _load
        DO _semis
.endif

ATOM "car", _load, "_cdr_"

ATOM "cons", _cons, "_car_"
;;; 6
bc_cons:
        DO _swap
;;; TODO: how to say use lowcons???
;;; to ptr1?
        DO _comma
        DO _comma
        DO _semis

.ifnblank
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

_store: 
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

.endif




;;; ATOM "null", _null, "_car"
;;; TODO: if nil was at address 0 ...
;        LIT _nil_
ATOM "eq", _eq, "_cons_"

FUNC _bc_eval
;;; ATOM "eval", _eval, _
;;; (+ 12 15) = 27

;;; 13 - atoms
bc_eval:
        IFNOT _atom, evalcons
        ;; atom
        ADDR envvar
;;; special assoc, returns: (sought . value)
;;;     or if fail return: sought
        DO _assoc
        IFNOT _atom, foundvar
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
;;; (+ 6 3 2) = 11
        ;; we have (fun params...)
        DO _dupcar
        ;; eval fun
        DO _eval
        IFNOT _isstrictfun, nlambda
evalapply:
;;; (4)
        ;; stack: (fun params...) funaddr
        DO _swap
        DO _evparams
        DO _swap
nlambda:        
;;; (3)

;;; TODO: handle _lambda?
;;;    maybe "explict" apply fun?

        ;; nlambdas
        DO _load
        DO _jump                
        ;; doesn't return (?) (have DO _call)

FUNC _bc_atom
bc_atom:        
        DO _semis

FUNC _bc_isstrictfun
bc_isstrictfun: 
        DO _semis

FUNC _bc_evparams
bc_evparams:       
;;; TODO:
        DO _semis
.ifnblank

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
.endif

ATOM "cond", _cond, "_eq"
;;; (+ 6 9 4 4) = 23

;;; (6)
FUNC _bc_cond
bc_cond:  
        ;; L= ( F=(test1 progn1) G=...)
        DO _dupcar              ; L F
        ;; (test1 progn1)
        DO _dupcar              ; L F test1
        DO _eval                ; L F res
        ;; jmp if nil = clause failed
        IF_NIL_GOTO cnext      ; L F res
        ;; true
;;; (9)
        DO _swap                ; L res F
        DO _cdr                 ; L res progn1
        DO _dup                 ; L res progn1 progn1
        IF _null                ; L res progn1 0/true  
        ELSE haveprogn            ; L res progn1
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
        GOTO bc_cond

.ifnblank

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

.endif

;;; TODO: why is this smaller?
;;;    hint: nullkeep? etc?
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

.endif

;; ATOM "progn", _progn, "...
;;;  P= (a Q=...)
;;; 12
FUNC _bc_progn
bc_progn: 
        DO _dupcar              ; P a
        DO _eval                ; P v
        DO _swap                ; v P
pnext:   
        DO _cdr                 ; v Q   
        IF_NIL_GOTO patend        ; v Q Q
        ;; have more
        DO _nip                 ; Q
        GOTO bc_progn

patend: 
        DO _drop                ; v
        DO _semis
        

FUNC _bc_assoc
;;; ATOM "assoc"
bc_assoc: 
;;; TODO: write bytecode!

.ifnblank
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

ATOM "lambda", _lambda, "_cond_"
        ;; TODO: needs to have access to itself
        ;; self-quoting, or applying? hmmmm
        ;; but would then need to have special support
        ;; in apply, or put something else on stack!
_lambda:
;;; TODO:

ATOM "print", _print, "_lambda_"
;;; (+ 9 19) = 28
;;; (9)
FUNC _bc_print
bc_print:       
        DO _dup
        IFNOT _atom, prcons
pratom:
        DO _printatom
        LIT ' '
        DO _putc
        DO _semis

FUNC _bc_prlist
prcons: 
;;; (19)
        LIT '('
        DO _putc
prlist: 
        DO _dupcar
        DO _print
        DO _cdr
        IFNOT _atom, prlist
pratend:        
        ;; if cdr<>nil print atom; putc ')'
        IF_NIL_GOTO prend
        ;; . atom
        LIT '.'
        DO _putc
prend:
        LIT ')'
        DO _putc
        DO _semis

ATOM "read", _read, "_print_"
;;; (+ 4 18 8 21) = 51
FUNC _bc_read
bc_read:        
;;; (4)
;        DO _getatomchar
        JZ bc_readlist
createatom:     
;;; (18)
        LIT here

        ;; set car
        LIT _nil_
        ;; TODO: how to say use here?
        ;; to ptr1?
        DO _comma
        DO _drop2

        ;; set cdr: next atom link
        ADDRESS _T_
        DO _cdr
        DO _comma

        ;; link this one in
        DO _dup
        ADDRESS _T_
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

;;; need mapped as we recruse!
;;; (alt: DO _exec (not have!))
FUNC _bc_readlist
bc_readlist:
;;; (21)


;;; TODO:  we're FULL !!!

        IFNOTEQ ')', readlist2

rdlend:  
        LIT _nil_
        DO _semis


readlist2:
        LIT '('
        IF _eq
;;; TODO:too big bytecodes?
;       ELSE rderr
rdlstart:
        DO _read
        DO _readlist
;;; tail call?
        DO _cons
        DO _semis

rderr:  
        LIT _nil_
        DO _semis
        

getatomc:       
;        DO _peekc
;;; TODO: 

;;;  ......






ATOM "quote", _quote, "_read_"
        ;; TODO: needs to have access to itself
_quote: 
;;; TODO:

ATOM "T", .ident("_T_"), "_quote_"

;;;                  M A I N
;;; ========================================

.include "end.asm"

.end

;;; Just the names and no impl: 85 bytes!
;;; 10 entries, 35 chars, 10 \0, 10x2 words
;;; and because names.len > 3 => 13 bytes align!
;;; (+ 35 10 40) = 85   + 13 ==> 98 .. + 2 rts dummys

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
;;;   semis JZ JP                (+ 0 14 3)      = 17
;;; TODO: jump                   (+ 12)     ???  = 12
;;;   emti key                   (+ 7 8)         = 11
;;; TODO: getatomchar peekc      (+ 15 10)       = 25
;;;  )
;;; 
;;; (+ 38 33 45 30 17 25 17 12 11 25) = 253
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


;;; 
