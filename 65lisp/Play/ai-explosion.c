#include <stdint.h>
#include <oric.h>  // Oric-specific header from cc65
#include <peekpoke.h>  // For direct memory access

// Oric Atmos HIRES screen memory starts at 0xA000
#define HIRES_BASE 0xA000
#define TEXT_BASE  0xBB80  // Text area at bottom

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

// Set HIRES mode
void init_hires() {
    POKE(0x26A, 0x80);  // Enable HIRES mode
    POKE(HIRES_BASE, 0x18);  // Clear attribute byte for first line
    memset((void*)HIRES_BASE, 0, 8000);  // Clear HIRES screen (8KB)
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
        memset((void*)HIRES_BASE, 0, 8000);

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

        // Check for keypress to exit (e.g., ESC)
        if (PEEK(0x208) != 0) {  // Keyboard register
            break;
        }
    }

    // Return to text mode
    POKE(0x26A, 0x00);
}

int main() {
    animate_explosion();
    return 0;
}
