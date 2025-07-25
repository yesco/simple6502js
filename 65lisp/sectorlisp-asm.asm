;;; SectorLisp with orig as guide!

;;; Yet another start,


;;; ========================================
;;;                 C O N F I G

;TRACE=trace

;;; Applies to the "sectorlisp"
;;; (it has no numbers, even == atom, odd == cons)
;;; 

;;;                 C O N F I G
;;; ========================================

;;; See template-asm.asm for docs on begin/end.asm
.include "begin.asm"


;;; ========================================
;;;                  M A I N

;;; CONFIG OF MEMORY

;;; "heap"
HEAPSIZE= 1024
;;; "cons" heap
CONSSPACESIZE= 1024*32

HERESTART= endaddr
LOWCONSSTART= ((endaddr+HEAPSIZE+CONSSPACESIZE)/4)*4

_NOP_=$ea

;;; ========================================

.zeropage

ptr1:   .res 2
ptr2:   .res 2

env:    .res 2

.code

.macro SKIPONE
        .byte $24               ; BITzp 2 B
.endmacro

.macro SKIPTWO
        .byte $2c               ; BITabs 3 B
.endmacro


;;; ========================================
;;; START
FUNC _start

;;; sectorlisp.asm - analysis

;;; - https://justine.lol/sectorlisp2/sectorlisp.lst.html

;;; 44 B   0000-002b - NIL\0...
;;; ==> 44B
        jmp skipper

;;; Cannot do the sectorlisp trick as these goes astray
kNil:   .byte "NIL",0
kT:     .byte "T",0
kQuote: .byte "QUOTE",0
kCond:  .byte "COND",0
        .byte 0                 ; pad to odd addr
kAtom:  .byte "ATOM",0
        .byte 0                 ; pad to odd addr
kCar:   .byte "CAR",0
kCdr:   .byte "CDR",0
kCons:  .byte "CONS",0
        .byte 0                 ; pad to odd addr
kEq:    .byte "EQ",0

skipper:        
putc '-'

halt:   jmp halt

;;; 12     002c-0037 - begin - "BOOT"
;;; ==> 3
_boot:  
        ldx #$ff
        txs
        
;;; 22     0038-004d - main - "ReadEval-loop"
;;; ==> 22!
_readeval:      
        lda #'\n'
        jsr putchar
        lda #'>'
        jsr putchar

        jsr read
        jsr eval
        jsr print

        jmp _readeval

;;; 30     004e-006b - GetToken
;;; ==> 32, TODO: doesn't handle ungetc/lookup/restore
;;; Y is length (may be 0)
_read:  
        ;; peek
        lda unc
        cmp #'('
        beq _readlist
        ;; atom
        lda here
        and #1
        inc here
nowaligned:     
        ldy #0
rdloop: 
        jsr getchar
        cmp #')'+1
        bcc rdend 
        sta (here),y
        iny
        jmp redloop
rdend:  
        lda #0
        sta (here),y

        ;; TODO: advance here if not found?
        rts
        
        
;;; 30     006c-0086 - PrintList
;;; ==> 32 (not printing ".X")
_prinlist:     
;;; (assumes A is in Y!)
        lda #'('
        jsr putchar
        ;; push
_prrest:        
        tya
        pha
        txa
        pha
        tya

        jsr car
        jsr prin1
        ;; pop
        pla
        tax
        pla

        jsr cdr
        tay
        ror
        bcc _prrest

_endlist:       
        ;; TODO: (a . X) X!=nil print...
        lda #')'
        jmp putchar

;;; 27     0087-0092 - PutObject/PrintString/PrintAtom
;;; ==> 19 (!)
_prin1:
        tay
        ror
        bcs _prinlist
        ;; atom
        tya
        ;; just set ptr1
        jsr _car 
        ;; (y==0)
_prstr: 
        lda (ptr1),0
        beq ret
        jsr putchar
        iny
        bne _prstr
ret:
        rts
        
;;; 49     0093-00b8 - GetObject/Intern

;;;  3     00b9-00bc - GetChar
;;; 14     00c7-00c8 - PutChar \r \n

;;;  2     00c9-00e0 - PairLis
;;; TODO: not reqcurse on PairLis?
;;; 24     00e1-00f0 - EvLis
_evalist:       
        eqnil
        bnil rts

        jsr eval
        ...
        jsr _evallist
        ;; fall-trough - jsr _cons

;;; 16     00f1-00fc - xCons/Cons
;;; ==> 22
_cons:  
;;; (+ 3 19) = 22
        jsr rcomma               ; cdr first?
        ;; 2nd fall-through

.ifnblank
rcomma:  
;;; 22
        ldy #0
        sta (chere),y
        iny
        txa
        sta (chere),y

        ;; chere -= 2
        ldx chere+1
        lda chere
        pha
        sec
        sbc #2
        bcs nodec
        dec chere+1
nodec:  
        pla
        rts


rcomma: 
;;; 24
        pha
        txa
        pha

        ldy #0

        jsr bcomma
        ;; 2nd fall-through
bcomma: 
        lda chere
        bne nodec
        dec chere+1
nodec:  
        dec chere

        pla
        sta (chere),y
        
        lda chere
        ldx chere+1
        rts
        
.endif

rcomma: 
;;; 19 !!!
        ldy cherey
        dey
        ;; no underflow as it starts at end of page?
        ;; (TODO: hmm, strange align)
        sta (chere),y
        dey
        bne nodec
        dec chere+1
nodec:  
        txa
        sta (chere),y
        sty cherey

        tya
        ldx chere+1
        rts
        

;;; 12     00fd-0115 - Gc
;;;   TODO: I don't understand the ABC GC
;;;   (bad description?)
;;; 25     0116-012a - GetList
;;; ==> 20
_readlist:      
        ;; peek
        lda unc
        cmp #')'
        beq rdend
        
        jsr read
        ;; TODO: '.'
        jsr _readlist
        jmp _cons
rdend:  
        lda #<kNil
        ldx #>kNil
        rts

;;; 10     0164-016d - Assoc
;;; ==> 45 (ie. + 35 :-()
_assoc:
;;; itstart
;;; (11)
        sta ptr2
        stx ptr2+1
        jsr _car
        sta ptr1
        stx ptr1+1

        ;; reverse AX
        pla                     ; lo
        tax                     
        pla                     ; hi
        pha

        ;; (eq (car ptr1))
        ldy #1
        cmp (ptr1),y
        bne nassoc
        txa
        dey
        cmp (ptr1),y
        beq eqass
nassoc:
        txa
        pha

;;; itnext
;;; (7)
        lda ptr2
        ldx ptr2+1
        jsr _cdr

        jmp _assoc
        
eqass:  
        pla
        lda ptr2
        ldx ptr2+1
        rts
        

;;;  3     016e-0170 - Cadr - overlap fallthrough...
;;; ==> 4 B (+1)
_cadr:  
        jsr _cdr
        SKIPTWO

;;;  1     0171-0171 - Cdr
;;; ==> 3 B (+2)
_cdr:   
        ldy #3
        SKIPTWO

;;;  5     0172-0176 - Car
;;; ==> 13 B (+7)
_car:   
        ldy #1
        sta ptr1
        stx ptr1+1
        lda (ptr1),y
        tax
        dey
        lda (ptr1),y
        rts
        
;;; 17     0177-0187 - EvCon
;;; ==> 
;;; 47     0188-01b7 - Eval
;;; ==> 

;;; (+ 21 21 15 18 15) = 90
;;; sectorlisp: eval 47, evcon 17, apply: 57
;;; (+ 47 17 57) = 121 (more than 6502???)

_eval:  
;;; (21)
        tay
        ror
        bcc iscons
        tya
        ;; is atom, lookup value
        jsr callassoc
        jmp cdr

callassoc:      
        pha
        txa
        pha

        lda env
        ldx env+1
        jmp _assoc
        
iscons: 
;;; (21)
        tya
        pha
        txa
        pha
        tya
        
        ;; fun
        jsr _car
        
        ;; prim?
        cpx #>kNil
        bne notprim
        ;; now only need compare low byte
        tay
        
        ;; no-eval "special forms"
        cpy #<kQuote
        beq _quote
        cmp #<kCond
        beq _cond
        
        ;; eval args
;;; (15)
        sty savey
        pla
        tax
        pla
        tay

        lda savey
        pha

        tya
        jsr _evalargs
        
        sta savea

        ;; get lo fun atom
        pla
        tay

        lda savea
        
        ;; two args
        cpy #<kCons
        beq _cons

        cpy #<kEq              
	bne noteq
        ;; eq
        ...


;;; 21(57) 012b-0163 - Apply
;;;  5      130- 13b -   .lambda
;;; 12      13c- 142 -   .switch
;;;  7      143- 146 -   .ifCar
;;;  4      147- 14a -   .ifCdr
;;;  4      14b- 152 -   .ifAtom
;;;  8      153- 155 -   .retF
;;;  3      156- 15c -   .ifCons
;;; 11      161- 163 -   .retT
        ;; call prims
;;; (18)
noteq:  
        cpy #<kCar
        beq _car
        cpy #<kCdr
        beq _cdr

        ;cpy #<kAtom
        ;bne natom:
        ;; atom
        pla
        tax
        pla
        
        ...
        rts



notprim:
;;; (15)
        jsr _eval
        pha
        txa
        pha
        jsr _evalargs
apply:  
        pla
        tax
        pla
;       jmp _apply

;;; 71     01b8-01ff - fill! (name)


.ifnblank
        putc 'L'
        putc '1'
        putc 's'
        putc 'p'
        NEWLINE
.endif

;;; INIT
;;; 22 bytes already, make constants range and memcopy!

.ifnblank
        NEWLINE
        putc 'E'
        putc 'N'
        putc 'D'
.endif

;;; Or we could say this is up to the user app?
;;; 
;;; 4 (+1 DIS) (+3 LISPINIT)
.ifdef BOOT
boot:   

        ;; disable interrupts
.ifdef DISABLEINTERRUPTS
        sei
.endif
        ;; init hardware + data stack
        ldx #$ff
        txs

        ;;  init 0:es
.ifdef UNC
        inx
        sta unc
.endif ; UNC
        
        ;; init your "app"

.ifdef LISPINIT
        jmp _l1spinit
.else

        rts
.endif

.endif ; BOOT

;;; ----------------------------------------



;;; ========================================
;;; enable this JUST to get 1st page SIZE
;.ifnblank

endfirstpage:   
secondpage:
bytecodes:      
_l1spinit:      
_readeval:      
_nil_:  
.include "end.asm"
.end







.include "end.asm"
.end

.endif


secondpage:

.ifdef READERS

;;; ------ compare asmlisp-asm.asm
;;;  (put asm reader) 76 bytes...
;;; 
;;; READ:               = 80++    434
;;;   getc     12  (+ 12 8 19 19 22) = 80
;;;   skipspc   8
;;;   readatom 17 xx 19
;;;   read     17 xx 19
;;;     findsym  ??    
;;;   readlist 22

;;; (+ 12 8 10) = 30 ; _getc _skipspc _atomchar
;;;  we haven't even started on reader
;;; 
;;; _read (bytecodes) createatom rdatom rdatomend rdlst
;;; (+ 4 7 14 21) = 46
;;; 
;;; TOTAL: (+ 30 46) = 76 ...

        
;;; skips spaces
;;; 
;;; Returns:
;;;   A= peek at next key
;;; 
;;; To consume the key call _key
;;;   OR set unc=0
FUNC _skipspc
;;; 8
        jsr _key
        cmp #' '+1
        bcc _skipspc
        sta unc
        rts

;;; _atomkey: reads an atom valid char
;;;    (any other character is "put back")
;;; 
;;; Returns:
;;;   C is set if is valid char
;;;   A: char in register A
;;; 
FUNC _atomkey
;;; 12
        jsr _key
        cmp #')'+1
        bcs ret
notvalid:       
        sta unc
        lda #0
ret:    
        rts

;;; readsatom: Reads an atom of valid chars.
;;; 
;;; Result:
;;;   String read is stored at memory here+4.
;;;   It may be empty. Y is length + 4.
;;; 
;;;   Y>4 means an atom skring was read
;;;   or if mem[here+4] is set.
;;; 
;;; After:
;;;   A=0 Z=1

FUNC _readatomstr
;;; 11 - 6/7 B as bytecode?
;;;             _atomkey _dup _ccomma _jz xx _semis
rdloop: 
        ;; This also zero terminates as last char returned
        ;; is zero
        jsr _atomkey
        pha
        jsr _ccomma             ; TODO!?
        pla
        bne _readatom
        rts

FUNC _readatomstr
;;; 14
        jsr _skipspc
        ldy #3
valid:  
        iny
        jsr _atomkey
        ;; automatically zero terminates!
        sta (chere),y
        bne valid
        rts

_read:  
;        DO _readatomstr
        DO _dup
        JZ notatom
        DO _dup
;        DO _findatom
        JZ notfound
found:  
        DO _semis
notfound:       
        ;; create
;        ... (wrote before)
        
notatom:
;        ... readlist


.endif ; NEWREADERS



.include "end.asm"

.end
.endif


;;; sectorlisp.asm - analysis

;;; - https://justine.lol/sectorlisp2/sectorlisp.lst.html

;;; 44 B   0000-002b - NIL\0...
;;; ==> 44
;;; 12     002c-0037 - begin
;;; ==> 3
;;; 22     0038-004d - main
;;; ==> 22
;;; 30     004e-006b - GetToken
;;; ==> 32
;;; 30     006c-0086 - PrintList
;;; ==> 32
;;; 27     0087-0092 - PutObject/PrintString/PrintAtom
;;; ==> 19
;;; 49     0093-00b8 - GetObject/Intern
;;;  3     00b9-00bc - GetChar
;;; 14     00c7-00c8 - PutChar \r \n
;;;  2     00c9-00e0 - PairLis
;;; 24     00e1-00f0 - EvLis
;;; 16     00f1-00fc - xCons/Cons
;;; ==> 22
;;; 12     00fd-0115 - Gc
;;; 25     0116-012a - GetList
;;; ==> 20
;;; 21(57) 012b-0163 - Apply
;;; ==> see eval (+ 15 18 15 ...) = 48
;;;  5      130- 13b -   .lambda
;;; 12      13c- 142 -   .switch
;;;  7      143- 146 -   .ifCar
;;;  4      147- 14a -   .ifCdr
;;;  4      14b- 152 -   .ifAtom
;;;  8      153- 155 -   .retF
;;;  3      156- 15c -   .ifCons
;;; 11      161- 163 -   .retT
;;; 10     0164-016d - Assoc
;;; ==> 45
;;;  3     016e-0170 - Cadr - overlap fallthrough...
;;; ==> 3
;;;  1     0171-0171 - Cdr
;;; ==> 3
;;;  5     0172-0176 - Car
;;; ==> 13
;;; 17     0177-0187 - EvCon
;;; 47     0188-01b7 - Eval
;;; ==> (+ 21 21 15) = 57
;;; 71     01b8-01ff - fill! (name)
