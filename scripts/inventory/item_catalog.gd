extends RefCounted
class_name ItemCatalog

const ITEMS := {
	"wisp_essence": {
		"name": "Essencia do Ermo",
		"description": "Residuo frio deixado por espectros.",
		"max_stack": 20,
		"value": 3,
		"rarity": "Comum",
		"type": "material"
	},
	"bone_fragment": {
		"name": "Fragmento de Osso",
		"description": "Osso antigo ainda marcado pela corrupcao.",
		"max_stack": 20,
		"value": 4,
		"rarity": "Comum",
		"type": "material"
	},
	"ruin_shard": {
		"name": "Lasca das Ruinas",
		"description": "Fragmento mineral que pulsa com energia antiga.",
		"max_stack": 10,
		"value": 12,
		"rarity": "Incomum",
		"type": "material"
	},
	"healing_herb": {
		"name": "Erva Restauradora",
		"description": "Planta medicinal encontrada perto de fontes puras.",
		"max_stack": 10,
		"value": 8,
		"rarity": "Comum",
		"type": "consumable"
	},
	"pilgrim_sword": {
		"name": "Espada do Peregrino",
		"description": "Lamina simples, equilibrada e confiavel.",
		"max_stack": 1,
		"value": 28,
		"rarity": "Incomum",
		"type": "equipment",
		"equip_slot": "weapon",
		"attack_bonus": 4,
		"health_bonus": 0
	},
	"leather_vest": {
		"name": "Couraca de Couro",
		"description": "Protecao leve usada por viajantes das estradas antigas.",
		"max_stack": 1,
		"value": 32,
		"rarity": "Incomum",
		"type": "equipment",
		"equip_slot": "armor",
		"attack_bonus": 0,
		"health_bonus": 20
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

static func is_equipment(item_id: String) -> bool:
	var item := get_item(item_id)
	return String(item.get("type", "")) == "equipment" and not String(item.get("equip_slot", "")).is_empty()

static func equip_slot(item_id: String) -> String:
	return String(get_item(item_id).get("equip_slot", ""))

static func attack_bonus(item_id: String) -> int:
	return int(get_item(item_id).get("attack_bonus", 0))

static func health_bonus(item_id: String) -> int:
	return int(get_item(item_id).get("health_bonus", 0))
