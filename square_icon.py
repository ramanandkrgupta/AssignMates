from PIL import Image

def square_image(path):
    try:
        img = Image.open(path).convert("RGBA")
        w, h = img.size
        size = max(w, h)

        # Create square white background
        new_img = Image.new("RGBA", (size, size), (255, 255, 255, 255))

        # Paste centered
        x = (size - w) // 2
        y = (size - h) // 2
        new_img.paste(img, (x, y), img) # Use img as mask if it has transparency

        new_img.save(path)
        print(f"Squared image to {size}x{size}")

    except Exception as e:
        print(f"Error: {e}")

square_image("assets/images/app_icon.png")
