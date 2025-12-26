from PIL import Image, ImageChops, ImageOps

def aggressive_crop(path):
    try:
        img = Image.open(path).convert("RGBA")

        # Create a white background image
        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))

        # Compare
        diff = ImageChops.difference(img, bg)

        # Convert to grayscale
        diff = diff.convert("L")

        # Threshold: any difference > 5 is "content"
        mask = diff.point(lambda x: 255 if x > 5 else 0)

        bbox = mask.getbbox()

        if bbox:
            # Crop
            cropped = img.crop(bbox)

            # Add a small padding (10%) so it's not touching edge exactly (optional, but good for squircle)
            # Actually user wants "fill borders", so minimal padding.
            pad = 20
            w, h = cropped.size
            new_size = (w + 2*pad, h + 2*pad)
            final_img = Image.new("RGBA", new_size, (255, 255, 255, 255))
            final_img.paste(cropped, (pad, pad))

            final_img.save(path)
            print(f"Aggressively cropped to {bbox} and saved with size {final_img.size}")
        else:
            print("No content found.")

    except Exception as e:
        print(f"Error: {e}")

aggressive_crop("assets/images/app_icon.png")
