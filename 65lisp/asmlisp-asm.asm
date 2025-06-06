.export _initlisp, _initscr
.export _scrmova
.export _printz, _printzptr

;; TODO: not working in ca65, too old?

;.feature string_escape

.zeropage

curscr: .res 2
leftx:  .res 1
lefty:  .res 1
newlineadjust:  .res 1

ptr:    .res 2



.code

;;; =========================================================
;;; Implements a "mini-terminal" printing strings

;;; _initscr, with leftx and lefty, keeping leftx in X
;;; doesn't modify register Y
.proc _initscr
        lda #$80
        sta curscr
        lda #$BB
        sta curscr+1

        ;; important X must contain leftx when exit
        ldx #40
        stx leftx

        lda #28
        sta lefty

        rts
.endproc

;;; printz: Prints an ASCIIZ zero terminated string
;;; identified by address in AX.
;;; 
;;; optimized to print strings upto 256 chars
;;; (putchar might call this one with wrapper, lol)
;;; 
;;; wraps around at end of screen
;;; keeps leftx, lefty updated, at end updates curscr
;;; 
;;; special characters recognized:
;;; \n - newline (wraps around to top, too)

;;; Note: AX is trashed

_printz:      
        sta ptr
        stx ptr+1

;;; printzptr: Prints an ASCIIZ zero terminated string
;;; identified by address in ptr

;;; Note: can be used to print the last string printed!

;; init screen state

_printzptr:        
        ldy #00
        sty newlineadjust
        ldx leftx

@next:   
        lda (ptr),y
        beq @end
        cmp #10
        beq @newline
        sta (curscr),y
        iny
        dex
        bne @next

        ;; line overflow
        ;; (this is cheap, only run every 40 chars)
@nextline:
        ldx #40
        dec lefty
        bne @next
        ;; rows overflow - wrap! (TODO: or scroll?)
        jsr _initscr

        ;; adjust address to make Y work
        ;; (todo: redo with reverse subtraction curscr -= Y)
        lda curscr
        sec
        sbc newlineadjust
        sta curscr
        lda curscr+1
        sbc #0
        sta curscr+1

        jmp @next
        
;;; handle special chars
@newline:
        sty newlineadjust
        iny

        ;; skip rest of line
        txa
        jsr _scrmova
        jmp @nextline


@end:    
        stx leftx

        ;; TODO: not correct at overflow...
        ;; neither newline char, lol!
        ;; could advance ptr, but then no reuse
        ;; advance str pointer
        dey                     
        tya

_scrmova:
        clc
        adc curscr
        sta curscr
        lda curscr+1
        adc #00
        sta curscr+1

        rts



;hello:  .asciiz "2 Hello AsmLisp!",10,""

hello:   .byte "3 Hello AsmLisp!",10,0
helloN:   .byte "4 Hello AsmLisp!",10,0


.proc _initlisp
        jsr _initscr

        ;; an A was written by c-code

        ;; write a B directly
        lda #66
        sta $BB81

	;; move 2 char forward to keep AB on screen
        dec leftx
        dec leftx
        lda #02
        jsr _scrmova

        ;; write string x 17
        lda #<hello
        ldx #>hello
        jsr _printz
        jsr _printzptr
        jsr _printzptr

        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr

        ;; 13 x helloN
        lda #<helloN
        ldx #>helloN
        jsr _printz
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        
        lda #<helloN
        ldx #>helloN
        jsr _printz
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr

        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr

        ;; write a C indirectly at current pos
        lda #67
        ldy #00
        sta (curscr),y

        rts
.endproc

        
