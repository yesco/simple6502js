; Minimal BRK Handler for ca65
; Targets generic 6502

.segment "CODE"

.import _putchar

.export _main
_main:   

; 1. Main Entry Point
start:
        ;; install handler
        lda #<irq_brk_handler
        ldx #>irq_brk_handler
        sta $fffe
        stx $fffe+1

        sei
        cld
        ldx #$FF
        txs
        
        ;; meat
        lda #'A'
        jsr _putchar


        ldy #0

        brk
        iny
        iny

        brk
        iny
        iny

        brk
        iny
        iny
        
        clc
        tya
        adc #'0'
        jsr _putchar
halt:
        jmp halt

; 2. The BRK/IRQ Handler
;
; When BRK happens, the CPU pushes PC+2 (or +1) and P (with B flag set)
irq_brk_handler:
        pha
        txa
        pha
        tya
        pha

        lda #'B'
        jsr _putchar

        ;; --- Exit the handler ---
        pla
        tay
        pla
        tax
        pla

        ;; should skip one more byte than rti!
;rti
        plp
        rts


; 3. Vector Table
;.segment "VECTORS"
;    .addr $0000     ; NMI
;    .addr start     ; RESET
;    .addr irq_brk_handler ; IRQ/BRK

