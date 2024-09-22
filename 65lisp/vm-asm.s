;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.import	ldaxi, ldaxidx
.import staxspidx


.import tosadda0, tosaddax
.import tosmulax

.import asrax1
.import shraxy
.import shlaxy

.import pusha
.import pushax
.import pusha0sp

.import addysp

.import ptr1,ptr2,ptr3

.import _nil


.export _ldaxi, _ldaxidx

.export _staxspidx

.export _pushax
.export _pusha0sp
.export _pusha

.export _addysp

.export _tosaddax
.export _tosmulax

.export _asrax1
.export _shraxy
.export _shlaxy

.export _ffcar, _ffcdr

.export _retnil

;;; make names visible from C

_ldaxi		= ldaxi
_ldaxidx	= ldaxidx
_staxspidx      = staxspidx

_pushax         = pushax
_pusha0sp       = pusha0sp
_pusha          = pusha

_tosaddax       = tosaddax
_tosmulax       = tosmulax

_asrax1         = asrax1
_shraxy         = shraxy
_shlaxy         = shlaxy

_addysp         = addysp

;;; some routines in assembly, can't put inline in .c as optimized meddles...

_ffcar:  
  tay
  and #$01                      ; use bit?
  beq _retnil
  tya

_ffat: 
  jmp ldaxi

_retnil:
  lda _nil
  lda _nil+1
  rts

_ffcdr:
  tay
  and #$01                      ; use bit?
  beq _retnil
  tya

  ldy #$03
  jmp ldaxidx
