#!/usr/bin/env python3
"""Regenerate Valence's launcher icons from assets/logo/valence_logo.png.

Run:  python3 -m pip install Pillow && python3 tool/icons/build_icons.py
Then: dart run flutter_launcher_icons

WHY THIS EXISTS. The V used to render tiny on the home screen, and the reason
was DOUBLE PADDING: the source logo already carries its own generous margin
(the glyph fills ~70% of a 1024 canvas), and the old adaptive foreground shrank
that *again* into Android's 66/108 safe zone. Net result ~43% of the canvas,
then cropped further by the launcher mask.

The fix is to work from the GLYPH, not the padded artwork: extract it, throw
away the source's margin entirely, and re-inset it exactly once — to the
largest size that still fits inside Android's safe circle. That bound is
computed from the real pixels here (the widest point of the V's arms), not
guessed.

Colour: the plate moves from #1D1E23 (a COOL blue-grey that appears nowhere in
the product) to the design system's own `ink` #1A1814 — the warm near-black the
whole app is built on. Gold snaps to the exact brand `#C6A87C`. So the icon is
finally made of the same two colours as the app it opens: ink carries the
structure, gold is the identity (design.md §1.1).

Outputs (all 1024²):
  tool/icons/adaptive_fg.png    transparent + gold glyph, safe-zone inset
  tool/icons/adaptive_mono.png  transparent + white glyph (Android 13 themed)
  assets/logo/valence_icon.png  ink plate + gold glyph, full-bleed (iOS/legacy)
"""
from PIL import Image

SRC = 'assets/logo/valence_logo.png'
FG_OUT = 'tool/icons/adaptive_fg.png'
MONO_OUT = 'tool/icons/adaptive_mono.png'
FULL_OUT = 'assets/logo/valence_icon.png'

SIZE = 1024
INK = (26, 24, 20)        # #1A1814 — design.md `ink`
GOLD = (198, 168, 124)    # #C6A87C — design.md `gold`

# Android adaptive icons: 108dp canvas. 66dp is the "safe zone" (guaranteed
# visible under EVERY mask); the mask itself actually reveals ~72dp.
#
# Fitting the glyph's BOUNDING BOX to the safe square was tried and REJECTED by
# rendering it: at 60% the circle mask sliced the top-left arm and the arrow tip
# clean off, and circles are what Pixel and Samsung ship by default. So the
# scale is set by the glyph's FURTHEST PIXEL against the mask circle — the V's
# arm tips sit near its bbox corners, and a wide mark inside a circle is simply
# bounded by its diagonal.
#
# The circle actually revealed is 72dp (the 66dp "safe zone" is the stricter
# guarantee); targeting 72dp with a small margin is both safe on every launcher
# and as large as this mark can honestly go.
VISIBLE_RATIO = 72 / 108
SAFE_FILL = 0.96
# iOS / legacy icons are full-bleed with no mask, so the glyph can run larger.
FULL_FILL = 0.92


def load_glyph():
    """Returns an RGBA image cropped tight to the glyph, alpha from the plate."""
    im = Image.open(SRC).convert('RGB')
    w, h = im.size
    px = im.load()
    plate = px[5, 5]

    def dist(c):
        return max(abs(a - b) for a, b in zip(c, plate))

    # The source plate is not flat — it carries a faint vignette. A naive
    # "anything unlike the corner pixel is glyph" cut treats that gradient as
    # artwork and drags the bounding box to the canvas edge, which silently
    # shrinks the glyph on every downstream scale. CUT well above the vignette
    # (measured: it never exceeds ~15) and ramp from there so real antialiased
    # edges still survive.
    CUT, FULL = 20, 70

    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    op = out.load()
    for y in range(h):
        for x in range(w):
            d = dist(px[x, y])
            if d <= CUT:
                continue
            a = 255 if d >= FULL else int(255 * (d - CUT) / (FULL - CUT))
            op[x, y] = (*GOLD, a)
    return out.crop(out.getbbox())


def max_radius(glyph):
    """Distance from the glyph's centre to its furthest opaque pixel.

    This — not width/2 — is what a circular mask actually tests.
    """
    w, h = glyph.size
    a = glyph.split()[3].load()
    cx, cy = w / 2, h / 2
    worst = 0.0
    for y in range(h):
        for x in range(w):
            if a[x, y] > 24:
                d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                worst = max(worst, d)
    return worst


def place_radius(glyph, target_r):
    """Scales the glyph so its furthest pixel lands target_r from the centre."""
    scale = target_r / max_radius(glyph)
    w, h = glyph.size
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    g = glyph.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(g, ((SIZE - nw) // 2, (SIZE - nh) // 2))
    return canvas


def main():
    glyph = load_glyph()
    print(f'glyph cropped to {glyph.size[0]}x{glyph.size[1]} '
          f'(source margin discarded)')

    # --- adaptive foreground: fit inside the mask circle.
    fg = place_radius(glyph, (SIZE * VISIBLE_RATIO / 2) * SAFE_FILL)
    fg.save(FG_OUT)
    bb = fg.getbbox()
    print(f'{FG_OUT}: glyph spans {bb[2]-bb[0]}x{bb[3]-bb[1]} '
          f'= {(bb[2]-bb[0])/SIZE:.0%} of canvas (was ~43%)')

    # --- monochrome (Android 13 themed icons): same geometry, white.
    mono = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    mono.putalpha(fg.split()[3])
    white = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 255))
    white.putalpha(fg.split()[3])
    white.save(MONO_OUT)
    print(f'{MONO_OUT}: white silhouette, same geometry')

    # --- full-bleed icon for iOS / legacy / web.
    full = Image.new('RGBA', (SIZE, SIZE), (*INK, 255))
    full.alpha_composite(place_radius(glyph, SIZE * FULL_FILL / 2))
    full.convert('RGB').save(FULL_OUT)
    bb = place_radius(glyph, SIZE * FULL_FILL / 2).getbbox()
    print(f'{FULL_OUT}: ink plate + glyph {(bb[2]-bb[0])/SIZE:.0%} of canvas '
          f'(was 70% on a cool-grey plate)')


if __name__ == '__main__':
    main()
