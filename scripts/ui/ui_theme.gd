class_name UiTheme
extends RefCounted
## Accesso al tema di progetto (data/ui/wanderloot_theme.tres) per la UI costruita da codice (M13, #86).
## Tutti gli stili stanno nel tema come tipi (WindowPanel, ItemSlot, HpBar, ...): scene e script usano
## theme_type_variation, mai StyleBox scritti in giro. Cosi' il reskin grafico (docs/UI_ASSETS.md)
## tocca un solo file.


static func project_theme() -> Theme:
	return ThemeDB.get_project_theme()


## Copia di uno stile del tema con il bordo nel colore dato (es. rarita' di un oggetto).
static func tinted(style: StringName, type: StringName, color: Color) -> StyleBox:
	return tint(project_theme().get_stylebox(style, type), color)


## Copia di box con il bordo nel colore dato, l'originale non si tocca. Funziona sia con gli stili piatti
## di oggi sia con le cornici a texture del reskin (StyleBoxTexture.modulate_color): la cornice si
## disegna chiara e prende il colore qui.
static func tint(box: StyleBox, color: Color) -> StyleBox:
	var copy: StyleBox = box.duplicate()
	if copy is StyleBoxFlat:
		(copy as StyleBoxFlat).border_color = color
	elif copy is StyleBoxTexture:
		(copy as StyleBoxTexture).modulate_color = color
	return copy
