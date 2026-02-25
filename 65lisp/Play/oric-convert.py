from PIL import Image

def convert_to_oric_hires(input_path, output_path):
    # 1. Load and resize to Oric HIRES resolution: 240x200
    img = Image.open(input_path).convert('L') # Convert to grayscale
    img = img.resize((240, 200), Image.NEAREST)
    
    # 2. Threshold image to black and white (1-bit)
    img = img.point(lambda x: 1 if x > 128 else 0, mode='1')
    pixels = img.load()
    
    oric_buffer = bytearray()

    for y in range(200):
        for x_block in range(40): # 40 bytes per line
            byte_value = 0x40 # Base bit 6 set to 1 for "graphic" mode
            
            # 3. Pack 6 pixels into bits 0-5
            for bit in range(6):
                px = pixels[x_block * 6 + bit, y]
                if px: # If pixel is "on" (foreground color)
                    byte_value |= (1 << (5 - bit)) # Oric uses bit 5 for first pixel
                    
            oric_buffer.append(byte_value)

    # 4. Save the 8000-byte raw buffer
    with open(output_path, "wb") as f:
        f.write(oric_buffer)
        print(f"Successfully saved 8000 bytes to {output_path}")

# Usage
convert_to_oric_hires("test-image.png", "buffer.raw")
#convert_to_oric_hires("monoscope.jpg", "buffer.raw")
#convert_to_oric_hires("test-image-black.jpg", "buffer.raw")
