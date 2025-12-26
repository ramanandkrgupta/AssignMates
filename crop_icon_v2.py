from PIL import Image, ImageChops

def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

def process_icon(path):
    try:
        img = Image.open(path)
        img = img.convert("RGBA")

        # Trim borders (assuming top-left pixel color is background)
        cropped = trim(img)

        # Save
        cropped.save(path)
        print(f"Trimmed image to new size: {cropped.size}")
    except Exception as e:
        print(f"Error: {e}")

process_icon("assets/images/app_icon.png")
