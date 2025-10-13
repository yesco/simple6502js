;;; jsk's asm minimal implementation....

        jsr nl

        ldy #0
        sty savey
:       
.ifnblank
        sty tos
        ldx #0
        stx tos+1
        jsr printd
        putc ':'
.endif
        ldy savey
        lda chars,y
        beq :+

        jsr putchar
        putc '-'
        putc '>'

        ldy savey
        lda chars,y
;        jsr isalpha
;        jsr isdigit
        jsr isxdigit

        sta tos
        ldx #0
        stx tos+1
        jsr printd
        jsr nl

        inc savey
        ldy savey
        jmp :-
:       
        jmp halt


;;; IDEA
;;;        Z=1 means TRUE!
;;; TWO RULES:
;;; 
;;; testsGivingZ: == isblank
;;; testsGivingC: <  isalpha isdigit isxdigit isspace
;;; 
;;; can have two "IF" rules C=0 for < !!!
;;; 
;;; C=1 == false LDA #0; ROL => Z=0   !!!
;;; C=0 == true  LDA #0; ROL => Z=1   !!!

isspace:        
;;; 2 + 4 + 1
        cmp #' '+1
isblank:        
;;; 6 Z=0
        cmp #' '
        beq :+
        cmp #'I'-'@'
:       
;;; 10 C=0
        clc
        cmp #' '
        beq :+
        cmp #'I'-'@'
        bne :++
:       
        sec
:       
isxdigit:       
;;; 11 (saves 2 by reusing isdigit)
;;; 'a'<=tolower(x)<='z'
        pha
        ora #32                 ; lower-case
        sec
        sbc #'a'
        cmp #6
        pla
        bcc :+
        ;; fallthrough
isdigit:        
;;; 5 + 4 + 1 (C=0, A=255, rts)
        sec
        sbc #'0'
        cmp #10
:       
        lda #0
        sbc #0

        rts
isxdigitFULL:   
;;; 13 + 4 + 1 (C=0
        sec
        sbc #'0'
        cmp #10

        bcc :+
        ;; hex?
        ora #32                 ; lower-case
        sbc #49
        cmp #6
:       

;        rts

        lda #0
        sbc #0

        rts
isalpha:        
;;; 7 + 4 + 1 (C=0, A=255, rts)
;;; x doesn't matter, if x return result undefined!
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1

        lda #0
        sbc #0

        rts

;;; 8C C=0 isalpha
        ora #32
        eor #64+32
        tax
        dex
        cpx #'z'-'a'+1
        
        lda #0
        rol
        rts
;;; 7C
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        ;; C=0 if 
        rts
;;; 18 B
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        ;; C=0 if 

        ldx #0
        txa

        ;; reverse C: 5 B
        bcs :+
        sec
        SKIPONE
:       
        clc

        adc #0

        rts
;;; 14+1
.ifnblank
        ldx #1
        ora #32
        eor #64+32
        beq :+
        cmp #'z'-'a'
:
        txa
        bcc :+
        dex
:       
        rts
.endif
;;; 15+1
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        ;; C=0 if 
        ldx #0
        txa
        bcs :+
        adc #1
:       
        dex
        rts
;;; 15+1
        ldx #1
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        txa
        tax
        dex

        rts
;;; 15+1
        ldx #1
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        txa
        bcc :+
        sbc #1
:       
        dex

        rts
;;; 14+1
        ldx #0
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        txa
        bcs @zero
        lda #1
@zero:
        rts

       
chars:  
        .byte '8','A'-1,'A','O','Z','Z'+1
        .byte     'a'-1,'a','o','z','z'+1,'}'
        .byte '0'-1,'0','9','9'+1,'a'-1,'a','f','f'+1
        .byte                     'A'-1,'A','F','F'+1
        .byte 0












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
