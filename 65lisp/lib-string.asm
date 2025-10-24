;;; lib-string.asm
;;; 
;;; Part of library for parse CC02 C-compiler



FUNC _stringstart
.ifdef STRING
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


strTOSstr:
        rts

;;; tos: first arg, copy to
;;; AX : second, arg, source
;;; 
;;; TODO: can combine into a strncpy?
strTOScpy:
;;; 24 B (cc65: 31 B)
        ;; save destination
        sta dos
        stx dos+1

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
        ;; return orig destination
        ;; X is untouched
        lda dos
        rts

;;; stpcpy, same as strcpy
;;; EXCEPT! Returns pointer to last byte (@ \0)
;;; 
;;; TODO: is it more efficent to have strpcpy implement
;;; and strcpy callling? (turn around?)
stpTOScpy:
;;; 14 B
        jsr strTOScpy
        ;; AX = dos+Y
        clc
        tya
        adc #dos
        bcc :+
        inc dos+1
:       
        ldx dos+1
        rts

;;; TOS: first argument: destination
;;; AX : second argument: what to concat at end
strTOScat: 
;;; 16B ~ TODO: finish it...
        ;; save AX to concat for later, lol
        pha
        txa
        pha
        ;; search first string for \0 - end of string
        ldy #0
        jsr strTOSchrY
        ;; AX points to \0 at end of string!
        ;; store lo A in tos (X== value at tos+1 already)
        sta tos
        ;; pop revesre destination
        pla
        txa
        pla
        ;; concat(TOS,AX)
        jmp strTOScat
        ;; STRCAT returns original dest
.endif ; STRING
FUNC _stringend
