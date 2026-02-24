.macro GOTO addr
        .byte "%R"
        .word addr
.endmacro


ruleE:
        .byte "%?",5,"Expr",10
        .byte "(",_E,")",_D
        

        .byte "|"
assignment:     
        .byte "%V="
        .byte "%!=",$80
        .byte "[#]",_E
      .byte "[;"
        sta VAR0
        stx VAR1
      .byte "]"


        .byte "|"
unary:  
        .byte "%d",_D
        .byte "|%D",_D
        .byte "!(",_E,")",_D
        .byte "|!%V",_D
        .byte "|&%V",_D
        .byte "|++%V",_D
        .byte "|--%V",_D
        .byte "|%V++",_D
        .byte "|%V++",_D
        .byte "|%V--",_D
        .byte "|%V",_D

;;; Not needed anymore?
ruleC:  
        .byte 0



ruleD:

multiply:       
        .byte "\*2"
        GOTO multiply

        .byte "|/2"
        GOTO multiply

        .byte "|\*%D"
        GOTO multiply

        .byte "|\*%V"
        GOTO multiply

        .byte "|"
add:    
        .byte "+%d"
        GOTO add

        .byte "|+%D"
        GOTO add

        .byte "|+%V"
        GOTO add

        .byte "|-%D"
        GOTO add

        .byte "|-%V"
        GOTO add

        ;; Done/nothing
        .byte "|"
.byte "%{"
putc '$'
IMM_RET        
        
        .byte 0


;; | `(... , ...)`	| Parenthesis
;; | `++ -- ! -`   | Unary (one arg) |
;; | `* / %`	| Multiplicative |
;; | `+ -`         | Additive |
;; | `<< >>`       | Shift |
;; | `< > <= >=`   | Relational |
;; | `== !=`       | Equality |
;; | `&`           | Bitwise AND |
;; | `^`           | Bitwise XOR |
;; | `|`           | Bitwise OR |
;; | `&&`          | Logical AND |
;; | `||`          | Logical OR |
;; | `+= -+ /+ *= <<= >>=` | Assignment Modifier |
;; | `=`           | Assignement

;; ### Complex

;; Can be any of:
;; ```
;; (...)
;; array[...]
;; ptr[...]
;; variable
;; 0xf00d
;; 4711
;; 'c'

;;    OR

;; ++variable --variable variable-- variable++
;; variable= ...

;;    These are special as they are very efficient

;; variable+= bytevalue;
;; variable-= bytevalue;

;; variable<<= simple;
;; variable>>= simple;
