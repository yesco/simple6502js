.ifdef FUNCALL
        ;; function call
        .byte "|%V()"
      .byte "%{"
        putc '!'
        putc '!'
        putc '!'
        IMM_RET
      .byte '['
        ;; lol, we need to quote JSR haha to have VAL0 used!
        DOJSR VAL0
      .byte ']'

.ifndef JSK_CALLING

;;; TODO: REMOVE!
;;;    this is just a prototype experiement
;;;    to get to RECURSIVE... keep for now

        ;; Function call!!!
        ;; TODO: for 0 args this still pushes, lol
        .byte "|%V[#]("
        .byte _W
      .byte "[;"
        DOJSR VAL0
;;; TODO: remove, use JSK_CALLING
;;; (this is C style where caller cleanup)
tya

pla
pla

pla
pla

pla
pla

pla
pla

tya
      .byte "]"

.else

;;; ========================================
;;;          JSK CALLING CONVENTION
;;; 
;;;       Calling "foo" with parameters
;;;  
;;;              jmp callfoo
;;;     
;;;  fooparams:  
;;;              ... eval first param => AX ...
;;; 
;;;              ;; push reverse
;;;              pha
;;;              txa
;;;              pha
;;; 
;;;              ... second param ...
;;;              pha
;;;              txa
;;;              pha
;;; 
;;;              ... last param, same ...
;;;              pha
;;;              txa
;;;              pha
;;; 
;;; 
;;;              ;; finally call "foo"
;;;              JMP foo
;;; 
;;; 
;;;  callfoo:    JSR fooparams
;;;              ... foo returns here! ...
;;; 
;;; 
;;;  foo:        
;;;              ldy #8            ; 4 params = 8 bytes
;;;              jsr save_old_regs
;;;                  (+ copy_new_params_to_regs)
;;; 
;;;              ... body foo ...
;;;   
;;;              ;; drop params
;;;              ldy #8
;;;              jmp drop_and_restore
;;; 

        ;; Function call!!!
        .byte "|%V[#]("
;.byte "%{"
;jsr puth
;IMM_RET
      .byte "["
        ;; jump to jsr
        jmp PUSHLOC
        ;; jsr will call here!
        .byte ":"
      .byte "]"

        ;; generate evaluating
        ;; and pushing parameters
        .byte _W

      .byte "["
        ;; JUMP to the function; return after JSR!
	;TODO:  DOJMP in future?
        .byte "?2"
        jmp VAL0
      .byte "]"


      .byte "["                  ; tos= dos
        ;; patch the jump to here
        .byte "?1B"

        ;; JSR to prepare parameters
        .byte ";"
        DOJSR VAL0
        ;; after FUN; it'll RTS to here!
      .byte ";;]"

;.byte "%{"
;PUTC '.'
;jsr _iasm        
;IMM_RET

.endif ; JSK_CALLING


.endif ; FUNCALL

