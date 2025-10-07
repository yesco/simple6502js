// according to grok

int isspace(int c) {
  // Covers \t (9), \n (10), \v (11), \f (12), \r (13)
  return (c == ' ') | (c - 9 <= 4U);
}

int isspace(int c) {
  // Covers \t (9), \n (10), \v (11), \f (12), \r (13)
  return (c == ' ') | (c - 9 <= 4U);
}

int isalpha(int c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

int isalpha(int c) {
  // Converts to lowercase by setting bit 5
  return ((c | 32) >= 'a' && (c | 32) <= 'z');
}

int isdigit(int c) {
  return c >= '0' && c <= '9';
}

int isdigit(int c) {
  // Subtract '0' to check if result is 0-9
  return (unsigned)(c - '0') <= 9;
}

int isalnum(int c) {
    return isalpha(c) || isdigit(c);
}


.macro RANGE fun, s, e
        .byte .concat("|", fun)
      .byte '['
;;; 11B inline
        ldx #0
        clc
        sbc #s
        cmp #e-s+1
        bcc :+
        ;; make true $ff
        dex
:       
        tax
      .byte ']'
.endmacro
      
;;;    .byte "|isxdigit(",_E,")"

        RANGE "islower", 'a', 'z'
        RANGE "isupper", 'A', 'Z'

;;; isspace(), ispunct(), isalnum(), isprint(), iscntrl(), isascii()

.ifdef ISPUNCT
        ;; ispunct== !isspace && isprint
        .byte "|ispunct(",_e,")"
      .byte '['
;;; 36B - crazy!
        ldx #0
        cmp #' '+1
        bcc @false
        cmp #'0'+1
        bcc @true
        cmp #'9'+1
        bcc @false
        cmp #'A'+1
        bcc @true
        cmp #'Z'+1
        bcc @false
        cmp #'a'+1
        bcc @true
        cmp #'z'+1
        bcc @false
        cmp #127
        bcs @false
@true:
        dex
@false:        
        txa
      .byte ']'
.endif ; ISPUNCT

        .byte "|isspace(",_E,")"
      .byte '['
;;; 8B
        ldx #0
        cmp #' '+1
        bcs :+
        dex
:       
        txa
      .byte ']'

        .byte "|isdigit(",_E,")"
      .byte '['
;;; 10B
        ldx #0
        eor #32+16
        cmp #'9'+1
        bcs :+
        dex
:       
        tax
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
;;; 12B
        ldx #0
        and #%1101111
        tay
        dey
        cpy #'Z'-'A'+1
        bcs :+
        dex
:       
        txa
      .byte ']'
