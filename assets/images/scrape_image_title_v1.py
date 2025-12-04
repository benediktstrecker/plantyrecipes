import os
import re

def rename_files():
    # Ordner mit den Bildern
    folder = r"C:\plantyrecipes\assets\images\recipes"

    for filename in os.listdir(folder):
        print("Prüfe:", filename)

        if filename.lower().endswith((".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".webp")):
            name, ext = os.path.splitext(filename)

            # alles klein
            new_name = name.lower()

            # deutsche Sonderzeichen
            new_name = (new_name
                        .replace("ä", "ae")
                        .replace("ö", "oe")
                        .replace("ü", "ue")
                        .replace("ß", "ss"))

            # Leerzeichen und Kommas
            new_name = new_name.replace(" ", "_").replace(",", "_")

            # führende Zahlen + Leerzeichen oder Unterstrich entfernen (z. B. "01 " oder "03_")
            new_name = re.sub(r'^[0-9]+\s*_?', '', new_name)

            # verbotene Zeichen entfernen oder ersetzen
            new_name = re.sub(r'[\\/:*?"<>|]', '_', new_name)

            # Dateiendung klein
            final_name = new_name + ext.lower()

            # umbenennen
            if final_name != filename:
                os.rename(os.path.join(folder, filename),
                          os.path.join(folder, final_name))
                print(f"{filename} → {final_name}")

if __name__ == "__main__":
    rename_files()
