;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.import	ldaxi, ldaxidx

.import tosadda0, tosaddax
.import tosmulax

.import pushax

.import ptr1,ptr2,ptr3

.import _nil


.export _ldaxi, _ldaxidx

.export _pushax

.export _tosaddax
.export _tosmulax


.export _ffcar, _ffcdr

.export _retnil

;;; make names visible from C

_ldaxi		= ldaxi
_ldaxidx	= ldaxidx
_pushax         = pushax
_tosaddax       = tosaddax
_tosmulax       = tosmulax

;;; some routines in assembly, can't put inline in .c as optimized meddles...

_ffcar:  
  tay
  and #$01                      ; use bit?
  beq _retnil
  tya

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
