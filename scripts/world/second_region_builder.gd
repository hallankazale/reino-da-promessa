extends Node3D

const GROUND_COLOR := Color(0.24, 0.42, 0.25, 1.0)
const SAND_COLOR := Color(0.57, 0.47, 0.29, 1.0)
const WATER_COLOR := Color(0.12, 0.42, 0.58, 1.0)
const STONE_COLOR := Color(0.46, 0.47, 0.43, 1.0)
const STONE_DARK := Color(0.31, 0.34, 0.32, 1.0)
const WOOD_COLOR := Color(0.31, 0.18, 0.08, 1.0)
const LEAF_COLOR := Color(0.27, 0.49, 0.23, 1.0)
const LEAF_LIGHT := Color(0.39, 0.60, 0.28, 1.0)

# A ponte visual fica elevada para cruzar o riacho, mas CharacterBody3D nao sobe
# degraus verticais sozinho. Mantemos uma colisao continua no tabuleiro e duas
# rampas suaves nas extremidades para transformar a transicao em uma superficie
# caminhavel, sem acoplar nenhuma regra especial ao Player.
const BRIDGE_DECK_Y := 0.20
const BRIDGE_DECK_THICKNESS := 0.34
const BRIDGE_DECK_TOP_Y := BRIDGE_DECK_Y + BRIDGE_DECK_THICKNESS * 0.5
const BRIDGE_HALF_LENGTH := 2.61
const BRIDGE_RAMP_RUN := 1.70
const BRIDGE_RAMP_THICKNESS := 0.18

var _material_cache: Dictionary = {}

func _ready() -> void:
	_build_ground()
	_build_stream()
	_build_bridge()
	_build_spring_sanctuary()
	_build_vegetation()
	_build_arrival_marker()

func _build_ground() -> void:
	_add_box("Ground", Vector3(0, -0.2, 0), Vector3(58, 0.4, 58), GROUND_COLOR, true)
	_add_box("ArrivalPath", Vector3(0, 0.02, 14), Vector3(5.0, 0.06, 18), SAND_COLOR, false)
	_add_box("SanctuaryPath", Vector3(0, 0.02, -8), Vector3(5.0, 0.06, 18), SAND_COLOR, false)

	# Relevo de borda: baixo custo e sem colisao, apenas para silhueta.
	for data in [
		[Vector3(-22, -1.7, 10), Vector3(1.7, 0.65, 1.1)],
		[Vector3(22, -1.9, 6), Vector3(1.8, 0.62, 1.2)],
		[Vector3(-20, -1.8, -20), Vector3(1.6, 0.60, 1.1)],
		[Vector3(21, -2.0, -19), Vector3(1.9, 0.66, 1.0)]
	]:
		_add_scaled_sphere("ValeHill", data[0], 5.0, GROUND_COLOR.darkened(0.14), data[1])

func _build_stream() -> void:
	# A agua fica abaixo da passarela; nao interfere na fisica nesta primeira versao.
	_add_box("Stream", Vector3(0, -0.02, 1.5), Vector3(30, 0.05, 5.5), WATER_COLOR, false)
	for x in range(-13, 14, 3):
		_add_scaled_sphere("RiverRock", Vector3(float(x), 0.10, -1.8), 0.42, STONE_DARK, Vector3(1.4, 0.45, 0.95))
		_add_scaled_sphere("RiverRock", Vector3(float(x) + 1.2, 0.09, 4.5), 0.35, STONE_COLOR, Vector3(1.2, 0.42, 1.0))

func _build_bridge() -> void:
	var bridge := Node3D.new()
	bridge.name = "StoneBridge"
	bridge.position = Vector3(0, 0, 1.5)
	add_child(bridge)

	# As placas sao somente apresentacao. Uma unica colisao sob o tabuleiro evita
	# pequenas emendas entre slabs que podem prender a capsula do jogador.
	for z in [-2.25, -1.50, -0.75, 0.0, 0.75, 1.50, 2.25]:
		_add_box_to(bridge, "BridgeSlab", Vector3(0, BRIDGE_DECK_Y, z), Vector3(4.2, BRIDGE_DECK_THICKNESS, 0.72), STONE_COLOR, false)

	_add_collision_box_to(
		bridge,
		"BridgeDeckCollision",
		Vector3(0, BRIDGE_DECK_Y, 0),
		Vector3(4.2, BRIDGE_DECK_THICKNESS, BRIDGE_HALF_LENGTH * 2.0)
	)

	_add_bridge_ramp(bridge, 1.0)
	_add_bridge_ramp(bridge, -1.0)

	_add_box_to(bridge, "RailLeft", Vector3(-2.05, 0.65, 0), Vector3(0.22, 0.85, 5.2), STONE_DARK, true)
	_add_box_to(bridge, "RailRight", Vector3(2.05, 0.65, 0), Vector3(0.22, 0.85, 5.2), STONE_DARK, true)

func _add_bridge_ramp(bridge: Node3D, side: float) -> void:
	var rise := BRIDGE_DECK_TOP_Y
	var angle := atan(rise / BRIDGE_RAMP_RUN)
	var ramp_length := sqrt(BRIDGE_RAMP_RUN * BRIDGE_RAMP_RUN + rise * rise)
	var center_z := side * (BRIDGE_HALF_LENGTH + BRIDGE_RAMP_RUN * 0.5)
	# O topo externo toca Y=0; o topo interno encontra exatamente o tabuleiro.
	var center_y := rise * 0.5 - BRIDGE_RAMP_THICKNESS * 0.5 * cos(angle)
	var rotation_x := rad_to_deg(angle) * side

	_add_rotated_box_to(
		bridge,
		"BridgeApproachRamp",
		Vector3(0, center_y, center_z),
		Vector3(4.2, BRIDGE_RAMP_THICKNESS, ramp_length),
		STONE_COLOR,
		Vector3(rotation_x, 0, 0),
		true
	)

func _build_spring_sanctuary() -> void:
	var sanctuary := Node3D.new()
	sanctuary.name = "SpringSanctuary"
	sanctuary.position = Vector3(0, 0, -17)
	add_child(sanctuary)

	_add_cylinder_to(sanctuary, "PoolOuter", Vector3(0, 0.18, 0), 3.2, 3.5, 0.36, STONE_DARK)
	_add_cylinder_to(sanctuary, "PoolWater", Vector3(0, 0.38, 0), 2.75, 2.75, 0.10, WATER_COLOR)
	_add_cylinder_to(sanctuary, "SpringRock", Vector3(0, 0.95, 0), 0.85, 1.15, 1.6, STONE_COLOR)
	_add_cylinder_to(sanctuary, "SpringCap", Vector3(0, 1.82, 0), 0.42, 0.62, 0.28, STONE_DARK)

	for angle_index in range(6):
		var angle := TAU * float(angle_index) / 6.0
		var p := Vector3(cos(angle) * 4.8, 0, sin(angle) * 4.8)
		_add_column_to(sanctuary, p, 2.4)

	var light := OmniLight3D.new()
	light.name = "SpringGlow"
	light.position = Vector3(0, 1.5, 0)
	light.light_color = Color(0.32, 0.72, 1.0, 1.0)
	light.light_energy = 1.0
	light.omni_range = 6.5
	light.shadow_enabled = false
	sanctuary.add_child(light)

func _build_vegetation() -> void:
	var positions := [
		Vector3(-8, 0, 18), Vector3(8, 0, 16), Vector3(-11, 0, 8), Vector3(11, 0, 7),
		Vector3(-10, 0, -7), Vector3(10, 0, -9), Vector3(-12, 0, -18), Vector3(12, 0, -19)
	]
	for index in range(positions.size()):
		_add_valley_tree(positions[index], 0.9 + float(index % 3) * 0.08)

	for position in [Vector3(-5, 0, 11), Vector3(5.5, 0, 10), Vector3(-6, 0, -11), Vector3(6.5, 0, -12)]:
		_add_shrub(position)

func _build_arrival_marker() -> void:
	var marker := Node3D.new()
	marker.name = "ArrivalMarker"
	marker.position = Vector3(0, 1.15, 22)
	add_child(marker)

	var sign_root := Node3D.new()
	sign_root.name = "ValleySign"
	sign_root.position = Vector3(3.4, 0, 21.0)
	add_child(sign_root)
	_add_box_to(sign_root, "Post", Vector3(0, 1.0, 0), Vector3(0.12, 2.0, 0.12), WOOD_COLOR, false)
	_add_box_to(sign_root, "Board", Vector3(0, 1.75, 0), Vector3(2.8, 0.65, 0.10), WOOD_COLOR, false)
	var label := Label3D.new()
	label.position = Vector3(0, 1.75, -0.07)
	label.text = "Vale das Fontes"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 22
	label.outline_size = 5
	label.modulate = Color(0.78, 0.93, 0.72, 1.0)
	sign_root.add_child(label)

func _add_valley_tree(position: Vector3, scale_value: float) -> void:
	var tree := Node3D.new()
	tree.name = "ValleyTree"
	tree.position = position
	tree.scale = Vector3.ONE * scale_value
	add_child(tree)

	_add_cylinder_to(tree, "Trunk", Vector3(0, 1.4, 0), 0.22, 0.40, 2.8, WOOD_COLOR)
	_add_scaled_sphere_to(tree, "CrownA", Vector3(0, 3.35, 0), 1.2, LEAF_COLOR, Vector3(1.0, 0.82, 1.15))
	_add_scaled_sphere_to(tree, "CrownB", Vector3(0.85, 3.05, 0.2), 0.85, LEAF_LIGHT, Vector3(1.2, 0.72, 1.0))
	_add_scaled_sphere_to(tree, "CrownC", Vector3(-0.78, 3.0, -0.15), 0.82, LEAF_COLOR, Vector3(1.1, 0.70, 1.0))
	_add_collision_box_to(tree, "TreeCollision", Vector3(0, 1.25, 0), Vector3(0.60, 2.5, 0.60))

func _add_shrub(position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Shrub"
	root.position = position
	add_child(root)
	_add_scaled_sphere_to(root, "LeafA", Vector3(0, 0.42, 0), 0.62, LEAF_COLOR, Vector3(1.2, 0.75, 1.0))
	_add_scaled_sphere_to(root, "LeafB", Vector3(0.55, 0.35, 0.2), 0.42, LEAF_LIGHT, Vector3(1.0, 0.70, 1.0))

func _add_column_to(parent: Node, position: Vector3, height: float) -> void:
	var root := Node3D.new()
	root.name = "SanctuaryColumn"
	root.position = position
	parent.add_child(root)
	_add_box_to(root, "Base", Vector3(0, 0.16, 0), Vector3(0.85, 0.32, 0.85), STONE_DARK, true)
	_add_cylinder_to(root, "Shaft", Vector3(0, height * 0.5 + 0.20, 0), 0.26, 0.34, height, STONE_COLOR)
	_add_box_to(root, "Cap", Vector3(0, height + 0.24, 0), Vector3(0.78, 0.26, 0.78), STONE_COLOR, true)
	_add_collision_box_to(root, "ColumnCollision", Vector3(0, height * 0.5 + 0.18, 0), Vector3(0.62, height + 0.36, 0.62))

func _add_box(name: String, position: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	_add_box_to(self, name, position, size, color, collision)

func _add_box_to(parent: Node, name: String, position: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	if collision:
		var body := StaticBody3D.new()
		body.name = name
		body.position = position
		parent.add_child(body)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _box_mesh(size)
		mesh_instance.material_override = _material(color)
		body.add_child(mesh_instance)
		var collision_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	mesh_instance.mesh = _box_mesh(size)
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)

func _add_rotated_box_to(parent: Node, name: String, position: Vector3, size: Vector3, color: Color, rotation_degrees_value: Vector3, collision: bool) -> void:
	if collision:
		var body := StaticBody3D.new()
		body.name = name
		body.position = position
		body.rotation_degrees = rotation_degrees_value
		parent.add_child(body)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _box_mesh(size)
		mesh_instance.material_override = _material(color)
		body.add_child(mesh_instance)
		var collision_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
		return

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = position
	mesh_instance.rotation_degrees = rotation_degrees_value
	mesh_instance.mesh = _box_mesh(size)
	mesh_instance.material_override = _material(color)
	parent.add_child(mesh_instance)

func _add_collision_box_to(parent: Node, name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	parent.add_child(body)
	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	body.add_child(collision_shape)

func _add_cylinder_to(parent: Node, name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.position = position
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)

func _add_scaled_sphere(name: String, position: Vector3, radius: float, color: Color, scale_value: Vector3) -> void:
	_add_scaled_sphere_to(self, name, position, radius, color, scale_value)

func _add_scaled_sphere_to(parent: Node, name: String, position: Vector3, radius: float, color: Color, scale_value: Vector3) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 9
	mesh.rings = 5
	var instance := MeshInstance3D.new()
	instance.name = name
	instance.position = position
	instance.scale = scale_value
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)

func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _material(color: Color) -> StandardMaterial3D:
	var key := str(color)
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	_material_cache[key] = material
	return material
