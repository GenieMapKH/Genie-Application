"""Writes the Android notification icon (the house of the logo, in white).

    python tool/generate_notification_icon.py

Android draws a notification's small icon as a flat shape: only the opaque
parts of the picture count, in one colour. So the full-colour logo cannot be
used (it shows as a plain blob); this makes a white-on-transparent copy of
the house symbol, without the wordmark, at every screen density.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "images" / "brand" / "app_icon_foreground.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# The house and its door, above the wordmark, in the source's 1024 px canvas.
SYMBOL = (380, 280, 645, 550)

# Folder -> icon size in pixels (24 dp at that density).
DENSITIES = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}

# Share of the canvas the symbol fills; Android keeps a margin around it.
FILL = 0.88


def silhouette(size):
    symbol = Image.open(SOURCE).convert("RGBA").crop(SYMBOL)
    alpha = symbol.getchannel("A")
    box = alpha.getbbox()
    alpha = alpha.crop(box)

    scale = size * FILL / max(alpha.size)
    shape = alpha.resize(
        (max(1, round(alpha.width * scale)), max(1, round(alpha.height * scale))),
        Image.LANCZOS,
    )
    icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    white = Image.new("RGBA", shape.size, (255, 255, 255, 255))
    icon.paste(
        white,
        ((size - shape.width) // 2, (size - shape.height) // 2),
        shape,
    )
    return icon


for folder, size in DENSITIES.items():
    target = RES / folder
    target.mkdir(parents=True, exist_ok=True)
    silhouette(size).save(target / "ic_stat_notification.png")
    print(f"{folder}/ic_stat_notification.png  {size}x{size}")
