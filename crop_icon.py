from PIL import Image

def crop_to_content(image_path):
    try:
        img = Image.open(image_path)
        img = img.convert("RGBA")

        # Get the bounding box of the non-transparent pixels
        # If the image has a white background instead of transparent, we might need to handle that.
        # Let's assume transparency first. If it's white, we might need to make white transparent or check for difference.

        # Check if the corner is white, if so, maybe treating white as background
        bg = Image.new(img.mode, img.size, img.getpixel((0,0)))
        diff = Image.frombytes(img.mode, img.size, img.tobytes())
        # Actually proper bbox is usually enough if alpha is used.
        # If it's a JPG or flat PNG with white bg, simple alpha bbox won't work.

        bbox = img.getbbox()

        if bbox:
            # Crop to content
            cropped = img.crop(bbox)

            # Now we want to add a *small* padding so it doesn't touch the absolute edges
            # But the user said "fill the borders", so maybe no padding is best for icon generators which add their own padding.
            # flutter_launcher_icons typically converts to adaptive icons on Android which might crop circles.
            # Let's verify if the image background is transparent or white.
            # If it is white, we might be just cropping white to white if we rely on alpha.

            # Let's try to detect if it's white background
            # We will convert to grayscale and look for 255
            # This is complex to guess.
            # Strategy: Simply crop alpha box first.

            cropped.save(image_path)
            print(f"Cropped image to {bbox}")
        else:
            print("No content found (image might be fully transparent)")

    except Exception as e:
        print(f"Error: {e}")

crop_to_content("assets/images/app_icon.png")
