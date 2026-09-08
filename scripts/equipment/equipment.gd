extends Node
class_name PlayerEquipment

signal changed
signal bonuses_changed(attack_bonus: int, health_bonus: int)

const ITEM_CATALOG = preload("res://scripts/inventory/item_catalog.gd")

@export var inventory_path: NodePath = NodePath("../Inventory")

var slots: Dictionary = {
	"weapon": "",
	"armor": ""
}

@onready var inventory: Node = get_node_or_null(inventory_path)

func equip_from_inventory(item_id: String) -> bool:
	if inventory == null or not ITEM_CATALOG.is_equipment(item_id):
		return false
	if inventory.count_item(item_id) <= 0:
		return false

	var slot := ITEM_CATALOG.equip_slot(item_id)
	if not slots.has(slot):
		return false

	var removed: int = inventory.remove_item(item_id, 1)
	if removed != 1:
		return false

	var previous := String(slots.get(slot, ""))
	if not previous.is_empty():
		var remaining: int = inventory.add_item(previous, 1)
		if remaining > 0:
			inventory.add_item(item_id, 1)
			return false

	slots[slot] = item_id
	_emit_state()
	return true

func unequip(slot: String) -> bool:
	if inventory == null or not slots.has(slot):
		return false
	var item_id := String(slots.get(slot, ""))
	if item_id.is_empty():
		return false

	var remaining: int = inventory.add_item(item_id, 1)
	if remaining > 0:
		return false

	slots[slot] = ""
	_emit_state()
	return true

func get_equipped(slot: String) -> String:
	return String(slots.get(slot, ""))

func get_attack_bonus() -> int:
	var total := 0
	for item_id in slots.values():
		if not String(item_id).is_empty():
			total += ITEM_CATALOG.attack_bonus(String(item_id))
	return total

func get_health_bonus() -> int:
	var total := 0
	for item_id in slots.values():
		if not String(item_id).is_empty():
			total += ITEM_CATALOG.health_bonus(String(item_id))
	return total

func get_save_state() -> Dictionary:
	return {"slots": slots.duplicate(true)}

func load_save_state(data: Dictionary) -> void:
	var incoming: Dictionary = data.get("slots", {})
	var restored := {"weapon": "", "armor": ""}
	for slot in restored.keys():
		var item_id := String(incoming.get(slot, ""))
		if item_id.is_empty():
			continue
		if ITEM_CATALOG.is_equipment(item_id) and ITEM_CATALOG.equip_slot(item_id) == slot:
			restored[slot] = item_id
	slots = restored
	_emit_state()

func clear() -> void:
	slots = {"weapon": "", "armor": ""}
	_emit_state()

func _emit_state() -> void:
	bonuses_changed.emit(get_attack_bonus(), get_health_bonus())
	changed.emit()
