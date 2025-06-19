;;; cut-n-paste variants not used?

;;; comma moves words from stack to ptr1
;;;   ptr1 advances
;;; 
;;; C: *ptr1= stack[x]; x+= 2; top+= 2;
;;;
;;; ccomma:
;;;   WARNING: stack is misaligned one byte!
;;; 
;;; 12+7= 19 B
_comma:
;;; 12
        ldy #0
        jsr _ccomma
_ccomma:
        lda stack,x
        sta (top),y
        inx
        iny

.proc _inc
;;; (7 B)
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc

_store: 
;;; 8 B
        jsr _comma
drop2:  
        dex
        dex
        jmp pop

_rcomma:        
;;; 6+12 = 18
        jsr dec2
        jsr _comma
        ;; dec2 again, lol
dec2:   
;;; 3+9 = 12
        jsr _dec

.proc _dec
;;; (9 B)
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc
;;; 
        

;;; ^ (+ 19 8 18) = 45 top, inc store top, dec2 dec

;;; (+ 14 16 14)= 44 store  topcomma toprc
;;; (+ 3 8 1 9 16 9)=46 load2 store topc toprc

topcomma:
;;; 8+6 = 14
        jsr store
;;; 8
        jsr push
        lda #2
        sta top
        lda #0
        sta top+1
;;; (3)
;        jmp push2              ;

        jmp _sbc

store: 
;;; 16 B
        ldy #0
        lda stack,x
        sta (top),y
        inx

        iny
        lda stack,x
        sta (top),y
        inx

        rts
        
toprcomma:      
;;; 8+6 = 14 B
;;; 8
        jsr push
        lda #2
        sta top
        lda #0
        sta top+1
;;; (3)
;        jsr push2              ;

;;; 6
        jsr _plus
        jmp store
        


;;; rcomma needed for cons
;;; 
_rcomma:        
        

;;; 19B
_rcomma:        
        jsr _rbcomma
_rbcomma:       
        ldy #0
        lda stack+1,x
;;; writing wrong order bytes!
;;;  bakcwards
        dex
        
.proc _dec
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc



_dup:   
push:   
;;; 13 B
        lda top+1
        dex
        sta stack,x

        lda top
        dex
        sta stack,x

        rts


dup:    
push:  
;;; 4+10 = 14 B
        lda top
        ldy top+1

;;; pushAY A low, Y hi, push on data stack
pushAY:
;;; (10 B)
        dex
        dex
        sta stack,x
        tya
        sta stack+1,x
        rts

;;; maybe not needed
.ifnblank

pushA:  
;;; 5 B
        ldy #0
        jmp pushAY

pushreg:        
;;; 9 B
        lda 0,y
        ldx 1,y
        jmp pushAY

car:    
;;; 16
        ldy #0
        lda (top),y
        sta ptr1
        iny
        lda (top),y
        sta ptr1+1

        ldy #ptr1
        jmp pushregY
        
cdr:    
;;; 13 + 3 = 16B
car:    
;;; 13B
        ldy #2
        lda (top),y
        pha
        iny
        lda (top).y
        tay
        pla
        jmp pushAY

cdr:    
;;; 3 + 14 = 17 B
        ldy #2
        ;; BIT-hack (skips next 2 bytes)
        .byte $2c
load:  
car:    
;;; (14 B)
        ldy #0
cYr:    
        lda (top),y
        pha
        iny
        lda (top),y
;;; load TOP w (A, pla) (hi,lo)
;;; (useless?)
loadPOPA: 
;;; (6 B)
        sta top+1
        pla
        sta top
        rts

dup:    
;;; 2+13 = 15
        ldy #top
pushregY:       
;;; (13 B)
        lda 0,y
        dex
        sta stack,x
        
        lda 1,y
        dex
        sta stack,x
        rts

pushregY:       
;;; 14 B
        jsr push
        lda 0,y
        sta top
        lda 1,y
        sta top+1
        rts
        


;;; This one would be smaller with recursive dup
;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack,y
        pla

        rts

popret: 
        RPOP
        rts



.macro iJSR where
.assert ((where-jmptable)<(256-4)),error,"iJSR: too far"
        brk
        .byte (where-jmptable)
.endmacro

.macro pJSR where data
        iJSR where
        .byte data
.endmacro

;;; interrupt handler for
;;; BRK dispatch
;;; 
;;;  call _car         - 2 bytes (1 saved) - rti
;;;  pcall _print '>'  - 3 bytes (2 saved) - rts

;;; (lit 'A'           - 3 bytes (2 saved) - rts)
;;; (literal $beef     - 4 bytes (3 saved))

;;; (xcall _extrawork) - 2 bytes (1 saved)
;;; (uses a forwarding byte to call second page)

;;; Generally dispatched functions don't
;;; rely on any value in A or Y when entering.
;;; 
;;; (X contains data stack pointer, don't use)
;;; 36 B - TOO MUCH - probably no savings...
;;; (unless have 36 calls, lol)
_BRK:

;;; stack contains: lo, hi addr to continue
;;; "BRK i j k" pointing to d; rti continues at j;
;;; rts continues at k!

;;; 17 B
;;; (need to save 17 bytes to make it worth!)
        ;; dup
        pla                     ; lo

        ;; pBRK.lo= retaddr.lo-1
        sec
        sbc #1
        sta pBRK
        ;; no need care underflow
        ;; as we keep within page boundaries!

        ;; set return address -1
        ;; so can rely on rts
        pha

        ;; load "i"
        ldy #0
        lda (pBRK),y

        sta docall+1
docall: jmp jmptable


;;; get i(nstruction) byte
;;; 11 B
        ;; dup
        pla                     ; lo
        pha
        ;; pBRK.lo= retaddr.lo-1
        sec
        sbc #1
        sta pBRK
        ;; no need care underflow
        ;; as we keep within page boundaries!
        ;; a= "actual i" (instruction/offset)
        ldy #0
        lda (pBRK),y



;;; dispatch depending on size/function
;;; 
        ;; modify lo of call!
        sta docall+1

;;; LITERAL $beef = brk _literal $be $ef
;        cmp #fourbytes_instructions
;        bcs fourcall

;;; xcall _foo = jsr jmpage+256+offset[_foo-jmppage]
;;; 
;;; eXtended call
;;; (at end page, forward offset to second page)
;;; = eJSR    
;        cmp #vecInstructions
;        bcs vectorcall         ;

        cmp #pInstructions
        bcs paramcall
        cmp #iInstructions
        bcs docall

;;; two byte instruction
;;; tail jmp!
;;; adjust ret address -1
;;; 4 B
        pla
        lda pBRK                ; already dec!
        pha
        ;; fall-through

;;; three byte instruction
;;; tail jmp! (will returns w rts)
docall: jmp jmptable

paramcall:
;;; 7 B
        ;; load parameter
        iny                     ; 1
        lda (pBRK),y

        ;; Y = A= param !
        tay
        
        jmp docall

;;; four byte instruction
fourcall:       
        pop
        sec
        



;;; Follow: loads ptr1 from stack
;;;   it kindof can be used as an iterator
;;;   using , comma operator to
;;;   move values from stack to where ptr1 points
_follow:        
;;; 11 B
        lda top
        sta ptr1
        lda top+1
        sta ptr1+1
        jmp pop

;;; 7
        lda #from
        ldy #to
        jsr copyreg_y2a

copyreg_y2a:
;;; 23 B
        sta savea
        sty savey

        ;; lo: rY -> rA
        lda 0,y
        ldy savea
        sta 0,y

        ;; hi: rY -> rA
        ldy savey
        lda 1,y
        ldy savey
        sta 1,y
        
        rts

;;; comma moves words from stack to ptr1
;;;   ptr1 advances
;;; 
;;; C: *ptr1= stack[x]; x+= 2; top+= 2;
;;;
;;; ccomma:
;;;   WARNING: stack is misaligned one byte!
;;; 
;;; 11+7= 18 B
_comma:
        jsr _ccomma
_ccomma:
        ldy #0
        lda stack,x
        sta (top),y
        inx

.proc _inc
;;; (7 B)
        inc top
        bne ret
        inc top+1
ret:    
        rts
.endproc


;;; building blocks
;;; 
;;; 20 B
;;; 
;;; ay= top
top2ay:        
        lda top
        ldy top+1
        rts
;;; top= ay
ay2top: 
        sta top
        sty top+1
        rts
;;; ptr1= ay
ay2ptr1:        
        sta ptr1
        sty ptr1+1
        rts
;;; ay= ptr1
ptr12ay:        
        lda ptr1
        ldy ptr1+1
        rts

comma:  
;;; 32B
        ;; ptr1= pop # 10
        lda top
        sta ptr1
        lda top+1
        sta ptr1+1
        inx
        inx

        ;; *ptr= pop # 15
        ldy #0
        lda stack,x
        sta (ptr1),y
        inx

        iny
        lda stack,x
        sta (ptr1),y
        inx

        ;; 
        jsr rinc2
        jmp pop

rinc2:  
;;; 12 B
        jsr rinc
rinc:   
;;; 9 B
        inc 0,y
        bne noinc
noinc:  
        inc 1,y
        rts
        
        

comma:  
;;; 8 + 13
;;;     + 4+13 (radda)  (+ 8 13 4 13) = 38 
;;;  OR + 3+12 (rinc2)  (+ 8 13 3 12) = 36
        jsr top2ay
        inx
        inx
        jsr ay2ptr
        
citer:   
;;; 13
        ;; *ptr1= *stack
        ldy #0
        lda stack,x
        sta (ptr1),y

        iny
        lda stack+1,x
        sta (ptr1),y
        
;;; 3 + 
        jsr pop
        (fall through to rinc2)
;;; 4
        lda #2
        ldy #ptr1
        jsr rinca
        (fall through to radda)
radda:  
;;; 13
        clc
        adc 0,y
        sta 0,y
        bcc noinc
        inc 1,y
        rts

rinc2:  
;;; 12 B
        jsr rinc
rinc:   
;;; 9 B
        inc 0,y
        bne noinc
noinc:  
        inc 1,y
        rts


;;; rcomma
;;; 
_rcomma:        
        

;;; 19B
_rcomma:        
        jsr _rbcomma
_rbcomma:       
        ldy #0
        lda stack+1,x
;;; writing wrong order bytes!
;;;  bakcwards
        dex
        
.proc _dec
        lda top
        bne ret
        dec top+1
ret:    
        dec top
        rts
.endproc


;;; TODO: is this just copy from one memory location
;;; to another???

.proc setnewcdr
        ldy #2
        jmp setnewcYr
.endproc

setnewcar:      
        ldy #0
.proc setnewcYr
        sta (lowcons),y
        txa
        iny
        sta (lowcons),y
        jmp pop
.endproc

;;; newcons -> AX address of new cons

;;; 
;;; 16B
;.ifdef USECONS
.proc newcons
        ;; lowcons-= 4
        sec
        lda lowcons
        sbc #04
        sta lowcons
        bcs nodec
        dec lowcons+1
nodec:  
        lda #<lowcons
        ldx #>lowcons
.endproc


;;; decw decrease zp word at Y by A
;.proc dec4w                     
;        clc
;        adc 0,y

;;; 14B + 4B load later
.proc dec4lowcons
        tay
        sec
        lda lowcons
        sbc #4
        sta lowcons
        bcs nodec
        dec lowcons+1
nodec:  
        tya
        rts
.endproc

;;; 16B
.proc newcons
        ldx lowcons
        lda lowcons
        tay

        sec
        sbc #4
        sta lowcons     
        bcs nodec
        dec lowcons+1
nodec:  
        tya
        rts
.endproc

;;; 

;;; 14B - 25c
.proc decw2
        pha

        lda lowcons
        sec
        sbc #2
        sta lowcons
        bcc nodec
        dec lowcons+1
nodec:  
        pla
        rts
.endproc

;;; 14B - 19c+
.proc decw2
        ldy lowcons
        bne nodec
        dec lowcons+1
nodec:  
        dey
        bne nodec2
        dec lowcons+1
nodec2: 
        dey
        sty lowcons
        rts
.endproc

;;; 13B - 16c
.proc decw2
        ldy lowcons
        cpy #2
        bcs noinc
        dec lowcons+1
noinc:  
        dey
        dey
        sty lowcons
        rts
.endproc
        
;;; 11B - slow 6+17=23c
decw2:  
        jsr decw
        ;; -- fallthrough


;;; 9B 17c
.proc decw
        ldy lowcons
        bne nodec
        dec lowcons+1
nodec:  
        dec lowcons
        rts
.endproc



.ifnblank
;;; TODO: no better only 1B
;;; 11B
.proc dup
        jsr write ; A
        txa       ; X
;;; ; WRONG a is lost...
write:  
        dec sidx
        lda sidx
        sta stack,y
        rts
.endproc
.endif


_dup:   
push:   
;;; This one would be smaller with recursive dup
;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack,y
        pla

        rts





;;; 4B 8c
dec foo
ldy foo

;;; 5B 8c
ldy foo
dey
sty foo

;;; 6B 13c
dec foo
dec foo
ldy foo

;;; 8B 10c
ldy foo
dey
dey
sta foo



_shl:   
;;; 8B 19c
        asl a
        stx savex
        ror savex
        ldx savex
        rts
_shl:   
;;; 7B 18c
        asl a
        tay
        txa
        ror a
        tax
        tay
        rts

_shr:   
;;; 8B
        stx savex
        lsr savex
        ror a
        ldx savex
        rts

_halve:
;;; 7B 
        tay
        txa
        lsr
        tax
        tya
        ror
        rts


garbage....
_dup:   
push:   
;;; 15B
        inc sidx
        inc sidx
        ldy sidx
        sta stack,y
        pha
        sta stack+1,y
        pla
        rts

;;; TODO:  generic
;;; _sta _dup

;_ror:  
        ;; ROR oper,x
;        ldy #$7e
;        bne gen
;;; HAHA no use, as it just need to change AX!


_sta:   
push:   
        ;; STA oper,x
        ldy #$9d
        ;; fall-through

gen:    
        sty op1
        sty op2
        ldy sidx
        dey
        dey

        pha
        txa

        pla
        
        sty sidx


;;; 17B ! specialized == 15B
gen:    
        sty genop
        pha
        txa
        jsr gen2                ; X
        pla
        ;; fall-through         ; A

gen2:    
        dec sidx
        ldx sidx
genop:  sta stack,x
        rts

;;; 15B
        inc sidx
        inc sidx
        ldy sidx
        sta stack,y
        pha
        sta stack+1,y
        pla
        rts



.ifnblank
;;; 13B 22c
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dey
        dey
        sta sidx
        rts
.endif

.ifnblank
;;; 13B 28c
ppop:   
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dec sidx
        dec sidx
        rts
.endif
.ifnblank
;;; 13B 22c
        ldy sidx
        lda stack,y
        ldx stack+1,y
        dey
        dey
        sta sidx
        rts
.endif

.ifdef OPT
;;; OPS that go from lobyte to hibyte
_adc:  
        ;; ADC stack,y
        clc
        ldy #$79
        bne mathop
_and:
        ;; AND stack,y
        lda #$39
        bne mathop

;;; cmp oper,y $d9 - can't use doesn't ripple

_eor:
        ;; EOR stack,y
        lda #$59
        bne mathop
_ora:
        ;; AND stack,y
        lda #$19
        bne mathop

;;; no ROL oper,y ????
;_rol:
;        ;; ROL stack,y
 ;       clc
  ;      lda #$


_sbc:   
        ;; SBC stack,y
        sec
        ldy #$f9
        bne mathop

        bne mathop

;;; Can't do as it's postdec???
;xxpush:
;xx_sta:   
;       ;; STA oper,y
;        lda #$99
;        bne mathop

pop:
_lda:   
        ;; LDA oper,y
        ldy #$b9
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP

;;; 22B - 32+2*18=68
mathop:
        sty op
        jsr write
        pha
        txa
        jsr write
        tax
        pla
        rts
write:
        ldy sidx
op:     adc stack,y
        inc sidx
        rts

;;;  mush faster! 1B MORE...
;;; 23B - 36C
mathop: 
        sty op1
        sty op2
        ldy sidx
op1:    adc stack,y
        pha
        txa
        iny
op2:    adc stack,y
        iny
        sty sidx
        tax
        pla
        rts

;;; too slow, doen't save bytes!
;;; 23B - 39+2*12=63
mathop:
        sty op
        ldy sidx
        jsr write ; A
        pha
        txa
        jsr write ; X
        tax
        sty sidx
        pla
        rts
write:
op:     adc stack,y
        iny
        rts


_plus:  
        clc
        ldx #$ff

;;; these are no top in AX

;;; 20B 58c
domath: 
        stx op
        jsr doone

doone:  
        ldy sidx
        lda stack,y
op:     adc stack+2,y
        sta stack+2,y
        inc sidx
        rts

_dup:   
push:   
;;; 16B
        ;; sidx -= 2
        ldy sidx
        dey
        dey
        sty sidx

        sta stack,y
        pha
        txa
        sta stack+1,y
        pla
        rts

;;; 14B
        ;; sidx--
        dec sidx
        ldy sidx

        sta lostack,y

        pha
        txa
        sta histack+1,y
        pla

        rts


_drop:  
pop:    
;;; 11B 21c
        ;; sidx++
        inc sidx
        ldy sidx

        lda lostack,y
        ldx histack+1,y

        rts

pop:    

;;; 13B 24c
        ;; sidx++
        ldy sidx
        iny
        iny
        sty sidx

        lda stack,y
        ldx stack+1,y

        rts

_sbc:   
        ;; SBC stack,y
        sec
        ldy #$f9
        bne mathop

;;; Can't do as it's postdec???
;xxpush:
;xx_sta:   
;       ;; STA oper,y
;        lda #$99
;        bne mathop

pop:
_lda:   
        ;; LDA oper,y
        ldy #$b9
        ;; fall-through

;;; self-modifying code
;;;   Y contains byte of asm "OP oper,y"
;;;   AX = AX op POP

;;; 22B - 32+2*18=68
mathop:
        sty op
        jsr write
        pha
        txa
        jsr write
        tax
        pla
        rts
write:
        ldy sidx
op:     adc stack,y
        inc sidx
        rts

;;;  mush faster! 1B MORE...
;;; 23B - 36C
mathop: 
        sty op1
        sty op2
        ldy sidx
op1:    adc stack,y
        pha
        txa
        iny
op2:    adc stack,y
        iny
        sty sidx
        tax
        pla
        rts

;;; too slow, doen't save bytes!
;;; 23B - 39+2*12=63
mathop:
        sty op
        ldy sidx
        jsr write ; A
        pha
        txa
        jsr write ; X
        tax
        sty sidx
        pla
        rts
write:
op:     adc stack,y
        iny
        rts

_plus:  
        clc
        ldx #$ff

;;; 21B
mathop: 
        sty op1
        sty op2
        ldy sidx

op1:    adc stack,y

        pha
        txa
op2:    adc stack+1,y
        tax
        pla

        iny
        iny
        sty sidx

        rts

;;; 19B
mathop: 
        sty op1
        sty op2

        ldy sidx
op1:    adc lostack,y
        pha
        txa
op2:    adc histack,y
        tax
        dec sidx
        pla
        rts

