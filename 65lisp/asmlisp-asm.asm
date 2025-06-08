.import incsp2, incsp4, incsp6, incsp8
.import addysp

.export _nil
.export _initlisp, _initscr
.export _scrmova
.export _printz, _printzptr

.export _test

;; TODO: not working in ca65, too old?

;.feature string_escape

.zeropage

curscr: .res 2
leftx:  .res 1
lefty:  .res 1
        ;;  TODO: do something clever to remove this?
newlineadjust:  .res 1          ; or use tmp1?

;;; used as (non-modifiable) arguments

ptr1:   .res 2
ptr2:   .res 2
ptr3:   .res 2

;;; be careful saving (as may trash other save!)
savea:  .res 1
savex:  .res 1
savey:  .res 1

;;; various special data items, constants
;;; - ATOMS
.align 4                        ; meaing: 4 or 2^4
.res 1

;;; _nil atom at address 5 (4+1 == atom)
;;; TODO: create segment to reserve memory?

_nil:   .res 6
        .byte "nil", 0

;;; ----------------------------------------



.code

;;; various special data items, constants
;;; - ATOMS
.align 2
.res 1

_T:     .word _T, _nil, _eval
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

.proc newline
        lda #10
        jmp _putchar
.endproc

.proc putspc
        lda #32
        pha
.endproc

plaputchar:    
        pla

;;; _putchar A on screen, move position forward
;;; trashes A,X,Y,ptr1,ptr2
.proc _putchar
        ;; save char in 2 byte asciiz buffer end with 0
        sta ptr2
        lda #0
        sta ptr2+1

        lda #<(ptr2)
        ldx #>(ptr2+1)
        ;; fallthrough to _printz
.endproc

;;; _printz: Prints an ASCIIZ zero terminated string
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

;;; Note: AX is trashed (it's stored in ptr1!)
_printz:      
        sta ptr1
        stx ptr1+1

;;; printzptr: Prints an ASCIIZ zero terminated string
;;; identified by address in ptr1

;;; Note: can be used to print the last string printed!

;; init screen state

_printzptr:        
        ldy #00
        sty newlineadjust
        ldx leftx

@next:   
        lda (ptr1),y
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
        iny
        sty newlineadjust

        ;; skip rest of line
        dex
        txa
        jsr _scrmova
        jmp @nextline


@end:    
        stx leftx

        ;; move forwade
        ;dey                     ; ???
        tya

_scrmova:
        clc
        adc curscr
        sta curscr
        lda curscr+1
        adc #00
        sta curscr+1

        rts



;;; print one hex digit from A lower 4 bits at position Y
;;; (doesn't trash X)
.proc _print1h
        and #15
        clc
        adc #48                 ; '0'
        cmp #58                 ; '9'+1
        bcc print
        ;; >'9' => 'A'-'F'
        adc #6                  ; 'A'-'9'+1-1 (carry set)
print:  
        sta (curscr),y
        iny
        rts
.endproc

;;; _printds print a decimal value from AX (retained, Y trashed)
.proc _printd
        ;; save ax
        sta savea
        stx savex

        jsr _voidprintd

        ;; restore ax
        ldx savex
        lda savea

        rts
.endproc

;;; _voidprintd print a decimal value from AX (+Y trashed)
;;; 35B - this is a very "minimal" sized routine
;;;       slow, one loop per bit/16
;;;       (+ 3B for store AX)
;;; 
;;; ~554c = (+ (* 26 16) (* 5 24) 6 6 6)
;;;       (not include time to print digits)
;;; 
;;; Based on DecPrint 6502 by Mike B 7/7/2017
;;; Optimized by J. Brooks & qkubma 7/8/2017
;;; This implementation by jsk@yesco.org 2025-06-08

.proc _voidprintd
        sta ptr1
        stx ptr1+1
        
_voidprintptr1d:

digit:  
        lda #0
        tay
        ldx #16

div10:  
        cmp #10/2
        bcc under10
        sbc #10/2
        iny
under10:        
        rol ptr1
        rol ptr1+1
        rol

        dex
        bne div10

        ;; make 0-9 to '0'-'9'
        clc
        adc #48

        ;; push delayed putchar
        ;; (this is clever hack to reverse digits!)
        pha
        lda #>(plaputchar-1)
        pha
        lda #<(plaputchar-1)
        pha

        dey
        bpl digit

        rts
.endproc
        

.proc _print2h
        pha
        lsr
        lsr
        lsr
        lsr
        jsr _print1h
        pla
        jsr _print1h
        rts
.endproc
        
;;; print hex from AX (retained) Y=5
.proc _printh
        pha

        ;; print '$'
        pha
        ldy #0
        lda #$24                ; '$'
        sta (curscr),y
        iny

        ;; print hi-byte
        txa
        jsr _print2h
        pla
        ;; print lo-byte
        jsr _print2h

        ;; move cursor forward Y (=5)
        tya
        jsr _scrmova

        pla

        rts
.endproc


;;; typeNZVC, set flag depending on type of AX (retained):
;;;    N = Number, lol
;;;    Z = Null, Nil
;;;    V = Atom
;;;    C = Cons

.proc _type                     ; 34 bytes: 18-38c
        tay
        clv

        lsr
        bcs notnum
        ;;; Number => N
        tya
        ldy #$ff
        rts                     ; 18c Number

notnum: 
        lsr                     ; 9c
        bcs iscons

isatom: 
        ;;; Atom

        ;; NULL?
        cpy #<_nil
        bne notnull
        cpx #>_nil
        bne notnull
        ;; is null
        lda #64+2               ; V+N
        bne end                 ; is jmp end (N=0)
notnull:        
        lda #64                 ; V
end:    
        ;; "SEV" (+ "SEZ")
        pha
        tya
        plp

        rts                     ; 38c Vatom (+ maybe Zull)

iscons:
	;;; Cons
        sec
        tya
        ldy #1
        rts		        ; 24c
.endproc


;;;  TODO: inline macro? 3B
.proc _isnumSetC                ; 12c 3B+1
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
.endproc


;; not inline...
.proc _isconsSetC               ; 14-19c 14B
        tay
        lsr
        bcs maybecons
                                ; C= 0
ret:    
        tya
        rts                     ; 14c

maybecons:      
        lsr
        adc #1                  ; low bit 1 if partity (1+1+1)
        lsr                     ; C= 1 if cons!
        tya
        rts                     ; 19c
.endproc


;;;  TODO: inline macro? 6B
.proc isnullSetN                ; 11-12c 6B+1
        cmp #<_nil               
        bne ret                 ; if Z=0 => not Null
        cpx #>_nil               ; if Z=1 => is Null!
ret:    
        rts

.endproc


;;; TODO: inline macro? 8B
.proc isatomSetC                ; 15-18c 8B+1
        tay
        lsr
        bne ret
        adc #0
        lsr
ret:    
        tya
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
        cpx #>_nil
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

.proc _mul2
        asl
        tay
        txa
        rol
        tax
        tya
        rts
.endproc

.proc _div2
        tay
        txa
        lsr
        tax
        tya
        ror
        rts
.endproc

.proc _printatom
        ;; add 6 offset to point to name
        clc
        adc #6
        bcc noinc
        inx
noinc:  
        jmp _printz
.endproc

.proc _print
        pha
        tay
        txa
        pha
        tya

        jsr _type

        bmi isnum
        bcs iscons
        bvs issym

        ;; TODO: error?
        jmp ret

isnum:  
        jsr _div2
        jsr _printd
        jmp ret

issym:  
        jsr _printatom
        jmp ret

iscons: 
        jsr _printh

ret:    
        pla
        tax
        pla
        
        rts
.endproc

.proc _initlisp

        jsr _initscr
        
        ;; store _nil as car and cdr of _nil
        lda #<_nil
        sta _nil
        sta _nil+2

        lda #>_nil
        sta _nil +1
        sta _nil+2 +1

        ;;  write 'nil'
        lda #110
        sta _nil+6
        lda #105
        sta _nil+7
        lda #108
        sta _nil+8
        lda #0
        sta _nil+9

        ; TODO: store address of "evalsecond"
        ; (nil (+ 3 4) (+ 4 5)) => 9 !


        ;; TODO: move to main?
        jsr _test

        ;; test hex
        ldx #$be
        lda #$ef
        jsr _printh
        jsr _printh

        ldx #$12
        lda #$34
        jsr _printh
        jsr _printh

        ;; test putchar
        lda #67
        jsr _putchar
        lda #66
        jsr _putchar
        lda #65
        jsr _putchar

        ;; TEST push delayed putchar
        ;; (this is clever hack to reverse chars)
        ;; (these will print AFTER rts of this routine!)
        lda #(65+32)
        pha
        lda #>(plaputchar-1)
        pha
        lda #<(plaputchar-1)
        pha

        lda #66+32
        pha
        lda #>(plaputchar-1)
        pha
        lda #<(plaputchar-1)
        pha

        lda #67+32
        pha
        lda #>(plaputchar-1)
        pha
        lda #<(plaputchar-1)
        pha

        ;; test dec
        ldx #$10                ; 4321 dec
        lda #$e1
        jsr _printd
        jsr _printd

        ldx #$dd                ; 56789 dec
        lda #$d5
        jsr _printd
        jsr _printd

        ldx #$be                ; 48879 dec
        lda #$ef
        jsr _printd
        jsr _printd

        ldx #$12                ; 4660 dec
        lda #$34
        jsr _printd
        jsr _printd

        ;;; test type

        ;; Number
        lda #<(2*4711)
        ldx #>(2*4711)
        jsr _print
        jsr _print
        jsr _print
        jsr _testtype

        ;; Atom
        lda #<_T
        ldx #>_T
;;; TODO: somehow value gets lost in _print ???
        jsr _print

        lda #<_nil
        ldx #>_nil
        jsr _print

        lda #<_T
        ldx #>_T
        jsr _print

        lda #<_T
        ldx #>_T
        jsr _print

        lda #<_T
        ldx #>_T
        jsr _testtype
        lda #<_T
        ldx #>_T
        jsr _testtype

        lda #<_nil
        ldx #>_nil
        jsr _testtype
        lda #<_nil
        ldx #>_nil
        jsr _testtype

        lda #<_nil
        ldx #>_nil
        jsr _print

        rts
.endproc

;hello:  .asciiz "2 Hello AsmLisp!",10,""

_hello:	   .byte "4 Hello AsmLisp!",10,0
_helloN:   .byte "5 Hello AsmLisp!",10,0

thetypeis: .byte "The value and type is: ",0

.proc _testtype
        jsr _print

        pha
        txa
        pha
        
        lda #58                 ; ':'
        jsr _putchar

        pla
        tax
        pla

        jsr _type
        bmi isnum
        beq isnull
        bvs issym
        bcs iscons
        
nomatch:        
        lda #63                 ; '?'
        jmp _putchar

isnum:  lda #78                 ; 'N'
        jmp _putchar

isnull: lda #90                 ; 'Z'
        jsr _putchar

issym:  lda #83                 ; 'S'
        jmp _putchar

iscons: lda #64+3               ; 'C'
        jmp _putchar

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

