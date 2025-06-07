.import incsp2, incsp4, incsp6, incsp8
.import addysp

.export _nil
.export _initlisp, _initscr
.export _scrmova
.export _printz, _printzptr

.export _test, _hello, _helloN

;; TODO: not working in ca65, too old?

;.feature string_escape

.zeropage

curscr: .res 2
leftx:  .res 1
lefty:  .res 1
        ;;  TODO: do something clever to remove this?
newlineadjust:  .res 1          ; or use tmp1?

;;; used as (non-modifiable) arguments

ptr:    .res 2


;;; various special data items, constants
;;; - ATOMS
.align 2
.res 1

;;; _nil atom at address 5 (4+1 == atom)
;;; TODO: create segment to reserve memory?

_nil:   .res 4

;;; ----------------------------------------



.code

;;; various special data items, constants
;;; - ATOMS
.align 2
.res 1

_t:     .word _t, _nil, _eval
        .byte "T", 0

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
;;; #10=\n - newline (wraps around to top, too)
;;;           (TODO: should newline clear end of line?)
;;; TODO: \m - move to first col
;;; TODO: #12 = CTRL-L clear screen
;;; TODO: #30 = "home"ax
;;; TODO: skip attributes on screen? (unless wrap?)
;;; TODO: hibit (&7f<32 print as attribute, otherwise inverse)

;;; Note: AX is trashed (it's stored in ptr!)

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

_hello:	   .byte "4 Hello AsmLisp!",10,0
_helloN:   .byte "5 Hello AsmLisp!",10,0


.proc _initlisp

        jsr _initscr
        
        ;; store _nil as car and cdr of _nil
        lda #<_nil
        sta _nil
        sta _nil+2

        lda #>_nil
        sta _nil +1
        sta _nil+2 +1

        ; TODO: store address of "evalsecond"
        ; (nil (+ 3 4) (+ 4 5)) => 9 !


        ;; TODO: move to main?
        jsr _test

        rts
.endproc

;;; eval(env, x) -> val
;;;   NUM => NUM
;;;   ATOM => assoc(env, x)
;;;      result => return it
;;;    else
;;;      global value lookup (= car)

.proc _eval
        ;; NIL => NIL
        cmp #<_nil
        bne testnum
        cmp #>_nil
        beq ret

testnum:        
        ;; TODO: if _nil==$01 then can test!
        lsr
        bcs notnum
        ;; NUMBER
        rol

ret:    jmp incsp2

notnum: 
        ror
        bcs iscons

        ;; ATOM => lookup var in env/global
        ; jmp _getval

iscons:
        ;; CONS => APPLY!
        ; jsr pushax (dup x)

        ;; get global val
        ; jsr _car
again:  
        ;; TODO: test is atom/function/closure
        ;; TODO: if not then
        ;;         jsr AX=eval(env, AX)
        ;;         jmp again

        ;; AX contains ptr to "atom/func"
        ;;    w JSR addr

;;; now, basically eval falls through to
;;;   apply(env, x, AX)

apply:  
        clc
        ;; skip over cdr; point to addr
        adc #04
        bcc go
        inx

go:     
        ;; Note: args are not evaluated

        ;; AX(env,args)
        ; jmp callax              

.endproc


;;; 123 bytes
.proc _test

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
        lda #<_hello
        ldx #>_hello
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
        lda #<_helloN
        ldx #>_helloN
        jsr _printz
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        jsr _printzptr
        
        lda #<_helloN
        ldx #>_helloN
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

