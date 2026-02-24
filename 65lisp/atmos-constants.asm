;;; ORIC ATMOS Specific addresses as (potentially)
;;; used by MeteoriC-compiler

;;; TODO: give name/move all jsr addresses to here
;;;       with names, for easier re-mapping.


;;; TODO: move to atmos constants file?
HICHARSET  = $9800
HIRES      = $a000
;SCREEN     = $bb80
SC=$bb80
CHARSET    = $b400

PAPER      = $026b
INK        = $026c

;;; ORIC ADDRESSES
;;; TODO: don't assume oric, lol
SCREEN		= $bb80
SCREENSIZE	= 40*28+0
SCREENEND	= SCREEN+SCREENSIZE
ROWADDR		= $12
CURROW		= $268
CURCOL		= $269
CURCALC		= $001f      ; ? how to update?

;;; NMI place to patch
;NMIVEC=$FFFA                    ; => $0247
NMIVEC=$0248                    ; => $F8B2

;;; BRK handler pointer (normal int)

;;; ORIC_ATMOS (BRK and interrupt)
INTVEC=$0245 ; ?


;;; ORIC ATMOS
;;; - github:cc65/asminc/atmos.inc

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


;;; ZERO PAGE

SCRPTR          = $12
BASIC_BUF       = $35
CHARGOT         = $E8
TXTPTR          = $E9

;;; address used to choose ping/explode etc ORIC?
QUIET           = $31


;;; Girl on page 2? LOL

MODEKEY         = $0209
CAPSLOCK        = $020C        ; $7F = not locked, $FF = locked
PATTERN         = $0213
IRQVec          = $0245        ; "fast" interrupt vector
JOINFLAG        = $025A        ; 0 = don't joiu, $4A = join BASIC programs
VERIFYFLAG      = $025B        ; 0 = load, 1 = verify
CURS_Y          = $0268
CURS_X          = $0269
STATUS          = $026A
BACKGRND        = $026B
FOREGRND        = $026C
TIMER3          = $0276
CFILE_NAME      = $027F
CFOUND_NAME     = $0293
FILESTART       = $02A9
FILEEND         = $02AB
AUTORUN         = $02AD        ; $00 = only load, $C7 = autorun
LANGFLAG        = $02AE        ; $00 = BASIC, $80 = machine code
LOADERR         = $02B1
KEYBUF          = $02DF
PARMERR         = $02E0
PARAM1          = $02E1        ; & $02E2
PARAM2          = $02E3        ; & $02E4
PARAM3          = $02E5        ; & $02E6
BANGVEC         = $02F5


; ROM entries

GETLINE         = $C592
TEXT            = $EC21
rHIRES          = $EC33
CURSET          = $F0C8
CURMOV          = $F0FD
DRAW            = $F110
CHAR            = $F12D
POINT           = $F1C8
rPAPER          = $F204
rINK            = $F210
PRINT           = $F77C

; Sound Effects (is PING1 for ORIC-1?)
PING            = $FA9F
PING1           = $FA85
SHOOT           = $FAB5
SHOOT1          = $FA9B
EXPLODE         = $FACB
EXPLODE1        = $FAB1
ZAP             = $FAE1
ZAP1            = $FAC7
TICK            = $FB14
TICK1           = $FAFA
TOCK            = $FB2A
TOCK1           = $FB10
