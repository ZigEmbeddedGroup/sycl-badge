#!/usr/bin/env python3
"""
Convert PNG image to RGB565 format for SYCL Badge LCD
Usage: python convert_pug.py <input.png> <output.zig>
"""

import sys
from PIL import Image

def rgb888_to_rgb565(r, g, b):
    """Convert 24-bit RGB to 16-bit RGB565"""
    r5 = (r >> 3) & 0x1F  # 5 bits for red
    g6 = (g >> 2) & 0x3F  # 6 bits for green
    b5 = (b >> 3) & 0x1F  # 5 bits for blue
    
    # Pack into RGB565 format (BGR for ST7735)
    hi = (b5 << 3) | (g6 >> 3)
    lo = ((g6 & 0x07) << 5) | r5
    
    return hi, lo

def convert_image(input_path, output_path, target_width=160, target_height=128):
    """Convert PNG to RGB565 Zig array"""
    
    # Load and resize image
    img = Image.open(input_path)
    print(f"Original image size: {img.size}")
    
    # Convert to RGB if necessary
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Resize to target dimensions
    img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
    print(f"Resized to: {img.size}")
    
    # Convert to RGB565
    pixels = img.load()
    rgb565_data = []
    
    for y in range(target_height):
        for x in range(target_width):
            r, g, b = pixels[x, y]
            hi, lo = rgb888_to_rgb565(r, g, b)
            rgb565_data.append(hi)
            rgb565_data.append(lo)
    
    # Write Zig file
    with open(output_path, 'w') as f:
        f.write("// Auto-generated RGB565 image data from pugImg.png\n")
        f.write(f"// {target_width}x{target_height} pixels, 2 bytes per pixel (RGB565 format)\n\n")
        f.write(f"pub const pug_image_data: [{len(rgb565_data)}]u8 = .{{\n")
        
        for i in range(0, len(rgb565_data), 16):
            line = "    "
            for j in range(i, min(i + 16, len(rgb565_data))):
                line += f"0x{rgb565_data[j]:02X}, "
            f.write(line + "\n")
        
        f.write("};\n")
    
    print(f"Converted {input_path} to {output_path}")
    print(f"Output size: {len(rgb565_data)} bytes ({target_width} x {target_height} pixels)")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python convert_pug.py <input.png> <output.zig>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        convert_image(input_file, output_file)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
