#include <stdint.h>

// Oric Atmos memory locations
#define HIRES_BASE 0xA000  // HIRES screen memory start
#define TEXT_BASE  0xBB80  // Text area at bottom
#define MODE_REG   0x026A  // Mode register (HIRES/TEXT)
#define KEY_REG    0x0208  // Keyboard status register

// Oric color codes (foreground in attribute byte)
uint8_t colors[] = {
    0x00, // Black
    0x01, // Red
    0x02, // Green
    0x03, // Yellow
    0x04, // Blue
    0x05, // Magenta
    0x06, // Cyan
    0x07  // White
};

// Precomputed sprite data: 24x24 pixels, 4 blocks (6 pixels each) per row
// Each row has 8 bytes: 4 attribute bytes + 4 pixel bytes
uint8_t explosion_sprites[3][24][8] = {
    // Stage 1: Small burst (centered 8x8 expanded to 24x24)
    {
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0,0,0b000110,0}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001111,0}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001111,0}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0,0,0b000110,0}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    },
    // Stage 2: Medium burst
    {
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001100,0}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0,0,0b011110,0}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b111111}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b110011}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0,0b011111,0b110011}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b111111,0b110000}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0b000111,0b111111,0b111000}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111100}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111100}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0b000111,0b111111,0b111000}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b111111,0b110000}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0,0b011111,0b110011}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b110011}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b111111}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0,0b011110,0}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001100,0}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    },
    // Stage 3: Large burst (spiky)
    {
        {0x10, 0x10, 0x10, 0x10, 0,0b001100,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0b011110,0b110000}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b001100}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b110011,0b111000}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111110}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0b011111,0b110011,0b001111}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b110011}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0b001100,0b111111,0b111000}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0b011110,0b110011,0b001100}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111110}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0b110011,0b111111,0b110011}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111111}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0b110011,0b111111,0b110011}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111110}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0b011110,0b110011,0b001100}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0b001100,0b111111,0b111000}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b110011}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0b011111,0b110011,0b001111}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111110}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b110011,0b111000}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b001100}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0b011110,0b110000}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0b001100,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    }
};

// Simple delay function
void delay(uint16_t cycles) {
    while (cycles--) {
        __asm__("nop");
    }
}

// Set HIRES mode and clear screen once
void init_hires() {
    volatile uint8_t* mode_reg;
    volatile uint8_t* hires_mem;
    uint16_t i;

    mode_reg = (volatile uint8_t*)MODE_REG;
    hires_mem = (volatile uint8_t*)HIRES_BASE;
    
    *mode_reg = 0x80;  // Enable HIRES mode
    *hires_mem = 0x18; // Default attribute
    
    for (i = 0; i < 8000; i++) {
        hires_mem[i] = 0;
    }
}

// Draw 24x24 sprite using precomputed data
void draw_sprite(uint16_t screen_addr, uint8_t sprite_idx, uint8_t color) {
    uint8_t row;
    volatile uint8_t* screen;
    uint8_t col;

    screen = (volatile uint8_t*)screen_addr;

    for (row = 0; row < 24; row++) {
        for (col = 0; col < 4; col++) {
            // Write attribute with color
            screen[col * 2] = 0x10 | colors[color];
            // Write pixel data
            screen[col * 2 + 1] = explosion_sprites[sprite_idx][row][col + 4];
        }
        screen += 40;  // Next row (40 bytes per line)
    }
}

// Main explosion animation
void animate_explosion() {
    uint8_t center_x;
    uint8_t center_y;
    uint16_t screen_addr;
    uint8_t stage;
    uint8_t max_stage;
    uint8_t color_idx;
    volatile uint8_t* screen;
    volatile uint8_t* key_reg;
    uint16_t i;

    center_x = 120;  // Middle of 240px width
    center_y = 88;   // Adjusted to fit 24x24 in 200px height (88 = 100 - 12)
    screen_addr = HIRES_BASE + (center_y * 40) + (center_x / 6) - 2; // Center 24px sprite
    stage = 0;
    max_stage = 3;
    color_idx = 0;

    init_hires();

    screen = (volatile uint8_t*)HIRES_BASE;
    key_reg = (volatile uint8_t*)KEY_REG;

    while (1) {
        // Clear only the sprite area (24 rows, 8 bytes wide)
        for (i = 0; i < 24; i++) {
            screen[screen_addr + (i * 40)] = 0x10;     // Attr 1
            screen[screen_addr + (i * 40) + 1] = 0;    // Pixels 1
            screen[screen_addr + (i * 40) + 2] = 0x10; // Attr 2
            screen[screen_addr + (i * 40) + 3] = 0;    // Pixels 2
            screen[screen_addr + (i * 40) + 4] = 0x10; // Attr 3
            screen[screen_addr + (i * 40) + 5] = 0;    // Pixels 3
            screen[screen_addr + (i * 40) + 6] = 0x10; // Attr 4
            screen[screen_addr + (i * 40) + 7] = 0;    // Pixels 4
        }

        // Draw current explosion stage
        draw_sprite(screen_addr, stage, color_idx);

        // Update stage and color
        stage++;
        if (stage >= max_stage) {
            stage = 0;
            color_idx = (color_idx + 1) % 8;
        }

        // Delay for animation
        delay(6000);  // Adjusted for larger sprite

        // Check for keypress to exit
        if (*key_reg != 0) {
            break;
        }
    }

    // Return to text mode
    {
        volatile uint8_t* mode_reg;
        mode_reg = (volatile uint8_t*)MODE_REG;
        *mode_reg = 0x00;
    }
}

int main() {
    animate_explosion();
    return 0;
}#include <stdint.h>

// Oric Atmos memory locations
#define HIRES_BASE 0xA000  // HIRES screen memory start
#define TEXT_BASE  0xBB80  // Text area at bottom
#define MODE_REG   0x026A  // Mode register (HIRES/TEXT)
#define KEY_REG    0x0208  // Keyboard status register

// Oric color codes (foreground in attribute byte)
uint8_t colors[] = {
    0x00, // Black
    0x01, // Red
    0x02, // Green
    0x03, // Yellow
    0x04, // Blue
    0x05, // Magenta
    0x06, // Cyan
    0x07  // White
};

// Precomputed sprite data: 24x24 pixels, 4 blocks (6 pixels each) per row
// Each row has 8 bytes: 4 attribute bytes + 4 pixel bytes
uint8_t explosion_sprites[3][24][8] = {
    // Stage 1: Small burst (centered 8x8 expanded to 24x24)
    {
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0,0,0b000110,0}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001111,0}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001111,0}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0,0,0b000110,0}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    },
    // Stage 2: Medium burst
    {
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001100,0}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0,0,0b011110,0}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b111111}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b110011}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0,0b011111,0b110011}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b111111,0b110000}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0b000111,0b111111,0b111000}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111100}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111100}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0b000111,0b111111,0b111000}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b111111,0b110000}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0,0b011111,0b110011}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b110011}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0,0b001111,0b111111}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0,0b000111,0b111110}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0,0b000011,0b111100}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0,0b011110,0}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0,0b001100,0}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    },
    // Stage 3: Large burst (spiky)
    {
        {0x10, 0x10, 0x10, 0x10, 0,0b001100,0,0}, // Row 0
        {0x10, 0x10, 0x10, 0x10, 0,0b011110,0b110000}, // Row 1
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b001100}, // Row 2
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b110011,0b111000}, // Row 3
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111110}, // Row 4
        {0x10, 0x10, 0x10, 0x10, 0b011111,0b110011,0b001111}, // Row 5
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b110011}, // Row 6
        {0x10, 0x10, 0x10, 0x10, 0b001100,0b111111,0b111000}, // Row 7
        {0x10, 0x10, 0x10, 0x10, 0b011110,0b110011,0b001100}, // Row 8
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111110}, // Row 9
        {0x10, 0x10, 0x10, 0x10, 0b110011,0b111111,0b110011}, // Row 10
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111111}, // Row 11
        {0x10, 0x10, 0x10, 0x10, 0b110011,0b111111,0b110011}, // Row 12
        {0x10, 0x10, 0x10, 0x10, 0b111111,0b111111,0b111110}, // Row 13
        {0x10, 0x10, 0x10, 0x10, 0b011110,0b110011,0b001100}, // Row 14
        {0x10, 0x10, 0x10, 0x10, 0b001100,0b111111,0b111000}, // Row 15
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b110011}, // Row 16
        {0x10, 0x10, 0x10, 0x10, 0b011111,0b110011,0b001111}, // Row 17
        {0x10, 0x10, 0x10, 0x10, 0b001111,0b111111,0b111110}, // Row 18
        {0x10, 0x10, 0x10, 0x10, 0b000011,0b110011,0b111000}, // Row 19
        {0x10, 0x10, 0x10, 0x10, 0,0b111111,0b001100}, // Row 20
        {0x10, 0x10, 0x10, 0x10, 0,0b011110,0b110000}, // Row 21
        {0x10, 0x10, 0x10, 0x10, 0,0b001100,0,0}, // Row 22
        {0x10, 0x10, 0x10, 0x10, 0,0,0,0}  // Row 23
    }
};

// Simple delay function
void delay(uint16_t cycles) {
    while (cycles--) {
        __asm__("nop");
    }
}

// Set HIRES mode and clear screen once
void init_hires() {
    volatile uint8_t* mode_reg;
    volatile uint8_t* hires_mem;
    uint16_t i;

    mode_reg = (volatile uint8_t*)MODE_REG;
    hires_mem = (volatile uint8_t*)HIRES_BASE;
    
    *mode_reg = 0x80;  // Enable HIRES mode
    *hires_mem = 0x18; // Default attribute
    
    for (i = 0; i < 8000; i++) {
        hires_mem[i] = 0;
    }
}

// Draw 24x24 sprite using precomputed data
void old_draw_sprite(uint16_t screen_addr, uint8_t sprite_idx, uint8_t color) {
    uint8_t row;
    volatile uint8_t* screen;
    uint8_t col;

    screen = (volatile uint8_t*)screen_addr;

    for (row = 0; row < 24; row++) {
        for (col = 0; col < 4; col++) {
            // Write attribute with color
            screen[col * 2] = 0x10 | colors[color];
            // Write pixel data
            screen[col * 2 + 1] = explosion_sprites[sprite_idx][row][col + 4];
        }
        screen += 40;  // Next row (40 bytes per line)
    }
}

// Draw 24x24 sprite using precomputed data with assembly-optimized loops
void draw_sprite(uint16_t screen_addr, uint8_t sprite_idx, uint8_t color) {
    uint8_t row;
    volatile uint8_t* screen;
    uint8_t col;

    screen = (volatile uint8_t*)screen_addr;

    __asm__ volatile (
        "ldx #$00          ; X = row counter (0 to 23)\n"
        "loop_row:\n"
        "ldy #$00          ; Y = column counter (0 to 3)\n"
        "loop_col:\n"
        "lda %v,x          ; Load color array base\n"
        "clc\n"
        "adc %v            ; Add color index\n"
        "tax\n"
        "lda %v,x          ; Load color value\n"
        "ora #$10          ; OR with foreground bit\n"
        "sta (%v),y        ; Store attribute at screen + col*2\n"
        "lda %v,x          ; Load sprite pixel data for this row and col\n"
        "sta (%v),y        ; Store pixel data at screen + col*2 + 1\n"
        "iny\n"
        "iny               ; Move to next block (2 bytes per block)\n"
        "cpy #$08          ; Compare Y with 8 (4 blocks * 2 bytes)\n"
        "bne loop_col      ; Branch if not done\n"
        "ldy #$00          ; Reset Y for next row\n"
        "txa               ; Transfer X to A for row increment\n"
        "clc\n"
        "adc #$08          ; Move to next row in sprite data (8 bytes per row)\n"
        "tax               ; Put back in X\n"
        "inx               ; Increment row counter\n"
        "cpx #$18          ; Compare with 24 (24 rows)\n"
        "bne loop_row      ; Branch if not done\n"
        : /* outputs */
        : "r" (colors), "r" (color), "r" (explosion_sprites[sprite_idx]), "r" (screen)
        : "x", "y", "a" /* clobbers */
    );
}

// Main explosion animation
void animate_explosion() {
    uint8_t center_x;
    uint8_t center_y;
    uint16_t screen_addr;
    uint8_t stage;
    uint8_t max_stage;
    uint8_t color_idx;
    volatile uint8_t* screen;
    volatile uint8_t* key_reg;
    uint16_t i;

    center_x = 120;  // Middle of 240px width
    center_y = 88;   // Adjusted to fit 24x24 in 200px height (88 = 100 - 12)
    screen_addr = HIRES_BASE + (center_y * 40) + (center_x / 6) - 2; // Center 24px sprite
    stage = 0;
    max_stage = 3;
    color_idx = 0;

    init_hires();

    screen = (volatile uint8_t*)HIRES_BASE;
    key_reg = (volatile uint8_t*)KEY_REG;

    while (1) {
        // Clear only the sprite area (24 rows, 8 bytes wide)
        for (i = 0; i < 24; i++) {
            screen[screen_addr + (i * 40)] = 0x10;     // Attr 1
            screen[screen_addr + (i * 40) + 1] = 0;    // Pixels 1
            screen[screen_addr + (i * 40) + 2] = 0x10; // Attr 2
            screen[screen_addr + (i * 40) + 3] = 0;    // Pixels 2
            screen[screen_addr + (i * 40) + 4] = 0x10; // Attr 3
            screen[screen_addr + (i * 40) + 5] = 0;    // Pixels 3
            screen[screen_addr + (i * 40) + 6] = 0x10; // Attr 4
            screen[screen_addr + (i * 40) + 7] = 0;    // Pixels 4
        }

        // Draw current explosion stage
        draw_sprite(screen_addr, stage, color_idx);

        // Update stage and color
        stage++;
        if (stage >= max_stage) {
            stage = 0;
            color_idx = (color_idx + 1) % 8;
        }

        // Delay for animation
        delay(6000);  // Adjusted for larger sprite

        // Check for keypress to exit
        if (*key_reg != 0) {
            break;
        }
    }

    // Return to text mode
    {
        volatile uint8_t* mode_reg;
        mode_reg = (volatile uint8_t*)MODE_REG;
        *mode_reg = 0x00;
    }
}

int main() {
    animate_explosion();
    return 0;
}
#include <stdint.h>

