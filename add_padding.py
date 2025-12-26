from PIL import Image

def add_padding(path, scale_factor=1.5):
    try:
        img = Image.open(path).convert("RGBA")
        old_w, old_h = img.size

        # New size based on scale factor (to shrink content relative to canvas)
        # If we want content to be 66% of canvas: new_size = old_size / 0.66 ~= old_size * 1.5
        new_w = int(old_w * scale_factor)
        new_h = int(old_h * scale_factor)
        size = max(new_w, new_h)

        # Create white background
        new_img = Image.new("RGBA", (size, size), (255, 255, 255, 255))

        # Center the original image
        x = (size - old_w) // 2
        y = (size - old_h) // 2

        new_img.paste(img, (x, y), img)

        new_img.save(path)
        print(f"Added padding. New size: {size}x{size}. Original: {old_w}x{old_h}")

    except Exception as e:
        print(f"Error: {e}")

# Re-run aggressive crop first to ensure we have clean content (optional if we implicitly trust current state, but safer to just pad current)
# Actually, the user said "quality is perfect", so the *source* is good, just layout bad.
# Current state: app_icon.png is the "zoomed in" version.
add_padding("assets/images/app_icon.png", scale_factor=1.5)
