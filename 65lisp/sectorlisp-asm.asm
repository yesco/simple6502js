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

;;; 12     002c-0037 - begin
;;; 22     0038-004d - main
;;; 30     004e-006b - GetToken
;;; 30     006c-0086 - PrintList
;;; 27     0087-0092 - PutObject/PrintString/PrintAtom
;;; 49     0093-00b8 - GetObject/Intern

;;;  3     00b9-00bc - GetChar
;;; 14     00c7-00c8 - PutChar \r \n

;;;  2     00c9-00e0 - PairLis
;;; 24     00e1-00f0 - EvLis
;;; 16     00f1-00fc - xCons/Cons
;;; 12     00fd-0115 - Gc
;;; 25     0116-012a - GetList
;;; 21(57) 012b-0163 - Apply
;;;  5      130- 13b -   .lambda
;;; 12      13c- 142 -   .switch
;;;  7      143- 146 -   .ifCar
;;;  4      147- 14a -   .ifCdr
;;;  4      14b- 152 -   .ifAtom
;;;  8      153- 155 -   .retF
;;;  3      156- 15c -   .ifCons
;;; 11      161- 163 -   .retT

;;; 10     0164-016d - Assoc
;;; ==> 45 (+ 35!)
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
        sta (here),y
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

