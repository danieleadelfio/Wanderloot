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


# --- Nemici dell'Ossario (M7) ---------------------------------------------------------------------
def ghoul_svg(up=False, rage=False):
    skin = ("#c07a6a", "#8a3a33", "#4a1616") if rage else ("#9bb49a", "#5c7a62", "#2c3d33")
    eye = "#ff3b2f" if rage else "#ffe066"
    dy = -6 if up else 0
    defs = ('<radialGradient id="s" cx="0.4" cy="0.3" r="0.8"><stop offset="0" stop-color="%s"/><stop offset="0.5" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>'
            '<radialGradient id="e"><stop offset="0" stop-color="#fff"/><stop offset="0.35" stop-color="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>'
            % (skin[0], skin[1], skin[2], eye, eye))
    body = ('<ellipse cx="128" cy="238" rx="80" ry="12" fill="#000" opacity="0.35"/><g transform="translate(0 %d)">'
            # braccia lunghe con artigli
            '<path d="M76 150 Q40 180 44 222 M180 150 Q216 180 212 222" stroke="%s" stroke-width="20" fill="none" stroke-linecap="round"/>'
            '<path d="M76 150 Q40 180 44 222 M180 150 Q216 180 212 222" stroke="url(#s)" stroke-width="12" fill="none" stroke-linecap="round"/>'
            '<path d="M34 222 l4 16 M44 224 l2 18 M54 222 l-2 16 M202 222 l-4 16 M212 224 l-2 18 M222 222 l2 16" stroke="#e8e2d0" stroke-width="5" stroke-linecap="round"/>'
            # corpo curvo con stracci
            '<path d="M70 232 C66 170 90 136 128 136 C166 136 190 170 186 232 Q128 246 70 232 Z" fill="url(#s)" stroke="%s" stroke-width="7"/>'
            '<path d="M78 200 L100 236 L112 204 L128 238 L142 204 L156 236 L178 200 Q128 222 78 200 Z" fill="#1c1a24" opacity="0.85"/>'
            '<path d="M104 168 Q128 178 152 168 M108 184 Q128 192 148 184" stroke="%s" stroke-width="4" fill="none" opacity="0.6"/>'
            # testa
            '<ellipse cx="128" cy="112" rx="48" ry="44" fill="url(#s)" stroke="%s" stroke-width="7"/>'
            '<circle cx="108" cy="106" r="22" fill="url(#e)"/><circle cx="148" cy="106" r="22" fill="url(#e)"/>'
            '<ellipse cx="108" cy="106" rx="7" ry="9" fill="%s"/><ellipse cx="148" cy="106" rx="7" ry="9" fill="%s"/>'
            '<path d="M104 132 L112 142 L120 132 L128 142 L136 132 L144 142 L152 132" stroke="#e8e2d0" stroke-width="4" fill="#1a0c10" stroke-linejoin="round"/>'
            '</g>' % (dy, skin[2], skin[2], skin[2], skin[2], eye, eye))
    return svg(body, defs)


def skeleton_svg(up=False, rage=False):
    bone = ("#f0c8b8", "#b0706a") if rage else ("#efe8d6", "#a89f88")
    eye = "#ff3b2f" if rage else "#8fd3ff"
    dy = -6 if up else 0
    defs = ('<linearGradient id="b" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
            '<radialGradient id="e"><stop offset="0" stop-color="#fff"/><stop offset="0.3" stop-color="%s"/><stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>'
            '<linearGradient id="h" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2f4a"/><stop offset="1" stop-color="#15111e"/></linearGradient>'
            % (bone[0], bone[1], eye, eye))
    O = 'stroke="#141a2c" stroke-width="6"'
    body = ('<ellipse cx="124" cy="238" rx="66" ry="12" fill="#000" opacity="0.35"/><g transform="translate(0 %d)">'
            # mantello logoro
            '<path d="M64 232 L84 128 L164 128 L184 232 L164 218 L150 236 L130 220 L112 236 L96 218 Z" fill="url(#h)" %s stroke-linejoin="round"/>'
            # gabbia toracica
            '<rect x="100" y="140" width="48" height="62" rx="16" fill="#0f0c16"/>'
            '<path d="M124 142 L124 200 M104 152 Q124 162 144 152 M104 168 Q124 178 144 168 M106 184 Q124 192 142 184" stroke="url(#b)" stroke-width="6" fill="none" stroke-linecap="round"/>'
            # arco e corda
            '<path d="M204 84 Q246 158 204 232" stroke="#5a3218" stroke-width="10" fill="none" stroke-linecap="round"/>'
            '<path d="M204 84 Q246 158 204 232" stroke="#9a6035" stroke-width="4" fill="none" stroke-linecap="round"/>'
            '<line x1="204" y1="84" x2="204" y2="232" stroke="#d8d0c0" stroke-width="2"/>'
            '<path d="M150 156 L204 158" stroke="url(#b)" stroke-width="7" stroke-linecap="round"/>'
            # teschio con cappuccio
            '<path d="M72 118 C68 44 180 44 176 118 Z" fill="url(#h)" %s/>'
            '<path d="M92 108 C92 64 156 64 156 108 C156 124 146 134 138 136 L138 146 L110 146 L110 136 C102 134 92 124 92 108 Z" fill="url(#b)" %s/>'
            '<ellipse cx="111" cy="104" rx="11" ry="12" fill="#0b0a10"/><ellipse cx="137" cy="104" rx="11" ry="12" fill="#0b0a10"/>'
            '<circle cx="111" cy="105" r="9" fill="url(#e)"/><circle cx="137" cy="105" r="9" fill="url(#e)"/>'
            '<path d="M121 118 L124 126 L127 118 Z" fill="#0b0a10"/>'
            '<path d="M112 138 L112 146 M118 138 L118 146 M124 138 L124 146 M130 138 L130 146 M136 138 L136 146" stroke="#0b0a10" stroke-width="2"/>'
            '</g>' % (dy, O, O, O))
    return svg(body, defs)


def enemy_bolt_svg():
    defs = ('<radialGradient id="g"><stop offset="0" stop-color="#e0b0ff" stop-opacity="0.95"/><stop offset="1" stop-color="#6a2c8a" stop-opacity="0"/></radialGradient>'
            '<linearGradient id="t" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6a2c8a" stop-opacity="0"/><stop offset="1" stop-color="#c77dff" stop-opacity="0.85"/></linearGradient>')
    return svg('<path d="M4 32 L42 24 L42 40 Z" fill="url(#t)"/><circle cx="44" cy="32" r="18" fill="url(#g)"/>'
               '<path d="M34 32 L54 32 M50 27 L56 32 L50 37" stroke="#f4eeff" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>', defs, 64)


def icon_bone():
    return svg('<g transform="rotate(-35 32 32)"><rect x="14" y="27" width="36" height="10" rx="4" fill="#efe8d6" %s/>'
               '<circle cx="14" cy="26" r="7" fill="#efe8d6" %s/><circle cx="14" cy="38" r="7" fill="#efe8d6" %s/>'
               '<circle cx="50" cy="26" r="7" fill="#efe8d6" %s/><circle cx="50" cy="38" r="7" fill="#efe8d6" %s/>'
               '<rect x="12" y="28" width="40" height="8" fill="#efe8d6"/></g>' % ((OUTLINE,) * 5), "", 64)


def icon_essence():
    defs = ('<radialGradient id="g" cx="0.45" cy="0.4" r="0.7"><stop offset="0" stop-color="#f4eeff"/><stop offset="0.35" stop-color="#9d4edd"/><stop offset="1" stop-color="#240046"/></radialGradient>'
            '<radialGradient id="h"><stop offset="0" stop-color="#c77dff" stop-opacity="0.7"/><stop offset="1" stop-color="#c77dff" stop-opacity="0"/></radialGradient>')
    return svg('<circle cx="32" cy="32" r="30" fill="url(#h)"/>'
               '<path d="M32 8 C44 22 50 30 48 42 C46 52 38 58 32 58 C26 58 18 52 16 42 C14 30 20 22 32 8 Z" fill="url(#g)" %s/>'
               '<path d="M26 30 C24 38 28 46 34 48" stroke="#f4eeff" stroke-width="3" fill="none" opacity="0.7" stroke-linecap="round"/>' % OUTLINE, defs, 64)


def build_ossuary_enemies():
    save("ghoul", [ghoul_svg(), ghoul_svg(up=True)], 96)
    save("ghoul_rage", [ghoul_svg(rage=True), ghoul_svg(up=True, rage=True)], 96)
    save("skeleton", [skeleton_svg(), skeleton_svg(up=True)], 96)
    save("skeleton_rage", [skeleton_svg(rage=True), skeleton_svg(up=True, rage=True)], 96)
    save("enemy_bolt", [enemy_bolt_svg()], 32)
    save("icon_bone_shard", [icon_bone()], 64)
    save("icon_shadow_essence", [icon_essence()], 64)


# --- Ossario (M7): pavimento, muri, decorazioni macabre ---------------------------------------------
def ossuary_floor_svg():
    parts = ['<rect width="384" height="384" fill="#141219"/>']
    for gy in range(3):
        for gx in range(3):
            v = RNG.randint(-3, 3)
            x, y = gx * 128 + 3, gy * 128 + 3
            parts.append('<rect x="%d" y="%d" width="122" height="122" rx="6" fill="rgb(%d,%d,%d)"/>' % (x, y, 34 + v, 31 + v, 40 + v))
            if RNG.random() < 0.45:
                cx, cy = x + RNG.randint(20, 90), y + RNG.randint(20, 90)
                parts.append('<path d="M%d %d l%d %d l%d %d l%d %d" stroke="#1a1720" stroke-width="3" fill="none"/>'
                             % (cx, cy, RNG.randint(8, 24), RNG.randint(4, 16), RNG.randint(-12, 8), RNG.randint(8, 20), RNG.randint(4, 14), RNG.randint(-6, 8)))
            if RNG.random() < 0.12:
                parts.append('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="#2a1418" opacity="0.45"/>' % (x + RNG.randint(30, 90), y + RNG.randint(30, 90), RNG.randint(10, 22), RNG.randint(6, 14)))
    return svg("".join(parts), "", 384)


def ossuary_wall_svg():
    parts = ['<rect width="64" height="64" fill="#0c0b10"/>']
    for row in range(2):
        off = 0 if row == 0 else -16
        for col in range(3):
            parts.append('<rect x="%d" y="%d" width="28" height="28" rx="3" fill="#2a2632"/>' % (off + col * 32 + 2, row * 32 + 2))
            parts.append('<rect x="%d" y="%d" width="28" height="5" rx="2" fill="#3a3544"/>' % (off + col * 32 + 2, row * 32 + 2))
    parts.append('<circle cx="32" cy="16" r="7" fill="#b8b0a0"/><circle cx="29" cy="15" r="2" fill="#0c0b10"/><circle cx="35" cy="15" r="2" fill="#0c0b10"/>')
    return svg("".join(parts), "", 64)


BONE = 'fill="#d9d1bf" stroke="#141a2c" stroke-width="4"'


def skull_svg():
    return svg('<ellipse cx="64" cy="112" rx="40" ry="8" fill="#000" opacity="0.4"/>'
               '<path d="M28 64 C28 26 100 26 100 64 C100 80 92 88 84 90 L84 104 L44 104 L44 90 C36 88 28 80 28 64 Z" %s/>'
               '<ellipse cx="50" cy="64" rx="11" ry="12" fill="#0b0a10"/><ellipse cx="78" cy="64" rx="11" ry="12" fill="#0b0a10"/>'
               '<path d="M60 80 L64 88 L68 80 Z" fill="#0b0a10"/><path d="M52 96 L52 104 M60 96 L60 104 M68 96 L68 104 M76 96 L76 104" stroke="#0b0a10" stroke-width="3"/>' % BONE, "", 128)


def bones_svg():
    def bone(x1, y1, x2, y2):
        return ('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#141a2c" stroke-width="16" stroke-linecap="round"/>'
                '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#d9d1bf" stroke-width="9" stroke-linecap="round"/>' % (x1, y1, x2, y2, x1, y1, x2, y2))
    return svg('<ellipse cx="64" cy="100" rx="50" ry="10" fill="#000" opacity="0.35"/>' + bone(24, 90, 100, 60) + bone(30, 60, 104, 94) + bone(44, 100, 84, 40), "", 128)


def ribcage_svg():
    ribs = "".join('<path d="M64 %d Q%d %d %d %d" stroke="#141a2c" stroke-width="10" fill="none" stroke-linecap="round"/>'
                   '<path d="M64 %d Q%d %d %d %d" stroke="#d9d1bf" stroke-width="5" fill="none" stroke-linecap="round"/>'
                   % (y, 64 + s * 40, y + 6, 64 + s * 34, y + 22, y, 64 + s * 40, y + 6, 64 + s * 34, y + 22)
                   for y in (34, 50, 66) for s in (-1, 1))
    return svg('<ellipse cx="64" cy="104" rx="48" ry="10" fill="#000" opacity="0.35"/>'
               '<line x1="64" y1="26" x2="64" y2="98" stroke="#141a2c" stroke-width="12" stroke-linecap="round"/>'
               '<line x1="64" y1="26" x2="64" y2="98" stroke="#d9d1bf" stroke-width="6" stroke-linecap="round"/>' + ribs, "", 128)


def blood_svg():
    return svg('<path d="M30 60 C20 40 50 26 66 36 C84 22 110 40 100 62 C112 80 88 100 70 90 C52 104 26 90 36 76 C24 72 24 64 30 60 Z" fill="#4a0f14" opacity="0.8"/>'
               '<circle cx="104" cy="92" r="5" fill="#4a0f14" opacity="0.8"/><circle cx="22" cy="40" r="4" fill="#4a0f14" opacity="0.8"/>', "", 128)


def gravestone_svg():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4a4658"/><stop offset="0.5" stop-color="#6b667a"/><stop offset="1" stop-color="#3a3646"/></linearGradient>'
    return svg('<ellipse cx="64" cy="116" rx="44" ry="8" fill="#000" opacity="0.45"/>'
               '<path d="M30 116 L30 50 C30 20 98 20 98 50 L98 116 Z" fill="url(#g)" stroke="#141a2c" stroke-width="5"/>'
               '<path d="M64 44 L64 88 M50 58 L78 58" stroke="#2a2632" stroke-width="7" stroke-linecap="round"/>'
               '<path d="M38 116 Q44 100 52 116 M76 116 Q84 104 92 116" stroke="#2c3d33" stroke-width="5" fill="none"/>', defs, 128)


def candle_svg():
    defs = '<radialGradient id="f" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#fff2e0"/><stop offset="0.45" stop-color="#ff7a5c"/><stop offset="1" stop-color="#b3202a" stop-opacity="0"/></radialGradient>'
    return svg('<ellipse cx="32" cy="58" rx="16" ry="4" fill="#000" opacity="0.4"/>'
               '<rect x="24" y="30" width="16" height="28" rx="3" fill="#d8cfbf" stroke="#141a2c" stroke-width="3"/>'
               '<path d="M26 34 Q30 42 28 48" stroke="#b8ae9a" stroke-width="3" fill="none"/>'
               '<path d="M32 8 C38 16 40 22 38 27 C36 31 28 31 26 27 C24 22 26 16 32 8 Z" fill="url(#f)"/>', defs, 64)


def icon_bone_wand():
    defs = '<radialGradient id="g" cx="0.35" cy="0.35" r="0.7"><stop offset="0" stop-color="#f4eeff"/><stop offset="0.4" stop-color="#9d4edd"/><stop offset="1" stop-color="#240046"/></radialGradient>'
    return svg('<line x1="10" y1="56" x2="42" y2="22" stroke="#141a2c" stroke-width="11" stroke-linecap="round"/>'
               '<line x1="10" y1="56" x2="42" y2="22" stroke="#d9d1bf" stroke-width="5" stroke-linecap="round"/>'
               '<path d="M12 50 l6 6 M20 42 l6 6 M28 34 l6 6" stroke="#141a2c" stroke-width="2"/>'
               '<circle cx="46" cy="18" r="11" fill="#d9d1bf" %s/><circle cx="42" cy="16" r="2.5" fill="#0b0a10"/><circle cx="50" cy="16" r="2.5" fill="#0b0a10"/>'
               '<circle cx="46" cy="18" r="16" fill="url(#g)" opacity="0.35"/>' % OUTLINE, defs, 64)


def build_ossuary():
    save("ossuary_floor", [ossuary_floor_svg()], 384)
    save("ossuary_wall", [ossuary_wall_svg()], 64)
    for name, fn in [("deco_skull", skull_svg), ("deco_bones", bones_svg), ("deco_ribcage", ribcage_svg), ("deco_blood", blood_svg), ("deco_gravestone", gravestone_svg)]:
        save(name, [fn()], 128)
    save("candle", [candle_svg()], 64)
    save("icon_bone_wand", [icon_bone_wand()], 64)


# --- Hub: piazza all'aperto (M7) --------------------------------------------------------------------
def save_rect(name, svg_text, w, h):
    """Come save() ma per un singolo sprite non quadrato."""
    os.makedirs(ART, exist_ok=True)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(ART, name + ".svg"), "w", newline="\n") as f:
        f.write(svg_text)
    render(svg_text, w, h).save(os.path.join(OUT, name + ".png"))


def svg_rect(body, defs, vw, vh):
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d"><defs>%s</defs>%s</svg>' % (vw, vh, defs, body)


def plaza_floor_svg():
    parts = ['<rect width="384" height="384" fill="#2c2932"/>']
    y = 0
    row = 0
    while y < 384:
        h = 48
        x = -24 if row % 2 else 0
        while x < 384:
            w = RNG.randint(40, 64)
            v = RNG.randint(-8, 8)
            parts.append('<rect x="%d" y="%d" width="%d" height="%d" rx="12" fill="rgb(%d,%d,%d)"/>' % (x + 3, y + 3, w - 6, h - 6, 94 + v, 88 + v, 96 + v))
            parts.append('<rect x="%d" y="%d" width="%d" height="5" rx="3" fill="#ffffff" opacity="0.08"/>' % (x + 6, y + 6, w - 12))
            x += w
        y += h
        row += 1
    return svg("".join(parts), "", 384)


def fountain_svg():
    defs = ('<radialGradient id="w" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#b8f0ff"/><stop offset="0.6" stop-color="#4a8fd0"/><stop offset="1" stop-color="#1f4a80"/></radialGradient>'
            '<linearGradient id="s" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b7b2bf"/><stop offset="1" stop-color="#6e6878"/></linearGradient>')
    O = 'stroke="#1d1a24" stroke-width="7"'
    return svg('<ellipse cx="240" cy="330" rx="210" ry="120" fill="#000" opacity="0.3"/>'
               '<ellipse cx="240" cy="300" rx="200" ry="110" fill="url(#s)" %s/>'
               '<ellipse cx="240" cy="290" rx="170" ry="86" fill="url(#w)" stroke="#2c4a6a" stroke-width="4"/>'
               '<path d="M130 290 Q160 276 190 290 T250 290 T310 290 T350 290" stroke="#e0fbff" stroke-width="4" fill="none" opacity="0.6"/>'
               '<rect x="222" y="150" width="36" height="140" rx="10" fill="url(#s)" %s/>'
               '<ellipse cx="240" cy="160" rx="70" ry="26" fill="url(#s)" %s/>'
               '<ellipse cx="240" cy="154" rx="54" ry="16" fill="url(#w)"/>'
               '<path d="M240 110 Q200 120 190 200 M240 110 Q280 120 290 200 M240 110 L240 150" stroke="#cdf6ff" stroke-width="7" fill="none" opacity="0.75" stroke-linecap="round"/>'
               '<circle cx="240" cy="104" r="10" fill="#e0fbff" opacity="0.9"/>' % (O, O, O), defs, 480)


def house_svg(roof, roof_dark, window_glow, sign):
    defs = ('<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8d8494"/><stop offset="1" stop-color="#5a5262"/></linearGradient>'
            '<linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>'
            '<radialGradient id="glow"><stop offset="0" stop-color="%s" stop-opacity="0.95"/><stop offset="1" stop-color="%s" stop-opacity="0.2"/></radialGradient>'
            % (roof, roof_dark, window_glow, window_glow))
    O = 'stroke="#1d1a24" stroke-width="6" stroke-linejoin="round"'
    stones = "".join('<rect x="%d" y="%d" width="46" height="20" rx="4" fill="#ffffff" opacity="0.06"/>' % (40 + (i % 7) * 50 + (10 if (i // 7) % 2 else 0), 150 + (i // 7) * 26) for i in range(28))
    return svg_rect('<ellipse cx="210" cy="252" rx="200" ry="10" fill="#000" opacity="0.35"/>'
                    '<rect x="30" y="130" width="360" height="120" fill="url(#wall)" %s/>%s'
                    '<path d="M10 140 L70 30 L350 30 L410 140 Z" fill="url(#roof)" %s/>'
                    '<path d="M40 120 L380 120 M58 90 L362 90 M74 60 L346 60" stroke="%s" stroke-width="5" opacity="0.7"/>'
                    '<rect x="300" y="0" width="36" height="60" fill="#5a5262" %s/>'
                    '<rect x="180" y="170" width="60" height="80" rx="26" fill="#3a2418" %s/>'
                    '<rect x="70" y="160" width="70" height="50" rx="6" fill="url(#glow)" %s/><path d="M105 160 L105 210 M70 185 L140 185" stroke="#1d1a24" stroke-width="5"/>'
                    '<rect x="280" y="160" width="70" height="50" rx="6" fill="url(#glow)" %s/><path d="M315 160 L315 210 M280 185 L350 185" stroke="#1d1a24" stroke-width="5"/>'
                    '<rect x="160" y="128" width="100" height="34" rx="6" fill="#5a3218" %s/>%s'
                    % (O, stones, O, roof_dark, O, O, O, O, O, sign), defs, 420, 260)


def forge_sign():
    return '<path d="M186 140 L234 140 L228 148 L214 148 L216 156 L204 156 L206 148 L192 148 Z" fill="#c8c0b0"/>'


def store_sign():
    return '<rect x="196" y="136" width="28" height="20" rx="3" fill="#9a6035" stroke="#1d1a24" stroke-width="2"/><rect x="196" y="143" width="28" height="3" fill="#ffcd75"/>'


def anvil_svg():
    defs = '<linearGradient id="m" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9aa0b0"/><stop offset="1" stop-color="#3a3f4e"/></linearGradient>'
    O = 'stroke="#141a2c" stroke-width="5" stroke-linejoin="round"'
    return svg('<ellipse cx="64" cy="112" rx="44" ry="8" fill="#000" opacity="0.4"/>'
               '<rect x="44" y="84" width="40" height="26" rx="4" fill="#5a3218" %s/>'
               '<path d="M14 52 L100 52 Q116 52 118 62 L96 66 L90 84 L38 84 L32 66 Q14 64 14 52 Z" fill="url(#m)" %s/>'
               '<path d="M20 54 L98 54" stroke="#e0e6f0" stroke-width="3" opacity="0.6"/>' % (O, O), defs, 128)


def chest_svg():
    defs = '<linearGradient id="wd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b87a45"/><stop offset="1" stop-color="#6a3f1f"/></linearGradient>'
    O = 'stroke="#141a2c" stroke-width="5" stroke-linejoin="round"'
    return svg('<ellipse cx="64" cy="112" rx="50" ry="8" fill="#000" opacity="0.4"/>'
               '<rect x="16" y="54" width="96" height="54" rx="6" fill="url(#wd)" %s/>'
               '<path d="M16 58 Q64 18 112 58 Z" fill="url(#wd)" %s/>'
               '<path d="M36 40 L36 108 M92 40 L92 108" stroke="#6b7690" stroke-width="7"/>'
               '<rect x="54" y="58" width="20" height="22" rx="4" fill="#ffcd75" stroke="#7a4d1c" stroke-width="3"/>' % (O, O), defs, 128)


def portal_arch_svg():
    defs = '<linearGradient id="s" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5a5466"/><stop offset="0.5" stop-color="#9a94a6"/><stop offset="1" stop-color="#4a4456"/></linearGradient>'
    O = 'stroke="#1d1a24" stroke-width="8" stroke-linejoin="round"'
    runes = "".join('<circle cx="%d" cy="%d" r="6" fill="#c77dff"/>' % (240 + 150 * math.cos(a), 250 - 150 * math.sin(a)) for a in [math.pi * (i + 0.5) / 7 for i in range(7)])
    return svg('<ellipse cx="240" cy="440" rx="180" ry="22" fill="#000" opacity="0.4"/>'
               '<path d="M60 440 L60 250 A180 180 0 0 1 420 250 L420 440 L360 440 L360 250 A120 120 0 0 0 120 250 L120 440 Z" fill="url(#s)" %s/>'
               '<rect x="40" y="420" width="100" height="24" rx="6" fill="#6e6878" %s/><rect x="340" y="420" width="100" height="24" rx="6" fill="#6e6878" %s/>%s' % (O, O, O, runes), defs, 480)


def portal_swirl_svg():
    defs = '<radialGradient id="p" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/><stop offset="0.25" stop-color="#e0b0ff"/><stop offset="0.7" stop-color="#7b2cbf"/><stop offset="1" stop-color="#240046" stop-opacity="0.9"/></radialGradient>'
    arms = "".join('<path d="M128 128 Q%d %d %d %d" stroke="#f4eeff" stroke-width="6" fill="none" opacity="0.55" stroke-linecap="round"/>'
                   % (128 + 70 * math.cos(a), 128 + 70 * math.sin(a), 128 + 110 * math.cos(a + 1.2), 128 + 110 * math.sin(a + 1.2)) for a in [i * math.tau / 5 for i in range(5)])
    return svg('<circle cx="128" cy="128" r="120" fill="url(#p)"/>' + arms, defs, 256)


def lamp_svg():
    defs = '<radialGradient id="l"><stop offset="0" stop-color="#fffbe8"/><stop offset="0.5" stop-color="#ffcd75"/><stop offset="1" stop-color="#ef7d57"/></radialGradient>'
    O = 'stroke="#141a2c" stroke-width="5" stroke-linejoin="round"'
    return svg('<ellipse cx="128" cy="244" rx="34" ry="8" fill="#000" opacity="0.4"/>'
               '<rect x="120" y="70" width="16" height="170" fill="#2a2632" %s/><rect x="104" y="228" width="48" height="14" rx="4" fill="#2a2632" %s/>'
               '<path d="M98 40 L158 40 L150 80 L106 80 Z" fill="url(#l)" %s/><path d="M92 40 L164 40 L128 16 Z" fill="#2a2632" %s/>' % (O, O, O, O), defs, 256)


def tree_svg(tint=0):
    g = [("#3f7a4a", "#23452c", "#142a1b"), ("#4d6e3a", "#2c4422", "#182614")][tint]
    defs = '<radialGradient id="c" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="%s"/><stop offset="0.6" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % g
    O = 'stroke="#0e1a12" stroke-width="7"'
    return svg('<ellipse cx="160" cy="300" rx="90" ry="16" fill="#000" opacity="0.4"/>'
               '<rect x="144" y="190" width="32" height="110" rx="8" fill="#5a3218" %s/>'
               '<circle cx="110" cy="160" r="70" fill="url(#c)" %s/><circle cx="210" cy="160" r="70" fill="url(#c)" %s/>'
               '<circle cx="160" cy="100" r="84" fill="url(#c)" %s/>'
               '<circle cx="130" cy="80" r="18" fill="#ffffff" opacity="0.08"/>' % (O, O, O, O), defs, 320)


def build_hub():
    save("plaza_floor", [plaza_floor_svg()], 384)
    save("fountain", [fountain_svg()], 480)
    save_rect("house_forge", house_svg("#8a3a33", "#4a1c1a", "#ffb347", forge_sign()), 840, 520)
    save_rect("house_store", house_svg("#3f5f8a", "#1f2f4a", "#ffe29a", store_sign()), 840, 520)
    save("anvil", [anvil_svg()], 128)
    save("chest", [chest_svg()], 128)
    save("portal_arch", [portal_arch_svg()], 480)
    save("portal_swirl", [portal_swirl_svg()], 256)
    save("lamp", [lamp_svg()], 256)
    save("tree", [tree_svg(0)], 320)
    save("tree_b", [tree_svg(1)], 320)


# --- Boss Re Slime (M8): grande slime con corona, 2 frame; palla di gelatina; ombra --------------------
def king_slime_svg(squash=False):
    c = ("#d8ffa0", "#3fc46c", "#1a6a42", "#0e3a24")
    t = ' transform="translate(128 232) scale(1.06 0.93) translate(-128 -232)"' if squash else ""
    defs = ('<radialGradient id="b" cx="0.38" cy="0.3" r="0.85"><stop offset="0" stop-color="%s"/>'
            '<stop offset="0.45" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>'
            '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff2a8"/><stop offset="1" stop-color="#e0a030"/></linearGradient>' % c[:3])
    blobs = "".join('<circle cx="%d" cy="%d" r="%d" fill="#ffffff" opacity="0.18"/>' % p for p in ((70, 170, 8), (180, 186, 6), (150, 214, 5)))
    body = ('<g%s>'
            '<path d="M22 206 C22 110 80 58 128 58 C176 58 234 110 234 206 C234 230 210 236 128 236 C46 236 22 230 22 206 Z" fill="url(#b)" stroke="%s" stroke-width="8"/>'
            '<ellipse cx="86" cy="104" rx="30" ry="15" fill="#fff" opacity="0.6" transform="rotate(-28 86 104)"/>%s'
            '<path d="M84 150 L118 160" stroke="%s" stroke-width="9" stroke-linecap="round"/><path d="M172 150 L138 160" stroke="%s" stroke-width="9" stroke-linecap="round"/>'
            '<ellipse cx="102" cy="176" rx="13" ry="16" fill="%s"/><ellipse cx="154" cy="176" rx="13" ry="16" fill="%s"/>'
            '<circle cx="106" cy="170" r="5" fill="#fff"/><circle cx="158" cy="170" r="5" fill="#fff"/>'
            '<path d="M104 206 Q128 194 152 206" stroke="%s" stroke-width="6" fill="none" stroke-linecap="round"/>'
            '<path d="M84 74 L90 30 L108 56 L128 22 L148 56 L166 30 L172 74 Z" fill="url(#g)" stroke="#6a4210" stroke-width="6" stroke-linejoin="round"/>'
            '<circle cx="128" cy="58" r="7" fill="#e8433a" stroke="#6a4210" stroke-width="3"/><circle cx="102" cy="64" r="5" fill="#4ab0ff"/><circle cx="154" cy="64" r="5" fill="#4ab0ff"/></g>'
            % (t, c[3], blobs, c[3], c[3], c[3], c[3], c[3]))
    return svg(body, defs)


def slime_ball_svg():
    defs = '<radialGradient id="g" cx="0.35" cy="0.35" r="0.7"><stop offset="0" stop-color="#f0ffd0"/><stop offset="0.5" stop-color="#7ee06a"/><stop offset="1" stop-color="#1d6e45"/></radialGradient>'
    return svg('<circle cx="32" cy="32" r="22" fill="url(#g)" stroke="#11402a" stroke-width="4"/><ellipse cx="25" cy="24" rx="7" ry="4" fill="#fff" opacity="0.7"/>', defs, 64)


def boss_shadow_svg():
    return svg('<ellipse cx="128" cy="128" rx="110" ry="30" fill="#000" opacity="0.4"/>', "", 256)


def build_boss():
    save("king_slime", [king_slime_svg(), king_slime_svg(squash=True)], 256)
    save("slime_ball", [slime_ball_svg()], 48)
    save("boss_shadow", [boss_shadow_svg()], 256)


# --- Icone dell'hub (M9): inventario (sacca) e statistiche (pergamena) ------------------------------
def icon_bag():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c98a52"/><stop offset="1" stop-color="#6a3f1f"/></linearGradient>'
    return svg('<path d="M20 22 Q32 12 44 22" stroke="#3a2210" stroke-width="5" fill="none"/>'
               '<path d="M12 28 Q12 22 20 22 L44 22 Q52 22 52 28 L54 50 Q54 58 46 58 L18 58 Q10 58 10 50 Z" fill="url(#g)" %s/>'
               '<rect x="26" y="32" width="12" height="9" rx="2" fill="#ffcd75" stroke="#7a4d1c" stroke-width="2"/>' % OUTLINE, defs, 64)


def icon_stats():
    defs = '<linearGradient id="p" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e8d9b0"/><stop offset="1" stop-color="#f6ecd0"/></linearGradient>'
    return svg('<rect x="14" y="10" width="36" height="46" rx="4" fill="url(#p)" %s/>'
               '<rect x="20" y="36" width="6" height="14" fill="#e8433a"/><rect x="29" y="28" width="6" height="22" fill="#38b764"/><rect x="38" y="20" width="6" height="30" fill="#4a8fd0"/>'
               '<path d="M18 52 L46 52" stroke="#3a2e1a" stroke-width="2.5"/>' % OUTLINE, defs, 64)


def build_hub_icons():
    save("icon_bag", [icon_bag()], 64)
    save("icon_stats", [icon_stats()], 64)


# --- Icone delle abilita' della bacchetta (M10) ----------------------------------------------------
def ability_frame(inner, c1, c2):
    defs = '<radialGradient id="bg" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % (c1, c2)
    return svg('<rect x="4" y="4" width="56" height="56" rx="12" fill="url(#bg)" stroke="#141a2c" stroke-width="3.5"/>' + inner, defs, 64)


def icon_arcane_ring():
    dots = "".join('<circle cx="%.1f" cy="%.1f" r="4.5" fill="#f4e0ff" stroke="#3a1060" stroke-width="1.5"/>' % (32 + 17 * math.cos(a), 32 + 17 * math.sin(a)) for a in [i * math.tau / 8 for i in range(8)])
    return ability_frame('<circle cx="32" cy="32" r="17" fill="none" stroke="#c77dff" stroke-width="3" opacity="0.7"/>' + dots + '<circle cx="32" cy="32" r="6" fill="#fff"/>', "#7b2cbf", "#240046")


def icon_wandering_lightning():
    return ability_frame('<path d="M36 8 L20 36 L31 36 L26 56 L46 26 L34 26 Z" fill="#e8f7ff" stroke="#1d4e89" stroke-width="3" stroke-linejoin="round"/>', "#4ab0ff", "#10305a")


def icon_arcane_barrier():
    return ability_frame('<path d="M32 10 L50 18 L48 36 Q44 50 32 56 Q20 50 16 36 L14 18 Z" fill="#ffe29a" stroke="#7a4d1c" stroke-width="3" stroke-linejoin="round"/>'
                         '<path d="M32 18 L32 48 M22 30 L42 30" stroke="#b8741a" stroke-width="3" stroke-linecap="round"/>', "#e0a030", "#5a3510")


def build_ability_icons():
    save("icon_arcane_ring", [icon_arcane_ring()], 64)
    save("icon_wandering_lightning", [icon_wandering_lightning()], 64)
    save("icon_arcane_barrier", [icon_arcane_barrier()], 64)


# --- Cursori (M10.1): freccia chiara con contorno scuro, mirino. PNG a dimensione reale (48 px) -------
def cursor_arrow_svg():
    return svg('<path d="M6 4 L6 38 L15 30 L21 44 L28 41 L22 27 L34 27 Z" fill="#fff4d6" stroke="#141a2c" stroke-width="3.5" stroke-linejoin="round"/>'
               '<path d="M9 10 L9 30 L15 25" fill="none" stroke="#ffcd75" stroke-width="2" stroke-linecap="round"/>', "", 48)


def cursor_crosshair_svg():
    ring = '<circle cx="24" cy="24" r="12" fill="none" stroke="%s" stroke-width="%s"/>'
    ticks = "".join('<path d="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % (d, "%s", "%s") for d in ("M24 3 L24 13", "M24 35 L24 45", "M3 24 L13 24", "M35 24 L45 24"))
    dark = ring % ("#141a2c", 6) + ticks % (("#141a2c", 6) * 4)
    light = ring % ("#fff4d6", 2.5) + ticks % (("#ffcd75", 2.5) * 4)
    return svg(dark + light + '<circle cx="24" cy="24" r="2.5" fill="#ffcd75" stroke="#141a2c" stroke-width="1.5"/>', "", 48)


def build_cursors():
    save("cursor_arrow", [cursor_arrow_svg()], 48)
    save("cursor_crosshair", [cursor_crosshair_svg()], 48)


# --- Consumabili (M10.1): magnete, cuore, furia -----------------------------------------------------
def icon_magnet():
    return svg('<path d="M14 12 L26 12 L26 34 Q26 42 32 42 Q38 42 38 34 L38 12 L50 12 L50 34 Q50 56 32 56 Q14 56 14 34 Z" fill="#e8433a" %s/>'
               '<rect x="14" y="12" width="12" height="9" fill="#dfe6f0" stroke="#141a2c" stroke-width="3"/><rect x="38" y="12" width="12" height="9" fill="#dfe6f0" stroke="#141a2c" stroke-width="3"/>'
               '<path d="M18 30 Q18 50 32 50" stroke="#fff" stroke-width="3" fill="none" opacity="0.4"/>' % OUTLINE, "", 64)


def icon_heart():
    defs = '<radialGradient id="g" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="#ffb3c1"/><stop offset="0.5" stop-color="#e8436a"/><stop offset="1" stop-color="#8a1a3a"/></radialGradient>'
    return svg('<path d="M32 56 C10 40 6 28 10 20 C14 10 28 10 32 20 C36 10 50 10 54 20 C58 28 54 40 32 56 Z" fill="url(#g)" %s/>'
               '<ellipse cx="21" cy="22" rx="5" ry="3.5" fill="#fff" opacity="0.7" transform="rotate(-30 21 22)"/>' % OUTLINE, defs, 64)


def icon_frenzy():
    defs = '<linearGradient id="f" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ef7d57"/><stop offset="0.6" stop-color="#ffcd75"/><stop offset="1" stop-color="#fff4c0"/></linearGradient>'
    return svg('<path d="M32 6 C36 18 48 22 48 38 C48 50 40 58 32 58 C24 58 16 50 16 38 C16 30 20 26 24 22 C24 30 28 32 30 32 C28 22 30 14 32 6 Z" fill="url(#f)" %s/>'
               '<path d="M32 36 C35 40 38 42 38 47 C38 52 35 55 32 55 C29 55 26 52 26 47 C26 43 30 41 32 36 Z" fill="#fff4c0"/>' % OUTLINE, defs, 64)


def build_consumables():
    save("icon_magnet", [icon_magnet()], 64)
    save("icon_heart", [icon_heart()], 64)
    save("icon_frenzy", [icon_frenzy()], 64)


if __name__ == "__main__":
    build_characters()
    build_arena_and_icons()
    build_props()
    build_ossuary_enemies()
    build_ossuary()
    build_hub()
    build_boss()
    build_hub_icons()
    build_ability_icons()
    build_cursors()
    build_consumables()
    print("sprites:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
