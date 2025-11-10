;;; edit.asm -
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
;;; A simple emacs style editor for ORIC ATMOS
;;; written in pure assembly.
;;; 
;;; NOTE: this need to be made into a generic
;;;       variant, vt100/ansi-style...

;;; IMPLEMENTATION DETAILS
;;; 
;;; This code knows it's native on ORIC ATMOS.
;;; It particularly uses the HIRES (grabbable)
;;; memory as edit buffer.
;;; 
;;; For each (!!) keystroke the WHOLE screen is
;;; _redraw:n. This may seem "wasteful" but there
;;; is no "background" operations to steal from.
;;; 
;;; However, the current editor implementation
;;; uses a contious implementation, each insert,
;;; delete, does memmoves on the size of the file
;;; potentially. The typicaly memory copy bandwidth
;;; of an 1MHz 6502 is about 62.5K/s So if the "file"
;;; edited is 7K we can only do (/ 62.5 7) 8 inserts
;;; per second. That's rather slow...
;;; 
;;; For comparsison, a normal typer does 3-4 cps,
;;; whereas more experienced maybe 10. Expert typist
;;; may reach 20cps. So...
;;; 
;;; The problem may be misssed keystrokes as currently
;;; keyboard is only read when waiting for key, if there
;;; is a keypress before I don't catch it as interrupts
;;; are off (try turn on?)
;;; 
;;; The bigger problem is that I stop the interrupts,
;;; as ATMOS ROM "corrupts" zero-page.
;;; 
;;; To revisit!
;;; 



;;; TODO: optimize for code-size.
;;; TODO: and... is gap-buffer smaller? (faster for sure!)

;;; This module is 
;;;    545 B / IDE: 2432 B
;;;    683 B - added ^A ^E (hmmm?), command stuff
;;;    769 B - ^P ^N ^I etc, but many jsr togglecursor 
;;;    723 B - ...  removed many jsr togglecursor!
;;;    669 B - saved 54 B only using BRANCH table :-(
;;; 
;;; Old editor ( edit-atmos-screen.asm )
;;;    529 B / IDE: 2428 B
;;; 



;;; TODO: move to atmos constants file?
HIRES      = $a000
HICHARSET  = $9800
;SCREEN     = $bb80
SC=$bb80
CHARSET    = $b400


;;; Currently, we have a fixed buffer for editing.
;;; EDITSTART points to first char of text.
;;; EDITNULL  is one byte before containing 0!
;;; (to facilitate backward processing)

;;; For ORIC ATMOS we're going to use part of the
;;; HIRES as an editing buffer. '-lol
EDITNULL= HICHARSET

;;; lol
;EDITNULL= input-1


EDITSTART= EDITNULL+1

;;; non inclusive
;;; TEXTSCREEN CHARSET start
EDITEND= CHARSET
;;; 
EDITSIZE= EDITEND-EDITSTART


WIDTH=40
;ROWS=20
ROWS=27

.zeropage
;;; A value of point EDITSTART <= x < EDITEND
editpos:        .res 2

;;; TODO: doesn't need to be zeropage?
editend:        .res 2

editcol:        .res 1

;;; TODO: just use a tmp in zp?
editrow:        .res 1


.code



;;; Edit the current buffer
;;; 
;;; Depending on "mode", you're either in
;;; edit mode (BPL) or command mode (BMI).
;;; 
;;; 
FUNC _edit
        ;; init if first time
        bit mode
        bvc :+
        ;; init + "load"
        jsr loadfirst
        ;; remove init bit
        lda mode
        eor #64
        sta mode

     ldx #0
     jsr _printu
:       

        jmp editstart

command:
        jsr _eosnormal

        ;; 'Q' to temporary turn on cursor!
        PRINTZ {10,">",'Q'-'@'}
        jsr getchar
        PUTC CTRL('Q')

        ;; ignore return
        cmp #13
        beq command

        cmp #'?'
        bne :+
@minihelp:
        PRINTZ {"?",10,"Command",10,YELLOW,"h)elp c)ompile r)un v)info ESC-edit ",10,YELLOW,"z)ource q)asm l)oad w)rite"}
        jmp command
:       

        ;; lowercase whatever to print!
        ora #64+32           
        jsr putchar

        ;; then convert any char to CTRL to run it!
        and #31

editing:
        jsr _editaction

editstart:
        bit mode
        bmi command

        ;; don't redraw if key waiting!'
        jsr KBHIT
        bmi :+
        ;; redraw
        jsr _redraw
:       
        jsr getchar
        jmp editing



;;; This is the local CTRL dispatch BRANCH table
;;; 
.macro BR label
        .byte label-patchbranch-2
        .assert label-patchbranch-2<128,error,"%% BR too far"
.endmacro
;;; BackRuB? BRanchBack!
.macro BRB label
        .byte $100+label-patchbranch-2
        .assert $100+label-patchbranch-2,error,"%% BR too far BACK"
.endmacro


ctrlbranch:     
;;; For test only
;BR lastctrl
        BR ctrlSPC
        
        ;; ^A-^E
       BRB ebeginning
        BR eback
        BR jcompile
        BR edel
       BRB eend

        ;; ^F-^J
        BR eforward
        BR jgarnish
        BR jhelp
       BRB eindent
;        BR jins
        BR jreturn

        ;; ^K-^O
        BR jkill
        BR jload
        BR jreturn
       BRB enext
        BR ctrlO

        ;; ^P-^T
       BRB eprev
        BR jdasm
        BR jrun
        BR ctrlS
        BR jcaps

        ;; ^U-^Y
        BR ctrlU
        BR jinfo
        BR jwrite
        BR jextend
        BR eyank

        ;; ^Z ESC
        BR jzource
        BR jcmd

        ;; Arrows remapeed: 29--31!
        BR eback
        BR eforward
       BRB enext
       BRB eprev






;;; putting some routines BEFORE ediaction
;;; (to reach them)

enext:
        lda #10
        jsr etill

;;; TODO: very similar to etill!!!
egotocol:       
        ldx editcol
:       
        jsr eforward

        lda (editpos),y
        beq rts2
        cmp #10
        beq rts2

        ;; move forward more?
        dex
        bpl :-
rts2:       
        rts

eprev:  
        jsr eback
        lda #10
        jsr ebtill
        jsr eback
        lda #10
        jsr ebtill

        ;; similar to 
        jmp egotocol


eend:   
        lda #10
        jmp etill

ebeginning:     
        jsr eback
        lda #10
        jsr ebtill
        jmp eforward
        
eindent:
        jsr ebeginning
:       
        lda (editpos),y
        ;; damn cursor lol
        and #$7f
        beq rts2
        cmp #' '+1
        bcs rts2
        
        jsr eforward
        jmp :-
        

;;; each operation ends with rts
;;; (instead of jmp edit, saving 2 bytes)
FUNC _editaction

;;; 36 * 4 cmp/beq = 144 B
        ;; some may need it
        ldy #0

        ;; noctrl: special keys without cTRL
        cpx #sCTRL
        beq ctrl
@noctrl:
        ;; DEL key on ORIC (do perform BS)
        cmp #127
        beq ebs

        ;; TODO: META (>128 keys?)

        ;; Insert normal characters
        ;; 4 B but cam't catch ^M (is == RETURN)
        cmp #' '
        bcs jins

;;; fall-through: control codes

;;; Using dispatch table intead of cmp/beq (4 B)
;;; 
;;; (- 18790 18706) = 84 bytes saved (only?)
	;; --- CTRL DISPATCH
        ;; A= 0..31 !
ctrl:   
        tax
        lda ctrlbranch,x
        ;; self-modifying code
        sta patchbranch+1

        sec
patchbranch:
        bcs eprev               ; gets "self-modified"!

;;; --------------------- brnaches to here after

;;; jmp dispatch 9*3= 27 B
;;; (almost worth it to just do wide dispatch table!)
jcompile:       
        jmp ecompile
jrun:   
        jmp _run
jmystery:       
        jmp emystery
jkill:          
        jmp ekill
jzource:  
        jmp loadfirst
jcaps:  
        jmp putchar
jhelp:  
        jmp _help
jdasm:  
        jsr _dasm
        jmp forcecommandmode
jinfo:  
        .import _info
        jsr _info
        jmp getchar
jcmd:   
        jmp togglecommand
jextend:        
        jmp extend
jgarnish:       
        .import _prettyprint
        jsr nl
        lda #<EDITSTART
        ldx #>EDITSTART
        jsr _prettyprint
        jmp forcecommandmode


jreturn:        
        lda #10
        ;; fall-through
        ;; normal char - insert
jins:   
        jsr einsert
        ;; fall-through
eforward:       
        ;; TODO: at beginning of file - stop
        ;; todo: jsr _ince
        inc editpos
        bne :+
        inc editpos+1
:
;;; TODO: these are un-assigned, just return for now
ctrlSPC:                        ; TODO: mark?
ctrlO:                          ; TOOD: insert RET after
ctrlS:                          ; TODO: searcd
ctrlU:                          ; TODO: repeat
jload:                          ; TODO: load
jwrite:                         ; TODO: write
eyank:                          ; TODO: yank
        rts

eback:
	;; TODO: at end of file - stop
	;; todo: jsr _dece
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos
        rts
        

forcecommandmode:       
        ;; - turn on command mode unconditionally
        lda mode
        ora #128
        sta mode

        jmp _edit

togglecommand:
;;; 7
        lda mode
        eor #128
        sta mode

	;; actions
        ;; TODO: feels like lots of duplications?
;;; 11
        bpl @ed
        ;; re-sshow compilation result
        jsr _eosnormal
        jmp _aftercompile

@ed:
        jmp _redraw



ebs:    
        jsr eback
        ;; fall-through
;;; just a marker for the last (see BR lastctrl)
lastctrl:       

edel:    
        ;; delete one character at cursor
        ;; - to
        lda editpos
        ldx editpos+1
        sta tos
        stx tos+1

        ;; Y=0
@loop:   
        ;; - copy back
        iny
        lda (tos),y
        dey
        sta (tos),y
        tax
        beq @done
        ;; - INC tos
        inc tos
        bne :+
        inc tos+1
:       
        bne @loop
@done:
        ;; - DEC editend
        lda editend
        bne :+
        dec editend+1
:       
        dec editend
        rts

;;; ------------ END CTRL DISPATCH
        

;;; raw raw raw - relatively fast!
FUNC _redraw 
;;; (+ 24 55) = 79
;;; (16)
        ;; we need to set the cursor when drawing!
        jsr togglecursor

        lda #<EDITNULL
        ldx #>EDITNULL
        sta pos
        stx pos+1

        lda #<(SC+40)
        ldx #>(SC+40)
        sta tos
        stx tos+1
;;; (8)
        lda #ROWS
        sta editrow
        
        ldx #WIDTH
        ldy #0

@nextc:
;;; 
        inc pos
        bne :+
        inc pos+1
:       
        ;; copy byte
        lda (pos),y
        beq @clreol             ; clrEOS!
        sta (tos),y
        ;; at cursor, save COL
        bpl :+
        stx editcol
        ;; store editrow? currently used as loopvar
:
        ;; newline
        cmp #10
        beq @nl
        cmp #10+128             ; nl + cursor!
        beq @nl
@forw:
        dex
        bne :+
        ldx #WIDTH
:       
        inc tos
        bne :+
        inc tos+1
:       
        ;; always
        bne @nextc

        ;; we clear till end of line
@clreol:
        lda #' '
        sta (tos),y
@nl:
        inc tos
        bne :+
        inc tos+1
:       
        dex
        bne @clreol

        ;; no more rows
        dec editrow
        beq @done

        ldx #WIDTH

        lda (pos),y
        beq @clreol
        bne @nextc

@done:
        ;; reverse editcol
        lda #40
        sec
        sbc editcol
        sta editcol

        ;; clear the cursor bit, used for display

        ;; fall-throught to togglecursor!
togglecursor:
;;; 9
        ldy #0
        lda (editpos),y
        eor #$80
        sta (editpos),y
        rts



;;; move forwards (editpos) till A
;;; make use X for max moves
etill:  
;;; 15
        sta savea
@nextc:       
        lda (editpos),y
        beq eret
        cmp savea
        beq eret

        jsr eforward
        jmp @nextc
eret:   
        rts


;;; move backward (editpos) till A
ebtill:  
;;; 12
        sta savea
@nextc:       
        lda (editpos),y
        beq eret
        cmp savea
        beq eret

.ifnblank
        jmp eback
.else
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos
.endif
        jmp @nextc


;;; Insert A at current cursor position
einsert:
;;; (+ 1 10 7 14 9) = 41
        ;; - save key for later
        pha

        ;; require cursor to be on!
        ;; (use hibit to know when to stop copy)
        jsr togglecursor

        ;; To insert a character we need to push
        ;; overy thing up (unless we use gap-buffer)

        ;; - move back from end
;;; (10)
        lda editend
        sta tos
        lda editend+1
        sta tos+1

        ldy #0
        ;; TODO: revisit
        ;; double 0 byte makes this insert
        ;; not bleed into next input

        ;; TODO: alternatives to double 0?
; jsr _inct
        jmp @copyc
@nextc:
;;; (7)
        ;; dec tos
        lda tos
        bne :+
        dec tos+1
:       
        dec tos
@copyc:       
;;; (14)
        lda (tos),y
        pha
        iny
        and #$7f
        sta (tos),y
        dey
        pla
        ;; hibit == curpos! => exit!
;;; TODO: end/beginning \0 ?
;        beq @done
        bpl @nextc
        
@done:
;;; (9)
        pla
        sta (editpos),y
;        sta (tos),y

        ;; Hmmm, mustn't turn it off, huh?
;        jsr togglecursor      

        ;; inc editend
        inc editend
        bne :+
        inc editend+1
:       
        rts



;;; TODO: crashes...
emystery:       
        ;; CTRL-M .... ? Sectret Mystery Action?
        jsr _eosnormal

        putc 'S'
        jsr spc
        lda #<EDITSTART
        ldx #>EDITSTART
        jsr _printh
        jsr nl

        putc 'P'
        ldy #editpos
        jsr printvar

        putc 'E'
        ldy #editend
        jsr printvar

        putc 'e'
        jsr spc
        lda #<EDITEND
        ldx #>EDITEND
        jsr _printh
        jsr nl

        putc 'Z'
        jsr spc
        lda #<EDITSIZE
        ldx #>EDITSIZE
        jsr _printu
        jsr nl

        jsr nl

        putc 'c'
        jsr spc
        lda editcol
        ldx #0
        jsr _printu

        jmp getchar

ekill:  
;;; TODO: iplement kill line
        rts


loadfirst:
;;; (+ 20 11 12 3 14 3) = 63

;;; 20+11
;;; TODO: 20 bytes param set up
        ;; tos= from
        lda #<input
        ldx #>input
        sta tos
        stx tos+1
        ;; dos= to
        lda #<EDITSTART
        ldx #>EDITSTART
        sta dos
        stx dos+1
        ;; sta EDITSTART as editpos, too
        sta editpos
        stx editpos+1
        ;; 
        jsr copyz
        ;; zero terminate
        lda #0
        sta (dos),y
        iny
        sta (dos),y
        dey

        ;; calculate end

        ;; TODO: maybe copyz does this? 
        ;; or dos+a reoutine?
        ;; update edit end
;;; 12
        tya
        clc
        adc dos
        sta editend
        lda #0
        adc dos+1
        sta editend+1
;;; 3



.ifnblank

;.if ((EDITSTART .mod 256)==0)
;EDITALIGNED=1
.scope
.ifdef EDITALIGNED
;;; 6

        .assert ((EDITNULL .mod 256)=0),error,"%% EDITALIGNED"
        sty editend
        lda dos+1
        sta editend+1
.else
;;; 14
        clc
        tya
        adc dos
        bcc :+
        inc dos+1
:       

        sta editend
        ldx dos+1
        stx editend+1
.endif
.endscope
;;; 3

.endif ; BLANK

        jmp _redraw



ecompile:
        ;; We need to make sure no hibit (cursor)
        ;; is set in the code we compile, either
        ;; save a copy to compile in the background
        ;; or wait...

        jsr nl
        lda #(BLACK+BG)&127
        ldx #WHITE&127
        jsr _eoscolors
        PRINTZ {10,YELLOW,"compiling...",10,10}
        
        ;; set output
        lda #<_output
        ldx #>_output
        sta _out
        stx _out+1
        ;; set input = EDITSTART
        lda #<EDITSTART
        ldx #>EDITSTART
        ;; alright, all done?
        jmp _compileAX

