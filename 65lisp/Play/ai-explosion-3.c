#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Define sprite dimensions
#define SPRITE_WIDTH 24
#define SPRITE_HEIGHT 24
#define NUM_FRAMES 6

// Type for a single pixel ('x' for colored, '_' for black)
typedef char Pixel;

// A single frame is a 24x24 array of pixels
typedef Pixel Sprite[SPRITE_HEIGHT][SPRITE_WIDTH];

// Array to hold all 6 frames of the explosion
Sprite explosion[NUM_FRAMES];

// Color names for rows (cycle every 3)
const char *colors[] = {"_RED__", "_YELLO", "_WHITE"};
#define NUM_COLORS 3

// Seed for randomness
void seed_random() {
    srand((unsigned)time(NULL));
}

// Helper: Flame-like irregularity (returns 1 if pixel should be set)
int is_flame_pixel(int x, int y, int base_dist, int frame) {
    int dx = x - 12;
    int dy = y - 12;
    int dist = dx * dx + dy * dy;
    int noise = rand() % (frame * 5 + 5); // More chaos as frames progress
    return (dist <= base_dist + noise && rand() % 3 != 0) ? 1 : 0;
}

// Function to initialize the explosion animation frames
void init_explosion_sprites() {
    seed_random();

    // Frame 1: Small white spark
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[0][y][x] = '_'; // Default black
            if (y % NUM_COLORS == 2) { // White rows
                if (is_flame_pixel(x, y, 2, 0)) {
                    explosion[0][y][x] = 'x'; // Tiny, jagged white spark
                }
            }
        }
    }

    // Frame 2: Yellow flames with red edges
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[1][y][x] = '_';
            int color_idx = y % NUM_COLORS;
            if (color_idx == 1 && is_flame_pixel(x, y, 12, 1)) { // Yellow core
                explosion[1][y][x] = 'x';
            } else if (color_idx == 0 && is_flame_pixel(x, y, 16, 1)) { // Red edges
                explosion[1][y][x] = 'x';
            }
        }
    }

    // Frame 3: Larger flames, yellow core, red tendrils
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[2][y][x] = '_';
            int color_idx = y % NUM_COLORS;
            if (color_idx == 1 && is_flame_pixel(x, y, 25, 2)) { // Yellow flames
                explosion[2][y][x] = 'x';
            } else if (color_idx == 0 && is_flame_pixel(x, y, 36, 2)) { // Red edges
                explosion[2][y][x] = 'x';
            }
        }
    }

    // Frame 4: Peak explosion, full 24x24, yellow/red flames, white smoke hints
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[3][y][x] = '_';
            int color_idx = y % NUM_COLORS;
            if (color_idx == 1 && is_flame_pixel(x, y, 100, 3)) { // Yellow core flames
                explosion[3][y][x] = 'x';
            } else if (color_idx == 0 && is_flame_pixel(x, y, 144, 3)) { // Red tendrils
                explosion[3][y][x] = 'x';
            } else if (color_idx == 2 && rand() % 8 == 0) { // White smoke patches
                explosion[3][y][x] = 'x';
            }
        }
    }

    // Frame 5: Fading flames, more white smoke
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[4][y][x] = '_';
            int color_idx = y % NUM_COLORS;
            if (color_idx == 1 && is_flame_pixel(x, y, 64, 4)) { // Shrinking yellow
                explosion[4][y][x] = 'x';
            } else if (color_idx == 0 && is_flame_pixel(x, y, 80, 4)) { // Red edges
                explosion[4][y][x] = 'x';
            } else if (color_idx == 2 && rand() % 5 == 0) { // More white smoke
                explosion[4][y][x] = 'x';
            }
        }
    }

    // Frame 6: Sparse embers and white smoke cloud
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            explosion[5][y][x] = '_';
            int color_idx = y % NUM_COLORS;
            if (color_idx == 1 && is_flame_pixel(x, y, 25, 5) && rand() % 4 == 0) { // Few yellow embers
                explosion[5][y][x] = 'x';
            } else if (color_idx == 0 && is_flame_pixel(x, y, 36, 5) && rand() % 4 == 0) { // Red embers
                explosion[5][y][x] = 'x';
            } else if (color_idx == 2 && rand() % 3 == 0) { // White smoke cloud
                explosion[5][y][x] = 'x';
            }
        }
    }
}

// Function to print a frame with new format (6 pixels, space, repeat)
void print_sprite(int frame) {
    if (frame < 0 || frame >= NUM_FRAMES) return;
    printf("Frame %d:\n", frame + 1);
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        const char *color = colors[y % NUM_COLORS];
        printf("%s ", color); // Color name followed by space
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            printf("%c", explosion[frame][y][x]);
            if ((x + 1) % 6 == 0 && x < SPRITE_WIDTH - 1) {
                printf(" "); // Space after every 6 pixels
            }
        }
        printf("\n");
    }
    printf("\n");
}

// Main function to test the sprite initialization
int main() {
    init_explosion_sprites();

    // Print all frames for visualization
    for (int i = 0; i < NUM_FRAMES; i++) {
        print_sprite(i);
    }

    return 0;
}
