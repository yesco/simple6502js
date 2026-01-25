;;; lib-string.asm
;;; 
;;; Part of library for parse CC02 C-compiler


;;; --------- <string.h>
;;; 
;;; TODO: 
;;; - memset
;;; - memcpy
;;; - memmove
;;; 
;;; - memchr
;;; - memcmp
;;; - (memccopy) can be used to impl strcpy
;;; 
;;; 14 - stpcpy (stpTOScpy using strTOScpy)
;;; 16 - strcat (strTOScat using strTOSchrY)
;;; 26 - strcpy (strAXcpy and strTOScpy)
;;; 
;;; 22 - strlen
;;; 30 - strcmp (strTOScmp)
;;; 36 - strchr (strAXchrY, strTOSchrY)
;;; - strstr
;;; -----
;;; 144 Bytes
;;; 
;;; 
;;; - strdup
;;; 
;;; - strncat
;;; - strncmp
;;; - (strndup)
;;; - (strnlen)
;;; 
;;; - strcspn
;;; - strpbrk
;;; - strrchr
;;; - strspn
;;; - strtok
;;; 
;;; - (strerror)
;;; 
;;; TESTED: ok!
strlen: 
;;; 22 B
        sta pos
        stx pos+1

        ldy #0
        ldx #0                  ; hi-length
:       
        lda (pos),y
        beq :+
        iny
        bne :-
        ;; inc hibyte
        inc pos+1
        inx
        bne :-
:       
        tya
        rts
        
;;; TODO: strchrnul really?

;;; strchr(AX,Y)
;;;   tos := AX
;;; 
strAXchrY:
;;; 36 B (any savings at call with this acrobatics?)
        sta tos
        stx tos+1

;;; TESTED: ok!
strTOSchrY:
;;; (32 B) fastest and smallest!
        sty savey
        ;; use tos.lo
        ldy tos

        lda #0
        sta tos
:       
        lda (tos),y
        ;; look for char (even 0)
        cmp savey
        beq @found
        ;; end (after cmp savey)
        cmp #0                  ; +2c
        beq ret0
        ;; forward 
        iny
        bne :-
        ;; int hibyte
        inc tos+1
        bne :-
        ;; always loops back
@found:
        tya                     ; lo
        ldx tos+1               ; hi
        rts
;;; TODO: (if called strAXchrY)
;;; note: (orig @(tos+1) stored in X, stil there)
;;;  ????
ret0:
        ldx #0
        txa
        rts


;;; tos already contains first argument
;;; AX has second arg
;;; 
;;; TODO: combine with strncmp (?)
strTOScmp:
;;; 30 B (cc65: 33 B)
        sta pos
        stx pos+1

        ldy #0
;;; 18   cc65: 18
:       
        sec
        lda (tos),y
        beq @end
        sbc (pos),y
        bne @neq
        iny
        bne :-
        ;; inc hi
        inc tos
        inc pos
        bne :-
        ;; always
;;; fix after 6 (cc65: 8)
@end:
;;; TODO: check neg if first < last
        sec
        sbc (pos),y
@neq:
;;; TODO: sign extend into X ... >128 == neg, lol
        ldx #0
        rts


;;; TODO: ????
;strTOSstr:
        rts

;;; tos: destination, first arg
;;; AX : source, second arg
;;; 
;;; TODO: can combine into a strncpy?
;;; 
;;; TESTED: ok!
strTOScpy:
;;; 24 B (cc65: 31 B)
        ;; save source
        sta dos
        stx dos+1

strTOScpyDOS:
        ;; tos+1 will change, store it
        ldx tos+1
        ldy #0
:       
        ;; copy byte, including \0 byte
        lda (dos),y
        sta (tos),y
        beq :+
        iny
        bne :-
        ;; inc hi
        inc dos+1
        inc tos+1
        bne :-
:       
        ;; return orig destination (tos,x unchanged)
        lda tos
        rts

;;; stpcpy, same as strcpy
;;; EXCEPT! Returns pointer to last byte (@ \0)
;;; 
;;; TODO: is it more efficent to have strpcpy implement
;;; and strcpy callling? (turn around?)
;;; 
;;; TESTED: ok!
stpTOScpy:
;;; 13 B
        jsr strTOScpy
        ;; Y=lo end, tos+1 hi end
        ldx tos+1
        tya

        clc
        adc tos
        bcc :+
        inx
:       
        rts

;;; TODO: funny how this would benefit from reverse args?
;;; 
;;; TOS: first argument: destination
;;; AX : second argument: what to concat at end
;;; 
;;; TESTED: ok!
strTOScat: 
;;; 16B ~ TODO: finish it...
        sta dos
        stx dos+1

        ;; save destination to be returned
        ldy tos
        tya
        pha
        lda tos+1
        pha

        ;; find \0 in destination

;;; TODO: save bytes using:
;        jsr strTOSchrY

        lda #0
        sta tos
:       
        lda (tos),y
        beq :+
        iny
        bne :-
        inc tos+1
        bne :-                  ; always
:       
        sty tos
        ;; tos points to \0 at end of string!
        jsr strTOScpyDOS

        ;; return destinatipn
        pla
        tax
        pla

        rts

