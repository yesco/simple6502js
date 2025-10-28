;;; TODO: look at 
;;; - https://github.com/Michaelangel007/6502_calling_convention


;;; ----------------------------------------
;;;    a) push parameteers pha;txa;pha - fastest!
;;;    b) jsr function
;;;    b) swap parameters from stack, to zp block
;;;    c) perform function
;;;    d) swap parameters again!

        lda #11
        ldx #11

        pha
        txa
        pha

        ...
        4 params pushed
        ..
        
;;; TEST cc65 4 parameters recursion!

        ;; COPY
        ;; 
        ;; 4 parameters
        ;; 3*4 = 12 bytes calling overhead 8c*4= 32c)
        ;;            + copy cost 106c (+ 32 106)
        ;; 12 + 8 B
        ;; 18 B  128c (+ 104c cmp zp...)

        jsr fun

        ;; STA zp
        ;; 
        ;; 4 parameters
        ;; dedicationed sta zp locations
        ;; (no care overlap probelm)
        ;; 6*4= 24 B  6*4= 24c
        ;; 24 B  24c

        ;; SWAP (RECURSION!)
        ;; 
        ;; 4 parameters
        ;; recursion support+swap
        ;; + 32c + 464c (4 params, 8 bytes) - can do recursion!
        ;; (+ (* 8 4) (* 2 2) 12 464) = 512c
        ;; (+ (* 3 4) (* 2 (+ 3 2))) = 22 B
        ;; 22 b  512c !!!


fun:    
;;; no recursion, private zp vars, no overlap
;;; (solves the foo(3, foo(4, 5)) - problem!
;;; 
;;; + 5 B
;;; + (+ 2 12 (* 2 4 13)) = 118c 4 params
;;; + (+ 2 (* 2 4 13)) =    106c 4 params INLINE
;;;     (but inline + 6 B... CHEAP!!!)
        ldy #8
        jsr copyparams
        
        ...body...rts...


copyparams:     
;;; 6 + 1 B  cycles: bytes * 13c !!!
:       
        pla
        sta params-1,y
        dey
        bne :-

        rts


fun:    
;;; + 8 B 2*12
;;; + 2*12 + 2*4 + bytes * 2 * 29c
;;; + 32c + 464c (4 params, 8 bytes) - can do recursion!
        ldy #8                  ; bytes
        jsr swapparams
        
        ...body...
        
        ldy #8
        jmp swapparams

swapparams:     
;;; 20 B  4c + bytes * 29c
        tsx
:       
        ;; swap stack <-> params
        lda 101,x
        sta savea

        lda params,y
        sta 101,x

        lda savea
        sta params,y

        inx
        dey
        bpl :-

        rts
        



;;; ----------------------------------------
;;;                BLOCK



;;; TODO: block calling convention
;;;    - save, no save
;;;    
;;;    (optional)
;;;    lda ...
;;;    ldx ...
;;;    sta @params+(2-1)
;;;    stx @params+(2-1)+1
;;; 
;;;    lda #0
;;;    sta @params+(3-1)
;;;    stx @params+(3-1)
;;; 
;;;    jsr inlineMEMCPY
;;;    .byte N*2
;;; @params:
;;;       .word param_1
;;;       ...
;;;       .word param_N
;;; .  <AFTER CALL>

        ;; Now save the damn screen!

;;; 23 B 24 (+ jsr)
        ;; from
        lda #<SCREEN
        ldx #>SCREEN
        sta tos
        stx tos+1
        ;; to
        lda #<savedscreen
        ldx #>savedscreen
        sta dos
        stx dos+1
        ;; copy
        lda #<SCREENSIZE
        ldx #>SCREENSIZE
        
        jsr _memcpy


;;; 10 B (save 13 bytes) (callee overhead 9 B)
;;; (+ 12 6 5 bytes * 25) ???
;;; 
        jsr memcpyPARAMS
        .byte 6
        .word SCREEN            ; from
        .word savedscreen       ; to
        .word SCREENSIZE        ; bytes
        
;;; 13 B (+ 3) (callee overhead 12+12+57+N*23 ?)

;;; 81c + bytes *23
        CALL memcpy5, {SCREEN,savedscreen,SCREENSIZE}
        ;; generates
        ;; (TODO: make sure even address!)
        ;; (insert nop otherwise!)
        jsr PARAMS_CALL
        .byte 6
        .word SCREEN            ; from
        .word savedscreen       ; to
        .word SCREENSIZE        ; bytes
        
        ;; (TODO: make sure even address!)
        jsr memcpy5



memcpyPARAMS:   
;;; 

;;; 9 B overhead in function :-
        ;; lo
        pla
        tay
        ;; hi
        pla
        jsr copyparams
        ;; hi
        pha
        tya
        ;; lo
        pha

        jmp memcpy5

copyparams:
;;; 30 B :-(
        sty tmp1
        sta tmp1+1
        ;; Stack points to byte before
        ;; read #bytes
        ldy #1
        lda (tmp1),y
        tax
        ;; copy
@next:       
        inc tmp1
        bne :+
        inc tmp1+1
:       
        dex
        bmi @done

        lda (tmp1),y
;;; wrong if not INY!
        sta tos-2,y
        jmp @next

@done:
        ;; get updated address
        ;; after copied block
        lda tmp1+1
        ldy tmp1
        
        rts


;;; ----------------------------------------

;;; 13 B (+ 3)
        CALL memcpy5, {SCREEN,savedscreen,SCREENSIZE}
        ;; generates
        ;; (TODO: make sure even address!)
        ;; (insert nop otherwise!)
        jsr PARAMS_CALL
        .byte 6
        .word SCREEN            ; from
        .word savedscreen       ; to
        .word SCREENSIZE        ; bytes
        
        ;; (TODO: make sure even address!)
        jsr memcpy5




PARAMS_CALL
;;; 31 B  57c + bytes * 27c
        ;; lo
        pla
        sta tmp1
        ;; hi
        pla
        sta tmp1+1
        ;; init
        ldy #1
        lda (tmp1),y
        sta savex
        ldx #0
        ;; copy
@next:
        inc tmp1
        bne :+
        inc tmp1+1
:       
        lda (tmp1),y
        sta tos,x

        dec savex
        bmi @next
@done:
        ;; TODO: aligned right?
        jmp (tmp1)



;;; ALT 9 (no need extra jsr)
        iny
        lda (tmp1),y
        pha
        dey
        lda (tmp1),y
        pha

        rts
        


        ;; tmp1+= Y; jmp (tmp1)
;;; 13
        tya
        clc
        adc tmp1
        sta tmp1
        bcc :+
        inc tmp1+1
:       
        ;; should point to subr address!
        jmp (tmp1)



PARAMS_CALL
;;; 19 + 13 = 32 B !
        ;; lo
        pla
        sta tmp1
        ;; hi
        pla
        sta tmp1+1
        ;; init
        ldy #0
        lda (tmp1),y
        tax
        ;; copy
@next:
        iny
        lda (tmp1),y
        sta tos-2,y
        dex
        bne @next

@done:
        ;; tmp1+= Y; jmp (tmp1)
;;; 13
        tya
        clc
        adc tmp1
        sta tmp1
        bcc :+
        inc tmp1+1
:       
        ;; should point to subr address!
        jmp (tmp1)


        ;; tmp1+= Y; phRTS; rts;
;;; 15
        ldx tmp1+1

        clc
        tya
        adc tmp1
        tay
        bcc :+
        inx
:       
        txa
        pha
        tya
        pha
        
        rts


;;; lo byte PC in Y
PARAMS_CALL:    
;;; 33 B (+ 42c + bytes * 26c)
        ;; lo
        pla
        tay

        lda #0
        tax
        sta tmp1
        sta savey
        ;; hi
        pla
        sta tmp1+1

        ;; copy
@next:
        iny
        bne :+
        inc tmp1+1
:       
        lda (tmp1),y

        ;; not init?
        dex
        bpl :+
        tax
        bne @next
:       
        sta tos,x
        txa
        bne @next

@done:
        ;; should point to subr address!
        jmp (tmp1)
        



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; jsk newest variant
;;; CALLER cleanup!

hwstack:        
        ;; prelude
        ;; - push old, replace w new

;;; 3 B  38c+6= 44c
        jsr markstack

;;; 6 B  11c ==== OK OVERHEAD!
        tsx
        lda savedS
        pha
        stx savedS

        ;; first arg
        lda #$11
        ldx #$11

        ;; 3 B, 7c overhead
        pha
        txa
        pha

        ...

        ;; last arg
        lda #$44
        ldx #$44

        ;; should save
        pha
        txa
        pha
        
        ;; call
        jsr fixed4

        ;; after do cleanup
;;; 10 B  16c
        stx savex
        ldx savedS
        ;; 
        ldy 101,x               ; instead of pla!
        sty saveS
        ldx savex

        lll

fixed4: 
        rts



;;; OR add it to exit of fun


fixed4: 
        ...
        jmp cleanup
        








markstack:      
;;; 21 B  38c + 6c (call it)
        pla
        sta tos
        pla
        sta tos+1
        ;; 
        tsx
        lda savedS
        pha
        stx savedS
        ;; 
        inc tos
        bne :+
        inc tos+1
:       
        jmp (tos)

;;; OR
;;; 14 B  37c
        pla
        tay
        pla
        sta savea
        ;; 
        tsx
        txa
        pha
        ;; 
        lda savea
        pha
        tya
        pha
        rts
        

;;; instead of RTS we do cleanup
cleanup:    
;;; 29 B  49c
        ;; 
        tay
        stx savex
        ;;      
        pla
        sta tos
        pla
        sta tos+1
        ;; 
        ldx savedS
        lda 101,x
        sta savedS
        txs
        ;; 
        ldx savex
        tya
        ;; 
        inc tos
        bne :+
        inc tos+1
:       
        jmp (tos)

;;; OR

;;; 23 or 21 B  54c (both)
        ;; 
        tay
        stx savex
        ;;      
        pla
        sta tos
        pla
        sta tos+1
        ;; 

;;; ONE BEGIN
;;; 8 B  12c
        ldx savedS
        lda 101,x
        sta savedS
        txs
;;; OR: ONE END TWO BEGIN
;;; 6 B  12c
        ldx savedS
        txs
        ;; may need change push order?
        pla
        sta savedS
;;; TWO END

        ;; 
        lda tos+1
        pha
        lda tos
        pha
        ;; 
        ldx savex
        tya
        ;; 
        rts
        



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; jsk 

;;; TODO: this is incorrect as it
;;; disposes of the return address!
;;; to fix it needs to be saved before
;;; pulling things from the stack! LOL

;;; PROBLEM solved if using a separate stack


;;; TODO: maybe use CALLER cleanup!

hwstack:
        lda #$11
        ldx #$11

        ;; push lo, hi (opposite byte order!)
        pha
        txa
        pha


        lda #$22
        ldx #$22

        pha
        txa
        pha

        lda #$33
        ldx #$33

        pha
        txa
        pha

        ;; last arg
        lda #$44
        ldx #$44

        ;; push LAST argument - always!
        pha
        tax
        pha

;;; NORMAL FIXED arg style
        jsr hwfunc


;;; VARARG-style
        ldy #8
        ;; fast call, last arg in AX
        jsr hwfunc_vararg
        ;; return value in AX
        

hwfunc:
        ;; get paramN value
;;; 10 B !
        tsx
        lda 102 + N*2,x       ; lo (reversed)
        tay
        lda 101 + N*2,x       ; hi (reversed)
        tax
        tya

        ;; to exit must cleanup
@rts:   
;;; ALT: 5 + 62c - slowest (N=1 => 27c)
        ldy #8
        jmp leaveY
;;; ALT: 6 + 35c - fastest (N=1 => 11c)
;;; TODO: remove - doesn't work!
;        sta savea
;        jmp leave8Bpop
;;; ALT: 5 + 26c + 6c
        ldy #8
        jmp leave_SY



hwfunc_vararg: 
        ;; - store Y bytes to pop
        tay
        pha

        ;; get paramN value
;;; 10 B !
        tsx
        lda 102 + N*2,x       ; lo (reversed)
        tay
        lda 101 + N*2,x       ; hi (reversed)
        tax
        tya

        ;; to exit must cleanup
@rts:   
;;; ALT: 57c (4 args)
        jmp leave
;;; ALT: 26c + 6c FIXED!
        jmp leave_vararg


leaveY:
;;; SLOWEST!
;;; 20 b, 18 + y*11 (+3c return!) (n==4 => 18+44=62c!)
        ;; return value in ax, so save a
        sta savea

        ;; load return address
;;; 6 b 14c
        pla
        sta tos
        pla
        sta tos+1

        ;; drop n bytes
:       
        dey
        bmi :+
        pla
        jmp :-

        lda savea
        ;; return
        jmp (tos)


leave:  
;;; slowest!
;;; 14 b, 12 + 1 + y*11 (+6c rts) (n==4 => 13+44=57c!)
        ;; return value in ax, so save a
        sta savea
        pla
        tay
        ;; drop n bytes
:       
        dey
        bmi :+
        pla
        jmp :-

        lda savea
        rts


;;; todo: cannot doe!!!!

;;; fastest (n<=3), but "stupid"
;;; 11 b, 3 + n*8 c   (n==4 => 35c ! fastest!
leave8bpop:
        pla
        pla
leave6bpop:        
        pla
        pla
leave4bpop:        
        pla
        pla
leave2bpop:
        pla
        pla
leave0bpop:                     ; lol
        lda savea
        rts

leave_sy:       
;;; 16 b 26c (+ 6c rts) (n==4 => 26c)
        ;; save
        sty savey
        stx savex
        tay
        ;; s += y
        tsx
        txa
        clc
        adc savey
        tax
        txs
        ;; restore
        ldx savex
        tya
        rts

;;; clever, medium fixed cost 28c!
;;; ... and needed for vararg!
leave_vararg:  
;;; 24 b 47c (incl return) (n==4 => 47c)
        ;; save
        tay
        stx savex
        ;; s += y
        tsx
        stx savey               ; lol
        pla
        clc
        adc savey
        tax

        ;; get return address, stuff it!
        pla                     ; lo
        sta tos
        pla
        sta tos+1
        ;; cleanup stack!
        txs
        ;; restore
        ldx savex
        tya
        ;; jump back !
        jmp (tos)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; jsk calling convention trampoline (?)

;;; CALLE cleanup 

hwstack:        
;;; 3 B 3c overhead, but simplifies stack cleanup!
        jmp TRAMPOLINE
TRAMP:  
        lda #$11
        ldx #$11

        ;; push lo, hi (opposite byte order!)
        pha
        txa
        pha

        lda #$22
        ldx #$22

        pha
        txa
        pha

        lda #$33
        ldx #$33
        jsr pushax

        pha
        txa
        pha

        ;; last arg
        lda #$44
        ldx #$44

;        ;; push LAST argument - always!
;        pha
;        tax
;        pha

;;; NORMAL FIXED arg style
        jmp hwfunc
        
TRAMPLINE:      
        jsr TRAMP
        ;; get's here after rts!


;;; VARARG-style
        ldy #8
        ;; fast call, last arg in AX
        jsr hwfunc_vararg
        ;; return value in AX
        

hwfunc:
        ;; push last arg!
        pha
        txa
        pha

        ;; get paramN value
;;; 10 B !
        tsx
        lda 102 + N*2,x       ; lo (reversed)
        tay
        lda 101 + N*2,x       ; hi (reversed)
        tax
        tya

        ;; to exit must cleanup
@rts:   
;;; ALT: 5 + 53c + 6c - slow (N=1 => 20c)
        ldy #8
        jmp leaveY
;;; ALT: 6 + 35c + 6c - fastest (N=1 => 11c)
        sta savea
        jmp leave8Bpop
;;; ALT: 5 + 26c + 6c
        ldy #8
        jmp leave_SY



hwfunc_vararg: 

;;; Prelude
;;; 5 B 13c
        ;; - push last arg from AX, reverse order
        pha
        txa
        pha
        ;; - store Y bytes to pop
        tay
        pha

        ;; get paramN value
;;; 10 B !
        tsx
        lda (102 + N*2),x       ; lo (reversed)
        tay
        lda (101 + N*2),x       ; hi (reversed)
        tax
        tya

        ;; to exit must cleanup
@rts:   
;;; ALT: 57c (4 args)
        jmp leave
;;; ALT: 26c + 6c FIXED!
        jmp leave_vararg


leaveY:
;;; SLOWEST!
;;; 12 B, 9 + Y*11 (+6c rts) (N==4 => 9+44=53c!)
        ;; return value in AX, so save A
        sta savea
        ;; drop N bytes
:       
        dey
        bmi :+
        pla
        jmp :-

        lda savea
        rts


leave:  
;;; SLOWEST!
;;; 14 B, 12 + 1 + Y*11 (+6c rts) (N==4 => 13+44=57c!)
        ;; return value in AX, so save A
        sta savea
        pla
        tay
        ;; drop N bytes
:       
        dey
        bmi :+
        pla
        jmp :-

        lda savea
        rts


;;; FASTEST (N<=3), but "STUPID"
;;; 11 B, 3 + N*8 c   (N==4 => 35c ! fastest!
leave8Bpop:
        pla
        pla
leave6Bpop:        
        pla
        pla
leave4Bpop:        
        pla
        pla
leave2Bpop:
        pla
        pla
leave0Bpop:                     ; lol
        lda savea
        rts

leave_SY:       
;;; 22 B 40c (+ 3c return) (N==4 => 40c)
        ;; save
        sty savey
        stx savex
        tay
;;; 
        pla
        sta tos
        pla
        sta tos+1

        ;; S += Y
        tsx
        txa
        clc
        adc savey
        tax
        txs
        ;; restore
        ldx savex
        tya
        rts

;;; CLEVER, medium FIXED cost 28c!
;;; ... and needed for vararg!
leave_vararg:  
;;; 16 B 28c (+ 6c RTS) (N==4 => 28c)
        ;; save
        tay
        stx savex
        ;; S += Y
        tsx
        stx savey               ; lol
        pla
        clc
        adc savey
        tax
        txs
        ;; restore
        ldx savex
        tya
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

oricparams:     
        lda #$11
        ldx #$11

        sta PARAMS+0
        stx PARAMS+1
        
        lda #$22
        ..
        stx PARAMS+3

        ;; last arg n=4
        ...
        sta PARAMS + n*2
        stx PARAMS + n*2 + 1

        jsr ROMFUNC
        ;; error code in PARAMS-1 (or -2?)
        lda PARAMS-1
        ldx #0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cc65:   
        lda #$11
        ldx #$11
        jsr pushax

        lda #$22
        ldx #$22
        jsr pushax

        lda #$33
        ldx #$33
        jsr pushax

        ;; last arg
        lda #$44
        ldx #$44

        ;; fast call, last arg in AX
        jsr cc65func
        ;; return value in AX

cc65func:       
        jsr pushax              ; LOL, ok saved 3 B!
        ;; get paramN value
;;; 10 B !
        tsx
        lda (102 + N*2),x
        tay
        lda (101 + N*2),x
        tax
        tya
        
        ;; no direct rts
@ret:
        ;; value to return in AX
        ;; jump to cleanup stack 8 bytes (sp -= 8)_
        ;; preserves AX
        jmp incsp8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; int cdecl printf(const char* fmmt, ...) {
cc65_vararg:    
        ;; last arg
        ... (same as cc65:) ...
        
        ;; call (no value in AX (well last))
        ;; (but all on stack for varargs)
        jsr pushax

        ;; Y is number of bytes to drop from dstack
        ldy #8
        ;; CDECL call (vararg) call
        ;; FUNC does: dstack -= 6; before return
        jsr cc65_vararg_func
        ;; return value in AX



cc65_vararg_func
        jsr enter

        ;; return by jmp not rts!
@ret:
        jmp    leave




        ;; stores Y the number of bytes
        ;; to drop when done (in leave)
enter:
;;; 14 B 25c
        tya 
        ldy     sp
        bne     :+
        dec     sp+1
:
        dec     sp
        ldy     #0
        sta     (sp),y          ; Store the arg count
        rts

leave:
;;; 16 B 29 (+6c rts)
        ;; save A
        pha     
        ldy     #0
        lda     (sp),y
        ;; add 1 more! - clever, lol
        sec
        adc     sp
        sta     sp
        bcc     :+
        inc     sp+1
:       
        ;; restore A
        pla

.endif
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

push0:  
        lda     #0
pusha0:
        ldx     #0

;;; keeps AX unchanged!

pushax: 
;;; 22 B  44/49c
        pha                     ; (3)
        lda     sp              ; (6)
        sec                     ; (8)
        sbc     #2              ; (10)
        sta     sp              ; (13)
        bcs     @L1             ; (17)
        dec     sp+1            ; (+5)
@L1:    ldy     #1              ; (19)
        txa                     ; (21)
        sta     (sp),y          ; (27)
        pla                     ; (31)
        dey                     ; (33)
        sta     (sp),y          ; (38)
        rts                     ; (44/43)

;;; no keep AX
;;; TODO: if the dec after...
;;;   assuming we have more pushax than pops!
;;;   (reasonable as end of fun pop-all!)
pushax_nokeep_postdec: 
;;; 20 B  37c (+4c sometimes)

;;; 8 B  18c
        ldy     #1
        sta     (sp),y          ; 6c
        iny
        txa
        sta     (sp),y          ; 6c

        ;; sp -= 2;
;;; 12 B  13c (+4c) +6c= 19c (+4c occasionally)
        sec
        lda     sp
        sbc     #2
        sta     sp
        bcs     :+
        dec     sp+1
:       
        rts


;;; split stack (index y)
;;; no keep AX
push:   
;;; 12B  24c
        dec stack               ; pre/post no diff!
        ldy stack
        sta lostack,y
        ;; sta savea
        txa
        sta histack,y
        ;; lda savea
        rts

;;; split stack
push:   
;;; 12B  24c
        dec stack
        ldx stack
        sta lostack,x
        txa
        sta histack,x
        rts
