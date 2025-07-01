;;; ENDCHAR can't occur anywhere in the compressed data
;;; 
;
ENDCHAR=0

;_initlisp:      

;;; unzip - decompressor for one pae
;;; 
;;; (- 1 (/ (- 256 43) 256.0)) = 17%
;;; 
;;; Alas the compressed data is 213 BYTES!
;;; 
;;; (can max be 256, without change)
;;; (would have to inc source+1 +8 bytes)
;;; 
;;; We need to achieve a compression ratio
;;; of at least 18% for it to be worth it!
;;; 
;;; Alternatives
;;; - Haruhiko Okumura's lzss.c
;;; - Fabrice Bellard's lzexe
;;; - Markus Oberhumer's NRV series
;;; - 6502 asm FilePack part of OSD
;;; 
;;; REF:
;;; 
;;; - https://github.com/mywave82/unlzexe/blob/master/unlzexe.c
;;; - https:github.com/Oric-Software-Development-Kit/osdk/blob/master/osdk%2Fmain%2FOsdk%2F_final_%2Flib%2Funpack.s
;;; 
;;; was: (42 B for ASCII, (+ 13= 52 B if UNZBINARY))

;;; TODO: variant AX

;;; (+ 4 6 5 13 18 33 22) = 101 slightly smaller...
;;;    BUT WORKS!!!
.proc unz
        ;; init
;;; 4
        lda #<(compresseddata-1)
        ldx #>(compresseddata-1)

loop:   
;;; 6
        jsr unzchar
        jmp loop

unzchar:        
;;; 5
        jsr nextbyte
        bmi minus
        ;; plain
save:   
;;; 14
;;; TODO: remove! debug
        jsr putchar

dest:   sta destination
        ;; step
        inc dest+1
        bne @noinc
        inc dest+2
@noinc: 
        lda savea
        rts

minus:    
;;; 13
        ;; quoted?
        cmp #$ff
        bne ref
        ;; quoted
quoted: 
        lda savea
        jsr nextbyte
        eor #128
        ;; jmp save (always pl!)
        bpl save
        
ref:    
;        lda #':'
;        jsr putchar

;;; 33
        ;; ref to two pos
        dey
        sty savey

        ;; save current pos: hi,lo
        txa
        pha
        lda savea
        pha

        ;; modify pos by add a
        clc ; ? or sec?
        adc savey
        tay
        txa
        adc #$ff                ; we're really sub!
        tax
        tya

        ;; unz(pos+ref)->newpos
        jsr unzchar

        ;; unz(newpos + 1)
        jsr unzchar

        ;; restore pos
        sty savex               ; lol

        pla
        tay                     ; lo
        pla
        tax                     ; hi
        tya                     ; lo

        ldy savex

        rts

nextbyte:
;;; 22
        ;; step
        clc
        adc #1
        bcc noinc
        inx
noinc:  
        sta savea

        sta ptr1
        stx ptr1+1
        ldy #0
        lda (ptr1),y

        ;; end? -> assumes stack will be fixed
        cmp #ENDCHAR
;        beq destination
hlt:    beq hlt

        ;; flags reflect A
        tay
        rts
.endproc


.ifnblank


;;; 86 B - unlimited length, fixed addr, self mod
;;;        (but requires unique stopchar)
;;; 
;;; (+ 8 7 7 12 12 32 15) = 93 correct missed on 12
.proc unz
        ;; init
;;; 8
        lda #<compresseddata
        sta ptr1
        lda #>compresseddata
        sta ptr1+1

loop:   
;;; 7
        ldy #0
        jsr unzchar
        bne loop


unzchar:        
;;; 7
        jsr nextbyte
        cmp #0
        bmi minus
        ;; plain
save:   
;;; 12
dest:   sta dest
        lda savea
        jsr putchar
        ;; step
        inc dest+1
        bne @noinc
        ind dest+2
@noinc: 
        rts

minus:    
;;; 12
        ;; quoted?
        cmp #$ff
        bne ref
        ;; quoted
quoted: 
        pha

        ;; store a $ff
        lda #$ff
        jsr save

        ;; save byte ^ 128 (so it's no ref)
        pla
        jsr nextbyte
        eor #128
        iny ; to handle this at read time
        ;; jmp save (always pl!)
        bpl save
        
ref:    
;;; 32
        ;; ref to two pos
        sta savea
        ;; save current pos
        lda ptr1+1
        pha
        lda ptr1
        pha

        ;; modify by add a
        clc ; ?
        adc savea
        sta ptr1
        lda ptr1+1
        adc #$ff                ; we're really sub!
        sta ptr1+1

        ;; unz(pos+ref)->newpos
        ;; Y==0
        jsr unzchar

        ;; unz(newpos + 1)
        jsr unzchar

        ;; restore pos
        pla
        sta ptr1
        pla
        sta ptr1+1
        ;; Z=0
        rts

nextbyte:
;;; 15
        lda (ptr1),y

        cmp #stopbyte
        beq startaddr

        ;; step
        inc ptr1
        bne noinc
        inc ptr1+1
noinc:  
        rts

.endproc


.proc unz
        adjusteddata= compresseddata+128-1

        ;; when this is read means stop
sentinel:
        lda #0
        pha
        pha

next:   
        inc source+1
        bne noinc2
        inc source+2

load:

source: lda adjusteddata,y
        bpl plain
        ;; done?
        cmp #endchar
        beq startaddr

minus:  
        ;; process pair
        tay
        ;; second part of pair
;;; TODO: how about when quoted?
        iny
        tya
        pha                     ; second pat of pair
        dey
        jmp load                ; first part of pair
        
plain:  
        ;; plain -> store it
dest:   sta startaddr
        inc dest+1
        bne noinc
        inc dest+2
noinc:  

processesqueue: 
        pla
        tay
        bne load
        
.endproc


.proc unz
;;; (+ 9 5 12 18) = 44 lol (+10= 54 B if UNZBINARY)


;;; 9 (if use rts)
        compresslen= (compressend-compresseddata)
        starty= (256-compresslen)

        ldy #starty
        ;;; top level keep track of when to stop
loop:   
        jsr doone
        iny
        bne loop
        ;; done
        ; rts
        ;; (non library optimization)
        beq startaddr
        


doone:
;;; 5
        ;; Y is source read index
        adjusteddata= (compresseddata-starty)

source: lda adjusteddata,y
        bmi ninus


storeit:        
;;; 12
        ;; plain char, store it
dest:   sta startaddr
        ;; inc inline ptr to destination
        inc dest+1
        bne noinc
        inc dest+2
noinc:    
        rts


minus:    

.ifdef UNZBINARY
;;; (10 B)
        ;; is a the quote char?
        cmp #$ff
        bne ref

        ;; read and store
        iny
        lda adjusteddata,y
        bmi store

.endif ; UNZBINARY

ref:    
;;; 18
        ;; at index A we got two chars to process

;;; TODO: maybe start w index in A?

        ;; save A char and get curent index
        sta savea
        tya
        pha

        ;; Y+= ref
        clc
        adc savea
        tay

        ;; process two chars (recursivly)
        jsr doone
        iny
        jsr doone
        
        ;; restore Y
        pla
        tay
        rts

unzip:  
        ldx #0
loop:   
        lda rd,x
unz:    
        pla
        bmi ref
        ;; plain char
        ldy #0
        sta (wr),y
        inc wr
        bne noinc
        inc wr
noinc:  
        inx
        jmp unz
ref:    
        sta savea
        txa

        sec
        sbc #1
        pha
        ;; push delayed call
        ...

        txa
        clc
        adc savea
        tax
load:   
        lda rd,x
        jmp unz
        
data:   

.endif ; nblank

;;; Everything after the unz is compressed data!

compresseddata: 
        .byte "Jonas S Karlsson",10
;;; a b c d e f g h ef hef ef hef
        .byte "abcdefgh",256-4,256-2,256-2,10
        .byte ENDCHAR
compressend:

        

.res 256 - * .mod 256

destination:    
        .res 512


.endif ; COMPRESSED

;;; just for testing COMPRESSED/unz
;.end

