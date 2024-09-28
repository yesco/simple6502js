;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.import	ldaxi, ldaxidx, ldax0sp, ldaxysp, ldaxy
.import staxspidx

.importzp sp

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

.import pusha
.import pushax
.import pusha0sp
.import popax

.import incsp2, incsp4, incsp6, incsp8
.import addysp

.importzp ptr1,ptr2,ptr3

.import _nil, _T



.export _ldaxi, _ldaxidx, _ldax0sp, _ldaxysp

.export _staxspidx

.export _pushax
.export _pusha0sp
.export _pusha
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
.export _ffnull, _ffisnum, _ffiscons, _ffisatom, _fftype
;;.export _ffisheap ;; TODO: hmmm

.export _retnil, _rettrue

;;; make names visible from C

_ldaxi		= ldaxi
_ldaxidx	= ldaxidx
_ldax0sp        = ldax0sp
_ldaxysp        = ldaxysp

_staxspidx      = staxspidx

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
        bne _retnil

_rettrue:
        lda _T
        ldx _T+1
        rts


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
        bne _retnil
        jmp _rettrue

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


        

        tya


_ffcar:  
        tay
        and #$01
        beq _retnil
        tya

_ffat: 
        jmp ldaxi

_retnil:
        lda _nil
        ldx _nil+1
        rts



_ffcdr:
        tay
        and #$01
        beq _retnil
        tya

_ffcdrptr:
        ldy #$03
        jmp ldaxidx

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

.import _print

.export _asmfib

;;; 16 bit optimal uint fib

_asmfib:
        ;; if (ax <= 1)
        tay
        cmp #2
        txa
        sbc #0
        bcs @gt                 ; 8B 11c

        tya
        ;; return n
        rts

@gt:
        tya

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
