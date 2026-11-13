#!/usr/bin/env python3
"""Generate Play/App Store marketing screenshots for ScanForge."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_PHONE = ROOT / "store" / "screenshots" / "phone"
OUT_TABLET = ROOT / "store" / "screenshots" / "tablet"
ICON = ROOT / "assets" / "branding" / "app_icon.png"

ACCENT = (15, 138, 107)  # #0F8A6B
ACCENT_SOFT = (184, 228, 214)
INK = (20, 33, 43)
SLATE = (44, 62, 74)
FOAM = (244, 247, 249)
MIST = (232, 238, 242)
WHITE = (255, 255, 255)
SCANNER_BG = (11, 18, 24)
TEAL_DARK = (7, 70, 62)

FONT_REG = "/usr/share/fonts/truetype/macos/Inter-Regular.ttf"
FONT_MED = "/usr/share/fonts/truetype/macos/Inter-Medium.ttf"
FONT_SEMI = "/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/macos/Inter-Bold.ttf"


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def gradient(size: tuple[int, int], c1: tuple[int, int, int], c2: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        for x in range(w):
            # slight horizontal warmth
            u = x / max(w - 1, 1)
            rr = min(255, int(r + 8 * u))
            gg = min(255, int(g + 4 * u))
            px[x, y] = (rr, gg, b)
    return img


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    radius: int,
    fill,
    outline=None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_text_center(draw, xy, text, fnt, fill):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text((xy[0] - tw / 2, xy[1] - th / 2), text, font=fnt, fill=fill)


def phone_frame(content: Image.Image, width: int = 1080, height: int = 1920) -> Image.Image:
    """Place UI content inside a device chrome on a branded backdrop."""
    canvas = gradient((width, height), (8, 92, 78), (12, 40, 48))
    draw = ImageDraw.Draw(canvas)

    # Headline band
    draw_text_center(draw, (width // 2, 110), "ScanForge", font(FONT_BOLD, 54), WHITE)

    # Device body
    margin_x = 90
    top = 200
    bottom = height - 120
    body = (margin_x, top, width - margin_x, bottom)
    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        (margin_x + 18, top + 28, width - margin_x + 18, bottom + 28),
        radius=64,
        fill=(0, 0, 0, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(canvas)
    rounded_rect(draw, body, 60, fill=(18, 22, 28), outline=(40, 55, 60), width=3)

    # Screen inset
    inset = 18
    screen_box = (margin_x + inset, top + inset, width - margin_x - inset, bottom - inset)
    screen_w = screen_box[2] - screen_box[0]
    screen_h = screen_box[3] - screen_box[1]
    fitted = content.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    # mask rounded
    mask = Image.new("L", (screen_w, screen_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, screen_w, screen_h), radius=46, fill=255)
    canvas.paste(fitted, (screen_box[0], screen_box[1]), mask)

    # Notch
    nx0, nx1 = width // 2 - 90, width // 2 + 90
    draw.rounded_rectangle((nx0, top + 28, nx1, top + 52), radius=12, fill=(10, 12, 14))
    return canvas


def ui_scan(w: int = 900, h: int = 1600) -> Image.Image:
    img = Image.new("RGB", (w, h), SCANNER_BG)
    draw = ImageDraw.Draw(img)
    draw.text((36, 48), "Scan", font=font(FONT_SEMI, 44), fill=WHITE)
    draw.text((36, 108), "Point at a QR or barcode", font=font(FONT_REG, 26), fill=(180, 196, 204))

    # Camera preview area
    preview = (40, 180, w - 40, h - 280)
    rounded_rect(draw, preview, 28, fill=(22, 36, 42))
    # faux scene
    for i in range(8):
        y = 260 + i * 70
        draw.rectangle((80, y, w - 80, y + 36), fill=(30 + i * 4, 48, 52))

    # Viewfinder
    cx, cy = w // 2, (preview[1] + preview[3]) // 2
    s = 220
    thick = 10
    gap = 34
    for x0, y0, x1, y1 in [
        (cx - s, cy - s, cx - s + gap, cy - s),
        (cx - s, cy - s, cx - s, cy - s + gap),
        (cx + s - gap, cy - s, cx + s, cy - s),
        (cx + s, cy - s, cx + s, cy - s + gap),
        (cx - s, cy + s, cx - s + gap, cy + s),
        (cx - s, cy + s - gap, cx - s, cy + s),
        (cx + s - gap, cy + s, cx + s, cy + s),
        (cx + s, cy + s - gap, cx + s, cy + s),
    ]:
        draw.line([(x0, y0), (x1, y1)], fill=WHITE, width=thick)

    # Sample barcode inside frame
    bx0 = cx - 120
    for i, bw in enumerate([8, 4, 12, 4, 6, 10, 4, 8, 4, 14, 4, 6, 10, 4, 8]):
        draw.rectangle((bx0, cy - 70, bx0 + bw, cy + 70), fill=WHITE)
        bx0 += bw + 4

    # Bottom controls
    rounded_rect(draw, (60, h - 220, w - 60, h - 120), 24, fill=(24, 34, 40))
    draw.text((90, h - 188), "Continuous scan · Torch · Gallery", font=font(FONT_MED, 24), fill=ACCENT_SOFT)

    # Tab bar
    rounded_rect(draw, (0, h - 90, w, h), 0, fill=(20, 33, 43))
    for i, label in enumerate(["Scan", "History", "Generate", "Settings"]):
        x = 60 + i * 210
        color = ACCENT_SOFT if i == 0 else (140, 160, 170)
        draw.text((x, h - 58), label, font=font(FONT_MED, 22), fill=color)
    return img


def ui_history(w: int = 900, h: int = 1600) -> Image.Image:
    img = Image.new("RGB", (w, h), FOAM)
    draw = ImageDraw.Draw(img)
    draw.text((36, 48), "History", font=font(FONT_SEMI, 44), fill=INK)
    draw.text((36, 108), "Search, retry upload, swipe to delete", font=font(FONT_REG, 24), fill=SLATE)

    rounded_rect(draw, (36, 170, w - 36, 250), 18, fill=WHITE, outline=MIST, width=2)
    draw.text((60, 195), "Search scans…", font=font(FONT_REG, 26), fill=(150, 165, 175))

    items = [
        ("https://ayunts.com", "QR_CODE · Uploaded", True),
        ("5901234123457", "EAN_13 · Local", False),
        ("WIFI:T:WPA;S:Office;", "QR_CODE · Uploaded", True),
        ("CODE128-INV-0042", "CODE_128 · Failed · Retry", False),
        ("tel:+96899206639", "QR_CODE · Local", False),
    ]
    y = 290
    for value, meta, ok in items:
        rounded_rect(draw, (36, y, w - 36, y + 150), 22, fill=WHITE, outline=MIST, width=2)
        draw.text((60, y + 28), value[:34], font=font(FONT_SEMI, 28), fill=INK)
        draw.text((60, y + 80), meta, font=font(FONT_REG, 22), fill=ACCENT if ok else SLATE)
        y += 170

    rounded_rect(draw, (0, h - 90, w, h), 0, fill=WHITE)
    for i, label in enumerate(["Scan", "History", "Generate", "Settings"]):
        x = 60 + i * 210
        color = ACCENT if i == 1 else SLATE
        draw.text((x, h - 58), label, font=font(FONT_MED, 22), fill=color)
    return img


def ui_generate(w: int = 900, h: int = 1600) -> Image.Image:
    img = Image.new("RGB", (w, h), FOAM)
    draw = ImageDraw.Draw(img)
    draw.text((36, 48), "Generate", font=font(FONT_SEMI, 44), fill=INK)
    draw.text((36, 108), "Create QR codes and barcodes", font=font(FONT_REG, 24), fill=SLATE)

    rounded_rect(draw, (36, 180, w - 36, 280), 18, fill=WHITE, outline=MIST, width=2)
    draw.text((60, 212), "https://ayunts.com/scan", font=font(FONT_MED, 28), fill=INK)

    # Format chips
    chips = ["QR", "EAN-13", "Code 128", "Code 39"]
    x = 36
    for i, chip in enumerate(chips):
        tw = 150 if i else 100
        fill = ACCENT if i == 0 else WHITE
        text_c = WHITE if i == 0 else SLATE
        rounded_rect(draw, (x, 310, x + tw, 370), 20, fill=fill, outline=MIST, width=2)
        draw_text_center(draw, (x + tw // 2, 340), chip, font(FONT_MED, 24), text_c)
        x += tw + 16

    # QR preview card
    card = (120, 420, w - 120, 1040)
    rounded_rect(draw, card, 28, fill=WHITE, outline=MIST, width=2)
    # Fake QR modules
    q0, q1 = 190, 490
    cell = 22
    pattern = [
        "1111111010101111111",
        "1000001011101000001",
        "1011101010101011101",
        "1011101001001011101",
        "1011101011111011101",
        "1000001010011000001",
        "1111111010101111111",
        "0000000101010000000",
        "1101011110001101011",
        "0010101001110010100",
        "1110010110101110010",
        "0000000101110000000",
        "1111111010011111111",
        "1000001001101000001",
        "1011101010101011101",
        "1011101000011011101",
        "1011101011111011101",
        "1000001010101000001",
        "1111111011011111111",
    ]
    for row, bits in enumerate(pattern):
        for col, bit in enumerate(bits):
            if bit == "1":
                x0 = q0 + col * cell
                y0 = q1 + row * cell
                draw.rectangle((x0, y0, x0 + cell - 2, y0 + cell - 2), fill=INK)

    rounded_rect(draw, (160, 1100, w - 160, 1200), 22, fill=ACCENT)
    draw_text_center(draw, (w // 2, 1150), "Share / Save to gallery", font(FONT_SEMI, 28), WHITE)

    rounded_rect(draw, (0, h - 90, w, h), 0, fill=WHITE)
    for i, label in enumerate(["Scan", "History", "Generate", "Settings"]):
        x = 60 + i * 210
        color = ACCENT if i == 2 else SLATE
        draw.text((x, h - 58), label, font=font(FONT_MED, 22), fill=color)
    return img


def ui_upload(w: int = 900, h: int = 1600) -> Image.Image:
    img = Image.new("RGB", (w, h), FOAM)
    draw = ImageDraw.Draw(img)
    draw.text((36, 48), "Settings", font=font(FONT_SEMI, 44), fill=INK)
    draw.text((36, 108), "Upload scans as JSON to your server", font=font(FONT_REG, 24), fill=SLATE)

    sections = [
        ("Server API", [
            ("Upload to server", "Enabled", True, True),
            ("Server URL", "https://ayunts.com/…/scan.php", False, False),
            ("API key", "Bearer ••••••", False, False),
        ]),
        ("Scanner", [
            ("Continuous scan", "On", True, True),
            ("Prevent duplicates", "Cooldown 30 minutes", True, True),
            ("Beep on scan", "On", True, True),
        ]),
    ]
    y = 180
    for title, rows in sections:
        draw.text((36, y), title, font=font(FONT_SEMI, 30), fill=INK)
        y += 60
        for label, value, on, show_toggle in rows:
            rounded_rect(draw, (36, y, w - 36, y + 110), 20, fill=WHITE, outline=MIST, width=2)
            draw.text((60, y + 24), label, font=font(FONT_SEMI, 26), fill=INK)
            draw.text((60, y + 64), value, font=font(FONT_REG, 22), fill=ACCENT if on else SLATE)
            if show_toggle:
                tx = w - 140
                rounded_rect(draw, (tx, y + 36, tx + 70, y + 74), 20, fill=ACCENT if on else MIST)
                knob_x = tx + 40 if on else tx + 6
                draw.ellipse((knob_x, y + 40, knob_x + 30, y + 70), fill=WHITE)
            y += 130
        y += 20

    rounded_rect(draw, (36, y, w - 36, y + 160), 22, fill=(230, 245, 240), outline=ACCENT_SOFT, width=2)
    draw.text((60, y + 30), "JSON payload", font=font(FONT_SEMI, 26), fill=INK)
    draw.text((60, y + 78), '{ "value", "format", "scannedAt", … }', font=font(FONT_REG, 22), fill=SLATE)

    rounded_rect(draw, (0, h - 90, w, h), 0, fill=WHITE)
    for i, label in enumerate(["Scan", "History", "Generate", "Settings"]):
        x = 60 + i * 210
        color = ACCENT if i == 3 else SLATE
        draw.text((x, h - 58), label, font=font(FONT_MED, 22), fill=color)
    return img


def ui_hero(w: int = 900, h: int = 1600) -> Image.Image:
    img = gradient((w, h), (10, 110, 95), (8, 45, 55))
    draw = ImageDraw.Draw(img)
    icon = Image.open(ICON).convert("RGBA").resize((280, 280), Image.Resampling.LANCZOS)
    # round mask already in icon
    img.paste(icon, ((w - 280) // 2, 280), icon)
    draw_text_center(draw, (w // 2, 640), "ScanForge", font(FONT_BOLD, 64), WHITE)
    draw_text_center(
        draw,
        (w // 2, 720),
        "Professional QR & barcode toolkit",
        font(FONT_MED, 28),
        ACCENT_SOFT,
    )

    bullets = [
        "Live camera scan + gallery import",
        "History with search & upload retry",
        "Generate, share, and save codes",
        "Configurable JSON server upload",
    ]
    y = 820
    for b in bullets:
        rounded_rect(draw, (90, y, w - 90, y + 90), 22, fill=(255, 255, 255, ))
        # PIL RGB can't use alpha fill easily; use soft green panel
        rounded_rect(draw, (90, y, w - 90, y + 90), 22, fill=(18, 70, 62))
        draw.text((130, y + 28), b, font=font(FONT_MED, 26), fill=WHITE)
        y += 110
    return img


def captioned(frame: Image.Image, caption: str, sub: str) -> Image.Image:
    """Add marketing caption under device area already has ScanForge title."""
    w, h = frame.size
    out = frame.copy()
    draw = ImageDraw.Draw(out)
    draw_text_center(draw, (w // 2, h - 70), caption, font(FONT_SEMI, 34), WHITE)
    if sub:
        draw_text_center(draw, (w // 2, 155), sub, font(FONT_MED, 28), ACCENT_SOFT)
    return out


def make_tablet(phone_img: Image.Image) -> Image.Image:
    """Simple 7-inch tablet size from phone art (landscape-ish portrait pad)."""
    return phone_img.resize((1200, 1920), Image.Resampling.LANCZOS)


def main() -> None:
    OUT_PHONE.mkdir(parents=True, exist_ok=True)
    OUT_TABLET.mkdir(parents=True, exist_ok=True)

    shots = [
        ("01_hero_scanforge.png", ui_hero(), "QR & barcode scanner", "Scan · Generate · Upload"),
        ("02_live_scan.png", ui_scan(), "Fast live scanning", "QR codes & common barcodes"),
        ("03_history.png", ui_history(), "Searchable history", "Retry failed uploads anytime"),
        ("04_generate.png", ui_generate(), "Create codes in seconds", "Share or save to gallery"),
        ("05_server_upload.png", ui_upload(), "Your server, your data", "POST JSON with optional API key"),
    ]

    for name, ui, caption, sub in shots:
        framed = phone_frame(ui)
        final = captioned(framed, caption, sub)
        phone_path = OUT_PHONE / name
        final.save(phone_path, "PNG", optimize=True)
        tab_path = OUT_TABLET / name
        make_tablet(final).save(tab_path, "PNG", optimize=True)
        print(f"wrote {phone_path.relative_to(ROOT)} ({final.size[0]}x{final.size[1]})")


if __name__ == "__main__":
    main()
