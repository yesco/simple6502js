;;; ========================================
;;;               P R E L U D E

;;; We set up a CONSTANT START origin that includes
;;; the C-loader program, bios.asm, and _showsize.

;;; Why? If it's not constant, we can't use * to
;;; do our page-align. For some reason, the
;;; code segment (on ORIC) starts at odd address.
;;; (%501? Where BASIC progeram starts)

;;; Uncomment this to determine start
;;; (If size of the loader PROGRAM.c changed)

;;; used for show_size
;;; 
;;; TODO: make conditional


;;; TODO: make this no do again if included again!

.ifndef tos
.zeropage
tos:    .res 2
ctos:   .res 1
tmp1:   .res 2
ctmp1:  .res 1
.endif
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

.macro DEBUGPRINT
        jsr debugprintn
;; TODO: doesn't seem to trigger on this sybmold
  .ifdef debugprintd
        PUTC '#'
        jsr debugprintd
  .endif
.endmacro

;;; ========================================-

;;; TODO: comment to find out changed ORGSTART
;;;    (reported as "o$05xx" in _showsize)
;ORGSTART= $054E

;;; parse.c with disasm.c
;ORGSTART= $09db

;ORGSTART= $0ce4

.ifdef ORGSTART

.feature org_per_seg
.org ORGSTART

.endif

orgaddr:    

.ifndef BIOSINCLUDED
  .include "bios.asm"
.endif

.ifndef NOSHOWSIZE

.export _showsize
.proc _showsize

        putc 'o'
        SETNUM orgaddr
        DEBUGPRINT
        NEWLINE

        putc 's'
        SETNUM _start
        DEBUGPRINT
        NEWLINE

        putc 'b'
        SETNUM bytecodes
        DEBUGPRINT
        NEWLINE

        putc 'e'
        SETNUM endaddr
        DEBUGPRINT
        NEWLINE

        SETNUM endaddr
        PUTC 'z'
        SUBTRACT _start
        DEBUGPRINT
        NEWLINE

        NEWLINE


        SETNUM endfirstpage
        PUTC 'v'
        SUBTRACT _start
        DEBUGPRINT
        NEWLINE

        SETNUM endaddr
        PUTC 'w'
        SUBTRACT bytecodes
        DEBUGPRINT
        NEWLINE

        SETNUM endaddr
        PUTC 'z'
        SUBTRACT _start
        DEBUGPRINT
        NEWLINE

        NEWLINE

        rts
.endproc
.endif ; NOSHOWSIZE

;;; ========================================
;;;             I N T E R L U D E

;;; pad to new page, put "BEFORE>" just before page start
.ifdef ORGSTART
  .res 256-(* .mod 256)-7
.endif
.byte "BEFORE>"
;;; The data between "BEFORE>" ... and "<AFTER"
;;; is the CORE PROJECT (not counting BIOS/INFO/PRINT/TEST)


;;;          DON'T put anything here



;;;             I N T E R L U D E
;;; ========================================

;;; this macro exports the _NAME func so that 
;;; its size can be determined, as well as labels
;;; the function. 
;;; 
;;; For 2-page dispatch it can also align
.if !.definedmacro(FUNC)
  .macro FUNC name

    .ifdef DOUBLEPAGE
  ;;; TODO: seems .code segment not aligned?
  ;    .align 2, _NOP_
       .res (* .mod 2), _NOP_
   .endif ; DOUBLEPAGE

    .export .ident(.string(name))
    .ident(.string(name)) :
  .endmacro
.endif
