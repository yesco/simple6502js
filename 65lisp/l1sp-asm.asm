;;; l1sp = Lisp 1 Stack Page
;;; 
;;; Yet another start, possibly using off-vm.asm
;;; which is a simple library of 19 stack primitives
;;; implemented in 134 bytes!

;;; ========================================
;;; Initial functions requirement for
;;; template/begin.asm


;TRACE=trace

;ENFORCE_ONEPAGE=1

;USETHESE=1
;DISABLEINTERRRUPTS

;;; UNC: ungetchar needed by skipspace, readatom
;;; +9 B (_key: +6 B, +3 init/BOOT, )
;UNC=1


;;; BOOT does init UNC etc
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

;;; ORIC BASIC INTERACTS...

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

        ;;  init 0:es
.ifdef UNC
        inx
        sta unc
.endif ; UNC
        
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

.ifdef USETHESE

  .include "l1sp-funs.asm"

.else

  .include "off-vm.asm"

.endif ; USETHESE


;;; ========================================
;;; enable this JUST to get 1st page SIZE
;.ifnblank

endfirstpage:   
secondpage:
bytecodes:      
_l1spinit:      
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

;;; TODO: change, we don't do jumps this way anymore?

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
;        .byte label-bytecodes
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
;; TODO: make this _instruction! (9B)
;;; 7x (+ (* 4 7) -7 +9) = 30 (loose 2 bytes)
.macro IFNOT test, label
        IF test
        ELSE label
.endmacro

.macro IF_NIL_GOTO label
        DO _djz
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

.ifdef READERS

;;; ------ compare asmlisp-asm.asm
;;;  (put asm reader) 76 bytes...
;;; 
;;; READ:               = 80++    434
;;;   getc     12  (+ 12 8 19 19 22) = 80
;;;   skipspc   8
;;;   readatom 17 xx 19
;;;   read     17 xx 19
;;;     findsym  ??    
;;;   readlist 22

;;; (+ 12 8 10) = 30 ; _getc _skipspc _atomchar
;;;  we haven't even started on reader
;;; 
;;; _read (bytecodes) createatom rdatom rdatomend rdlst
;;; (+ 4 7 14 21) = 46
;;; 
;;; TOTAL: (+ 30 46) = 76 ...

        
;;; skips spaces
;;; 
;;; Returns:
;;;   A= peek at next key
;;; 
;;; To consume the key call _key
;;;   OR set unc=0
FUNC _skipspc
;;; 8
        jsr _key
        cmp #' '+1
        bcc _skipspc
        sta unc
        rts

;;; _atomkey: reads an atom valid char
;;;    (any other character is "put back")
;;; 
;;; Returns:
;;;   C is set if is valid char
;;;   A: char in register A
;;; 
FUNC _atomkey
;;; 12
        jsr _key
        cmp #')'+1
        bcs ret
notvalid:       
        sta unc
        lda #0
ret:    
        rts

;;; readsatom: Reads an atom of valid chars.
;;; 
;;; Result:
;;;   String read is stored at memory here+4.
;;;   It may be empty. Y is length + 4.
;;; 
;;;   Y>4 means an atom skring was read
;;;   or if mem[here+4] is set.
;;; 
;;; After:
;;;   A=0 Z=1

FUNC _readatomstr
;;; 11 - 6/7 B as bytecode?
;;;             _atomkey _dup _ccomma _jz xx _semis
rdloop: 
        ;; This also zero terminates as last char returned
        ;; is zero
        jsr _atomkey
        pha
        jsr _ccomma             ; TODO!?
        pla
        bne _readatom
        rts

FUNC _readatomstr
;;; 14
        jsr _skipspc
        ldy #3
valid:  
        iny
        jsr _atomkey
        ;; automatically zero terminates!
        sta (here),y
        bne valid
        rts

_read:  
;        DO _readatomstr
        DO _dup
        JZ notatom
        DO _dup
;        DO _findatom
        JZ notfound
found:  
        DO _semis
notfound:       
        ;; create
;        ... (wrote before)
        
notatom:
;        ... readlist


.endif ; NEWREADERS




;;; ==================================================
;;; ------- simple experiment

;.ifnblank
FUNC _l1spinit
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

        LIT 'd'
        DO _dup
        DO _emit
bar:
        DO _zero
        DO _drop
        DO _zero
        DO _drop

        DO _key
        DO _emit
        DO _jp
        .byte $15




        LIT 12
        DO _emit

        LIT '.'

        LIT '?'

        LIT '_'
        DO _emit                ; ^

        DO _emit                ; ?

        DO _key
        DO _dup
        DO _emit                ; k
        DO _emit                ; k

        DO _emit                ; .

;        LIT 10
;        DO _emit

;;; jsk   _inc changes x???? hmmm

;        DO _inc
;        DO _inc
        DO _dup
        DO _emit                ; a

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
;;; (+ 12 15) = 27  _eval _apply but _nlambda ???

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
;;; TODO::
        DO _semis

FUNC _bc_isstrictfun
bc_isstrictfun: 
;;; TODO::
        DO _semis

FUNC _bc_evparams
bc_evparams:       
;;; TODO:
        DO _semis
.ifnblank

_eval:
;;; 36 B  [11? tokens] missing _apply!!!
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



ATOM "if", _if, "_if"
;;; 9
bc_if:  
        DO _decons              ; S: cdr car
        DO _eval
        DO _null
        JZ bc_then
bc_else:        
        ;; skip "then"
        DO _cdr
bc_then:
        DO _car
        DO _eval
        DO _semis


.ifnblank ; COND
ATOM "cond", _cond, "_eq"
;;; (+ 6 9 4 4) = 23 - too big

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
        IF _null                ; L res progn1 0/true
        ELSE haveprogn          ; L res progn1
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

.endif ; COND



;; ATOM "progn", _progn, "...
;;;  P= (a Q=...)
;;; 8
bc_prognext:       
        DO _nip
FUNC _bc_progn
        DO _decons
        DO _eval
        DO _swap
;;; This is what ?dup is for?
        IF_NOT_NIL_GOTO bc_prognext
bc_progend:
        DO _drop
        DO _semis



;;; ATOM "assoc"
;;; (de assoc (f l)
;;;   (if (null l) f
;;;      (if (eq f (caar l)) (car l)
;;;         (assoc f (cdr l)))))
;;; 16
FUNC _bc_assoc
        DJZ afail
        DO _decons
        DO _dupcar
        ;; get atom
        DO _pick3
        DO _eq
        JZ anotfound
afound:     
        ;; drop rest, atom
        DO _nip
        DO _nip
        DO _semis
anotfound:
        ;; drop pair, do rest
        DO _drop
        JP bc_assoc
afail:  
        ;; drop rest
        DO _drop
        ;; returns atom
        DO _semis


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
;;; (+ 4 19 8 14 21) = 66
FUNC _bc_read
bc_read:        
;;; (4)
        DO _skipspc
;;; TODO: rework
        DO _getatomchar
        DO _dup
        JZ bc_readlist
createatom:
;;; (18) + 1
        DO _align2
        ADDR here
        DO _dup
        DO _dup

        ;; set car
        ADDRESS _nil_
        DO _comma

        ;; set cdr: next atom link
        ADDRESS _T_
        DO _cdr
        DO _swap
        DO _comma

        ;; stack: address char
        DO _swap
rdatom: 
;;; (8)
        ;; store char
        DO _ccomma
        DO _getatomchar
        DO _dup
        JZ rdatom
rdatomend:
;;; (14)
        DO _findatom
        DO _dup
        DO _null
        JZ fndatom
rdnotfnd:       
        ;; create the atom
        DO _drop

        ;; link the new addr in
        DO _dup
        ADDRESS _T_
        DO _store
fndatom:
        ;; get rid of here addr
;;; TODO: undo here somehow...
        DO _nip

        DO _semis

;;; need mapped as we recruse!
;;; (alt: DO _exec (not have!))
FUNC _bc_readlist
bc_readlist:
;;; (21)
        ;; drop the zero
        DO _drop
        ;; we know it's not atomchar
        DO _getc
        IFNOTEQ ')', readlist2
rdlend:  
        LIT _nil_
        DO _semis

readlist2:
        IFNOTEQ '(', rderr

rdlstart:
        DO _read
        DO _readlist
        DO _cons
        DO _semis

rderr:  
        LIT _nil_
        DO _semis

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
;;; 
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
;;; exec/next/enter/semis        (+ 41)          = 41
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
