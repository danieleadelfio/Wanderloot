"""Generatore della grafica vettoriale di Wanderloot (da M6, sostituisce la pixel art).

Ogni asset e' un SVG (sorgente modificabile anche in Inkscape, salvato in assets/art/) esportato in PNG
a 2x della dimensione a schermo (assets/sprites/): in gioco gli Sprite2D stanno a scala 0.5 con filtro
lineare, cosi' restano nitidi fino a schermi 4K.
Uso (dalla root del progetto): python3 tools/sprites.py   — richiede: pip install cairosvg pillow
"""
import io
import math
import os
import random

import cairosvg
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ART = os.path.join(ROOT, "assets", "art")
OUT = os.path.join(ROOT, "assets", "sprites")
RNG = random.Random(4)


def render(svg, w, h):
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h))).convert("RGBA")


def save(name, frames, size):
    """frames: lista di SVG (viewBox quadrato). Salva gli SVG e un PNG con i frame affiancati."""
    os.makedirs(ART, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    sheet = Image.new("RGBA", (size * len(frames), size), (0, 0, 0, 0))
    for i, svg in enumerate(frames):
        suffix = "" if i == 0 else "_f%d" % (i + 1)
        with open(os.path.join(ART, name + suffix + ".svg"), "w", newline="\n") as f:
            f.write(svg)
        sheet.alpha_composite(render(svg, size, size), (i * size, 0))
    sheet.save(os.path.join(OUT, name + ".png"))


def svg(body, defs="", view=256):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d"><defs>%s</defs>%s</svg>' % (view, view, defs, body)


# --- Slime: frame 2 schiacciato (respiro) -------------------------------------------------------
def slime_svg(squash=False, rage=False):
    c = ("#ffc2b0", "#e8433a", "#7a1a1f", "#4a0d10") if rage else ("#c8ff8a", "#38b764", "#1d6e45", "#11402a")
    t = ' transform="translate(128 232) scale(1.07 0.92) translate(-128 -232)"' if squash else ""
    brows = ('<path d="M84 140 L118 152" stroke="%s" stroke-width="9" stroke-linecap="round"/>'
             '<path d="M172 140 L138 152" stroke="%s" stroke-width="9" stroke-linecap="round"/>' % (c[3], c[3])) if rage else ""
    mouth = 188 if rage else 206
    defs = ('<radialGradient id="b" cx="0.38" cy="0.32" r="0.8"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.45" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % c[:3])
    body = ('<ellipse cx="128" cy="234" rx="92" ry="14" fill="#000" opacity="0.28"/><g%s>'
            '<path d="M36 204 C36 120 88 64 128 64 C168 64 220 120 220 204 C220 226 200 232 128 232 C56 232 36 226 36 204 Z" fill="url(#b)" stroke="%s" stroke-width="7"/>'
            '<ellipse cx="92" cy="108" rx="26" ry="14" fill="#fff" opacity="0.65" transform="rotate(-28 92 108)"/>'
            '<ellipse cx="150" cy="96" rx="7" ry="5" fill="#fff" opacity="0.5"/>%s'
            '<ellipse cx="102" cy="168" rx="11" ry="15" fill="%s"/><ellipse cx="154" cy="168" rx="11" ry="15" fill="%s"/>'
            '<circle cx="106" cy="162" r="4" fill="#fff"/><circle cx="158" cy="162" r="4" fill="#fff"/>'
            '<path d="M114 196 Q128 %d 142 196" stroke="%s" stroke-width="5" fill="none" stroke-linecap="round"/></g>'
            % (t, c[3], brows, c[3], c[3], mouth, c[3]))
    return svg(body, defs)


# --- Player: mago incappucciato con bastone; frame 2 leggermente sollevato ----------------------
def player_svg(up=False):
    dy = -6 if up else 0
    defs = ('<linearGradient id="robe" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#4f78e0"/><stop offset="1" stop-color="#23306a"/></linearGradient>'
            '<radialGradient id="hood" cx="0.35" cy="0.3" r="0.9"><stop offset="0" stop-color="#6cc0ff"/><stop offset="0.5" stop-color="#3b5dc9"/><stop offset="1" stop-color="#23306a"/></radialGradient>'
            '<radialGradient id="orb" cx="0.4" cy="0.4" r="0.6"><stop offset="0" stop-color="#fffbe8"/><stop offset="0.5" stop-color="#ffcd75"/><stop offset="1" stop-color="#ef7d57"/></radialGradient>'
            '<radialGradient id="glow"><stop offset="0" stop-color="#ffcd75" stop-opacity="%s"/><stop offset="1" stop-color="#ffcd75" stop-opacity="0"/></radialGradient>' % ("0.85" if up else "0.6"))
    body = ('<ellipse cx="124" cy="238" rx="66" ry="12" fill="#000" opacity="0.3"/><g transform="translate(0 %d)">'
            '<path d="M64 232 L92 120 L156 120 L184 232 Q124 248 64 232 Z" fill="url(#robe)" stroke="#141a3a" stroke-width="7" stroke-linejoin="round"/>'
            '<path d="M108 128 L124 230 L140 128 Z" fill="#1c2656" opacity="0.5"/>'
            '<rect x="96" y="168" width="56" height="12" rx="4" fill="#ffcd75" stroke="#7a4d1c" stroke-width="3"/>'
            '<path d="M72 130 C66 58 182 58 176 130 C172 158 76 158 72 130 Z" fill="url(#hood)" stroke="#141a3a" stroke-width="7"/>'
            '<ellipse cx="124" cy="124" rx="34" ry="30" fill="#141a2c"/><ellipse cx="124" cy="130" rx="25" ry="20" fill="#f4c49a"/>'
            '<ellipse cx="113" cy="127" rx="5" ry="6" fill="#1a1c2c"/><ellipse cx="135" cy="127" rx="5" ry="6" fill="#1a1c2c"/>'
            '<line x1="200" y1="92" x2="182" y2="236" stroke="#5a3218" stroke-width="13" stroke-linecap="round"/>'
            '<line x1="200" y1="92" x2="182" y2="236" stroke="#9a6035" stroke-width="5" stroke-linecap="round"/>'
            '<circle cx="202" cy="80" r="42" fill="url(#glow)"/><circle cx="202" cy="80" r="15" fill="url(#orb)" stroke="#7a3a20" stroke-width="3"/></g>' % dy)
    return svg(body, defs)


# --- Proiettile: sfera luminosa con scia verso -x (il nodo ruota nella direzione di tiro) -------
def projectile_svg():
    defs = ('<radialGradient id="g"><stop offset="0" stop-color="#ffcd75" stop-opacity="0.95"/><stop offset="1" stop-color="#ef7d57" stop-opacity="0"/></radialGradient>'
            '<linearGradient id="t" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ef7d57" stop-opacity="0"/><stop offset="1" stop-color="#ffcd75" stop-opacity="0.85"/></linearGradient>')
    body = ('<path d="M6 32 L40 22 L40 42 Z" fill="url(#t)"/><circle cx="42" cy="32" r="20" fill="url(#g)"/>'
            '<circle cx="42" cy="32" r="8" fill="#fff6d8"/>')
    return svg(body, defs, 64)


# --- Gemma di exp --------------------------------------------------------------------------------
def exp_gem_svg():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#b8f6ff"/><stop offset="1" stop-color="#3b5dc9"/></linearGradient>'
    body = ('<path d="M32 4 L54 30 L32 60 L10 30 Z" fill="url(#g)" stroke="#16306b" stroke-width="4" stroke-linejoin="round"/>'
            '<path d="M32 4 L32 60 M10 30 L54 30" stroke="#ffffff" stroke-width="2" opacity="0.35"/>'
            '<path d="M22 22 L30 14" stroke="#fff" stroke-width="4" stroke-linecap="round" opacity="0.8"/>')
    return svg(body, defs, 64)


def build_characters():
    save("player", [player_svg(), player_svg(up=True)], 96)
    save("slime", [slime_svg(), slime_svg(squash=True)], 88)
    save("slime_rage", [slime_svg(rage=True), slime_svg(squash=True, rage=True)], 88)
    save("projectile", [projectile_svg()], 32)
    save("exp_gem", [exp_gem_svg()], 32)


# --- Arena: pavimento a lastre (tile 384px = 192px di mondo) e muri (64px = 32px) -----------------
def floor_svg():
    parts = ['<rect width="384" height="384" fill="#2c2f46"/>']
    for gy in range(3):
        for gx in range(3):
            v = RNG.randint(-3, 3)
            x, y = gx * 128 + 3, gy * 128 + 3
            parts.append('<rect x="%d" y="%d" width="122" height="122" rx="12" fill="rgb(%d,%d,%d)"/>' % (x, y, 56 + v, 60 + v, 82 + v))
            parts.append('<rect x="%d" y="%d" width="122" height="6" rx="3" fill="#ffffff" opacity="0.05"/>' % (x, y + 4))
            if RNG.random() < 0.2:
                cx, cy = x + RNG.randint(20, 80), y + RNG.randint(20, 80)
                parts.append('<path d="M%d %d l%d %d l%d %d" stroke="#34384f" stroke-width="3" fill="none" stroke-linecap="round"/>'
                             % (cx, cy, RNG.randint(12, 26), RNG.randint(8, 18), RNG.randint(-14, 4), RNG.randint(10, 22)))
    return svg("".join(parts), "", 384)


def wall_svg():
    parts = ['<rect width="64" height="64" fill="#1d2030"/>']
    for row in range(2):
        off = 0 if row == 0 else -16
        for col in range(3):
            parts.append('<rect x="%d" y="%d" width="28" height="28" rx="4" fill="#4a5270"/>' % (off + col * 32 + 2, row * 32 + 2))
            parts.append('<rect x="%d" y="%d" width="28" height="7" rx="3" fill="#6b7690"/>' % (off + col * 32 + 2, row * 32 + 2))
    return svg("".join(parts), "", 64)


# --- Icone 64px (hub, inventario, oggetti a terra) --------------------------------------------------
OUTLINE = 'stroke="#141a2c" stroke-width="3.5" stroke-linejoin="round"'


def icon_gel():
    defs = '<radialGradient id="g" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#c8ff8a"/><stop offset="0.5" stop-color="#38b764"/><stop offset="1" stop-color="#1d6e45"/></radialGradient>'
    return svg('<path d="M32 6 C40 20 52 30 52 42 C52 54 43 60 32 60 C21 60 12 54 12 42 C12 30 24 20 32 6 Z" fill="url(#g)" %s/>'
               '<ellipse cx="24" cy="38" rx="6" ry="9" fill="#fff" opacity="0.55" transform="rotate(20 24 38)"/>' % OUTLINE, defs, 64)


def icon_core():
    defs = ('<radialGradient id="g" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffd1dc"/><stop offset="0.35" stop-color="#e8436a"/><stop offset="1" stop-color="#5d275d"/></radialGradient>'
            '<radialGradient id="h"><stop offset="0" stop-color="#ff7aa0" stop-opacity="0.6"/><stop offset="1" stop-color="#ff7aa0" stop-opacity="0"/></radialGradient>')
    return svg('<circle cx="32" cy="32" r="30" fill="url(#h)"/><circle cx="32" cy="33" r="20" fill="url(#g)" %s/>'
               '<circle cx="25" cy="26" r="5" fill="#fff" opacity="0.7"/>' % OUTLINE, defs, 64)


def icon_wand(gem, spark):
    defs = '<radialGradient id="g" cx="0.35" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffffff"/><stop offset="0.4" stop-color="%s"/><stop offset="1" stop-color="#1a1c2c"/></radialGradient>' % gem
    sparks = "".join('<path d="M%d %d l3 -7 l3 7 l-3 7 Z" fill="#ffcd75"/>' % p for p in [(50, 30), (30, 10), (54, 6)]) if spark else ""
    return svg('<line x1="10" y1="56" x2="42" y2="22" stroke="#141a2c" stroke-width="11" stroke-linecap="round"/>'
               '<line x1="10" y1="56" x2="42" y2="22" stroke="#9a6035" stroke-width="5" stroke-linecap="round"/>'
               '<circle cx="46" cy="18" r="10" fill="url(#g)" %s/>%s' % (OUTLINE, sparks), defs, 64)


def icon_amulet():
    defs = '<radialGradient id="g" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffd1dc"/><stop offset="0.4" stop-color="#e8436a"/><stop offset="1" stop-color="#5d275d"/></radialGradient>'
    return svg('<path d="M12 6 Q32 34 52 6" stroke="#141a2c" stroke-width="7" fill="none" stroke-linecap="round"/>'
               '<path d="M12 6 Q32 34 52 6" stroke="#ffcd75" stroke-width="3" fill="none" stroke-linecap="round"/>'
               '<circle cx="32" cy="42" r="15" fill="#ffcd75" %s/><circle cx="32" cy="42" r="9" fill="url(#g)"/>'
               '<circle cx="29" cy="39" r="2.5" fill="#fff" opacity="0.8"/>' % OUTLINE, defs, 64)


def icon_boots():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7ee08a"/><stop offset="1" stop-color="#1d6e45"/></linearGradient>'
    return svg('<path d="M18 6 L36 6 L36 36 L54 42 Q58 44 56 52 L56 58 L12 58 L12 50 Q18 46 18 38 Z" fill="url(#g)" %s/>'
               '<path d="M18 14 L36 14" stroke="#c8ff8a" stroke-width="3" opacity="0.7"/>'
               '<rect x="12" y="54" width="44" height="5" rx="2" fill="#11402a"/>' % OUTLINE, defs, 64)


def build_arena_and_icons():
    save("floor", [floor_svg()], 384)
    save("wall", [wall_svg()], 64)
    save("icon_slime_gel", [icon_gel()], 64)
    save("icon_slime_core", [icon_core()], 64)
    save("icon_gel_wand", [icon_wand("#38b764", False)], 64)
    save("icon_rapid_wand", [icon_wand("#73eff7", True)], 64)
    save("icon_core_amulet", [icon_amulet()], 64)
    save("icon_slime_boots", [icon_boots()], 64)



# --- Luci e oggetti di scena (M7) -------------------------------------------------------------------
def torch_svg():
    defs = ('<radialGradient id="f" cx="0.5" cy="0.65" r="0.6"><stop offset="0" stop-color="#fffbe8"/><stop offset="0.45" stop-color="#ffcd75"/>'
            '<stop offset="1" stop-color="#ef7d57" stop-opacity="0"/></radialGradient>')
    return svg('<rect x="26" y="34" width="12" height="26" rx="3" fill="#5a3218" stroke="#141a2c" stroke-width="3"/>'
               '<rect x="20" y="30" width="24" height="8" rx="3" fill="#6b7690" stroke="#141a2c" stroke-width="3"/>'
               '<path d="M32 4 C40 14 44 20 42 28 C40 34 24 34 22 28 C20 20 26 14 32 4 Z" fill="url(#f)"/>'
               '<path d="M32 14 C36 20 37 24 35 28 C33 31 30 31 29 28 C28 24 29 20 32 14 Z" fill="#fff6d8" opacity="0.9"/>', defs, 64)


def build_props():
    save("torch", [torch_svg()], 64)


if __name__ == "__main__":
    build_characters()
    build_arena_and_icons()
    build_props()
    print("sprites:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
