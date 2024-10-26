
jsr abc
jsr def
jsr ghi

;;; interpreted
        ;; ENTER
code:   tya
        pha
        ldy #04                 ; newip+4 == bytes!
        ;; stack: <caller> Y
        jsr reinst              ; returns to caller of code. hmmm

reinst: jsr install
        jsr interpret
        jmp reinst
        ;;  calls other interpreted words
bytes:  x
        y
        z
        ^ -> we want it to return to
        
install:  
        sta aa

        ;; install new main ip
        pla
        sta ip+1
        pla
        sta ip

        lda aa
        rts
        


@each code
        ;; 13B 18c
selfinstall:                    
        lda 
        sta ip
        lda
        sta ip+1
        pla
        tay
        jmp next

enter:  
        ptr1= destination address
        phy
        lda
        pha selfinstallhi
        lda
        pha selfinstalllo
        jmp (ptr1)

ptr1:   user stuff
        rts 
        ;;  jumps back to selfinstall


;;; fast dispatch NEXT=18c DOCOL=30c EXIT=15c save AX in docol=10c   (sub +45c+10c save)
;;; fast dispatch NEXT=18c DOCOL=28c EXIT=15c save AX in docol=10c   (sub +43c+10c save)
;;;(fast dispatch NEXT=15c DOCOL=38c EXIT=14c ) NO SAVE AX index w Y TRASHES A Y ....
;;;(His 6502: NEXT=23c overhead, ENTER=34c, EXIT=15c (subroutine +49c))
;;; Mine:     NEXT=20c           ENTER=33c, EXIT=12c (subroutine +45c)

        ;; 30c + 10c save
docolon:  
        sta xaa+1               ; save 3c
        stx xxx+1               ; save 3c

        ;; put on stack by JSR self+3 in all prim/user code!
        ;; swap RET on stack with IP!
        tsx                     ; 2c
        ldy 102,x               ; 4c
        lda xip+2               ; 3c
        sty xip+2               ; 3c
        sta 102,x               ; 4c

        ldy 101,x               ; 4c
        lda xip+1               ; 3c
        sty xip+1               ; 3c
        sta 101,x               ; 4c

xxx:    ldx #ff                 ; save 2c
xaa:    lda #ff                 ; save 2c

        ;; 28c + 10c save
docolon:  
        sta aa
        stx xx

        ;; put on stack by JSR self+3 in all prim/user code!
        ldy xip+2               ; 3c
        pla                     ; 3c
        sta xip+2               ; 3c

        ldx xip+2               ; 3c
        pla                     ; 3c
        sta xip+1               ; 3c

        tya                     ; 2c
        pha                     ; 3c
        txa                     ; 2c
        pha                     ; 3c

        ldx xx
        lda aa
        
        ;; 18c
next:   inc ip                  ; 5c
        beq overflow...         ; 2c+1c...
xip:    ldy $ffff               ; 4c
        sty xjmp+1              ; 3c
xjmp:   jmp ($ff00)             ; 5c


        ;; 15c
exit:   
        pla                     ; 3c
        sta xip+1               ; 3c
        pla                     ; 3c
        sta xip+2               ; 3c
        
        jmp next                ; 3c




;;; fast dispatch NEXT=15c DOCOLON=38c EXIT=14c

;;; BUT: Y needs to be "untouched"/saved
;;; BUT: A is destroyd (contains token)

        ;; 38c
docolon:  
        sty yy                  ; 3c

        ;; put on stack by JSR self+3 in all prim/user code!
        pla                     ; 3c
        sta xip+2               ; 3c
        pla                     ; 3c
        sta xip+1               ; 3c

        ;; save current token
        lda xjmp+1              ; 3c
        pha                     ; 3c
        ;; save local ip
        lda yy                  ; 3c
        pha                     ; 3c
        
        ldy #$00                ; 2c - iny->one byte after JSR!
        
        ;; 15c
next:   iny                     ; 2c
xip:    lda ($ffff),y           ; 5c
        sta xjmp+1              ; 3c
xjmp:   jmp ($ff00)             ; 5c
        

        ;; 14c
exit:   
        ;; return to prev local ip
        pla                     ; 3c
        tay                     ; 2c
        ;; return to prev token
        pla                     ; 3c
        sta xip+1               ; 3c
        
        jmp next                ; 3c
        

        

next:   
        ldy yy                  ; 3c
        ;; jump here if y has right value
        ;; 20c
nexty:  
        iny                     ; 2c
        sty yy                  ; 3c
        
xip:    lda ($ffff),y           ; 5c
        bmi enter               ; 2c+1c
        
        sta xjmp+1              ; 3c
xjmp:   jmp ($ff00)             ; 5c

        ;; 21c
enter:
        ;; store token
        pha                     ; 3c
        sta xaddr+1             ; 3c

        tya                     ; 2c
        pha                     ; 3c

        ldy #$00
xaddr:  lda ($ff00),y           ; 5c
        pha
        


;;; compare with END of 
;;; His 6502: NEXT=23c overhead, ENTER=34c, EXIT=15c (subroutine +49c)

;;; Mine:     NEXT=20c           ENTER=33c, EXIT=12c (subroutine +45c)
;;;   (maybe should count store and restore A tay tya?)

;;; cc65 65vm => 60c NEXT ...

;;; SELF-MODIFYING CODE ZERO PAGE
;;;  subroutine next, so that prim can return with RTS!

        ;; WOZ-trick from SWEET-16 to allow prim to return by RTS intead of JMP next
snext:  jsr next                ; 6c
        jmp snext               ; 3c

        ;; just to do jsr lol
jjsr:   jmp next                ; 3c (+ 3c JMP exit)

;; enter: 12c + 18c + 3c = 33c
;; exit:                   12c (code exits with jmp exit + 3c)
;;;                  TOTAL 45c (+ 3c)
enter:
        ;; 12c store current IP to continue after "EXIT"
        lda xip+2               ; 3c
        pha                     ; 3c
        lda xip+1               ; 3c
        pha                     ; 3c

        ;; 18c set new IP from SUBVEC
xenter: lda ($ff00),y           ; 5c
        sta xip+1               ; 3c
        iny                     ; 2c
        lda ($ff00),y           ; 5c
        sta xip+2               ; 3c

;;; 1)
        jmp next                ; 3c (+ 3c JMP exit)
;;; 2)
        jsr jjsr                ; 6c (+ 6c JMP exit)

        ;; token subroutines need to jmp exit
exit:   
        ;; 12c pull IP to interpret
        pla                     ; 3c
        sta xip+2               ; 3c
        pla                     ; 3c
        sta xip+1               ; 3c

        ;; next token: 7c + 5c + 8c = 20c (1/256 + 9c)
next:   inc xip+1               ; 5c
        beq xover               ; 2c

xip:    ldy $ff00               ; 3c    ;; +2c if not ZP
        bmi enter               ; 2c
                                   
        sty xjmp+1              ; 3c
xjmp:   jmp ($ff00)             ; 5c    ;; +2c if not ZP
        

xover:  inc xip+2               ; 5c
        jmp xip                 ; 3c




;;;

        ;; enter: 3c + 10c + 12c + 5c = 30c
        ;; exit: 12c (+6c rts)        TOTAL 32c + (6c rts)
enter:
        sta xjsr+1              ; 3c

        ;; 10c address to return to   
        lda #>(EXIT-1)          ; 2c
        pha                     ; 3c
        lda #<(EXIT-1)          ; 2c
        pha                     ; 3c
        
        ;; 12c data IP to return to
        lda xip+2               ; 3c
        pha                     ; 3c
        lda xip+1               ; 3c
        pha                     ; 3c

xjsr:   jmp ($ff00)             ; 5c

        ;; magically returns here
exit:   
        ;; 12c pull IP to interpret
        pla                     ; 3c
        sta xip+2               ; 3c
        pla                     ; 3c
        sta xip+1               ; 3c

        ;; next token: 7c + 5c + 5c = 17c
next:   inc xip+1               ; 5c
        beq xover               ; 2c

xip:    lda $ff00               ; 3c
        bmi enter               ; 2c

        jmp ($ff00)             ; 5c
        
xover:  inc xip+2               ; 5c
        jmp xip                 ; 3c



;;; stack 23c

next:   
        lda #ff                 ; 2c hi byte of call
        pha                     ; 3c

        inc xip+1               ; 5c 
xip:    lda $ffff               ; 4c -> W == A
        pha                     ; 3c
        rts                     ; 6c
        

;;; simple 19c

next:   
        inc xip+1               ; 5c 
        beq ...                 ; 2c
xip:    ldy $ffff               ; 4c -> W
        
        sty xjmp+1              ; 3c
xjmp    jmp ($ff00)             ; 5c jp (W)
        

;;; Y-token dispach

        ;; 21c + 3c jmp next
next:
        inc yy                  ; 5c
        ldy yy                  ; 3c

        lda (code),y            ; 5c
        sta xip+1               ; 3c
xip:    jmp ($ff00)             ; 5c


        ;; 18c + 3c jmp next
next:   
        inc xcode+1             ; 5c
        beq hiinc               ; 2c
        
xcode:  lda code                ; 3c
        sta xip+1               ; 3c
        jmp ($ff00)             ; 5c




;;; Token dispatch, with lookup

again:  jsr next                ; allow routine to RTS or JMP NEXT!
        jmp again               ; (from Woz SWEET-16)

        ;; 5+2 + 3+3+5 == 18c if moved to zeropage, otherwise +2c
next:
        inc xip+1               ; 5c
        beq hiinc               ; 2c instead of 3!

xip:    lda $ffff               ; 3c
        sta xjp+1               : 3c
xjp:    jmp ($ffff)             ; 5c jmp ($ffff,y)


hiinc:  inc xip+2               ; 5c once in a full moon
        bne xip                 ; 3c


;;; brk tooken dispatch!

interrupt:
        pha
        txa
        pha

        tsx
        lda $103,x
        and #$10                ; B set?
        beq intorig

        lda $104,x              ; lo
        sec
        sbc #1
        sta tmp
        lda $104,x
        sbc #0
        sta tmp+1

        ldy #0
        lda (tmp),y             ; 45c till here... lol
        
        ;; have token, if we wan token, can dispatch... lol

        jmp (tmp)               ; return



;;; here is another variant BRK xx yy == JSR (xx yy)

JSRi:   
        sta tmpa                ; not reenetrant... hmmm
        pla
        pha
        and #10
        lda tmpa
        beq origint

        plp
        stx tmpx

        ;; from here 18c
        tsx
        inx
        stx xjmp+1              ; self modifying code

        ldx tmpx
        lda tmpa
xjmp:   jmp ($01ff)             ; 49c JSR () lol 


interrupt:
        sta tmpa                ; 3c ;; total 13c+1c
        pla                     ; 3c
        pha                     ; 3c
        and #07                 ; 2c
        beq intorig             ; 2c+1c
        
        ;; ok, we have BRK 
        
        pla                     ; 3c drop
        stx tmpx                ; 3c 
        tsx                     ; 2c
        lda $102,x              ; 4c lo ret
        sta tmp                 ; 3c
        lda $103,x              ; 4c hi ret
        sta tmp+1               ; 3c
        ldy 0                   ; 2c
        lda (tmp),y             ; 5c
        sta tmp2                ; 3c
        lda (tmp),y             ; 5c
        sta tmp2+1              ; 3c

        ;; restore x a
        ldx tmpx                ; 3c
        lda tmpa                ; 3c
        php                     ; 3c 
        rti                     ; 7c the pointer is one byte after BRK tok <here>
        
        ;; not BRK
intorig:
        lda tmpa
        jmp (origvec)


;;; First attempt playground for a "page"(sized)lisp

next:
        iny                     ; 2
xip:    ldx $ffff,y             ; 4* LDX <IPWORD> self modify
        txs                     ; 2  dispatch!
        php                     ; 3  (but it needs P reg to pull:)
        rti                     ; 7  rti jumps exactly the address
                                ; = 27 cycles

user:   
        ldx STK                 ; 6 bytes :-(
        txa
        brk                     ; ENTER! lol
        db $ff
        db 1,2,3,4,5,6,7        ; byte code
        db 0                    ; exit

enter:                          ; on stack is address of byte code!
        sta tmpa

        pla
        sta tmplo
        pla
        sta tmphi

        tya
        pha                     ; push y (local ip)

        lda xip+2               ; push hi ip
        pha
        lda xip+1               ; push lo ip
        pha

        lda tmplo
        sta xip+1
        lda tmphi
        sta xip+1
        
        tsx
        stx STK

        lda tmpa
        jmp next

exit:   

