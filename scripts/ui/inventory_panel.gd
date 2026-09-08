extends CanvasLayer

const ITEM_CATALOG = preload("res://scripts/inventory/item_catalog.gd")

@onready var panel: PanelContainer = $Panel
@onready var gold_label: Label = $Panel/VBox/GoldLabel
@onready var slots_label: Label = $Panel/VBox/SlotsLabel
@onready var item_list: ItemList = $Panel/VBox/ItemList
@onready var inventory: Node = get_node_or_null("../Player/Inventory")

func _ready() -> void:
	panel.visible = false
	if inventory != null and inventory.has_signal("changed"):
		inventory.changed.connect(_refresh)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		panel.visible = not panel.visible
		if panel.visible:
			_refresh()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	item_list.clear()
	if inventory == null:
		gold_label.text = "Ouro: -"
		slots_label.text = "Inventario indisponivel"
		return

	gold_label.text = "Ouro: %d" % int(inventory.gold)
	slots_label.text = "Espacos: %d / %d" % [inventory.used_slots(), inventory.capacity]

	var snapshot: Array[Dictionary] = inventory.get_snapshot()
	if snapshot.is_empty():
		item_list.add_item("Inventario vazio")
		item_list.set_item_disabled(0, true)
		return

	for slot in snapshot:
		var item_id := String(slot.get("item_id", ""))
		var quantity := int(slot.get("quantity", 0))
		var item := ITEM_CATALOG.get_item(item_id)
		var display_name := String(item.get("name", item_id))
		var rarity := String(item.get("rarity", "Comum"))
		item_list.add_item("%s  x%d   [%s]" % [display_name, quantity, rarity])
