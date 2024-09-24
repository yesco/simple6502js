;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.import	ldaxi, ldaxidx, ldax0sp, ldaxysp
.import staxspidx

.importzp sp

.import tosadda0, tosaddax
.import tossubax    	; , tossuba0
.import tosmulax, tosdivax
.import toseq00, toseqa0, toseqax

.import asrax1
.import aslax1
.import shraxy
.import shlaxy

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

.export _tosaddax
.export _tossubax	; , _tossuba0 
.export _tosmulax, _tosdivax
.export _toseq00, _toseqa0, _toseqax

.export _asrax1
.export _aslax1
.export _shraxy
.export _shlaxy

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

_tosaddax       = tosaddax
; _tossub0a       = tossuba0
_tossubax       = tossubax
_tosmulax       = tosmulax
_tosdivax       = tosdivax

_toseq00        = toseq00
_toseqa0        = toseqa0
_toseqax        = toseqax

_asrax1         = asrax1
_aslax1         = aslax1
_shraxy         = shraxy
_shlaxy         = shlaxy

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




