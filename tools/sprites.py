"""Generatore degli sprite 16x16 di Wanderloot: ogni sprite e' una griglia di caratteri mappati sulla palette P."""
import os, random, math
from PIL import Image
# Uso: python3 tools/sprites.py (dalla root del progetto). Richiede Pillow.
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)
P = {  # palette (Sweetie-16 derived)
 '.': None, 'k': (26,28,44), 'b': (59,93,201), 'l': (65,166,246), 'd': (41,54,111), 's': (244,196,154), 'e': (26,28,44),
 'y': (255,205,117), 'Y': (255,245,200), 'o': (239,125,87), 'g': (56,183,100), 'G': (167,240,112), 'D': (37,113,121),
 'w': (244,244,244), 'p': (177,62,83), 'P': (239,125,87), 'r': (93,39,93), 'n': (133,76,48), 'N': (180,110,60),
 'c': (115,239,247), 'C': (65,166,246), 'm': (86,108,134), 'M': (148,176,194), 'z': (51,60,87),
}
def img(rows):
    h = len(rows); w = len(rows[0]); im = Image.new("RGBA", (w, h), (0,0,0,0))
    for y, r in enumerate(rows):
        assert len(r) == w, (r, len(r), w)
        for x, ch in enumerate(r):
            if P[ch]: im.putpixel((x, y), P[ch] + (255,))
    return im
def mirror(half): return [h + h[::-1] for h in half]
def sheet(frames):
    w, h = frames[0].size; s = Image.new("RGBA", (w*len(frames), h), (0,0,0,0))
    for i, f in enumerate(frames): s.paste(f, (i*w, 0))
    return s
def save(name, im): im.save(os.path.join(OUT, name + ".png"))
player = ["........","......kk",".....kbb","....kbbl","....kbbb","...kbbkk","...kbkss","...kbkes","...kbkss","..kbbbkk","..kbbbyy","..kbbbbb",".kbbdbbb",".kbbdbbb",".kkkkkkk","........"]
f1 = mirror(player); f2 = ["................"] + f1[:13] + [f1[14]]
save("player", sheet([img(f1), img(f2)]))
slime = ["........"]*6 + ["......kk","....kkgg","...kgGgg","..kgGwgg","..kggegg",".kgggegg",".kgggggg",".kDggggg","..kkkkkk","........"]
s1 = mirror(slime); s2 = ["................"] + s1[:13] + [s1[14], s1[15]]
s2 = s2[:16]
save("slime", sheet([img(s1), img(s2)]))
save("projectile", img(mirror(["....","...o","..oy",".oyY",".oyY","..oy","...o","...."])))
rnd = random.Random(7)
floor = Image.new("RGBA", (16,16))
for y in range(16):
    for x in range(16):
        v = rnd.randint(-3, 3); c = tuple(max(0, min(255, a + v)) for a in (40,43,64))
        if x == 0 or y == 0: c = (35,38,57)
        floor.putpixel((x, y), c + (255,))
for (x, y) in [(5,6),(6,6),(6,7),(11,11)]: floor.putpixel((x, y), (35,38,57,255))
save("floor", floor)
wall = Image.new("RGBA", (16,16))
for y in range(16):
    for x in range(16):
        off = 0 if (y // 4) % 2 == 0 else 4
        c = (86,108,134) if rnd.random() > 0.15 else (100,122,148)
        if y % 4 == 3 or (x + off) % 8 == 7: c = (51,60,87)
        wall.putpixel((x, y), c + (255,))
save("wall", wall)
# icone 16x16 per hub
save("icon_slime_gel", img(mirror(["........"]*4 + ["......kk","....kkgg","...kgGgg","..kgGwgg","..kggggg","..kggggg","..kDgggg","...kkkkk","........","........","........","........"])))
save("icon_slime_core", img(mirror(["........","........","......kk","....kkrr","...krppp","...krpPP","..krppPw","..krppPP","..krpppp","..krrppp","...krrpp","...kkrrr","....kkkk","........","........","........"])))
def wand(gem, spark):
    rows = [list("................") for _ in range(16)]
    for i in range(10):
        x, y = 3 + i, 13 - i
        rows[y][x] = 'n'; rows[y+1][x] = 'k'; rows[y][x-1] = 'k' if rows[y][x-1] == '.' else rows[y][x-1]
    for (dx, dy) in [(0,0),(1,0),(0,1),(1,1)]: rows[2+dy][12+dx] = gem
    rows[2][12] = 'w'
    for (x, y) in [(11,1),(14,1),(11,4),(14,4)]: rows[y][x] = 'k'
    if spark:
        for (x, y) in [(14,0),(15,1),(10,0),(15,5)]: rows[y][x] = spark
    return img(["".join(r) for r in rows])
save("icon_gel_wand", wand('g', None)); save("icon_rapid_wand", wand('c', 'y'))
save("icon_core_amulet", img(mirror(["..k.....","..kk....","...kk...","....kk..","....kyk.",".....ky.",".....kyk","....kkkk","...krppp","...krpPw","...krppp","....krrp",".....kkk","........","........","........"])))
save("icon_slime_boots", img(["................","....kkkk........","....kgGk........","....kggk........","....kggk........","....kggk........","....kggkk.......","....kgggkk......","...kggggGgkk....","...kgggggggGk...","...kDgggggggk...","...kkkkkkkkkk...","................","................","................","................"]))
# gemma di exp (8x8, disegnata a 2x)
save("exp_gem", img(mirror(["...k", "..kc", ".kcl", "kclb", "kclb", ".kbb", "..kb", "...k"])))
print("sprites:", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
