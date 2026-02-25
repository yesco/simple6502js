#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#define ORIC_WIDTH  240
#define ORIC_HEIGHT 200
#define BYTES_PER_LINE 40
#define MEM_SIZE 8000
#define SCALE 4 

uint8_t hires[MEM_SIZE];

const char* SIXEL_INIT = "\033Pq#0;2;0;0;0#1;2;100;0;0#2;2;0;100;0#3;2;100;100;0#4;2;0;0;100#5;2;100;0;100#6;2;0;100;100#7;2;100;100;100";
const char* SIXEL_EXIT = "\033\\";

void setup_clean_test_card() {
  // Fill with "Graphic" bytes (Bit 6 = 1), default bits all OFF (Black)
  memset(hires, 0x40, MEM_SIZE);

  for (int y = 0; y < ORIC_HEIGHT; y++) {
    int line = y * BYTES_PER_LINE;

    // 1. SET ATTRIBUTES AT START OF LINE
    // Column 0: Paper Color (changes every 25 lines for horizontal bands)
    hires[line + 0] = 16 + ((y / 25) % 8); 
    // Column 1: Ink Color (White for the circle/grid)
    hires[line + 1] = 7; 

    // 2. DRAW CENTERED CIRCLE & GRID
    double cx = 120.0; // Center X (of 240)
    double cy = 100.0; // Center Y (of 200)
    double r  = 75.0;  // Radius
        
    // Start from byte 2 to avoid overwriting attributes in 0 and 1
    for (int b = 2; b < BYTES_PER_LINE; b++) {
      uint8_t byte_pixels = 0;
      for (int bit = 0; bit < 6; bit++) {
        // Oric bit order: Bit 5 is left, Bit 0 is right
        double px = (double)(b * 6 + (5 - bit));
        double py = (double)y;
                
        double dist = sqrt(pow(px - cx, 2) + pow(py - cy, 2));

        int is_on = 0;
        // Draw white circle outline (2 pixels thick)
        if (dist >= r && dist <= r + 2.5) {
          is_on = 1;
        }
        // Draw a 20x20 background grid
        else if (((int)px % 20 == 0) || ((int)py % 20 == 0)) {
          is_on = 1;
        }
        // Draw a central cross
        if (fabs(px - cx) < 1.0 || fabs(py - cy) < 1.0) {
          is_on = 1;
        }

        if (is_on) byte_pixels |= (1 << bit);
      }
      hires[line + b] = 0x40 | byte_pixels;
    }
  }
}

void draw_sixel_oric() {
  printf("%s", SIXEL_INIT);
    
  for (int band_y = 0; band_y < ORIC_HEIGHT * SCALE; band_y += 6) {
    for (int color_idx = 0; color_idx < 8; color_idx++) {
      printf("#%d", color_idx);
            
      for (int xb = 0; xb < BYTES_PER_LINE; xb++) {
        for (int bit = 5; bit >= 0; bit--) {
          for (int sx = 0; sx < SCALE; sx++) {
            uint8_t sixel = 0;
            for (int dy = 0; dy < 6; dy++) {
              int ry = (band_y + dy) / SCALE;
              if (ry >= ORIC_HEIGHT) continue;

              // Standard Oric State logic
              uint8_t ink = 7, paper = 0;
              int line_start = ry * BYTES_PER_LINE;
              for (int i = 0; i <= xb; i++) {
                uint8_t attr = hires[line_start + i];
                if ((attr & 0x60) == 0) {
                  if ((attr & 0x1F) <= 7) ink = attr & 0x07;
                  else if ((attr & 0x1F) >= 16) paper = attr & 0x07;
                }
              }

              uint8_t b = hires[line_start + xb];
              uint8_t f_ink = (b & 0x80) ? paper : ink;
              uint8_t f_paper = (b & 0x80) ? ink : paper;

              if (b & 0x40) {
                if (((b & (1 << bit)) ? f_ink : f_paper) == color_idx) sixel |= (1 << dy);
              } else if (f_paper == color_idx) {
                sixel |= (1 << dy);
              }
            }
            putchar(sixel + 63);
          }
        }
      }
      putchar('$');
    }
    putchar('-');
  }
  printf("%s", SIXEL_EXIT);
  fflush(stdout);
}

int main(int argc, char** argv) {
  if (argc<=1) {
    setup_clean_test_card();
  } else {
    FILE* f= fopen(argv[1], "r");
    fread(hires, 8000, 1, f);
    fclose(f);
  }

  draw_sixel_oric();

  return 0;
}
