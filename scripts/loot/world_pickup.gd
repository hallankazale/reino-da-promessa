extends Node3D

const ITEM_CATALOG = preload("res://scripts/inventory/item_catalog.gd")

@export var item_id: String = ""
@export var quantity: int = 0
@export var gold_amount: int = 0
@export var spin_speed: float = 1.5

@onready var visual: Node3D = $Visual
@onready var orb: MeshInstance3D = $Visual/Orb
@onready var label: Label3D = $Label

func _ready() -> void:
	add_to_group("interactables")
	_refresh()

func _process(delta: float) -> void:
	visual.rotation.y += spin_speed * delta

func configure_item(new_item_id: String, new_quantity: int) -> void:
	item_id = new_item_id
	quantity = maxi(new_quantity, 1)
	gold_amount = 0
	if is_node_ready():
		_refresh()

func configure_gold(amount: int) -> void:
	gold_amount = maxi(amount, 1)
	item_id = ""
	quantity = 0
	if is_node_ready():
		_refresh()

func interact(player: Node) -> void:
	if not is_instance_valid(player):
		return
	var inventory := player.get_node_or_null("Inventory")
	if inventory == null:
		return

	if gold_amount > 0:
		if inventory.has_method("add_gold"):
			inventory.add_gold(gold_amount)
			queue_free()
		return

	if item_id.is_empty() or quantity <= 0 or not inventory.has_method("add_item"):
		return

	var remaining: int = inventory.add_item(item_id, quantity)
	if remaining <= 0:
		queue_free()
		return

	quantity = remaining
	_refresh()

func _refresh() -> void:
	if gold_amount > 0:
		label.text = "%d ouro  [E]" % gold_amount
		_apply_color(Color(0.92, 0.70, 0.16, 1.0))
		return

	if ITEM_CATALOG.has_item(item_id):
		label.text = "%s x%d  [E]" % [ITEM_CATALOG.display_name(item_id), quantity]
		var rarity := String(ITEM_CATALOG.get_item(item_id).get("rarity", "Comum"))
		_apply_color(Color(0.42, 0.76, 1.0, 1.0) if rarity == "Incomum" else Color(0.78, 0.92, 0.72, 1.0))
		return

	label.text = "Objeto desconhecido"
	_apply_color(Color(0.75, 0.75, 0.75, 1.0))

func _apply_color(color: Color) -> void:
	label.modulate = color
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.25)
	material.emission_enabled = true
	material.emission = color * 0.55
	material.emission_energy_multiplier = 1.2
	material.roughness = 0.45
	orb.material_override = material
