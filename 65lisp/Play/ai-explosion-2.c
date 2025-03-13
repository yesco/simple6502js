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

// Color cycle for rows
const char *colors[] = {"Red", "Yellow", "White"};
#define NUM_COLORS 3

// Seed for randomness
void seed_random() {
    srand((unsigned)time(NULL));
}

// Helper: Add chaos with unset pixels
int is_pixel_unset(int x, int y, int frame) {
    // Randomly unset pixels for texture, more in later frames
    int chaos_factor = frame * 3 + rand() % 10;
    return (rand() % 100 < chaos_factor) ? 1 : 0;
}

// Function to initialize the explosion animation frames
void init_explosion_sprites() {
    seed_random();

    // Frame 1: Small, spiky spark
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            explosion[0][y][x] = (dist <= 4 && rand() % 3 != 0) ? 'x' : '_'; // Jagged spark
        }
    }

    // Frame 2: Bursting fireball with tendrils
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            int noise = rand() % 6;
            if (dist <= 16 + noise && !is_pixel_unset(x, y, 1)) {
                explosion[1][y][x] = 'x'; // Spiky, uneven burst
            } else {
                explosion[1][y][x] = '_';
            }
        }
    }

    // Frame 3: Expanding chaos, irregular edges
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            int noise = rand() % 8;
            if (dist <= 36 + noise && !is_pixel_unset(x, y, 2)) {
                explosion[2][y][x] = 'x'; // Tendrils and gaps
            } else {
                explosion[2][y][x] = '_';
            }
        }
    }

    // Frame 4: Peak explosion, full 24x24 with edgy texture
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            int noise = rand() % 12;
            if (dist <= 144 + noise && !is_pixel_unset(x, y, 3)) {
                explosion[3][y][x] = 'x'; // Full size, chaotic
            } else {
                explosion[3][y][x] = '_';
            }
            // Extra edge spikes
            if (dist > 100 && rand() % 5 == 0) explosion[3][y][x] = 'x';
        }
    }

    // Frame 5: Fading with scattered remnants
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            int noise = rand() % 8;
            if (dist <= 100 + noise && !is_pixel_unset(x, y, 4)) {
                explosion[4][y][x] = 'x'; // Shrinking, fragmented
            } else {
                explosion[4][y][x] = '_';
            }
        }
    }

    // Frame 6: Sparse embers, very irregular
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            int dx = x - 12;
            int dy = y - 12;
            int dist = dx * dx + dy * dy;
            explosion[5][y][x] = (dist <= 64 && rand() % 5 == 0) ? 'x' : '_'; // Scattered embers
        }
    }
}

// Function to print a frame with color labels
void print_sprite(int frame) {
    if (frame < 0 || frame >= NUM_FRAMES) return;
    printf("Frame %d:\n", frame + 1);
    for (int y = 0; y < SPRITE_HEIGHT; y++) {
        const char *color = colors[y % NUM_COLORS];
        printf("%6s: ", color);
        for (int x = 0; x < SPRITE_WIDTH; x++) {
            printf("%c", explosion[frame][y][x]);
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
