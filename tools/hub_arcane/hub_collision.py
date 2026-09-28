"""Collisioni dell'hub arcano (GDD §7): area calpestabile e ostacoli, in coordinate mondo.

Legge tools/hub_arcane/hub_layout.json (scritto da render.js) e stampa i nodi .tscn di `World/Bounds`
(da incollare in scenes/hub/Hub/Hub.tscn). Coordinate degli oggetti = quelle del mockup (hub_arcane.html).
Uso: python3 tools/hub_arcane/hub_collision.py > /tmp/bounds.tscn   — richiede: pip install shapely
"""
import json
import os

from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
LAYOUT = json.load(open(os.path.join(HERE, "hub_layout.json")))
K = LAYOUT["scale"]


def w(x, y):
    return ((x - 704) * K, (y - 384) * K)


def rect(x0, y0, x1, y1):
    a, b = w(x0, y0), w(x1, y1)
    return box(a[0], a[1], b[0], b[1])


def disc(x, y, r):
    return Point(*w(x, y)).buffer(r * K, 48)


# Area calpestabile: pavimento delle tre isole raggiungibili, ponti ovest/est, scale e piazza del portale.
# Le isole di espansione (nord-ovest, nord-est, sud) sono chiuse da una barriera: fuori dall'area.
walk = unary_union([Polygon(f) for f in LAYOUT["floors"]] + [
    rect(326, 318, 432, 352), rect(976, 318, 1082, 352),      # ponti (tra le corde)
    rect(424, 299, 500, 371), rect(908, 299, 984, 371),       # scale
    disc(704, 335, 210),                                      # piazza rialzata
]).simplify(0.8)

# Muro della piazza rialzata (con la faccia visibile a sud), aperto solo sulle due scale; spallette delle scale.
dais_wall = unary_union([disc(704, 335, 222), disc(704, 363, 222).intersection(rect(400, 335, 1008, 700))])
dais_wall = dais_wall.difference(disc(704, 335, 210)).difference(rect(400, 299, 512, 371)).difference(rect(896, 299, 1008, 371))
solids = list(getattr(dais_wall, "geoms", [dais_wall])) + [
    rect(424, 289, 500, 299), rect(424, 371, 500, 391), rect(908, 289, 984, 299), rect(908, 371, 984, 391),
    rect(128, 320, 252, 366),                                 # incudine
    Polygon([w(100, 215), w(164, 215), w(164, 258), w(100, 244)]),  # mantice
    rect(228, 215, 268, 236), rect(286, 409, 334, 417),        # lingotti, base della mola
    rect(1154, 301, 1282, 381),                                # baule
    rect(1080, 375, 1108, 403), rect(1328, 375, 1356, 403),    # casse
]
circles = [
    (704, 335, 100),                                          # vortice
    (575.3, 206.3, 22), (832.7, 206.3, 22), (575.3, 463.7, 22), (832.7, 463.7, 22),  # obelischi
    (462, 452, 14), (946, 452, 14), (574, 566, 19), (834, 566, 19),                  # alberi, bracieri
    (340, 312, 7), (1068, 312, 7),                                                    # lanterne dei ponti
    (190, 351, 34), (92, 277, 34), (288, 277, 20), (310, 397, 18),                    # ceppo, focolare, barile, mola
    (1116, 277, 20), (1146, 251, 14), (1320, 277, 20), (1290, 251, 14),                # botti
    (1100, 425, 15), (1336, 425, 15),                                                 # sacchi
    (1140, 267, 7), (1296, 267, 7), (1140, 423, 7), (1296, 423, 7),                   # candele
]


def pts(poly):
    c = list(poly.exterior.coords)[:-1]
    return "PackedVector2Array(%s)" % ", ".join("%.1f, %.1f" % p for p in c)


radii = sorted({r for _, _, r in circles})
out = []
for r in radii:
    out.append('[sub_resource type="CircleShape2D" id="hub_c%d"]\nradius = %.1f\n' % (r, r * K))
out.append('[node name="Bounds" type="StaticBody2D" parent="World"]\nunique_name_in_owner = true\n')
out.append('[node name="WalkEdge" type="CollisionPolygon2D" parent="World/Bounds"]\nunique_name_in_owner = true\nbuild_mode = 1\npolygon = %s\n' % pts(walk))
for i, s in enumerate(solids):
    out.append('[node name="Solid%d" type="CollisionPolygon2D" parent="World/Bounds"]\npolygon = %s\n' % (i, pts(s)))
for i, (x, y, r) in enumerate(circles):
    p = w(x, y)
    out.append('[node name="Round%d" type="CollisionShape2D" parent="World/Bounds"]\nposition = Vector2(%.1f, %.1f)\nshape = SubResource("hub_c%d")\n' % (i, p[0], p[1], r))
print("\n".join(out))
