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
        jsr pushax

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
