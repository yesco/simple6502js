// ORIC1 I think generatec by grok
#include <cc65.h>  // For basic runtime
#include <conio.h> // For screen output (optional, for status)

// Define buffer at screen memory (e.g., $A000 for hi-res screen dump).
// Use fixed addr to avoid stack/heap issues on 6502.
unsigned char *screen_buffer = (unsigned char *)0xA000;
#define LOAD_SIZE 1024  // e.g., 1K screen

// Custom tape load function: Returns 0 on success, -1 on fail.
// Expects tape formatted as data block ($10 header type).
// Asm calls ROM: $E5E0 init, $F8A0 header read, $FC00 block load.
int load_tape_data(const char *filename, unsigned char *dest, unsigned int size) {
    unsigned char tmp[12];  // Temp for filename (padded to 11 chars +0)
    unsigned int addr = (unsigned int)dest;
    unsigned int bytes_loaded = 0;
    unsigned char block_type, checksum;
    
    // Pad filename to 11 chars (ROM expects fixed len).
    // Simple strcpy + pad (cc65 has no string.h by default, so inline).
    unsigned char i = 0;
    while (filename[i] && i < 11) {
        tmp[i] = filename[i];
        i++;
    }
    while (i < 11) tmp[i++] = 0x20;  // Space pad
    tmp[11] = 0;
    
    // Inline asm: Call ROM tape load sequence for data block.
    // - JSR $E5E0: Init tape motor/search.
    // - Print filename to screen (ROM echoes for user feedback).
    // - JSR $F8A0: Read header (verify name/type $10).
    // - Loop: JSR $FC00 load block until EOF or size reached.
    // - No JMP to autostart (data has none).
    // Registers: A=filename ptr lo, Y=hi; on return A=0 ok, !=0 error.
    __asm__("lda %v", tmp);  // A = filename lo
    __asm__("ldy %v+1", tmp);  // Y = hi (but tmp is local, adjust if needed)
    __asm__("jsr $E5E0");  // Init tape (motor on, search leader).
    // Echo filename (optional, via ROM print).
    __asm__("jsr $BFEE");  // Print string (assumes filename in $0200+ or adjust).
    __asm__("jsr $F8A0");  // Read header: Sets block_type in $9B, addr in $9C/$9D.
    __asm__("lda $9B");    // Check type == $10 (data).
    __asm__("cmp #$10");
    __asm__("bne %g<error>");  // Branch if not data.
    
    // Load loop: Until size or EOF ($1A block type).
load_loop:
    __asm__("jsr $FC00");  // Load block: Data to $9C/$9D, checksum in A.
    __asm__("sta $9F");    // Store checksum temp.
    __asm__("lda $9B");    // Get block type.
    __asm__("cmp #$1A");   // EOF?
    __asm__("beq %g<done>");
    __asm__("cmp #$10");   // Data cont.?
    __asm__("bne %g<load_loop>");  // Skip silent/noise blocks.
    
    // Copy loaded block to dest (ROM loads to temp $3000+, but for data it's direct? Adjust.
    // Note: ROM $FC00 loads to addr from header ($9C/Y).
    // If header specifies dest, it's already there; else copy.
    // For simplicity, assume header addr matches dest; else add memcpy asm.
    __asm__("ldx #$00");
copy_block:
    __asm__("lda $3000,x");  // Assume ROM temp buf $3000 (check ROM map).
    __asm__("sta %v,x", addr);
    __asm__("inx");
    __asm__("cpx #$FF");  // 256 bytes/block max? Oric blocks var, up to 256.
    __asm__("bne %g<copy_block>");
    __asm__("inc %v+1", addr);  // Next page if multi.
    __asm__("lda %v", bytes_loaded);
    __asm__("clc");
    __asm__("adc #$100");
    __asm__("sta %v", bytes_loaded);
    __asm__("cmp %v", size);
    __asm__("bcc %g<load_loop>");  // Cont if < size.
    
done:
    __asm__("lda #$00");
    __asm__("rts");
error:
    __asm__("lda #$FF");
    __asm__("rts");
    
    // Post: If success, bytes_loaded has total.
    return (bytes_loaded >= size) ? 0 : -1;
}

int main(void) {
    clrscr();  // Clear screen.
    gotoxy(0,0);
    cprintf("Loading screen...");
    
    if (load_tape_data("SCREEN   ", screen_buffer, LOAD_SIZE) == 0) {
        cprintf("Loaded OK. Continuing...");
        // Now your program logic: e.g., the screen is at $A000, process/display.
        // Infinite loop or whatever.
        while(1);  // Placeholder.
    } else {
        cprintf("Load fail!");
        while(1);
    }
    
    return 0;  // Won't reach, but good form.
}
