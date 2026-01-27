;;; Conclusion 44B 106c to x40
;;; optimal is 33B (grok managed eventually, store tmp in A and Y)
;FOURTY=1
;;; 62B 119c (program 16B overhead)

        .byte "// MUL40 - NO operator precedence",10
        .byte "word n, r;",10
        .byte "",10
        .byte "word main(){",10
        .byte "  r=17;",10
;        .byte "  while(r<28) {",10

;;; 49B => 42 B   84c
;        .byte "    n=r; n<<=2; n+=r; n<<=3;",10

;;; 47B => 40 B   75c
;;;  8B extra for << to store and retrieve x
        .byte "",10
        .byte "  // Example of no precedence...",10
        .byte "  // evaluation is LEFT-TO-RIGHT",10
        .byte "  // (not correct C ;-)",10 
        .byte "",10
        .byte "  n=r<<2 +r <<3;",10
;;; 
;        .byte "    n= PIPE r<<2+r<<3;",01
;        .byte "    n= WITH r SHL 2 PLUS r SHL 3 END;",01

;        .byte "    putu(n); putchar(' ');",10
;        .byte "    ++r;",10 
;        .byte "  }",10
;        .byte "  return n;",10
        .byte "}",10
        .byte 0
