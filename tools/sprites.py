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
    save("projectile", [projectile_svg()], 32)
    save("exp_gem", [exp_gem_svg()], 32)


if __name__ == "__main__":
    build_characters()
    print("sprites:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
