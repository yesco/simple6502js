.ifdef MINIMAL
;;; Just save (TODO:push?) AX
;;; TODO: remove!!!!
ruleU:
      .byte '['
        jsr _SAVE
      .byte ']'
        .byte 0
.endif

;;; ----------------------------------------

.ifdef MINIMAL

;;; TODO: _U used elsewhere...
        .byte "|+",_U
      .byte '['
        jsr _PLUS
      .byte ']'
        .byte TAILREC

        .byte "|-",_U
      .byte '['
        jsr _MINUS
      .byte ']'
        .byte TAILREC

        .byte "|&",_U
      .byte '['
        jsr _AND
      .byte ']'
        .byte TAILREC

        .byte '|',"\|",_U
      .byte '['
        jsr _OR
      .byte ']'
        .byte TAILREC

        .byte "|^",_C
      .byte '['
        jsr _EOR
      .byte ']'
        .byte TAILREC

        .byte "|/2%b"
      .byte '['
        jsr _SHR
      .byte ']'
        .byte TAILREC

        .byte "|\*2%b"
      .byte '['
        jsr _SHL
      .byte ']'
        .byte TAILREC

;;; ==

        .byte "|==",_U
      .byte '['
        jsr _EQ
      .byte ']'
        .byte TAILREC

        ;; Empty
        .byte '|'


.else ; !MINIMAL


.endif ; !MINIMAL
