#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "source-screens"
OUT = ROOT / "final"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1290, 2796
DARK = (20, 49, 38)
MINT = (61, 178, 122)
MINT_SOFT = (164, 235, 192)
GOLD = (202, 148, 51)
CREAM = (255, 252, 244)

SCREENS = [
    ("01-start-clear.png", "01-onboarding.png", "Start your\ntolerance break", "A calm plan for getting back to baseline."),
    ("02-track-progress.png", "02-home.png", "Track clear days\nand money saved", "See the streak, the savings, and today’s next step."),
    ("03-recovery-timeline.png", "03-progress.png", "Watch recovery\ncome back online", "Sleep, clarity, cravings, and money in one view."),
    ("04-urge-mode.png", "04-urge.png", "Ride out urges\nin the moment", "Breathe, name the craving, and choose one clean action."),
    ("05-milestones.png", "05-milestone.png", "Celebrate real\nmilestones", "Share the wins that prove the reset is working."),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Avenir Next.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size, index=2 if bold and path.endswith(".ttc") else 0)
        except OSError:
            pass
    return ImageFont.load_default()


TITLE = font(92, True)
SUBTITLE = font(34)
LABEL = font(30, True)


def gradient() -> Image.Image:
    img = Image.new("RGB", (W, H), CREAM)
    px = img.load()
    top = (241, 238, 218)
    bottom = (215, 235, 222)
    for y in range(H):
        t = y / (H - 1)
        row = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(W):
            px[x, y] = row
    return img.convert("RGBA")


def blob_layer() -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for box, color in [
        ((-260, 240, 440, 940), (*MINT, 34)),
        ((830, 90, 1460, 720), (*GOLD, 30)),
        ((650, 1500, 1580, 2520), (*MINT_SOFT, 58)),
        ((-220, 2060, 520, 2880), (*MINT, 42)),
    ]:
        d.ellipse(box, fill=color)
    return layer.filter(ImageFilter.GaussianBlur(72))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def shadowed_phone(screen: Image.Image, width: int = 810) -> Image.Image:
    ratio = screen.height / screen.width
    shot = screen.resize((width, int(width * ratio)), Image.Resampling.LANCZOS).convert("RGBA")
    pad = 20
    radius = 92
    framed = Image.new("RGBA", (shot.width + pad * 2, shot.height + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(framed)
    d.rounded_rectangle((0, 0, framed.width - 1, framed.height - 1), radius=radius + pad, fill=(255, 255, 255, 242))
    mask = rounded_mask((shot.width, shot.height), radius)
    clipped = Image.new("RGBA", shot.size, (0, 0, 0, 0))
    clipped.paste(shot, (0, 0), mask)
    framed.alpha_composite(clipped, (pad, pad))

    shadow = Image.new("RGBA", (framed.width + 120, framed.height + 120), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((60, 60, 60 + framed.width, 60 + framed.height), radius=radius + pad, fill=(20, 49, 38, 72))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    shadow.alpha_composite(framed, (60, 42))
    return shadow


def draw_centered(draw: ImageDraw.ImageDraw, text: str, y: int, fnt: ImageFont.FreeTypeFont, fill: tuple[int, int, int], spacing: int = 12) -> int:
    lines = text.splitlines()
    heights = [draw.textbbox((0, 0), line, font=fnt)[3] for line in lines]
    total = sum(heights) + spacing * (len(lines) - 1)
    yy = y
    for line, h in zip(lines, heights):
        box = draw.textbbox((0, 0), line, font=fnt)
        draw.text(((W - (box[2] - box[0])) / 2, yy), line, font=fnt, fill=fill)
        yy += h + spacing
    return y + total


def compose(name: str, source: str, title: str, subtitle: str) -> None:
    canvas = gradient()
    canvas.alpha_composite(blob_layer())
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((42, 48, W - 42, H - 48), radius=74, outline=(255, 255, 255, 126), width=2)
    d.text((72, 80), "CLEARING", font=LABEL, fill=(*DARK, 170))
    d.ellipse((1030, 70, 1100, 140), fill=(*MINT, 58))
    d.ellipse((1100, 116, 1146, 162), fill=(*GOLD, 66))

    title_bottom = draw_centered(d, title, 206, TITLE, DARK, 10)
    sub_box = d.textbbox((0, 0), subtitle, font=SUBTITLE)
    d.text(((W - (sub_box[2] - sub_box[0])) / 2, title_bottom + 42), subtitle, font=SUBTITLE, fill=(82, 111, 97))

    screen = Image.open(SRC / source)
    phone = shadowed_phone(screen, width=820)
    x = (W - phone.width) // 2
    y = 710
    if name == "05-milestones.png":
        y = 675
    canvas.alpha_composite(phone, (x, y))
    canvas.convert("RGB").save(OUT / name, quality=96)


for item in SCREENS:
    compose(*item)

print(f"Wrote {len(SCREENS)} images to {OUT}")
