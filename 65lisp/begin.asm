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

ORGSTART= $054E

.ifdef ORGSTART

.feature org_per_seg
.org ORGSTART

.endif

orgaddr:    

.include "bios.asm"

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

        putc 'e'
        SETNUM endaddr
        DEBUGPRINT
        NEWLINE

        PUTC 'z'
        SUBTRACT _start
        DEBUGPRINT
        NEWLINE

        NEWLINE

        rts
.endproc

;;; ========================================
;;;             I N T E R L U D E

;;; pad to new page, put "BEFORE>" just before page start
.ifdef ORGSTART
  .res 256-(* .mod 256)-7
  .byte "BEFORE>"
.endif


;;;          DON'T put anything here



;;;             I N T E R L U D E
;;; ========================================
