#include <stdio.h>
#include <stdlib.h>
#include <atmos.h>  // For Oric-specific defines, if needed (e.g., screen memory at $A000)

// Example: Load a 1K screen dump from tape into a buffer.
// Adjust BUFFER_SIZE, load address, etc., based on your data.
#define BUFFER_SIZE 1024
#define TAPE_FILENAME "SCREEN"  // Name of your tape file (up to 11 chars)

//dummy
char T,nil,print,doapply1;

unsigned char buffer[BUFFER_SIZE];  // Or use a fixed address like unsigned char *buffer = (unsigned char *)0xA000;

int main(void) {
    FILE *tape;
    size_t bytes_read;

    // Open the tape file for binary read. Prefix with "T:" to use the tape driver.
    tape = fopen("T:" TAPE_FILENAME, "rb");
    if (tape == NULL) {
        // Error: Tape not found, bad header, etc. Handle as needed (e.g., print error via conio).
        return 1;
    }

    // Read the entire file content into the buffer.
    // The driver skips tape headers/sync and delivers raw block data.
    bytes_read = fread(buffer, 1, BUFFER_SIZE, tape);
    fclose(tape);

    if (bytes_read == 0) {
        // Error: No data loaded.
        return 1;
    }

    // Now continue with your program—e.g., copy buffer to screen memory.
    // Example: memcpy((void *)0xA000, buffer, bytes_read);  // Requires <string.h>
    
    // Your post-load logic here (e.g., display the loaded screen, process data, etc.).
    // ...

    return 0;
}
