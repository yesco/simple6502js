;;; "SectorLisp for 6502" asmlisp-asm.asm (+ asmlisp.c)
;;; 
;;; (c) 2025 Jonas S Karlsson, jsk@yesco.org

;;; This is an attempt to write a pure assembly minimal
;;; lisp for 6502, similar to SectorLisp that was
;;; only 436 bytes, smaller than the SectoForth at 512
;;; bytes.
;;; 
;;; There is a z80/6502 milliforth is 336/328 bytes.
;;; 
;;; can we create a minimal 6502 lisp?

;;; SectorLisp limitations:
;;; - 512 bytes "bootable"
;;; - assumes prexisting "bios": getch putch
;;; - only SYMBOLS and CONS
;;; - reader and writer (no editor, or backspace)
;;; - T NIL QUOTE READ PRINT COND CONS CAR CDR (41)
;;;     ?LAMBDA ?EVAL ?APPLY (16)
;;; - no GC (or minimal "reset")



;;; START
;;; 
;;; .TAP delta
;;;  319          bytes - NOTHING (search)
;;;  502 +183     bytes - MINIMAL (- 502 319)
;;;  613          bytes - ORICON  (raw ORIC, no ROM)
;;;  681 +179 362 bytes - NUMBERS (- 681 502)
;;;  900          bytes - TEST + ORICON

;;; 183 bytes:
;;;       _type 30  just "BIT bit2"
;;;         isnum 4, iscons 14, isnull 6, isatom 9 (33)
;;;       print 35, printatom 8,
;;;       eval 30 
;;;    == 173  (+ 30 14 6 9 30 8 35 29 8 4) 

;;; enable numbers
NUMBERS=1

;;; enable tests (So far depends on ORICON)
;TEST=1

;;; enable ORICON(sole, code for printing)
;ORICON=1

.import incsp2, incsp4, incsp6, incsp8
.import addysp

.export _nil
.export _initlisp

.ifdef ORICON

.export _initscr
.export _scrmova
.export _printz, _printzptr

.endif ; ORICON

.ifdef TEST
.export _test
.endif

;; TODO: not working in ca65, too old?

;.feature string_escape

.zeropage

.ifdef ORICON
curscr: .res 2
leftx:  .res 1
lefty:  .res 1
        ;;  TODO: do something clever to remove this?
newlineadjust:  .res 1          ; or use tmp1?
.endif ; ORICON

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

.ifdef ORICON
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

.else ; ORICON

;;; - https:  //github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Fgpchar.s

;;; input char from keyboard
;;;
;;; 10B
.proc _getchar      
        jsr $023B               ; ORIC ATMOS only
        bpl _getchar            ; no char - loop
        tax
        ;; TODO: optional?
        jsr $0238               ; echo char
        rts
.endproc

;;; platputchar used to delay print A
;;; (search usage in printd)
plaputchar:    
        pla

;;; _putchar(c) print char from A
;;; 
;;; 12B
.proc _putchar
        ;; '\n' -> '\n\r' = CRLF
        cmp #$0A                ; '\n'
        bne notnl
        pha
        ldx #$0D                ; '\r'
        jsr $0238
        pla
notnl:  
        tax
        jmp $0238
.endproc

.endif ; ORICON

;;; enable these 3 lines for NOTHING
;.export _initlisp            
;_initlisp:      rts            
;.end


;;; _putz prints zstring at AX
;;; (no newline added that puts does)
_printz:  
        ldy #0

;;; _printzY prints zstring from AX starting at offset Y
;;; (no newline added that puts does)
.ifnblank
.proc _printzY
        sta ptr1
        stx ptr1+1
next:
        lda (ptr1),y
        beq end
        jsr _putchar
        iny
        bne next
end:    
        rts
.endproc
.endif

;;; ===================================
;;; LISP:

 
;;; various special data items, constants
;;; - ATOMS
;;; TODO: any evaluate to self, put in ZP?
;;;       (easier test in eval!)
.align 2
.res 1

_T:     .word _T, _nil, _eval
        .byte "T", 0


.ifdef NUMBERS

;;; print one hex digit from A lower 4 bits at position Y
;;; (doesn't trash X)
.proc _print1h
        and #15
        ora #48                 ; '0'
        cmp #58                 ; '9'+1
        bcc print
        ;; >'9' => 'A'-'F'
        adc #6                  ; 'A'-'9'+1-1 (carry set)
print:  
.ifdef ORICON
        sta (curscr),y
.endif ; ORICON
        iny
        rts
.endproc

;;; div16/16 - 40 Bytes
;;; - http://forum.6502.org/viewtopic.php?f=2&t=6258

;;; div16/8 divide ptr1 16-bits by ptr2 8-bits, result in ptr1
;;; 
;;; by strat @ nesdev forum ; 21B
;;; 
;;; out: A: remainder; X: 0; Y: unchanged

.proc div16
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  cmp ptr2
  bcc @no_sub
  sbc ptr2
  inc ptr1
@no_sub:
  dex
  bne @divloop

  rts
.endproc

;;; 16div16 => 16 ??? works?
;;; jsk 37B
.proc div1616
  ldx #16
  lda #0

@divloop:
  asl ptr1
  rol ptr1+1
  rol a

  ;; hi-byte cmp
  tay
  lda ptr1+1
  cmp ptr2+1        
  bcc @no_sub                   ; one off?
  tya

  ;; lo-byte cmp
  cmp ptr2
  bcc @no_sub

  ;; lo-byte sub
  sbc ptr2
  inc ptr1

  ;; hi-byte sub
  tay
  lda ptr1+1
  sbc ptr2+1
  sta ptr1+1
  tya
  
@no_sub:
  dex
  bne @divloop

  rts
.endproc



;;; _printd print a decimal value from AX (retained, Y trashed)
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
        ora #48                 ; '0'

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
.ifdef ORICON
        sta (curscr),y
.endif ; ORICON
        iny

        ;; print hi-byte
        txa
        jsr _print2h
        pla
        ;; print lo-byte
        jsr _print2h

        ;; move cursor forward Y (=5)
        tya
.ifdef ORICON
        jsr _scrmova
.endif ; ORICON
        pla

        rts
.endproc

.endif                          ; NUMBERS

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


.ifdef NUMBERS

;;;  TODO: inline macro? 3B
.proc _isnumSetC                ; 12c 3B+1
        tay
        lsr
        tya
        rts                     ; C= 0 if Number!
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

.ifdef TEST
.proc testnums
        ;; test hex
        ldx #$be
        lda #$ef
        jsr _printh
        jsr _printh

        ldx #$12
        lda #$34
        jsr _printh
        jsr _printh

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

        rts
.endproc
.endif ; TEST

.endif ; NUMBERS

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

.ifdef NUMBERS
        bmi isnum
.endif ; NUMBERS
        bcs iscons
        bvs issym

        ;; TODO: error?
        jmp ret

.ifdef NUMBERS
isnum:  
        jsr _div2
        jsr _printd
        jmp ret
.endif

issym:  
        jsr _printatom
        jmp ret

iscons: 
        ;; TODO: write it
        ;jsr _printh

ret:    
        pla
        tax
        pla
        
        rts
.endproc

.proc _initlisp

.ifdef ORICON        
        jsr _initscr
.endif ; ORICON
        
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


        lda #65+25
        jsr _putchar
        lda #65+24
        jsr _putchar
        lda #65+23
        jsr _putchar
        jsr _getchar
        jsr _putchar

        ;; TODO: move to main?
.ifdef TEST
        jsr _test
.endif ; TEST

        rts
.endproc

.ifdef TEST

thetypeis: .byte "The value and type is: ",0

.proc testatoms
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

        rts
.endproc

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


.proc _test
        jsr _testprint

.ifdef NUMBERS
        jsr testnums
.endif
        jsr testatoms

        jsr testtypefunc

        rts
.endproc


;;; 123 bytes
;hello:  .asciiz "2 Hello AsmLisp!",10,""

_hello:	   .byte "4 Hello AsmLisp!",10,0
_helloN:   .byte "5 Hello AsmLisp!",10,0

.proc _testprint

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


.proc testtypefunc
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

.endif ; TEST


;;; LISP:
;;;   SectorForth: 	512 bytes
;;;   SectorLisp:  	436 bytes
;;;   z80 milliforth:	336 bytes
;;;   6502 milliforth:  328 bytes !
;;; 
;;; - https://github.com/agsb/milliForth-6502
;;;   * no: line editor, bs, cancel, low ascii
;;;         stacks overflow, underflow checks
;;;   primitives: s@ + nand @ ! 0# exit key emit
;;;   internals: spush spull rpull rpush
;;;     copyfrom copyinto (heap code) incr decr add etc
;;;     cold warm quit token skip scan getline
;;;     parse find compile execute
;;;     unnest next nest unnest pick jump
;;;   externals: getch putch byes
;;;   ext: 2/ exec $(jmp to ipt) 
;;;   optional: bye abort .S .R . words dump
;;;;
;;; 6502 asmlisp - "SECTORLISP for 6502"
;;; (goal < 512 bytes, not care speed)
;;; 
;;; - = function planned
;;; * = function in SectorLisp
;;; # = number function / optional
;;; 
;;; [42] bytes neeeded but is "bios" (getchar/putchar)
;;; (42) bytes needed for optinoal (numbers)
;;;
;;;   - _type		29 (6)		29
;;;   * atom (== !iscons)
;;;   - prin1
;;;     - prinz         [75]
;;;     - putchar       [10]
;;;     N printd        (12)
;;;       - voidprintd  (38+1)	 	
;;;     - initscr       (17)
;;;     * print         28 (11)         67 (79) [85]
;;;       * print cons/list (TODO)
;;;   * eq
;;;   * read
;;;     * readatom       15             82
;;;     * readlist
;;;       * quote
;;;     # readnum       (38)              
;;;       # mul16       (33)                (150)  
;;;   * cons (grow down?)
;;;   * car
;;;   * cdr
;;;   * lambda
;;;   * eval            35              117        [85]
;;;     - assoc
;;;   * cond / if
;;;
;;; STACK (TODO: use limited 256 byte? or 80B in zp?)
;;;   - pushax
;;;   - popax
;;;   - incsp2
;;;   - incsp4
;;;
;;;   # plus (+)
;;;
;;; GOODIES
;;;   - def
;;;   - apply
;;;   - and
;;;   - or
;;;   - list
