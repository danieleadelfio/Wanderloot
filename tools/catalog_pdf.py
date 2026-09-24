"""Genera il catalogo di Wanderloot in PDF (docs/catalog/Wanderloot_Catalogo.pdf) da docs/catalog/catalog.json.
Uso: python3 tools/catalog_pdf.py (dalla root del progetto; richiede reportlab).
Il JSON e' la fonte: la futura enciclopedia in gioco partira' dagli stessi contenuti."""
import json, os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "docs", "catalog", "catalog.json")
OUT = os.path.join(ROOT, "docs", "catalog", "Wanderloot_Catalogo.pdf")

FONT_DIR = "/usr/share/fonts/truetype/dejavu"
for name, file in (("Sans", "DejaVuSans.ttf"), ("Sans-Bold", "DejaVuSans-Bold.ttf")):
    for d in (FONT_DIR, "/Library/Fonts", "/System/Library/Fonts/Supplemental"):
        if os.path.exists(os.path.join(d, file)):
            pdfmetrics.registerFont(TTFont(name, os.path.join(d, file)))
            break
BODY = "Sans" if "Sans" in pdfmetrics.getRegisteredFontNames() else "Helvetica"
BOLD = "Sans-Bold" if "Sans-Bold" in pdfmetrics.getRegisteredFontNames() else "Helvetica-Bold"

INK = colors.HexColor("#1d1a24")
GOLD = colors.HexColor("#b88a3e")
MUTED = colors.HexColor("#6b6475")
PAPER = colors.HexColor("#f6f2ea")
LINE = colors.HexColor("#d9d1c3")
SOURCE_COLORS = {"wanderloot": colors.HexColor("#2f7d4a"), "magicraft_wiki": colors.HexColor("#6a3fa0"),
                 "magicraft_steam": colors.HexColor("#6a3fa0"), "magicraft_shapes": colors.HexColor("#8a5bb8")}

title = ParagraphStyle("t", fontName=BOLD, fontSize=26, leading=30, textColor=INK, spaceAfter=4)
subtitle = ParagraphStyle("st", fontName=BODY, fontSize=11, leading=15, textColor=MUTED, spaceAfter=14)
h1 = ParagraphStyle("h1", fontName=BOLD, fontSize=17, leading=21, textColor=INK, spaceBefore=6, spaceAfter=8)
h2 = ParagraphStyle("h2", fontName=BOLD, fontSize=12, leading=15, textColor=GOLD, spaceBefore=8, spaceAfter=4)
body = ParagraphStyle("b", fontName=BODY, fontSize=9.5, leading=13.5, textColor=INK, spaceAfter=6)
cell = ParagraphStyle("c", fontName=BODY, fontSize=8.5, leading=11.5, textColor=INK)
cell_b = ParagraphStyle("cb", parent=cell, fontName=BOLD)
cell_m = ParagraphStyle("cm", parent=cell, textColor=MUTED, fontSize=7.8, leading=10.5)


def table(rows, widths, header_bg=INK):
    t = Table(rows, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), header_bg), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), BOLD), ("FONTSIZE", (0, 0), (-1, 0), 8.5),
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PAPER]),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, LINE), ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t


def header_row(*labels):
    return [Paragraph(l, ParagraphStyle("hh", parent=cell_b, textColor=colors.white)) for l in labels]


def on_page(canvas, doc):
    canvas.saveState()
    canvas.setFont(BODY, 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(18 * mm, 10 * mm, "Wanderloot — Catalogo (base dell'enciclopedia in gioco)")
    canvas.drawRightString(A4[0] - 18 * mm, 10 * mm, "pag. %d" % doc.page)
    canvas.restoreState()


def build():
    data = json.load(open(SRC, encoding="utf-8"))
    src = data["sources"]
    story = [Paragraph("Wanderloot — Catalogo", title),
             Paragraph("Abilità della bacchetta, eventi, equipaggiamento, rarità e achievement. Versione %s." % data["version"], subtitle),
             Paragraph(data["intro"], body), Spacer(1, 4)]
    legend = [header_row("Fonte", "Significato")]
    for key, s in src.items():
        link = ' <font color="#6b6475">%s</font>' % s["url"] if s["url"] else ""
        legend.append([Paragraph('<font color="%s"><b>%s</b></font>' % (SOURCE_COLORS[key].hexval().replace("0x", "#"), s["label"]), cell),
                       Paragraph(s["note"] + link, cell_m)])
    story += [table(legend, [55 * mm, 119 * mm]), Spacer(1, 10)]

    story.append(Paragraph("1. Abilità della bacchetta", h1))
    story.append(Paragraph(data["spells_intro"], body))
    trig = {"cooldown": "Ricarica", "colpi": "Ogni N colpi", "distanza": "Ogni N metri", "sempre": "Sempre attiva"}
    for group, label in (("M10", "Implementate (M10)"), ("pianificata", "Pianificate")):
        rows = [header_row("Abilità", "Attivazione", "Cosa fa", "Fonte")]
        for s in data["spells"]:
            if s["status"] != group:
                continue
            name = "<b>%s</b>" % s["name"] + ('<br/><font color="#6b6475" size="7.5">orig.: %s</font>' % s["original"] if s["original"] else "")
            t = trig[s["trigger"]] + ("<br/>%s" % s["trigger_value"] if s["trigger_value"] else "")
            color = SOURCE_COLORS[s["source"]].hexval().replace("0x", "#")
            rows.append([Paragraph(name, cell), Paragraph(t, cell_m), Paragraph(s["desc"], cell),
                         Paragraph('<font color="%s">%s</font>' % (color, src[s["source"]]["short"]), cell_m)])
        story += [Paragraph(label, h2), table(rows, [38 * mm, 26 * mm, 86 * mm, 24 * mm]), Spacer(1, 6)]

    story += [PageBreak(), Paragraph("2. Eventi della run", h1), Paragraph(data["events_intro"], body)]
    rows = [header_row("Evento", "Cosa si deve fare", "Stato")]
    for e in data["events"]:
        rows.append([Paragraph("<b>%s</b>" % e["name"], cell), Paragraph(e["desc"], cell), Paragraph(e["status"], cell_m)])
    story += [table(rows, [40 * mm, 110 * mm, 24 * mm]), Spacer(1, 10)]

    if data.get("consumables"):
        story += [Paragraph("2b. Consumabili", h1), Paragraph(data["consumables_intro"], body)]
        rows = [header_row("Consumabile", "Effetto", "Stato")]
        for e in data["consumables"]:
            rows.append([Paragraph("<b>%s</b>" % e["name"], cell), Paragraph(e["desc"], cell), Paragraph(e["status"], cell_m)])
        story += [table(rows, [40 * mm, 110 * mm, 24 * mm]), Spacer(1, 10)]

    story += [Paragraph("3. Equipaggiamento", h1), Paragraph(data["equipment_intro"], body)]
    story.append(Paragraph("Slot", h2))
    story.append(Paragraph(" · ".join(data["slots"]), body))
    story.append(Paragraph("Rarità", h2))
    rows = [header_row("Rarità", "Drop", "Statistiche", "Modificatore di gameplay")]
    for name, color, drop, stats, mod in data["tiers"]:
        rows.append([Paragraph('<font color="%s"><b>%s</b></font>' % (color, name), cell), Paragraph(drop, cell),
                     Paragraph(stats, cell), Paragraph(mod, cell)])
    story += [table(rows, [30 * mm, 24 * mm, 70 * mm, 50 * mm])]
    story.append(Paragraph(data["tiers_note"], cell_m))
    story.append(Paragraph("Regole", h2))
    for rule in data["equipment_rules"]:
        story.append(Paragraph("• " + rule, body))
    story.append(Paragraph("Oggetti", h2))
    rows = [header_row("Oggetto", "Slot", "Effetto", "Stato")]
    for e in data["equipment"]:
        rows.append([Paragraph("<b>%s</b>" % e["name"], cell), Paragraph(e["slot"], cell_m), Paragraph(e["desc"], cell), Paragraph(e["status"], cell_m)])
    story += [table(rows, [44 * mm, 24 * mm, 82 * mm, 24 * mm]), Spacer(1, 10)]

    story += [KeepTogether([Paragraph("4. Achievement (proposte)", h1), Paragraph(data["achievements_intro"], body),
              table([header_row("Achievement", "Condizione")] + [[Paragraph("<b>%s</b>" % a, cell), Paragraph(d, cell)] for a, d in data["achievements"]],
                    [50 * mm, 124 * mm])])]
    doc = SimpleDocTemplate(OUT, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=18 * mm,
                            title="Wanderloot — Catalogo", author="Wanderloot")
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    print("catalogo:", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    build()
