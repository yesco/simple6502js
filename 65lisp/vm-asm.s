;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.macpack        generic


.import return0

.import	ldaxi, ldaxidx, ldax0sp, ldaxysp, ldaxy
.import staxspidx

.importzp sp,tmp1

.import negax

.import tosaddax, tossubax, tosmulax, tosdivax
.import tosadda0, tossuba0, tosmula0, tosdiva0

.import mulax3, mulax5, mulax6, mulax7, mulax9, mulax10

.import decax1, decax2, decax3, decax4, decax5, decax6, decax7, decax8, decaxy
.import incax1, incax2, incax3, incax4, incax5, incax6, incax7, incax8, incaxy

;;.import asrax7, aslax7, shrax7, shlax7 ;; can't find!

.import asrax1, asrax2, asrax3, asrax4, asrax7, asraxy
.import aslax1, aslax2, aslax3, aslax4, aslax7, aslaxy

.import shrax1, shrax2, shrax3, shrax4, shrax7, shraxy
.import shlax1, shlax2, shlax3, shlax4, shlax7, shlaxy

.import toseq00, toseqa0, toseqax

.import callax

.import push0, push2, push4
.import pusha
.import pushax
.import pusha0sp
.import popax

.import incsp2, incsp4, incsp6, incsp8
.import addysp

.importzp ptr1,ptr2,ptr3

.import _nil, _T



.export _return0
.export _ldaxi, _ldaxidx, _ldax0sp, _ldaxysp

.export _staxspidx

.export _callax

.export _push0, _push2, _push4
.export _pusha
.export _pushax
.export _pusha0sp
.export _popax
.export _incsp2

.export _incsp2, _incsp4, _incsp6, _incsp8
.export _addysp

.export _negax
.export _tosaddax, _tossubax, _tosmulax, _tosdivax
.export _tosadda0, _tossuba0, _tosmula0, _tosdiva0

.export _decax1, _decax2, _decax3, _decax4, _decax5, _decax6, _decax7, _decax8, _decaxy
.export _incax1, _incax2, _incax3, _incax4, _incax5, _incax6, _incax7, _incax8, _incaxy

.export _toseq00, _toseqa0, _toseqax

.export _mulax3, _mulax5, _mulax6, _mulax7, _mulax9, _mulax10

;;.export asrax7, aslax7, shrax7, shlax7 ;; can't find!
.export _asrax1,_asrax2,_asrax3,_asrax4,_asraxy
.export _aslax1,_aslax2,_aslax3,_aslax4,_aslaxy

.export _shrax1,_shrax2,_shrax3,_shrax4,_shraxy
.export _shlax1,_shlax2,_shlax3,_shlax4,_shlaxy

.export _ffcar, _ffcdr
.export _fffcar, _fffcdr
.export _ffffcar, _ffffcdr
.export _ffnull, _ffisnum, _ffiscons, _ffisatom, _fftype
.export _istrue, _iscarry

;;.export _ffisheap ;; TODO: hmmm

.export _retnil, _rettrue

;;; make names visible from C

_return0        = return0

_ldaxi		= ldaxi
_ldaxidx	= ldaxidx
_ldax0sp        = ldax0sp
_ldaxysp        = ldaxysp

_staxspidx      = staxspidx

_callax          = callax

_push0          = push0
_push2          = push2
_push4          = push4
_pushax         = pushax
_pusha0sp       = pusha0sp
_pusha          = pusha
_popax          = popax

_incsp2         = incsp2
_incsp4         = incsp4
_incsp6         = incsp6
_incsp8         = incsp8

_negax          = negax

_tosaddax       = tosaddax
_tossubax       = tossubax
_tosmulax       = tosmulax
_tosdivax       = tosdivax

_tosadda0       = tosadda0
_tossuba0       = tossuba0
_tosmula0       = tosmula0
_tosdiva0       = tosdiva0


_mulax3   = mulax3 
_mulax5   = mulax5 
_mulax6   = mulax6 
_mulax7   = mulax7 
_mulax9   = mulax9 
_mulax10  = mulax10

_decax1 	= decax1
_decax2	        = decax2
_decax3	        = decax3
_decax4	        = decax4
_decax5	        = decax5
_decax6	        = decax6
_decax7	        = decax7
_decax8	        = decax8
_decaxy	        = decaxy

_incax1	        = incax1
_incax2	        = incax2
_incax3	        = incax3
_incax4	        = incax4
_incax5	        = incax5
_incax6	        = incax6
_incax7	        = incax7
_incax8	        = incax8
_incaxy	        = incaxy

_toseq00        = toseq00
_toseqa0        = toseqa0
_toseqax        = toseqax

_asrax1		= asrax1
_asrax2		= asrax2
_asrax3		= asrax3
_asrax4		= asrax4
;;_asrax7		= asrax7
_asraxy		= asraxy

_aslax1		= aslax1
_aslax2		= aslax2
_aslax3		= aslax3
_aslax4		= aslax4
;;_aslax7		= aslax7
_aslaxy		= aslaxy

_shrax1		= shrax1
_shrax2		= shrax2
_shrax3		= shrax3
_shrax4		= shrax4
;;_shrax7		= shrax7
_shraxy		= shraxy

_shlax1		= shlax1
_shlax2		= shlax2
_shlax3		= shlax3
_shlax4		= shlax4
;;_shlax7		= shlax7
_shlaxy		= shlaxy

_addysp         = addysp

;;; some routines in assembly, can't put inline in .c as optimized meddles...


_ffisnum:
        and #$01
  _istrue:
        bne _retnil

  _rettrue:
        lda _T
        ldx _T+1
        rts

_isfalse:
        beq _retnil
        jmp _rettrue

_ffiscons:
        and #$03
        cmp #$03
        beq _rettrue
        jmp _retnil
        
_ffisatom:
        and #$03
        cmp #$01
        beq _rettrue
        jmp _retnil
        

_ffnull:
        cmp #<_nil
        bne _retnil
        cpx #>_nil
        beq _rettrue

  _retnil:
        lda _nil
        ldx _nil+1
        rts


_iscarry:
        bcs _retnil
        jmp _rettrue


;;; faster car/cdr

;;; -b ffffcar: 6.792635
;;; -b ffcar:   6.862458
;;; -b 1:       1.986396
;;; (- 6.792635 1.986396) = 4.806239
;;; (- 6.862458 1.986396) = 4.876062
;;; (/ 4.877072 4.806239) = 1.014377 = 1.4% lol


;;; Need to store 01 at address 01, lol which is/will be NIL lo-byte==01!
;;; 4B 5c slightly better (?)
_fffffcar:      
        ;; very cheap isnum
        bit $01
        beq _retnil

        ;; consider inlining, 3c save
        jmp ldaxi

;;; TODO: 4B 6c is better!
_ffffcar:   
        ;; isnum
        lsr
        bcc _retnil
        rol

        jmp ldaxi

;;; TOOD: 5B 8c
_fffcar:   
        tay
        ror
        bcc _retnil
        tya

        jmp ldaxi

;;; 6B 8c
_ffcar:  
        tay
        and #$01
        beq _retnil
        tya

_ffat: 
        jmp ldaxi


;;; TOOD: 4B is better!
_ffffcdr:   
        ;; isnum
        lsr
        bcc _retnil
        rol

        ldy #$03
        jmp ldaxidx

;;; TOOD: 5B
_fffcdr:   
        tay
        ror
        bcc _retnil
        tya

        ldy #$03
        jmp ldaxidx


;;; TODO: use better
_ffcdr:
        tay
        and #$01
        beq _retnil
        tya

_ffcdrptr:
        ldy #$03
        jmp ldaxidx


;;; type 0 = null, K = cons, # = num, A = atom, num = heap type
_fftype:
        tay

        and #03
        cmp #03
        beq @cons

        and #01
        beq @num

@atom:  cpx #>_nil
        bne @atm
        tya
        cmp #<_nil
        beq @nil

@atm:   tya
        jsr _ffcdrptr
        jsr ldaxi
        ;; a smaller ldai
        ldy #00
        sta ptr1
        stx ptr1+1
        lda (ptr1),y
        bne @type

@tm:    lda #'A'
        bne @ret

@cons:  lda #'K'
        bne @ret

@num:   lda #'#'
        bne @ret

@nil:   lda #00
        
@type:

@ret:   ldx #00
        rts


;;; inspired by
;;; - http://forum.6502.org/viewtopic.php?f=2&t=6136
 
        ;; 16-bit number comparison...
        ;; TODO: this is unsigned int?
        ;;
        ;; Need 3 variants:
        ;; - ax  CMP const
        ;; - ax  CMP global var
        ;; - tos CMP ax
        ;; (others not worth it? local var, closure var)

        ;;    9 bytes:ish
        
        ;; ax CMP m
        ;; lo compare
_cmp:   pha
        cmp #>$1234           ;MSB of 2nd number
        ;; 
        bne @ret               ; not eq - done

        ;; hi eq - compare more
        pla
        cmp #<$1234           ;LSB of 2nd number
        ;; 
@ret:   rts


;;; how to use:

;;;     jsr _cmp

;;;     ;; pick one...

;;;     bcc @lt                 ; <
;;;     bcs @ge                 ; >=
;;;     bne @gt                 ; >
;;;     beq @eq                 ; ==

;;;     ;; for <=
;;;     bcs +2                  ; >=
;;;     beq @le                 ; = 

;;;     fall through to opposite of test


;;; For IF to jump to ELSE ! 
;;; (last byte will be patched to jump to ELSE)

;;;     ;; one of                      stacknotation
;;;     bcc @                   ; >=       <! I
;;;     bcs @                   ; <        <  I
;;;     bne @                   ; <=       >! I
;;;     beq @                   ; !=       =! I

;;;     ;; for >
;;;     bcs +2                  ; <
;;;     beq @le                 ; !=       >  I 

.import _print, _prin1



;;; ---- CLOSUREDATA:

;;; user code, calling closure

usercode:
        jsr closure
        ;; ...

closure:
        ;;  yes we call data to install itself as new self while saving old
        jsr pusholdself         ; save prev self on stack to be restored ( U - U O )
        jsr data                ; install new self ( - )
        ;;  stack is now (- U O)

main:   ;; ... generated code for function closure
        rts                     ; calls install old self! the that will return to usercode!

;;; This is the actual data object, starts with code
        ;; closure enter: (U O C - U O C) sideeffect: stores itself in self

self=0000

;;; DATA OBJECT:
;;; 
;;; a data object is basically an array defined as follows:
;;; 
;;; (de [xy x y] self)
;;; 
;;; (de (xy'len) (sqrt (sqr .x) (sqr .y)))
;;; 
;;; Usage: (setq coord [xy 3 4])
;;;        (xy.x coord) == (aref 1 coord) == (aref 'x coord) == (coord 'x) ==  (.x coord)
;;;        (xy'len coord) == ((coord 'len)) == ((.len coord))
;;;        (prinf "Length of coordinate %O is %d\n" coord (xy'len coord))


;;; LAYOUT OF OBJECT
;;; DATA:  JMP ODATA
;;;        typenum nargs
;;;        display...name 00
;;; 
;;; ODATA: JSR NEWSELF      - first byte 0x20 means "closure env"
;;;        JMP DATA
;;; 
;;; ODATA+2+3: DESC         - pointer to array of [TYPENAME FARG1 FARG2 ... FARGN]
;;; +7         NSIZE        - allow for growth
;;; +9       [ NFIXED       - current fixed by DESC ie. N of FARGN plus 1?
;;; +11        NUSED        - current used
;;; +13        S0 S1 ...    - TODO: JS S0 needs to be __PROTO__ ?
;;;            SNFIXED ...  - fixed correspond to FARG by position
;;;            KEY VAL ...  - overflow values, OR... just keep an ASSOC-list with pointer... lol
;;;            ...          - NIL/0 filling till NSIZE
;;;          ]

data:
        jsr newself             ; trick to get current address, store in self, return to caller of data
        ;; this is the addres stored (-1) so when main code returns, it comes here! reinstalls old returns
        jmp data                ; lol, so when reinstalling we come here
        ;; doesn't come here

        ;; stack on entry:       we want before RTS       (U C N - U O C) (1 2 3 - 1 o 2)
        ;; 105  usercaller            usercaller               
        ;; 103  closure               olddata
        ;; 101  newdata               closure

pusholdself:                   ; 46c
        tay

        ;; save caller
        pla
        sta tmp1+1
        pla
        sta tmp1

        ;; push self
        lda self+1
        pha
        lda self
        pha
        
        ;; restore caller
        lda tmp1+1
        pha
        lda tmp1
        pha

        tya
        rts
        

        ;; ( U C D - U C )
newself:                        ; 18c
        ;; todo, low byte pulled first? what order it gets pushed?
        pla
        sta self
        pla
        sta self+1

        rts                     ; returns to caller of data!





.export _asmfib

;;; 16 bit optimal uint fib - 41B in 29.16s

_asmfib:
        ;; if (ax <= 1)
        tay
        cmp #2
        txa
        sbc #0
        tya
        bcs @gt                 ; 8B 11c

        ;; return n
        rts

@gt:
        jsr pushax

        ;; return fib(n-1) + fib(n-2)
        jsr decax1
        jsr _asmfib

        jsr pushax

        ldy #3
        jsr ldaxysp

        jsr decax2
        jsr _asmfib

        jsr tosaddax

        jmp incsp2


.export _asmfibpha

;;; 16 bit optimal uint fib - 41B in 29.16s

;;; TODO: not correct! lol
;;; toadd... hmmm

_asmfibpha:
        ;; if (ax <= 1)
;;; jsr "cmpyax" 9B -> 7B
        tay
        cmp #2
        txa
        sbc #0
        tya
        bcs @gt                 ; 8B 11c

        ;; return n
        rts

@gt:
        ;; push ax, keep ax - 5B
        tay
        txa
        pha
        tya
        pha

        ;; return fib(n-1) + fib(n-2)
        jsr decax1
        jsr _asmfibpha

        ;; save result - push ax, no need keep ax (still is!) - 5B !
        tay
        txa
        pha
        tya
        pha

        ;; load "a" - 10B
;;; jsr "STKloadaxidx" 
        tsx
        lda $103,x              ; lo
        tay
        lda $104,x
        tax
        tya

        jsr decax2
        jsr _asmfibpha

        ; jsr tosaddax
;;;  jsr "STKaddax" 15B -> 3B 
        stx tmp1

        tsx
        clc
        adc $101,x
        tay

        lda tmp1
        adc $102,x
        tax

        tya

        ;; drop tmp, "a"
        tay
;;; make jump table, at each pos -> 1+3 B
          pla
          pla

          pla
          pla
        tya

        rts


.export _byteasmfib

_byteasmfib:
        ;; if (ax <= 1)
;;; jsr "cmpyax" 9B -> 7B
        cmp #2
        bcs @gt                 ; 8B 11c

        ;; return n
        rts

@gt:
        ;; push a keep a
        pha

        ;; return fib(n-1) + fib(n-2)
        sec
        sbc #1

        jsr _byteasmfib

        ;; save result - push ax, no need keep ax (still is!) - 5B !
        pha

        ;; load "a" - 10B
;;; jsr "STKloadaxidx" 
        tsx
        lda $102,x

;;;     jsr decax2
        sec
        sbc #2

        jsr _byteasmfib

        ; jsr tosaddax
;;;  jsr "STKaddax" 15B -> 3B 
        tsx
        clc
        adc $101,x

        ;; drop tmp, "a"
        tay
;;; make jump table, at each pos -> 1+3 B
          pla
          pla
        tya

        rts
;;; 32 B




;;; 16 bit optimal uint fib - 41B in 29.16s

;;; TODO: not correct! lol
;;; toadd... hmmm


;;; about 114 B - 21.45s !!!!!

.export _fibinline

;;; 16 bit optimal uint fib - 41B in 29.16s

_fibinline:
        ;; if (ax <= 1)
        tay
        cmp #2
        txa
        sbc #0
        tya
        bcs @gt                 ; 8B 11c

        ;; return n
        rts

@gt:
        ;; jsr pushax  (/ 29.18 27.88) 4.7%
        pha        
        lda     sp 
        sec        
        sbc     #2 
        sta     sp 
        bcs     @L1
        dec     sp+1    
@L1:    ldy     #1      
        txa             
        sta     (sp),y  
        pla             
        dey             
        sta     (sp),y  

        ;; return fib(n-1) + fib(n-2)

        ;; jsr decax1 - 24.3s
        sub     #1
        bcs     @Ldecax1
        dex
@Ldecax1:
        jsr _fibinline

        ;; jsr pushax 26.7s
        pha        
        lda     sp 
        sec        
        sbc     #2 
        sta     sp 
        bcs     @L2
        dec     sp+1    
@L2:    ldy     #1      
        txa             
        sta     (sp),y  
        pla             
        dey             
        sta     (sp),y  

        ;;ldy #3         
        ;;jsr ldaxysp - 21.75

        ldy     #3
        lda     (sp),y          ; get high byte
        tax                     ; and save it
        dey                     ; point to lo byte
        lda     (sp),y          ; load low byte



        ;; jsr decax2             
        sub     #2
        bcs     @Ldecax2
        dex
@Ldecax2:


        jsr _fibinline


        ;; jsr tosaddax -- 22.94s
        ldy     #0       
        adc     (sp),y   
        iny              
        sta     tmp1     
        txa              
        adc     (sp),y   
        tax              
        clc              
        lda     sp       
        adc     #2       
        sta     sp       
        bcc     Ladd
        inc     sp+1     
Ladd:   lda     tmp1     


        ;;jmp incsp2 - 21.45sg

        inc     sp   
        beq     @Lsp1  
        inc     sp   
        beq     @Lsp2 
        rts

@Lsp1:  inc     sp         
@Lsp2:  inc     sp+1       
        rts
