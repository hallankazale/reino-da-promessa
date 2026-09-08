extends RefCounted
class_name ItemCatalog

const ITEMS := {
	"wisp_essence": {
		"name": "Essencia do Ermo",
		"description": "Residuo frio deixado por espectros.",
		"max_stack": 20,
		"value": 3,
		"rarity": "Comum"
	},
	"bone_fragment": {
		"name": "Fragmento de Osso",
		"description": "Osso antigo ainda marcado pela corrupcao.",
		"max_stack": 20,
		"value": 4,
		"rarity": "Comum"
	},
	"ruin_shard": {
		"name": "Lasca das Ruinas",
		"description": "Fragmento mineral que pulsa com energia antiga.",
		"max_stack": 10,
		"value": 12,
		"rarity": "Incomum"
	},
	"healing_herb": {
		"name": "Erva Restauradora",
		"description": "Planta medicinal encontrada perto de fontes puras.",
		"max_stack": 10,
		"value": 8,
		"rarity": "Comum"
	}
}

static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func get_item(item_id: String) -> Dictionary:
	var item: Dictionary = ITEMS.get(item_id, {})
	return item.duplicate(true)

static func display_name(item_id: String) -> String:
	var item := get_item(item_id)
	return String(item.get("name", item_id))

static func max_stack(item_id: String) -> int:
	var item := get_item(item_id)
	return maxi(int(item.get("max_stack", 1)), 1)

static func value(item_id: String) -> int:
	var item := get_item(item_id)
	return maxi(int(item.get("value", 0)), 0)
