;;; ORIC ATMOS Specific addresses as (potentially)
;;; used by MeteoriC-compiler

;;; TODO: give name/move all jsr addresses to here
;;;       with names, for easier re-mapping.



;;; ORIC ADDRESSES
;;; TODO: don't assume oric, lol
SCREEN		= $bb80
SCREENSIZE	= 40*28+0
SCREENEND	= SCREEN+SCREENSIZE
ROWADDR		= $12
CURROW		= $268
CURCOL		= $269
CURCALC		= $001f      ; ? how to update?


;;; TODO: why are these so late?
;;;   used much earlier!

BLACK    =128+0
RED      =128+1
GREEN    =128+2
YELLOW   =128+3
BLUE     =128+4
MAGNENTA =128+5
CYAN     =128+6
WHITE    =128+7
BG       =16                    ; BG+WHITE
NORMAL   =128+8
DOUBLE   =128+10





;;; ORIC ATMOS
;;; 
;;; #228 ( 4244) is the address of the ‘fast’ interrupt
;;; jump. By altering the jump address at #229,A
;;; 
;;; (#245,6) you can provide your own interrupt handler.
;;; 
;;; #230 ( #24A) is the address of the ‘slow’ interrupt
;;; routine. Control is passed to here at the end
;;; of the fast interrupt routine. Although 3 bytes are
;;; eserved here, there is only the single-byte
;;; instruction RTI present normally.
;;; 
;;; #228(4247) contains the jump vector for the NMI
;;; (Non-Maskable Interrupt) routine, which on
;;; the Oric connects to the ‘Reset button’.

;;; TODO: replace NMI with _edit, lol!
;;; TODO: 
;;; 
;;; $0244: jmp ?
;;; points to $ee22 (ROM interrupt handler)
;ORICINTVEC=$0245
;;; doesn't matter?
;INTCOUNT=10000                  ; 100x/s
INTCOUNT=50000                  ; 100x/s

;INTERRUPT=1

TIMER_START	= $ffff
SETTIMER        = $0306
READTIMER	= $0304
CSTIMER         = $0276
