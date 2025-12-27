;;; memcpy.asm - collection of memcpy
;;; 
;;; Soma may be used by MeteoriC-compiler
;;; 
;;; 2025 (>) Jonas S Karlsson


;;; Copies memory from AX address (+2) to 
;;; destination address (first two bytes).
;;; String is zero-terminated.
;;; Zero termination not copied.

;;; TODO: rename, too general name
FUNC _memcpyz
;;; 16
        sta tos
        stx tos+1

        ldy #0
        lda (tos),y
        sta dos
        iny
        lda (tos),y
        sta dos+1

        iny
;;; if call here set Y=0
;;; TOS= text from (lol)
;;; DOS= destination
FUNC _copyz
;;; 16
        lda (tos),y
        beq @done
        sta (dos),y
        iny
        bne _copyz
        ;; y overflow
        inc tos+1
        inc dos+1
        ;; always
        bne _copyz
@done:       
        rts


.ifdef MEM1
FUNC _memcpy

;;; WORKS!

;;; memcopy smallest?
;;;   tos: FROM
;;;   dos: TO
;;;   AX:  0 <= LENGTH < 32K
;;; 
;;; Copies backwards - fast, but not good for overlap
;;; of FROM TO ranges...
;;; 
;;; - http://6502.org/source/general/memory_move.html
;;;   smallest is 33 B ?
;;; - cc65/libsrc/common/memcpy.s
;;;   ~31 B copies all in forward direction
;;; 
;;; jsk: 27 B
memcpy1: 
;;; 27 B  (+ 10 17)
        ;; copy X full pages first
        pha
        ldy #0
        jsr :+
        ;; copy A remaining bytes
        pla
        beq @done
        tay
;;; 17 B
:       
        dey
        lda (tos),y
        sta (dos),y
        tya
        bne :-
        ;; move to next page
        dex
        bmi @done
        inc tos+1
        inc dos+1
        bne :-
@done:
        rts
.endif ; MEM1
        
.ifdef MEM2
FUNC _memcpy

;;; jsk2: copy forwards
memcpy2: 
;;; 32 (+ 19 13)
;;; 19
        pha
        ;; copy X pages first
        ldy #0
@nextpage:
        dex
        bmi @pagesdone
@copypage:
        lda (tos),y
        sta (dos),y
        iny
        bne @copypage
        ;; move to next page
        inc tos+1
        inc dos+1
        bne @nextpage
@pagesdone:
;;; 13
        ;; assert: Y=0
        ;; copy A remaining bytes
        pla
        beq @done
        tax
@copyrest:
        lda (tos),y
        sta (dos),y
        iny
        dex
        bne @copyrest
@done:
        rts
.endif ; MEM2        

.ifdef MEM3
FUNC _memcpy

;;; jsk3: copies forward
;;; 26
memcpy3: 
        ldy #0
        ldx gos                 ; lo size
        inx ; ugly
@next:
        dex
        bne :+
        ;; more pages?
        dec gos+1
        bmi @done
:
        lda (tos),y
        sta (dos),y
        iny
        ;; page wrap after 256 bytes
        bne @next
        inc tos+1
        inc dos+1
        bne @next

@done:
        rts

.endif ; MEM3

.ifdef MEM4
FUNC _memcpy

;;; jsk4:
memcpy4: 
;;; 21 B - slow
        ldy #0
:       
        jsr _decG
        bmi @done
        lda (tos),y
        sta (dos),y
        jsr _incT
        jsr _incD
        jmp :-

@done:
        rts
.endif ; MEM4


MEM5=1

.ifdef MEM5
FUNC _memcpy
;;;  

;;; TODO: make better choosing mechanism

;;; CURRENT choosen one 
memcpy: 
        sta gos
        stx gos+1

;;; jsk5: copies forward CLEAN!
;;; assumes all parameters copied to
;;;   tos,dos,gos
memcpy5: 
;;; 26 B
        ldy #0
        ldx gos                 ; lo size
@next:
        bne :+
        ;; more pages?
        dec gos+1
        bmi @done
:
        lda (tos),y
        sta (dos),y
        iny
        ;; page wrap after 256 bytes
        bne :+
        inc tos+1
        inc dos+1
:       
        dex
        jmp @next

@done:
        rts
.endif ; MEM5


.ifdef MEM6
FUNC _memcpy

;;; jsk6: copies forwards
;;;   tos: from
;;;   dos: dest
;;;   gos: size > 0 (otherwise copy at least 1 byte)
;;; 
;;; 23 B
memcpy6:
;;; 23 (26) B
        ldy #0
        ldx gos                 ; lo size
;;; TODO: optional if SIZE > 0
;;;   otherwise copy at least one byte
;        jmp @test
@next:
        lda (tos),y
        sta (dos),y
        iny
        bne :+
        ;; page wrap after 256 bytes
        inc tos+1
        inc dos+1
:       
        dex
@test:
        bne @next
        ;; more pages?
        dec gos+1
        bpl @next

@done:
        rts
.endif ; MEM6

.ifdef MEMMAD
;;; - https://forums.atariage.com/topic/175905-fast-memory-copy/
;;; MADS (pascal?) example from D.W. Howerton?
;;; A= lo length, @length= hi length
;;; 26 B copies forwards
;;; 
;;; jsk BUG? always copies 1 byte at least
FUNC _memcpy
memcpyMAD:
.scope
        tax

.ifdef jsk ; 24 B
        beq nextpage
.else      ; 26 B
        bne start
        dec gos+1               ; it's needed?
.endif

start:
        ldy #0
move:   
        lda (tos),y             
        sta (dos),y
        iny
        bne next
        ;; wrap Y (inc page address)
        inc tos+1
        inc dos+1
next:   
        dex
        bne move
nextpage:       
        dec gos+1
        bpl move

        rts        ; done
.endscope

.endif ; MEMMAD
