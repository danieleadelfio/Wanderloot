class_name ItemText
extends RefCounted
## Testi e colori di un oggetto (inventario, fabbro, inventario di run). I colori per rarita' arrivano con #57.


static func color(_item: ItemInstance) -> Color:
	return Color(0.72, 0.72, 0.72)


static func title(item: ItemInstance) -> String:
	return TranslationServer.translate(item.base.display_name)


## Nome, descrizione dell'oggetto base e bonus, una riga ciascuno.
static func tooltip(item: ItemInstance) -> String:
	return "%s\n%s" % [title(item), TranslationServer.translate(item.base.description)]
