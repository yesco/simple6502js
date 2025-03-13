#include <stdint.h>
#include <peekpoke.h>  // For PEEK and POKE

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

// Simple delay function
void delay(uint16_t cycles) {
    while (cycles--) {
        __asm__("nop");
    }
}

// Set HIRES mode and clear screen
void init_hires() {
    POKE(MODE_REG, 0x80);  // Enable HIRES mode (bit 7 high)
    POKE(HIRES_BASE, 0x18);  // Default attribute byte for first line
    uint16_t i;
    for (i = 0; i < 8000; i++) {  // Clear 8KB of HIRES memory
        POKE(HIRES_BASE + i, 0);
    }
}

// Plot a pixel in HIRES mode (simplified, no bounds checking)
void plot_pixel(uint8_t x, uint8_t y, uint8_t color) {
    uint16_t addr = HIRES_BASE + (y * 40) + (x / 6);  // 40 bytes per line, 6 pixels per byte
    uint8_t bit_pos = 5 - (x % 6);  // Bit position within byte (0-5)
    uint8_t mask = 1 << bit_pos;
    uint8_t byte = PEEK(addr + 1);  // Pixel data is offset by 1 from attribute
    
    // Set attribute (color) for the 6x1 block
    POKE(addr, 0x10 | color);  // 0x10 = foreground, color = 0-7
    
    // Set the pixel
    POKE(addr + 1, byte | mask);
}

// Draw a circle (Bresenham's algorithm, adapted)
void draw_circle(uint8_t xc, uint8_t yc, uint8_t r, uint8_t color) {
    int8_t x = 0;
    int8_t y = r;
    int8_t d = 3 - 2 * r;
    
    while (y >= x) {
        plot_pixel(xc + x, yc + y, color);
        plot_pixel(xc - x, yc + y, color);
        plot_pixel(xc + x, yc - y, color);
        plot_pixel(xc - x, yc - y, color);
        plot_pixel(xc + y, yc + x, color);
        plot_pixel(xc - y, yc + x, color);
        plot_pixel(xc + y, yc - x, color);
        plot_pixel(xc - y, yc - x, color);
        
        if (d < 0) {
            d += 4 * x + 6;
        } else {
            d += 4 * (x - y) + 10;
            y--;
        }
        x++;
    }
}

// Main explosion animation
void animate_explosion() {
    uint8_t center_x = 120;  // Middle of 240px width
    uint8_t center_y = 100;  // Middle of 200px height (avoiding text area)
    uint8_t radius = 1;
    uint8_t max_radius = 30; // Smaller due to Oric limitations
    uint8_t color_idx = 0;

    init_hires();

    while (1) {
        // Clear screen (black)
        uint16_t i;
        for (i = 0; i < 8000; i++) {
            POKE(HIRES_BASE + i, 0);
        }

        // Draw explosion
        draw_circle(center_x, center_y, radius, colors[color_idx]);

        // Update radius and color
        radius++;
        if (radius > max_radius) {
            radius = 1;
            color_idx = (color_idx + 1) % 8;  // Cycle through 8 colors
        }

        // Simple delay for animation (tuned for 1 MHz CPU)
        delay(5000);

        // Check for keypress to exit (basic keyboard check)
        if (PEEK(KEY_REG) != 0) {
            break;
        }
    }

    // Return to text mode
    POKE(MODE_REG, 0x00);
}

int main() {
    animate_explosion();
    return 0;
}
