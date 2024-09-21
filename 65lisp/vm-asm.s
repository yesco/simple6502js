;; 6502 asm vm-code and symbols used in asm-code gen during execution/compilation
;;  -- https://stackoverflow.com/questions/71208847/how-to-access-assembly-language-symbols-without-a-leading-from-c-on-6502-cc65

.import	ldaxi, ldaxidx 

.import ptr1,ptr2,ptr3

.import _nil

.export _ldaxi, _ldaxidx
.export _ffcar, _ffcdr

;;; make names visible from C

_ldaxi		= ldaxi
_ldaxidx	= ldaxidx

;;; some routines in assembly, can't put inline in .c as optimized meddles...

_ffcar:  
  tay
  and #$01                      ; use bit?
  beq @nil
  tya

  jmp ldaxi

@nil:
  lda _nil
  lda _nil+1
  rts

_ffcdr:
  tay
  and #$01                      ; use bit?
  beq @nil
  tya

  lda #02
  jmp ldaxi

@nil:
  lda _nil
  lda _nil+1
  rts

  


foo:
 lda #$00
 jsr ldaxi
 jsr ldaxidx
 sta $0200
 rts
