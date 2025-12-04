from PIL import Image
import os

# === EINSTELLUNGEN ===
input_folder = r"C:\plantyrecipes\assets\images\scrape"
output_folder = os.path.join(input_folder, "optimized")
max_size = 1024  # maximale Seitenlänge in Pixeln
webp_quality = 80  # 0–100, niedriger = kleinere Datei

# === SETUP ===
os.makedirs(output_folder, exist_ok=True)

def make_square(im: Image.Image) -> Image.Image:
    """Bringt ein Bild auf quadratisches Format. Fügt transparenten Hintergrund hinzu, wenn nötig."""
    w, h = im.size
    if w == h:
        return im  # schon 1:1

    # quadratisches Canvas mit Transparenz
    size = max(w, h)
    new_im = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Bild mittig einfügen – fügt oben/unten oder links/rechts transparent hinzu
    offset = ((size - w) // 2, (size - h) // 2)
    new_im.paste(im, offset)
    return new_im

def resize_and_convert(path: str):
    name = os.path.basename(path)
    out_path = os.path.join(output_folder, os.path.splitext(name)[0] + ".webp")

    try:
        im = Image.open(path).convert("RGBA")

        # Quadrat herstellen (transparent ergänzen, falls nötig)
        im = make_square(im)

        # Runterskalieren falls größer als max_size
        im.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

        # Speichern als lossy WebP
        im.save(out_path, "WEBP", quality=webp_quality, method=6)
        print(f"✅ {name} → {os.path.basename(out_path)} ({im.size[0]}x{im.size[1]})")

    except Exception as e:
        print(f"❌ Fehler bei {name}: {e}")

def main():
    print(f"Starte Optimierung in: {input_folder}")
    for file in os.listdir(input_folder):
        if file.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
            resize_and_convert(os.path.join(input_folder, file))
    print("Fertig. Optimierte Bilder liegen in:", output_folder)

if __name__ == "__main__":
    main()



# cd "C:\plantyrecipes\assets\images\scrape"
# python .\scrape_image_size.py    
