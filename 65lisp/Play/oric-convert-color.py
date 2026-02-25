from PIL import Image

def get_oric_color(rgb):
    # Map RGB to Oric 3-bit color (0-7)
    r, g, b = (1 if c > 127 else 0 for c in rgb[:3])
    return (b << 2) | (g << 1) | r # Oric uses BGR bit order

def convert_to_oric_color_hires(input_path, output_path):
    img = Image.open(input_path).convert('RGB').resize((240, 200), Image.NEAREST)
    pixels = img.load()
    oric_buffer = bytearray()

    for y in range(200):
        current_ink = 7 # Default White
        line_bytes = []
        
        x_block = 0
        while x_block < 40:
            # 1. Determine dominant color in this 6-pixel block
            block_colors = [get_oric_color(pixels[x_block*6 + i, y]) for i in range(6)]
            dominant_color = max(set(block_colors), key=block_colors.count)

            # 2. If color changes, insert Attribute Byte (0-7)
            if dominant_color != current_ink and x_block < 39:
                line_bytes.append(dominant_color)
                current_ink = dominant_color
                x_block += 1 # Attribute byte "consumes" this 6-pixel block
            
            # 3. Otherwise, insert Graphic Byte (0x40 + 6 bits of data)
            if x_block < 40:
                byte_value = 0x40
                for bit in range(6):
                    px_color = get_oric_color(pixels[x_block*6 + bit, y])
                    if px_color != 0: # If not black, treat as "on"
                        byte_value |= (1 << (5 - bit))
                line_bytes.append(byte_value)
                x_block += 1

        oric_buffer.extend(line_bytes[:40]) # Ensure exactly 40 bytes

    with open(output_path, "wb") as f:
        f.write(oric_buffer)


# Usage

#convert_to_oric_color_hires("test-image.png", "buffer.raw")
#convert_to_oric_color_hires("monoscope.jpg", "buffer.raw")
#convert_to_oric_color_hires("test-image-black.png", "buffer.raw")
convert_to_oric_color_hires("impossible-colors-oric-maghs-twilite.jpg", "buffer.raw")
