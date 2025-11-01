        ;; ORIC ATMOS API

;;; TODO: these are quite costly and make statement
;;    parsing slow down maybe 30%.
;;
;; really should be hash-lookup?

.macro ORIC fun, addr
        .byte .concat("|", fun), _Y
      .byte "["
        jsr addr
      .byte "]"
.endmacro

.macro OJSR fun, addr
        .byte .concat("|", fun, "()")
      .byte "["
        jsr addr
      .byte "]"
.endmacro

        OJSR "hires",   $ec33
        OJSR "text",    $ec21
        OJSR "clrscr",  clrscr

        ORIC "paper",  $f204
        ORIC "ink",    $f210

        ORIC "circle", $f37f
        ORIC "curset", $f0c8
        ORIC "curmov", $f0fd
        ORIC "draw",   $f110
        ORIC "point",  $f1c8    ; verify output?

        ORIC "hchar",  $f12d
        ORIC "fill",   $f268    ; (rows,cols,char)

        .byte "|pattern(",_E,")"
      .byte "["
        sta $213
      .byte "]"

        ORIC "play",    $fbd0
        ORIC "music",   $fc18
        ORIC "sound",   $fb40

        OJSR "ping",    $fa9f
        OJSR "shoot",   $fab5
        OJSR "zap",     $fae1
        OJSR "explode", $facb
        OJSR "tick",    $fb14
        OJSR "tock",    $fb2a

        OJSR "cls",     $ccce
        OJSR "lores0",  $d9ed
        OJSR "lores1",  $d9ea

        .byte "|cwrite(",_E,")"
      .byte "["
        ;; value in A
        jsr $e65e
      .byte "]"

;;; TODO: function - MOVE!
        .byte "|cread()"
      .byte "["
        jsr $e6c9
        lda $02e0
        ldx #0
      .byte "]"


;;; from cc65 - libsrc/atmos/atmos_save.s (orig: Twilite)

JOINFLAG    = $025A        ; 0 = don't joiu, $4A = join BASIC programs
VERIFYFLAG  = $025B        ; 0 = load, 1 = verify

CFILE_NAME  = $027F
CFOUND_NAME = $0293
FILESTART   = $02A9
FILEEND     = $02AB
AUTORUN     = $02AD        ; $00 = only load, $C7 = autorun
LANGFLAG    = $02AE        ; $00 = BASIC, $80 = machine code
LOADERR     = $02B1

        ;; .byte "|cwritehdr();" - $e607
        ;; .byte "|creadsync();" - $e735 

.ifdef ATMOS_FIX
;;; 4.3 Saving an area of memory
;;; 
;;; The sequence of events when saving a block of
;;; memory (remember that a BASIC program is
;;; ust a block of memory) is:
;;; 
;;; 1. Disable interrupts and change the 6522 into
;;; cassette mode.
;;; 
;;; 2. Print the message ‘SAVING’ and the filename
;;; on the top line of the screen.
;;; 
;;; 3. Save a header record, composed of:
;;;    (a) 259 occurrences of #16 (this is the actual
;;;        ‘header’).
;;;    (b) The value #24 to indicate the start of
;;;        the record.
;;;    (c) For version 1.0 – #5E to #66 – or for
;;;        version 1.1 – #2A0 to #2B0. This information
;;;        is saved backwards and includes the start
;;;        and end addresses and other flags.
;;;    (d) A filename, ending with #0 – this is either
;;;        #35 onwards, for version 1.0, or #27F
;;;        onwards, for version 1.1.
;;; 4. Save the block of memory, byte by byte.
;;; 5. Re-enable interrupts and reset the 6522 back
;;; to its normal mode.
;;; 
;;; 2. For version 1.1:
;;; 
;;; JSR E76A (interrupts off)
;;; JSR E585 (print ‘saving’)
;;; JSR E607 (save header record)
;;; JSR E62E (save area of memory)
;;; JSR E93D (interrupts on)
;;; 
;;; The filename on tape is stored at #49 to #56
;;; (version 1.0) or #293 to #2A2 (version 1.1
;;; 
;;; JSR E76A (disable interrupts, etc.)
;;; JSR E57D (print ‘searching’ message)
;;; JSR E4AC (find file)
;;; JSR E59B (print ‘loading’)
;;; JSR E4E0 (load file, or verify)
;;; JSR E93D (enable interrupts)


        ;; void csave(char* name, void* s,, void* end)
        .byte "|csave(",_E,","
      .byte "["
        sei
        jsr     store_filename
      .byte "]"

        .byte _E,","
      .byte "["
        sta     FILESTART
        stx     FILESTART+1
      .byte "]"

        .byte _E,");"
      .byte "["
        sta     FILEEND
        stx     FILEEND+1

        lda     #0
        sta     AUTORUN
        jsr     csave_bit
        cli
      .byte "]"


;;; TODO: move to somewhere safe
csave_bit:      
        php
        jmp     $e92c

cload_bit:      
        pha
        jmp     $e874


store_filename: 
        sta     tos
        stx     tos+1
        ldy     #FNAME_LEN - 1  ; store filename
: 
        lda     (tos),y
        sta     CFILE_NAME,y
        dey
        bpl     :-
        rts


        ;; void cload(char* name);
        .byte "|cload(",E,");"
      .byte "["
        ;; 22B
        sei
        jsr     store_filename
        ldx     #$00
        stx     AUTORUN       ; don't try to run the file
        stx     LANGFLAG      ; BASIC
        stx     JOINFLAG      ; don't join it to another BASIC program
        stx     VERIFYFLAG    ; load the file
        jsr     cload_bit
        cli
      .byte "]"

.endif ; ATMOS_FIX

