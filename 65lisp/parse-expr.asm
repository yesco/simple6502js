;;; This is "full" rules of preceedened as BNF
;;; for the C language.
;;; 
;;; Part of MeteoriC C-compiler project.
;;; 
;;; jsk: It's been rewritten with the parse-asm.asm
;;;      BNF parser grammar.
;;; Limitations:
;;;      when an subrule has generated code,
;;;      the code isn't removed if upper rule fail!
;;;      (unless (not implemented) prefixed by "%",_rule)



;;; 15. Comma Operator (Lowest Precedence)
;<expression>
rule_a:
        .byte _b,",",TAILREC
        .byte 0

;;; TODO: use this level for arguments to function calls!

;;; 14. Assignment Operators (Right-to-Left)
;<assignment_expr>
rule_b:  
        .byte _d
        ;; <unary_expr> <assignment_op> <assignment_expr>
        ;; TODO: unary gives L-value?
        ;;   probably add special rules?
        .byte "|",_o,"=",_b
        .byte "|",_o,"+=",_b
        .byte "|",_o,"-=",_b
        .byte "|",_o,"*=",_b
        .byte "|",_o,"/=",_b
        .byte "|",_o,"%=",_b
        .byte "|",_o,"<<=",_b
        .byte "|",_o,">>=",_b
        .byte "|",_o,"&=",_b
        .byte "|",_o,"|=",_b
        .byte "|",_o,"&=",_b
        .byte "|",_o,"^=",_b
        .byte 0

;;; 13. Ternary Conditional (Right-to-Left)
;<conditional_expr>
rule_d:  
        <logical_or_expr> 
        | .byte _e,"?",_a,":",_d

;;; 12. Logical OR
;logical_or_expr>
rule_e: 
        <logical_and_expr>
        | <logical_or_expr> "||" <logical_and_expr>

;;; 11. Logical AND
;<logical_and_expr>
rule_f: 
        <inclusive_or_expr>
        | <logical_and_expr> "&&" <inclusive_or_expr>

;;; 10. Bitwise Inclusive OR
;<inclusive_or_expr>
rule_g: 
        <exclusive_or_expr>
        | <inclusive_or_expr> "|" <exclusive_or_expr>

;;; 9. Bitwise Exclusive OR
;<exclusive_or_expr>  ::=
rule_h: 
        <and_expr>
        | <exclusive_or_expr> "^" <and_expr>

;;; 8. Bitwise AND
;<and_expr>
rule_i: 
        <equality_expr>
        | <and_expr> "&" <equality_expr>

;;; 7. Equality and Inequality
rule_j: 
<equality_expr>      ::=
        <relational_expr> 
        | <equality_expr> "==" <relational_expr> 
        | <equality_expr> "!=" <relational_expr>

;;; 6. Relational Comparison
rule_k: 
<relational_expr>    ::= 
        .byte _kk
        .byte _k,"<",_kk
        .byte "|",_k,">",_kk
        .byte "|",_k,"<=",_kk
        .byte "|",_k,">=",_kk
        .byte 0

;;; 5. Bitwise Shift
rule_kk: 
<shift_expr>         ::=
        <additive_expr> 
        | <shift_expr> "<<" <additive_expr> 
        | <shift_expr> ">>" <additive_expr>

;;; 4. Additive
rule_l: 
<additive_expr>      ::=
        .byte _m
        .byte "|",_l,"+",_m
        .byte "|",_l,"-",_m
        .byte 0

;;; 3. Multiplicative
;multiplicative_expr>
rule_m: 
        .byte _m,"*",_n
        .byte "|",_m,"/",_n
        .byte "|",_m,"%",_n
 <cast_expr> 

;;; 2. Unary and Cast (Right-to-Left)
rule_n: 
        .byte "(","%",_T,")",_n
        .byte "|",_o
        .byte 0



;<unary_expr>
rule_o: 
        .byte "++",_o
        .byte "|a--",_o
        .byte "|&",<cast_expr>
        .byte "|*",<cast_expr>
        .byte "|+",<cast_expr>
        .byte "|-",<cast_expr>
        .byte "|~",<cast_expr>
        .byte "|!",<cast_expr>
        .byte "|sizeof",_o
        .byte "|sizeof" "(","%",_T,")"
        .byte "|_Alignof","(","%",_T,")"
        .byte "|",_p
        .byte 0

;;; 1. Postfix and Primary (Highest Precedence)
;<postfix_expr>
rule_p: 
        .byte _p,"[",_a,"]"
        .byte "|",_p,"(",<argument_expression_list>?,")"
        .byte "|",_p,".%V"
        .byte "|",_p,"->%V"
        .byte "|%V++"
        .byte "|%V--"
        .byte "|(",'%',_T,")","{",<initializer_list>,","?,"}"

        .byte "|%V"
        .byte "|%D"
        .byte "|%S"
        .byte "|(",_a,")"
        .byte 0
