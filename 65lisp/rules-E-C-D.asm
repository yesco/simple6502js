ruleE:  
        
        .byte "(",_E,")",_D
        
.ifnblank
;;; TODO: remove ?
        ;; Pascal style := works fine... LOL
        .byte "|%V:=[#]",_E
      .byte "[;"
        sta VAR0
        stx VAR1
      .byte "]"
.endif

        ;; make sure it's not '==' lol
        ;; (remember subexpr not fail!)
        .byte "|%V="
        .byte "%!=",$80
        .byte "[#]",_E
     .byte "[;"
        sta VAR0
        stx VAR1
      .byte "]"


        .byte "|",_C,_D
        
.ifdef BYTERULES
        .byte "|"
        .byte _U,_V
.endif ; BYTERULES
        
        .byte 0


;;; START of expression:
;;;   var/const/arrayelt/funcall()
FUNC ruleC_startof_expression
ruleC:  

;;; TODO: It seems it should be useful but not
.ifnblank
        .byte "%=;",$80

;      .byte "%{"
;        PUTC '/'
       ;jmp endrule
;        IMM_RET
        
;        .byte "%R"
;        .word endC

        .byte "|"
.endif

;        .byte "%{"
;          putc ':'
;          IMM_RET

;;; TODO: these are "more" statements...
FUNC _iorulesstart

        ;; TODO: fix
        ;; dummy rule to make | start - LOL
        .byte "d43fj3"

.ifdef STDIO
;;; TODO: these don't really return anything...

        ;;  potentially first so no "|"

        ;; "IO-lib" hack
        .byte "|putu(",_E,")"
      .byte '['
        LIBCALL _printu
      .byte ']'


        ;; miniprintf!

        .byte "|putfu(",_E,",%D,[#]%D,",34
      .byte "["
        ldy #LOVAL
        sty precision
        .byte ";"
        ldy #LOVAL

        LIBCALL printfu
      .byte "]"
        .byte "%S)"

        .byte "|putfd(",_E,",%D,[#]%D,",34
      .byte "["
        ldy #LOVAL
        sty precision
        .byte ";"
        ldy #LOVAL

        LIBCALL printfd
      .byte "]"
        .byte "%S)"

        .byte "|putfx(",_E,",%D,[#]%D,",34
      .byte "["
        ldy #LOVAL
        sty precision
        .byte ";"
        ldy #LOVAL

        LIBCALL printfx
      .byte "]"
        .byte "%S)"

        .byte "|putfs(",_E,",%D,[#]%D,",34
      .byte "["
        ldy #LOVAL
        sty precision
        .byte ";"
        ldy #LOVAL

        LIBCALL printfs
      .byte "]"
        .byte "%S)"


        ;; compatibility

        .byte "|printf(",34,"\%u",34,",",_E,")"
      .byte '['
        LIBCALL _printu
      .byte ']'

        .byte "|printf(",34,"\%x",34,",",_E,")"
      .byte '['
        jsr _print4h
      .byte ']'

        ;; LOL: printf("%s", s); // safe...
        .byte "|printf(",34,"\%s",34,",",_E,")"
      .byte '['
        jsr _printz
      .byte ']'

.ifdef OPTRULES
.ifdef INLINEPUTZOPT
        .byte "|putz(",34
      .byte '['
;;; TODO: ?
        jsr _iprintz
      .byte ']'
        .byte "%S)"

        ;; fputs("foo",stdout); == putz !
        ;; NO newline!
        .byte "|fputs(",34
      .byte '['
;;; TODO: ?
        jsr _iprintz
      .byte ']'
        .byte "%S,stdout)"

        .byte "|puts(",34
      .byte '['
;;; TODO: ?
        jsr _iprints
      .byte ']'
        .byte "%S)"
.endif ; INLINEPUTZOPT
.endif ; OPTRULES

        .byte "|fputs(",_E,",stdout)"
      .byte '['
        jsr _printz
      .byte ']'

.ifdef SIGNED
        .byte "|printf(",34,"\%d",34,",",_E,")"
      .byte '['
        jsr _printd
      .byte ']'

        ;; "IO-lib" hack
        .byte "|putd(",_E,")"
      .byte '['
        jsr _printd
      .byte ']'
.endif ; SIGNED

        .byte "|puth(",_E,")"
      .byte '['
        jsr _printh
      .byte ']'

        .byte "|putz(",_E,")"
      .byte '['
        jsr _printz
      .byte ']'

        .byte "|puts(",_E,")"
      .byte '['
;PRINTIT=1
.ifdef PRINTIT
;;; 20 B inline only...
        sta tos
        stx tos+1
        ldy #0
:       
        lda (tos),y
        beq :+
        jsr putchar
        iny
        bne :-
        inc tos+1
        bne :-
:       
.else

.ifnblank
sta tos
stx tos+1
PUTC '/'
jsr _printh
lda tos
ldx tos+1
.endif

        jsr _prints
.endif ; PRINTIT
      .byte ']'

        .byte "|putcraw(",_E,")"
      .byte '['
        jsr putcraw
      .byte ']'

.else ; !STDIO

        ;;  potentially first so no "|"

        .byte "|putz(",_E,")"
      .byte '['
        ;; 19 B inline only...
        sta pos
        stx pos+1
        ldy #0
:       
        lda (pos),y
        beq :+

;;; TODO: cleanup
.ifndef NOBIOS ; BIOS
        jsr putchar
.else ; !BIOS

  .ifdef __ATMOS__
        ;; ORIC: print character
        jsr $CCD0
  .else
        ;; I guess it's here? (non oric)
        jsr _putchar
  .endif ; __ATMOS__

.endif ;

        iny
        bne :-
        inc pos+1
        bne :-
:       

        .byte "|fgets(",_E,","
      .byte "["
        sta tos
        stx tos+1
      .byte "]"
        .byte _E,",stdin)"     ; cheat!
      .byte "["
        jsr _fgets
      .byte "]"

        .byte "|fgets_edit(",_E,","
      .byte "["
        sta tos
        stx tos+1
      .byte "]"
        .byte _E,",stdin)"
      .byte "["
        jsr _fgets_edit
      .byte "]"

.endif ; STDIO




.ifdef OPTRULES

.ifndef NOBIOS
        ;; putchar variable - saves 2 bytes!
;;; TODO: parser skips space, hahahaha!
        .byte "|putchar('')"    ; LOL!!!!
      .byte '['
        jsr spc
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar('\\n')" ;      double \\???
      .byte '['
        jsr nl
;;; TODO: about return value...
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar('\\t')" ;      double \\???
      .byte '['
        jsr tab
;;; TODO: about return value...
      .byte ']'

        ;; putchar constant - saves 2 bytes!
        .byte "|putchar(%D)"
      .byte '['
        lda #LOVAL
        jsr putcraw
;;; TODO: about return value...?
      .byte ']'

        ;; putchar variable - saves 2 bytes!
        .byte "|putchar(%V)"
      .byte '['
        lda VAR0
        jsr putchar
;;; TODO: about return value...
      .byte ']'

.else
        ;; LDA #0C 11 20 3F
        ;; 11= 17dec == ???

        .byte "|putchar('')"    ; LOL!!!!
        ;; (parser skips space...)
      .byte '['
        ;; ORIC: PRINT SPACE
        jsr $CCD4
      .byte ']'

        ;; putchar newline
        .byte "|putchar('\\n')" ;      double \\???
      .byte '['
        ;; ORIC: NEWLINE
        jsr $CBF0
      .byte ']'

.endif ; !NOBIOS

.endif ; OPTRULES


.ifndef NOBIOS
        ;; potentially first so no "|"

        .byte "|putchar(",_E,")"
      .byte '['
        jsr putchar
      .byte ']'

        .byte "|getchar()"
      .byte '['
        jsr getchar
        ldx #0
      .byte ']'
.else

.ifdef __ATMOS__
        ;; potentially first so no "|"

        .byte "|clrscr()"
      .byte '['
        ;; ORIC: CLS command (LDA #$0C)
        jsr $CCCE
      .byte ']'

        .byte "|putchar(",_E,")"
      .byte '['
        ;; ORIC: print character...
        jsr $CCD0 
;;; $f77c output X !
      .byte ']'

        .byte "|getchar()"
      .byte '['
;;; from oric_advanced_user_guide_rom_disassembly.pdf
;;; WARNING: it messes with address ZEROPAGE $2e ???
        ;; ORIC: READ KEY FROM KEYBOARD
;;; $c5e9 ?
;;; $f523 poll keyboard
        jsr $C5E8
        ldx #0
      .byte ']'
.else
        
.endif ; __ATMOS__
        

.endif ; !NOBIOS

;;; TODO: move all that don't change here?

        .byte "|kbhit()"
      .byte '['
        jsr kbhit
        ldx #0
      .byte ']'
 

.ifdef STDIO
        .byte "|fgets(%V,"
      .byte "["
        lda #LOVAL
        ldx #HIVAL
        sta tos
        stx tos+1
      .byte "]"
        .byte _E,",stdin)"      ; cheat!
      .byte "["
        jsr _fgets
      .byte "]"

        .byte "|fgets_edit(%V,"
      .byte "["
        lda #LOVAL
        ldx #HIVAL
        sta tos
        stx tos+1
      .byte "]"
        .byte _E,",stdin)"
      .byte "["
        jsr _fgets_edit
      .byte "]"
.endif ; STDIO



FUNC _iorulesend





.ifdef CTYPE
        .byte "|isxdigit(",_E,")"
      .byte '['
        jsr isxdigit
      .byte ']'

        .byte "|isdigit(",_E,")"
      .byte '['
        jsr isdigit
      .byte ']'

        .byte "|isalnum(",_E,")"
      .byte '['
        jsr isalnum
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        jsr isalpha
      .byte ']'

        .byte "|isspace(",_E,")"
      .byte '['
        jsr isspace
      .byte ']'

        .byte "|islower(",_E,")"
      .byte '['
        jsr islower
      .byte ']'

        .byte "|isupper(",_E,")"
      .byte '['
        jsr isupper
      .byte ']'

        .byte "|ispunct(",_E,")"
      .byte '['
        jsr ispunct
      .byte ']'

        .byte "|toupper(",_E,")"
      .byte '['
        jsr toupper
      .byte ']'

        .byte "|tolower(",_E,")"
      .byte '['
        jsr tolower
      .byte ']'
.else

;;; nah,it's compiletime
;FUNC _ctypestart 
;;; TODO: _byteexpr ??? X?
        .byte "|isdigit(",_E,")"
      .byte '['
;;; 11B
;;; TODO: make library? copy in on ref
        ldy #0
        sec
        sbc #'0'
        cmp #'9'-'0'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        .byte "|isalpha(",_E,")"
      .byte '['
        ldy #0
        ;; make all lower case
        ora #32
        sec
        sbc #'a'
        cmp #'z'-'a'+1
        bcs :+
        iny
:       
        tya
      .byte ']'

        ;; we take ourselves some freedom of interpreation!
        ;; (anything <= ' ' is space, lol)
        .byte "|isspace(",_E,")"
      .byte '['
        ldy #0
        cmp #' '+1
        bcs :+
        iny
:       
        tya
      .byte ']'
;FUNC _ctypeend
;;; nah,it's compiletime
.endif ; !CTYPE


;;; TODO: used for debugging LIBCALL
.ifnblank
        .byte "|dummy()"
      .byte "["
        lda #$12
        LIBCALL $5634
        lda #$78
      .byte "]"
.endif


FUNC _stringrulesstart
.ifdef STRING

        .byte "|strlen(",_E,")"
      .byte '['
        LIBCALL strlen
;        jsr strlen
      .byte ']'

        ;; all these takes 2 args
        ;; TODO: harmonize?
        .byte "|strchr(",_E,",",_F,")"
      .byte '['
        jsr strAXchrY
      .byte ']'

        .byte "|strcpy(",_E,",",_G
      .byte '['
        jsr strTOScpy
      .byte ']'

        .byte "|stpcpy(",_E,",",_G
      .byte '['
        jsr stpTOScpy
      .byte ']'

        .byte "|strcat(",_E,",",_G
      .byte '['
        jsr strTOScat
      .byte ']'

        .byte "|strcmp(",_E,",",_G
      .byte '['
        jsr strTOScmp
      .byte ']'

;;; TODO: not implemented yet!
        ;; 
;        .byte "|strstr(",_E,",",_G
;      .byte '['                 
;        jsr strTOSstr
;      .byte ']'



.endif ; STRING
FUNC _stringrulesend


FUNC _memoryrulesstart



        ;; ORIC peek/poke deek/doke



.ifdef OPTRULES

;;; TODO: too many |POKE( rules!!!!
;;;   (same as indexing?)

;;; OK zeropage write
;;; here arrassign
        .byte "|poke(%d,"
        .byte "[#]",_I
      .byte "[;"
        sta LOVAL
      .byte "]"

;;; OK
;;; here arrassign
        .byte "|poke(%D,[#]",_I
      .byte "[;"
        sta VAL0
      .byte "]"


.ifdef ZPVARS
;;; OK
;;; here arrassign
        .byte "|poke(%V,0)"
      .byte "["
        ;; save 1 B
        ldy #0
        tya
        sta (VAR0),y
      .byte "]"

;;; OK
;;; here arrassign
        .byte "|poke(%V,[#]",_I
      .byte "[;"
        ldy #0
        sta (VAR0),y
      .byte "]"
.endif ; ZPVARS        


;;; TOTEST
;;; here arrassign
        .byte "|doke(%D,[#]",_E,")"
      .byte "[;"
        ;; TODO: zero page addresses? save 2B
        sta VAL0
        stx VAL1
      .byte "]"

.endif ; OPTRULES


;;; OK
;;; here arrassign
        .byte "|poke(",_E,",",_J
      .byte "["
        sta (tos),y
      .byte "]"

;;; TOTEST
;;; here arrassign
        .byte "|doke(",_E,",",_G
        ;; AX: value to doke
        ;; tos: addrss to put it
      .byte "["
        ldy #0
        sta (tos),y

        txa
        iny
        sta (tos),y
      .byte "]"

.ifdef OPTRULES
;;; here arrassign
        .byte "|peek(%D)"
      .byte '['
        lda VAL0
        ldx #0
      .byte ']'

;;; here arrassign
        .byte "|deek(%D)"
      .byte '['
        lda VAL0
        ldx VAL1
      .byte ']'
.endif ; OPTRULES

;;; here arrassign
        .byte "|peek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldx #0
        lda (tos,x)
      .byte ']'

;;; here arrassign
        .byte "|deek(",_E,")"
      .byte '['
        sta tos
        stx tos+1
        ldy #1
        lda (tos),y
        tax
        dey
        lda (tos),y 
      .byte ']'


;.ifdef NONO_cc65_STDLIB
.ifdef STDLIB

        .byte "|srand(",_E,")"
      .byte "["
;;; rng at address $xx20 == "jsr" lol
        sta rng
        stx rng+1
      .byte "]"

        .byte "|rand()"
      .byte "["
        LIBCALL rand
      .byte "]"

;;; TODO: cheating, using cc65 malloc/free :-(

        ;; gives error if run out of memory
        .byte "|xmalloc(",_E,")"
      .byte "["
        jsr _xmalloc
      .byte "]"

        ;; return NULL if failed...
        .byte "|malloc(",_E,")"
;;; TODO: experiment test IMMPRINT
;        IMMPRINT "malloc"      
      .byte "["
        jsr _malloc
      .byte "]"

        .byte "|free(",_E,")"
      .byte "["
        jsr _free
      .byte "]"

.ifnblank
        .byte "|realloc(",_E,")"
      .byte "["
        jsr _realloc
      .byte "]"
.endif
        ;; Like pascal, this just sets free space
        ;; to start at the given address (as previously
        ;; returned from an xmalloc or malloc)
        .byte "|release(",_E,")"
      .byte "["
        sta _out
        stx _out+1
      .byte "]"

.else ; LIBRARYLESS/ !STDLIB

        ;; NOTE: no xmalloc as it
        ;;   we don't check anything!
        
        .byte "|malloc(",_E,")"
      .byte "["
        ;; 21 B  33c - works!
        sta savea
        stx savex

        lda _out
        tay
        
        clc
        adc savea
        sta _out
        
        lda _out+1
        tax
        adc savex
        sta _out+1
        
        ;; TODO: test if run-out of memory
        tax
        tya     
      .byte "]"

        ;; NOTE: no free and no realloc
.endif ; !STDLIB



;;; TODO: can we make this work? no need?

.ifdef NOTDEFINEDIN_CC65 ; ???
.import _heapmemavail
        .byte "|heapmemavail",_X
      .byte "["
        jsr _heapmemavail
      .byte "]"

.import _heapmaxavail
        .byte "|heapmaxavail",_X
      .byte "["
        jsr _heapmaxavail
      .byte "]"
.endif

FUNC _memoryrulesend



FUNC _funcallstart

;.include "lib-runtime-funcall.asm"


;;; TODO: not fully correct, as if it's a
;;;   normal variable, it'd jump to that variable
;;;   address??? LOL

        ;; CALL fun() { ... }
        .byte "|%V()"
      .byte "["
        DOJSR VAL0
      .byte "]"

        ;; CALL fun(...) { ... }
        .byte "|%V([#]",_E,_L,"[;]"

FUNC _funcallend

FUNC _ruleC_continue

        ;; !! - NOT variable
        .byte "|!!%V"
      .byte "["
        ;; 10 B
        lda VAR0
        ora VAR1

        cmp #1
        lda #0
        tax
        rol
      .byte "]"

        ;; ! - NOT variable
        .byte "|!%V"
      .byte "["
        ;; 12 B
        lda VAR0
        ora VAR1

        cmp #1
        lda #0
        tax
        rol

        eor #1
      .byte "]"

        ;; ! - NOT expression
        .byte "|!(",_E,")"
      .byte "["
        ;; 12 B  16c
        stx savex
        ora savex

        cmp #1
        lda #0
        tax
        rol
        eor #1
      .byte "]"


        .byte "|sizeof(%V)"
        JSRIMMEDIATE load_sizeof
      .byte "["
        lda #LOVAL
        ldx #HIVAL
      .byte "]"



        ;; current PC!
        .byte "|_PC()"
        JSRIMMEDIATE getpc
      .byte "["
        lda #LOVAL
        ldx #HIVAL
      .byte "]"

.ifnblank
;;; TODO: this returns cleanstack! lol
        ;; current RETPC!
        .byte "|_RETPC()"
      .byte "["
        ;; copy word from stack
        pla
        tay
        pla
        tax
        pha
        tya
        pha
      .byte "]"
.endif       

        ;; cast to char == &0xff !
        .byte "|(char)",_C
      .byte '['
        ldx #0
      .byte ']'

        ;; casting - ignore!
        ;; (we don't care legal, just accept if correct)
;;; TODO: lol funny way of skipping name/id/type
        .byte "|(%V\*)",_C

        



        ;; Surprisingly ++v and --v expression w value
        ;; arn't smalller or faster than v++ and v-- !
        .byte "|++%V"
      .byte '['
;;; 10B 14-18c
        inc VAR0
        bne :+
        inc VAR1
:       
        lda VAR0
        ldx VAR1
      .byte ']'

        .byte "|--%V"
      .byte '['
.ifblank
;;; 12B 17-21c
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
        lda VAR0
        ldx VAR1
.else
;;; 13B 16-20c
        ldx VAR1
        ldy VAR0
        bne :+
        dex
        stx VAR1
:       
        dey
        tya
        sta VAR0
.endif
      .byte ']'

        .byte "|%V++"
      .byte '['
;;; 10B ! 14-18c ! - no extra cost!
        lda VAR0
        ldx VAR1
        inc VAR0
        bne :+
        inc VAR1
:       
      .byte ']'

        .byte "|%V--"
      .byte '['
.ifblank
;;; 10B ! 14-18c
        ldx VAR1
        lda VAR0
        bne :+
        dec VAR1
:       
        dec VAR0
.else
;;; 13B 16-20c
        ldx VAR1
        ldy VAR0
        dey
        tya
        bne :+
        dex
        stx VAR1
:       
        sta VAR0
.endif
      .byte ']'

;;; cc65: get parameter value from subroutine
;000055r 1  A0 01        	ldy     #$01
;000057r 1  B1 rr        	lda     (sp),y
;000059r 1  88           	dey
;00005Ar 1  11 rr        	ora     (sp),y
;;; probably have to turn it around

;;; TDOO: $ arr\[\] ... redundant?
;;; TODO: store addresss of arr in variable


        .byte "|'\\n'"
;      .byte "%{"
;        putc '!'
;        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'

.ifnblank
        .byte "|"

      .byte "%{"
        putc '"'                ; "
        IMM_RET

        .byte "'"
      .byte "%{"
        putc '1'
        IMM_RET

        .byte "\\"               ; "
      .byte "%{"
        putc '2'
        IMM_RET

        .byte "n"
      .byte "%{"
        putc '3'
        IMM_RET

        .byte "'"
        
;      .byte "%{"
;        putc '!'
;        IMM_RET

      .byte '['
        lda #10
        ldx #0
      .byte ']'
.endif

.ifdef OPTRULES
        ;; load 0 saves 1 byte
        .byte "|0%b"
      .byte '['
        lda #0
        tax
      .byte ']'
.endif ; OPTRULES

        ;; digits
        .byte "|%D"
      .byte '['
        lda #'<'
        ldx #'>'
      .byte ']'
        

;;; TODO: cleanup?

;;; It seems the address is 3 bytes too small,
;;; (if it was 2 it'd make sense as it's what PUSHLOC
;;;  is, but it ISN'T!)
;;; 
;;; possiblities:
;;;  a) addresses of vars are different?
;;;     (could interact w %{ but I tested
;;;      using subroutines, doesn't seem to bit it)
;;;  b) somebody is modifying DOS? (lo byte)
;;;  c) 


;;; Simpliest for now

;;; TODO: remove routines at endrules
POS=gos

        .byte "|",34            ; " character
parsestring:    
      .byte "["
        ;; jump over inline string
        jmp PUSHLOC             ; Branch ?1
        .byte ":"               ; start of string ?0
      .byte "]"               
        ;; copy string to out
        .byte "%S"
      .byte "[?1B"      ; patch Branch to after string
        .byte "?0"      ; load string address
        lda #LOVAL
        ldx #HIVAL
      .byte ";;]"



;;; TODO: maybe no need this operator at all?
;;;   only case to allow pointer to variable
;;;   is only useful/safe for arrays!
;;; 
;;; pointer

;;; TODO: restrict pointer to "local"
;;;   variables (as they are copied and reused
;;;   in zeropage!)
        .byte "|&%V"
        IMMEDIATE disallowlocal
      .byte "["
        lda #LOVAL
        ldx #HIVAL
      .byte "]"

        .byte "|\*%V"
      .byte '['
.ifdef ZPVARS
        ldx #0
        ;; 1c more than (),y but sets X=0 for free!
        lda (VAR0,x)
.else
        lda VAR0
        sta tos
        lda VAR1
        sta tos+1

        ldx #0
        ;; 1c more than (),y but sets X=0 for free!
        lda (tos,x)
.endif
      .byte ']'




        ;; VARIABLES INDEXing and access

        ;; (Checking variables is expensive put last!)
        ;; TODO: consider using a subrule;
        ;;   first parse var then all that use it



;;; TODO: can we use sub-rule shared mostly
;;;   for both, LVALUE as well as VALUE addressing?
        
;;; seach for "here arrassign"




.ifdef OPTRULES
        ;; char array index [char]
        .byte "|%V\[(char)([#]"
        IMMEDIATE checkisarray
        .byte _E,")\]"
      .byte "[;"
        ;; 6++ B ==> 10
        tax
        lda VARRAY,x
        ldx #0
      .byte "]"

        ;; char array index [char var]
        .byte "|%V\[(char)[#]"
        IMMEDIATE checkisarray
        .byte "%V\]"
      .byte "["
        ;; 7 B
        ldx VAR0
        .byte ";"
        lda VARRAY,x
        ldx #0
      .byte "]"

        ;; char array index [CONST]
        .byte "|%V\[[#]"
        IMMEDIATE checkisarray
        ;;  only use of 'd' anymore? lol
        .byte "%D\][d;]"
        JSRIMMEDIATE addDOStoTOS
      .byte "["
        ;; 5 B
        lda VARRAY
        ldx #0
      .byte "]"
.endif ; OPTRULES

;;; TODO: word[] - word array

        ;; char array index [word]
        ;; (most generic and expensive)
        .byte "|%V\[[#]"
        IMMEDIATE checkisarray
        .byte _E,"\]"
      .byte "[;"
        ;; 14 B
        ;; calculate address
        clc
        adc #LOVAL
        sta tos
        txa
        adc #HIVAL
        sta tos+1
        
        ;; load it
        ldx #0
        lda (tos,x)
      .byte "]"


        ;; INDEX using POINTER to array

.ifdef OPTRULES
        .byte "|%V\[(char)([#]",_E,")\]"
      .byte "["
        ;; 13 B
        ;; calculate address
        clc
        adc VAR0
        sta tos
        lda #0
        sta tos+1
        ;; load it
        ldx #0
        lda (tos),y
      .byte "]"

        .byte "|%V\[(char)[#]%V\]"
      .byte "["
        ;; 14, save 6 B
        ldy LOVAL
        .byte ";"
        lda #LOVAL
        sta tos
        lda #HIVAL
        sta tos+1
        lda (tos),y
        ldx #0
      .byte "]"

        .byte "|%V\[[#]%d\]"
      .byte "["
        ;; 14, save 6 B
        ldy #LOVAL
        .byte ";"
        lda #LOVAL
        sta tos
        lda #HIVAL
        sta tos+1
        lda (tos),y
        ldx #0
      .byte "]"

.endif ; OPTRULES

        ;; ?pointer, as it wasn't array
        ;; LOL: we will happily use any var as ponter!
        .byte "|%V\[[#]",_E,"\]"
      .byte "[;"
        ;; 16 B 
        ;; calculate address
        clc
        adc VAR0
        sta tos
        txa
        adc VAR1
        sta tos+1
        
        ;; load it
        ldy #0
        lda (tos),y
        ldx #0
      .byte "]"


        ;; ARRAY-TO-POINTER DECAY!
        ;; degrade array to pointer
        .byte "|%V"
        IMMEDIATE checkisarray
      .byte "["
        lda #LOVAL
        ldx #HIVAL
      .byte "]"

        ;; variable
        .byte "|%V"
      .byte '['
        lda VAR0
        ldx VAR1
      .byte ']'



;;; last chance, try BYTERULES
;;; TODO: is this sane? doesn't seem to be triggerled?

.ifdef BYTERULES
        ;; BYTERULES
;;; TODO: if no match backtrack not propagated UP????
        .byte "|", _U
      .byte '['
;;; TODO: look into this...
;;; PRIMEBYTE: TODO: this adds 10bytes!!!! lol 313->323
;;; but sim: correct, and oric!
        ldx #0
      .byte ']'
.endif

endC:   

        .byte 0



;;; aDDons (::= op %d | op %V)
FUNC ruleD_expression_operators
ruleD:  

;;; TODO: generalize!

.ifdef CUT
        ;; "CUT" operator
        ;; if the next character is ,:;)]?
        ;; expression is ended
;;; BYTESIEVE:
;;;   3450146 before
;;;   2862018 cut only in ruleD
;;;   (/ 2862018 3430146.0)
;;; 
;;;   16.6% faster


      .byte "%{"
        jsr cut
        jmp _acceptrule

;;; TODO: use new %!

breakchars:
        ;; '|'+128 so not conflict with '|', not 0!
        .byte ",:;)]?",'|'+128

        .byte "|"
nextrule:       
.endif ; CUT

FUNC _oprulesstart
        ;; 7=>A; // Extention to C:
        ;; Forward assignment 3=>a; could work! lol
        ;; TODO: make it multiple 3=>a=>b+7=>c; ...
        .byte "=>%V"
      .byte "["
        sta VAR0
        stx VAR1
      .byte "]"
        .byte TAILREC


        ;; EXTENTION
        ;; .method call! - LOL
        .byte "|.%V"
      .byte '['
        ;; parameter already in AX
        DOJSR VAL0
      .byte ']'
        .byte TAILREC





        .byte "|+%V"
      .byte '['
        clc
        adc VAR0
        tay
        txa
        adc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; +BYTE
        .byte "|+%d"
      .byte '['
;;; 6 B
        clc
        adc #'<'
        bcc :+
        inx
:
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|+%D"
      .byte '['
;;; 9 B
        clc
        adc #'<'
        tay
        txa
        adc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 18 *2
        .byte "|-%V"
      .byte '['
        sec
        sbc VAR0
        tay
        txa
        sbc VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        ;; -BYTE
        .byte "|-%d"
      .byte '['
;;; 6 B
        sec
        sbc #'<'
        bcs :+
        dex
:       
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

        .byte "|-%D"
      .byte '['
;;; 9 B
        sec
        sbc #'<'
        tay
        txa
        sbc #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 17 *2
        .byte "|&%V"
      .byte '['
        and VAR0
        tay
        txa
        and VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|&0xff00%b"
      .byte '['
        lda #0
      .byte ']'
        .byte TAILREC

        .byte "|&0xff%b"
      .byte '['
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|&%d%b"
      .byte "["
        and #'<'
        ldx #0
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES


.ifdef MATH

.ifdef OPTRULES
        ;; most common?
        .byte "|*%d"
      .byte "["
        ;; 5 B
        ldy #LOVAL
        jsr _mulAXyAX
      .byte "]"
        .byte TAILREC

        .byte "|*%D"
      .byte "["
        ;; 15 B
        sta tos
        stx tos+1
        lda #LOVAL
        ldx #HIVAL
        sta dos
        stx dos+1
        jsr _mul
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES

        .byte "|*"
        ;; 16 B
      .byte "["
        pha
        txa
        pha
      .byte "]"
        .byte _E
      .byte "["
        sta dos
        stx dos+1
        pla
        sta tos+1
        pla
        sta tos
        jsr _mul
      .byte "]"
        .byte TAILREC

.endif ; MATH


        .byte "|&%D"
      .byte '['
        and #'<'
        tay
        txa
        and #'>'
        tax
        tya
      .byte ']'
;;; TODO: see FORDEBUG
;;;    if have this enabled then prase will loop >D>*>*>*...
;;;       why? we have and empty alt at end...
;        .byte TAILREC

.ifnblank
;;; TODO: \ quoting
;;; 17 *2
        .byte "|\|%V"
      .byte '['
        ora VAR0
        tay
        txa
        ora VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|\|%D"
      .byte '['
        ora #'<'
        tay
        txa
        ora #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC
.endif ; NBLANK

;;; 17 *2
        .byte "|^%V"
      .byte '['
        eor VAR0
        tay
        txa
        eor VAR1
        tax
        tya
      .byte ']'
        .byte TAILREC

        .byte "|^%D"
      .byte '['
        eor #'<'
        tay
        txa
        eor #'>'
        tax
        tya
      .byte ']'
        .byte TAILREC

;;; 24
        
        .byte "|/2%b"
      .byte '['
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
      .byte ']'
        .byte TAILREC

        .byte "|*2%b"
      .byte '['
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
      .byte ']'
        .byte TAILREC

.ifdef OPTRULES
        .byte "|>>8%b"
      .byte '['
        txa
        ldx #0
      .byte ']'
        .byte TAILREC

        .byte "|<<8%b"
      .byte '['
        tax
        lda #0
      .byte ']'
        .byte TAILREC
        
        ;; especially easy
        .byte "|>>9%b"
      .byte "["
        ;; 4 B
        txa
        lsr
        ldx #0
      .byte "]"
        .byte TAILREC

        ;; especially easy
        .byte "|<<7%b"
      .byte "["
        ;; 9 B
        tay
        txa
        asl
        tya
        ror
        tax
        lda #0
        ror
      .byte "]"
        .byte TAILREC


        .byte "|<<1%b"
      .byte '['
.ifblank
;;; 6B 12c
        asl
        tay
        txa
        rol
        tax
        tya
.else
;;; 7B 13c
        stx tos+1
        asl
        rol tos+1
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|<<2%b"
      .byte '['
;;; 10B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<3%b"
      .byte '['
;;; 13B= 4+3*n    15=4+3*n => n=11/3=4-
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|<<4%b"
      .byte '['
;;; 16B
        stx tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        asl
        rol tos+1
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>1%b"
      .byte '['
.ifblank
;;; 6B 12c
        tay
        txa
        lsr
        tax
        tya
        ror
.else
;;; 7B 13c
        stx tos+1
        lsr tos+1
        ror
        ldx tos+1
.endif
      .byte ']'
        .byte TAILREC

        .byte "|>>2%b"
      .byte '['
;;; 10B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>3%b"
      .byte '['
;;; 13B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

        .byte "|>>4%b"
      .byte '['
;;; 16B
        stx tos+1
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        lsr tos+1
        ror
        ldx tos+1
      .byte ']'
        .byte TAILREC

;;; TODO: optimize if >8
        .byte "|<<%D"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC


;;; TODO: so many duplicates...
;;;   can just do _C or _E ? priorities?

;;; TODO: optimize if >8
        .byte "|<<%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
;;; TODO: this is only difference...
;;;   IDEA: emit subroutine and remember;
;;;         incremental library buildup?
        ldy VAR0
:       
        dey
        bmi :+
        
        asl
        rol tos+1

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

;;; TODO: optimize if >8
        .byte "|>>%D"
      .byte '['
;PUTC '/'
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy #'<'
:       
        dey
        bmi :+
        
        lsr tos+1
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC

;;; TODO: optimize if >8
        .byte "|>>%V"
      .byte '['
;;; 15B (breakeven: D=4-)
        stx tos+1
        ldy VAR0
:       
        dey
        bmi :+
        
        lsr tos+1
        ror

        sec
        bcs :-
:       
        ldx tos+1
      .byte ']'
        .byte TAILREC
.endif ; OPTRULES

;;; COMPARISIONS

;;; TODO: really shouldn't give -1 lol
        .byte "|==%V%=,;)?",$80
      .byte '['
        ;; 15
        ldy #0
        cmp VAR0
        bne :+
        cpx VAR1
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC


;;; TODO: is one byte saved worth it?
        .byte "|==%d","%=,;)?",$80
      .byte '['
        ;; 12 (saves one byte...)
        ldy #0
        cmp #'<'
        bne :+
        txa
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

        .byte "|==%D","%=,;)?",$80 ; end of expression
;        .byte "|==%D"
      .byte '['
        ;; 13
        ldy #0
        cmp #'<'
        bne :+
        cpx #'>'
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC

        ;; general
        .byte "|=="
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['
        ;; 7
        sta tos
        stx tos+1

        pla
        txa
        pla

.ifblank
        ;; 15
        cmp tos
        bne @false
        cpx tos+1
        bne @false
@true:
        lda #1
        SKIPTWO
@false:       
        lda #0
        ldx #0
.else

        ;; 23 no add 5
        tay
        txa

        tsx
        cpy $101,x
        bne @false
        cmp $100,x
        bne @false
@true:
        ;; C=1
        SKIPONE
@false:
        clc
        pla
        pla

        ldx #0
        txa
        ror                     ; A=C
        eor #1
        

;;; All these add 7
        

        ;; 12
        cmp tos
        bne @false
        cpx tos+1
        bne @false
@true:
        ;; C=1 !!!
        SKIPONE
@false:
        clc
        tax
        ror
        
  
        

        ;; 13
        ldy #0
        cmp tos
        bne :+
        cpx tos+1
        bne :+
        ;; eq => -1
        dey
        ;; neq => 0
:       
        tya
        tax
      .byte ']'
        .byte TAILREC


;;; >=  7+ 9
        sta tos
        stx tos+1
        pla
        tax
        pla
        
        ;; 9 !!!
        cmp tos
        tax
        sbc tos+1
        ldx #0
        txa
        ror
.endif ; blank
        .byte "]"

;;; TODO: signed?
;;;    v < -42      => signed comparison
;;;    v < 32767    => SIGNED!
;;;    v < 40000    => UNSIGNED !
;;; 
;;;    v > 0        ?? impllies test for negative?
;;; 
;;; How to ipmlement signed comparison on 6502
;;; - just eor #$80 hi-byte of both values?
;;; 


;;; TODO: something messed up here? | ignored?

        .byte "|<%V%=,;)?",$80
      .byte '['
        ;; 11
        cmp VAR0
        tax
        sbc VAR1
        ;; A= !C, lol
        ldx #0
        txa
        ror
        eor #1
      .byte ']'


        .byte "|>=%V%=,;)?",$80
      .byte '['
        ;; 11
        cmp VAR0
        tax
        sbc VAR1
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'


        ;; < constant
        ;; (42 -> 28 bytes) saves 34 bytes cmp general
        .byte "|<%D"
        ;; Restrict to only at end of expression
        ;; (correct but might miss some)
        .byte "%=,;)?",$80
      .byte '['
        ;; 11
        cmp #LOVAL
        tax
        sbc #HIVAL
        ;; A= !C, lol
        ldx #0
        txa
        ror
        eor #1
      .byte ']'

;;; TODO: is $80 safe, or gets interrpreted as 0 some time?
        .byte "|>=%D%=,;)?",$80
      .byte '['
        ;; 11
        cmp #LOVAL
        tax
        sbc #HIVAL
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'

        ;; general
        ;; (21 B)
        .byte "|>="
      .byte '['
        ;; 3
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['
        ;; 7
        sta tos
        stx tos+1
        
        pla
        tax
        pla

        ;; 11
        cmp tos
        tax
        sbc tos+1
        ;; A= C, lol
        ldx #0
        txa
        ror
      .byte ']'

        ;; general
        .byte "|<"
      .byte '['
        pha
        txa
        pha
      .byte ']'
        .byte _E
      .byte '['


.ifblank
.scope
;;; < 18 bytes!

        ;; 7 B
        sta tos
        stx tos+1

        pla
        tax
        pla

        ;; 11 B
        cmp tos
        txa
        sbc tos+1

        ldx #0
        txa
        rol
        eor #1
.endscope

.else
        

        ;;
        tay
        pla
        

        ;; 17 (but reverse?)
        stx tos
        tsx
        cmp $00fe,x
        lda tos
        sbc $00ff,x
        pla
        pla
        ldx #0
        txa
        rol


;;; minimalist computing - Alan Cashin
;;; 18 B
        stx tos
        tsx
        sec
        sbc $00fe,x
        lda tos
        sbc $00ff,x
        pla
        pla
        ldx #0
        txa
        rol
        ;; eor #1
        
        


;;; <= 17 bytes!!!
.scope
        ;; 7
        tay
        pla
        sta tos+1
        pla
1        sta tos
        
        ;; 10
        ;; reverse cmp
        cpx tos+1
        bne @done
        cpy tos
@done:
        ldx #0
        txa
        rol
        
.endscope


;;; < 19 bytes
        ;; 7
        sta tos
        stx tos+1
        
        pla
        tax
        pla

        ;; 12
        ;; hi
        cpx tos+1
        bne @done
        ;; equal or
        ;; lo
        cmp tos
@done:
        ldx #0
        txa
        rol
        eor #1


.scope
; ;; posted on minimalist computing

;;; < 22 bytes
        sta tos                         ; zero page
        stx tos+1

        pla
        tax
        pla

        sec
        sbc tos
        txa
        sbc tos+1
        bcs false
true:
        lda #1
        SKIPTWO
false:
        lda #0
        ldx #0
.endscope

;;; < 7+11=18 B  16c
        cmp tos
        txa
        sbc tos+1
        ldx #0
        ;; A= !C flag!
        txa
        rol
        eor #1
:       


;;; < 7+13=20 B  13-16c
        cmp tos
        txa
        sbc tos+1
        ldx #0
        bcc :+
        lda #1
        SKIPONE
:       
        txa
        

        


;;; 7+14=21 B  15-19==> 
        cmp tos
        txa
        sbc tos+1
        bcs :+
        lda #1
        SKIPTWO
:       
        lda #0
        ldx #0

        ;; 12 B  17-18c
        ldy #0
        cmp tos
        txa
;;; TODO: test - I think
        sbc tos+1
        bcs :+
        ;; <   => -1
        dey
:       
        ;; <=  => 0
        tya
        tax



;;; < 7+13=20 B  12c-18c
        ldy #$ff
        cpx tos+1
        bne :+
        cmp tos
:       
        bcc :+
        ;; !< => 0
        iny
:       
        ;;  < => -1
        tya
        tax

.endif
      .byte ']'


;
LOGIC=1
.ifdef LOGIC

;;; TODO: these should have very low priority
;;;   we should also have rules thhat tkaes
;;;   conditions and these things but out
;;;   generating only a C boolean result!

;;; TODO: use hibit!

ALT='|'+128
;       .byte ALT "foobar"

        ;; || OR operator


;;; TODO: trouble with | operator matching and skipping!
.ifdef xOPTRULES
        ;; || %V
        .byte "|\|\|","%V"
;;; TODO: & suspect, but how about |
        .byte "%=&,:;)]?",$80
      .byte "["
;;; 14 B vs 23 B saves 9 B
        stx savex
        ora savex
        ora VAR0
        ora VAR1
        ;; 0 false
        cmp #1                  ; C=1 if A>=1
        lda #0
        txa
        rol
      .byte "]"
        .byte TAILREC
.endif ; OPTRULES

;;; TODO: trouble with | operator matching and skipping!
.ifnblank
        .byte "|\|\|"
;;; 19 B
        .byte "%{"
;        jsr nl                 
        putc '?'
;        jsr nl
        IMM_RET

      .byte "["
        ;; 9 B
        stx savex
        ora savex
        ;; zero go _E, otheriwse skip!
        beq :+
        ;; - true: AX!=0
        jmp PUSHLOC
:       
        ;; - false = continue
      .byte "]"
        .byte _E
      .byte "["
        ;; 10 B
        ;; we need to make the value 0 or 1
        stx savex
        ora savex

        .byte ";B"              ; patch to branch here
        ;; 0 => 0, _ => 1
        cmp #1
        lda #0
        tax
        rol
      .byte "]"
.endif         

        ;; && AND operator

.ifdef OPTRULES
        .byte "|&&","%V"
;;; TODO: & suspect, but how about |
;        .byte "%=&,:;)]?",$80
      .byte "["
;;; 16 B vs 23 B saves 7 B
        stx savex
        ora savex
        ;; eq => false
        beq :+

        lda VAR0
        ora VAR1
:       
        ;; A=0 if false
        cmp #1
        lda #0
        tax
        rol
      .byte "]"
;;; TODO: messed up ordering...||| &&& | &||&
        .byte TAILREC
.endif ; OPTRULES

        .byte "|&&"
;;; 19 B
      .byte "["
        ;; 9 B
        stx savex
        ora savex
        ;; zero done, return 0
        bne :+
        ;; - false
        jmp PUSHLOC
:       
        ;; - true = continue 
      .byte "]"
        .byte _E
      .byte "["
        ;; 10 B  14c - STABLE! faster
        stx savex
        ora savex

        .byte ";B"            ; jumps here
        ;; we need to make the value 0 or 1
        cmp #1                  ; 0 => C=0, _ => C=1
        lda #0
        tax
        rol
      .byte "]"

.endif ; LOGIC

;;; DID we used to do fallthrough?

        .byte 0


FUNC _oprulesend




