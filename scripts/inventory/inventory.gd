extends Node
class_name PlayerInventory

signal changed
signal item_added(item_id: String, amount: int)
signal gold_changed(total: int)

const ITEM_CATALOG = preload("res://scripts/inventory/item_catalog.gd")

@export var capacity: int = 20

var slots: Array[Dictionary] = []
var gold: int = 0

func add_item(item_id: String, amount: int) -> int:
	if amount <= 0 or not ITEM_CATALOG.has_item(item_id):
		return maxi(amount, 0)

	var remaining := amount
	var stack_limit := ITEM_CATALOG.max_stack(item_id)

	for index in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[index]
		if String(slot.get("item_id", "")) != item_id:
			continue
		var quantity := int(slot.get("quantity", 0))
		var free_space := maxi(stack_limit - quantity, 0)
		if free_space <= 0:
			continue
		var moved := mini(free_space, remaining)
		slot["quantity"] = quantity + moved
		slots[index] = slot
		remaining -= moved

	while remaining > 0 and slots.size() < capacity:
		var moved := mini(stack_limit, remaining)
		slots.append({"item_id": item_id, "quantity": moved})
		remaining -= moved

	var accepted := amount - remaining
	if accepted > 0:
		item_added.emit(item_id, accepted)
		changed.emit()
	return remaining

func remove_item(item_id: String, amount: int) -> int:
	if amount <= 0:
		return 0

	var remaining := amount
	for index in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[index]
		if String(slot.get("item_id", "")) != item_id:
			continue
		var quantity := int(slot.get("quantity", 0))
		var removed := mini(quantity, remaining)
		quantity -= removed
		remaining -= removed
		if quantity <= 0:
			slots.remove_at(index)
		else:
			slot["quantity"] = quantity
			slots[index] = slot

	if remaining != amount:
		changed.emit()
	return amount - remaining

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)
	changed.emit()

func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	changed.emit()
	return true

func count_item(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if String(slot.get("item_id", "")) == item_id:
			total += int(slot.get("quantity", 0))
	return total

func get_snapshot() -> Array[Dictionary]:
	return slots.duplicate(true)

func get_save_state() -> Dictionary:
	return {
		"capacity": capacity,
		"gold": gold,
		"slots": slots.duplicate(true)
	}

func load_save_state(data: Dictionary) -> void:
	slots.clear()
	gold = maxi(int(data.get("gold", 0)), 0)

	var saved_slots: Array = data.get("slots", [])
	for raw_slot in saved_slots:
		if slots.size() >= capacity or not raw_slot is Dictionary:
			break
		var slot := raw_slot as Dictionary
		var item_id := String(slot.get("item_id", ""))
		var quantity := maxi(int(slot.get("quantity", 0)), 0)
		if not ITEM_CATALOG.has_item(item_id) or quantity <= 0:
			continue
		var remaining := quantity
		var stack_limit := ITEM_CATALOG.max_stack(item_id)
		while remaining > 0 and slots.size() < capacity:
			var moved := mini(stack_limit, remaining)
			slots.append({"item_id": item_id, "quantity": moved})
			remaining -= moved

	gold_changed.emit(gold)
	changed.emit()

func used_slots() -> int:
	return slots.size()

func clear() -> void:
	slots.clear()
	gold = 0
	gold_changed.emit(gold)
	changed.emit()
