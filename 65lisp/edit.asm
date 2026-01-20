;;; edit.asm - ORIC EMACS EDITOR for MeteoriC
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org
;;; 
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

;;; 
;;; IMPLEMENTATION NOTICE
;;; 
;;; *ALL* e??? primives implementing editnig commands
;;; assumes Y=0, so don't modify it!
;;; 
;;; The dispatch is using a 1 byte relative dispatch
;;; giving an approximate range of (- 256 10) bytes range.
;;; 
;;; There is a large (10) routines essentially using a 
;;; trampoline jump to a ABSOLUTE address far away.
;;; 
;;; Using a 2 byte jmp table woudl only save 3 bytes...
;;; 
;;; (- (+ 32 10 (* 10 3)) (+ 64 11)) = -3
;;; 

;;; TODO: optimize for code-size.
;;; TODO: and... is gap-buffer smaller? (faster for sure!)

;;; This module is 
;;;    545 B / IDE: 2432 B
;;;    683 B - added ^A ^E (hmmm?), command stuff
;;;    769 B - ^P ^N ^I etc, but many jsr togglecursor 
;;;    723 B - ...  removed many jsr togglecursor!
;;;    669 B - saved 54 B only using BRANCH table :-(
;;;    828 B - really just contains lots of COMMAND action
;;;          - refactored, basically only keeping _editaction
;;;    493 B - moved out IDE stuff, and not direct editing

;;; Old editor+commands ( edit-atmos-screen.asm )
;;;    529 B / IDE: 2428 B
;;; 


;;; ========================================
;;;             C  O  N  F  I  G


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


.export __ZPEDITOR__
.export editpos,editend,editcol,editrow

.zeropage
__ZPEDITOR__:
;;; A value of point EDITSTART <= x < EDITEND
editpos:        .res 2

;;; TODO: doesn't need to be zeropage?
editend:        .res 2

editcol:        .res 1

;;; TODO: just use a tmp in zp?
editrow:        .res 1

.code



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


;;; CTRL:     @ABCDEFGHIJKLMNOPQRSTUVWXYZ ESC
;;; NOT USED  @         JK M O   S U W Y
;;; FREE      @           L  O   

;;; NOTICE: All these assume Y=0!

ctrlbranch:     
        BR eunused              ; CTRL-SPC
        
        ;; ^A-^E
       BRB ebeginning
        BR eback
        BR jcompile
        BR edel
       BRB eend

        ;; ^F-^J
        BR eforward
        BR jgarnish             ; LOL (pretty print)
        BR jhelp
       BRB eindent
        BR jreturn

        ;; ^K-^O
        BR eunused              ; jkill?
        BR jredraw              ; jredraw LOAD?
        BR jreturn
       BRB enext
        BR joutkey

        ;; ^P-^T
       BRB eprev
        BR jdasm                ; ^Q
        BR jrun
        BR eunused              ; ctrlS SEARCH!
        BR jcaps                ; toggle CAPS

        ;; ^U-^Y
        BR eunused              ; ctrlU REPEAT
        BR jinfo                ; ctrlView info
        BR eunused              ; jwrite? (emacs: wank? - kill region, lol)
        BR jextend              ; ctrlX
        BR eunused              ; ctrlY TODO: YANK!

        ;; ^Z ESC
        BR jzource              ; reload Zource
        BR jcmd                 ; ESC toggle cmd/edit mode

        ;; Arrows remapped! 29--31!
        BR eback
        BR eforward
       BRB enext
       BRB eprev





;;; move forwards (editpos) till A
;;; make use X for max moves
etill:  
;;; 17
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
;;; 17
        sta savea
@nextc:       
        lda (editpos),y
        beq eret
        cmp savea
        beq eret

        jsr eback
        bcs eret
        bcc @nextc




;;; putting some routines BEFORE ediaction
;;; (to reach them)

enext:
;;; 22
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

;;; "BUG:" at top line walks to end?
eprev:  
;;; 19
        jsr eback
        lda #10
        jsr ebtill
        jsr eback
        lda #10
        jsr ebtill

        ;; similar to 
        jmp egotocol


eend:   
;;; 5
        lda #10
        jmp etill

ebeginning:     
;;; 13
        jsr eback
        lda #10
        jsr ebtill
        bne rts2
        jmp eforward
        
eindent:
;;; 17
        jsr ebeginning
:       
        lda (editpos),y
        beq rts2
        cmp #' '+1
        bcs rts2
        
        jsr eforward
        jmp :-
        


;;; Editaction is the event-handler
;;; 
;;; It's jsr:ed into with a key in A
;;; (and residu from getchar in X on Atmos)
;;; 
;;; It then performs a dispatch based on the
;;; key-code to editor functions named like
;;; eXXXX or trampoline jumps jXXXX to 
;;; IDE functions. Each function does RTS
;;; to save code.
;;; 
;;; The locaiton of this function is in
;;; the middle of all the eFunctions as
;;; it does the dispatch with a BRANCH
;;; instruction that gets patched.
;;; 
;;; With almost all keys allocated, it's
;;; a break even to do jump table dispatch. LOL
;;; 
FUNC _editaction
        ;; most rourtines rely on Y=0
        ldy #0

        ;; noctrl: special keys without cTRL
        cpx #sCTRL
        beq ctrl
@noctrl:
        ;; DEL key on ORIC (do perform BS)
        cmp #127
        beq ebs

        ;; e)dit key in command mode, lol
        bit mode
        bpl :+
        cmp #CTRL('E')
        beq jedit
:       
        ;; TODO: META (>128 keys?)

        ;; Insert normal characters
        ;; 4 B but cam't catch ^M (is == RETURN)
        cmp #' '
        bcs jins

	;; fall-through: unhandled control codes

	;; --- CTRL DISPATCH
        ;; A= 0..31 !

	;; Using dispatch table intead of cmp/beq (4 B)
        ;; 
        ;; (- 18790 18706) = 84 bytes saved (only?)
        ;; 
        ;; 10 B relative BRANCH dispatch!
ctrl:   
        tax
        lda ctrlbranch,x
        ;; self-modifying code
        sta patchbranch+1
        txa

        ;; C=1 to bcs/branch relatively
        sec
patchbranch:
        bcs eprev               ; gets "self-modified"!

;;; --------------------- brnaches to here after

;;; jmp dispatch 9*3= 27 B
;;; (almost worth it to just do wide dispatch table!)
jcompile:       
        jmp _idecompile
jrun:   
        jmp _run
;jmystery:       
;        jmp _emystery
jkill:          
        jmp _ekill
jzource:  
        jsr _loadfirst
        ;; fall-through
jredraw:        
        jmp _redraw
jcaps:  
        jmp putchar
jhelp:  
        jmp _help
jdasm:  
        jsr _dasm
        jmp _forcecommandmode
jinfo:  
        .import _info
        jsr _info
        ;; TODO: depend on mode?
        jmp getchar
jedit:  
        jsr _goerrpos
jcmd:   
        jmp _togglecommand
joutkey:        
        jmp _outkey
jextend:        
        jmp _extend
jgarnish:       
;; 13
        .import _prettyprint
        jsr nl
        lda #<EDITSTART
        ldx #>EDITSTART
        jsr _prettyprint
        jmp _forcecommandmode


jreturn:        
        lda #10
        ;; fall-through
        ;; normal char - insert
jins:   
        jsr einsert
        ;; fall-through
;;; Moves editpos forward; Preserves X
eforward:       
;;; 11
        ;; make sure not "standing at the wall" \0
        lda (editpos),y
        beq ret3
;;; TODO: used in _redraw?
_incEP:                       
        inc editpos
        bne :+
        inc editpos+1
:       
        ;; Z!=0 (unless @editpos==0)
ret3:
        rts

;;; Moves editpos backward; Preserves X
eback:
;;; 15
	;; "_decEP" Not used anywhere else?
        lda editpos
        bne :+
        dec editpos+1
:       
        dec editpos
        ;; make sure didn't "hit the wall" \0
        lda (editpos),y
        sec
        beq _incEP
        clc
        ;; Returns C=1 if at boundary, C=0 otherwise!
eunused:        
        rts
        

ebs:    
        jsr eback
        ;; fall-through
edel:    
;;; 34
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
        

;EDITCOLORCOLS=1
EDITCOLOR=GREEN & 127


;;; raw raw raw - relatively fast!
FUNC _redraw 
;;; (+ 24 55) = 79
;;; (16)
        ;; we need to set the cursor when drawing!
        jsr togglecursor

        ;; Text pos
        lda #<EDITNULL
        ldx #>EDITNULL
        sta pos
        stx pos+1

        ;; Screen pos
        lda #<(SC+40)
        ldx #>(SC+40)
        sta tos
        stx tos+1
;;; (8)
        lda #ROWS
        sta editrow
        
        ldx #WIDTH
        ldy #0


.ifdef EDITCOLOR
        jmp @color
;        lda #EDITCOLOR
;        sta (pos),y
        ;; Always
;        bne @forw
.endif ; EDITCOLOR


@nextc:
;;; 
        inc pos
        bne :+
        inc pos+1
:
@nextln:        
        ;; copy byte

        lda (pos),y
        ;; end of text?
        beq @clreol             ; clrEOS!

; no goes bad?
;        cmp #128
;        beq @clreol             ; clrEOS!

@putc:
        ;; write to screen
        sta (tos),y
        ;; at cursor, save COL
        bpl :+
        stx editcol
        ;; store editrow? currently used as loopvar
:
        ;; remove "hibit" cursor indicator/inverse from text
        and #$7f
        sta (pos),y

        ;; newline => clear *rest* of line
        cmp #10
        ;; TODO: dots "clear" on EVERY SECOND??? line?
        beq @noclearlastchar
        ;; dots "clear" on every line
        ;        beq @clreol


@forw:
        dex
        bne :+
        ;; wrap text for this line
        ldx #WIDTH
;;; TODO: COLOR? no color/truncate?
        ;; no more screen rows?
        dec editrow
        beq @done

:       
        inc tos
        bne :+
        inc tos+1
:       
        ;; Always
        bne @nextc


        ;; we clear till end of line
@clreol:
;;; TOOD: BUG enable to detect every second line gets .....!
;        lda #'.'
        lda #' '
@colorln:
        sta (tos),y

@noclearlastchar:
        inc tos
        bne :+
        inc tos+1
:       
        dex
        bne @clreol

        ;; no more screen rows?
        dec editrow
        beq @done

        ;; prepare for next line
        ldx #WIDTH

        ;; if end of file, don't we don't advance
        ;; we just keep printing spaces!
        lda (pos),y
        beq @clreol

.ifdef EDITCOLOR
@color:
        lda #EDITCOLOR
        sta (tos),y
        ;; Always
;        bne @putc
        bne @forw
;        bne @nextc
.else
        ;; Always
        bne @nextc
.endif ; EDITCOLOR

@done:
        ;; reverse editcol
.ifdef EDITCOLOR
        lda #WIDTH-1
.else
        lda #WIDTH
.endif
        sec
        sbc editcol
        sta editcol

    rts

FUNC _editormisc

;;; TODO:O can remove? 
        ;; clear the cursor bit, used for display

        ;; fall-throught to togglecursor!
togglecursor:
;;; 9
        lda (editpos),y
        eor #$80
        sta (editpos),y
        rts


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



FUNC _ekill
;;; TODO: iplement kill line
        rts



;;; TODO: generalize to load specified file/buffer?

;;; Load the first buffer from input
FUNC _loadfirst
;;; (+ 15 25 12 6 3) = 61

;;; +15 B
        ;; clear edit area
        lda #<EDITNULL
        sta tos
        ldx #>EDITNULL
        stx tos+1

        lda #<EDITSIZE
        ldx #>EDITSIZE

        jsr _zero


;;; 25
;;; TODO: just to set up! (maybe a block copy?)
        ;; tos= from
        lda #<input
        ldx #>input
        sta tos
        stx tos+1
        ;; dos= destination
        lda #<EDITSTART
        ldx #>EDITSTART
        sta dos
        stx dos+1
        ;; sta EDITSTART as editpos, too
        sta editpos
        stx editpos+1
        ;; copy
        ldy #0
        jsr _copyz
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

        rts


FUNC _goerrpos       
        lda compilestatus
        beq :+
        ;; ?firsttime => erp not in editor buffer!
        ;; (cheat: just check same "page")
        lda originp+1
        cmp #>EDITSTART
        bne :+
        ;; ...move cursor to error
        lda erp
        ldx erp+1
        sta editpos
        stx editpos+1
:       
        rts



;;; For debugging
;MYSTERY=1
.ifdef MYSTERY
;;; TODO: crashes...
FUNC _emystery
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
        jsr _printvar

        putc 'E'
        ldy #editend
        jsr _printvar

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
.endif ; MYSTERY
