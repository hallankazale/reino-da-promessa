extends Node3D

const GROUND_COLOR := Color(0.30, 0.43, 0.22, 1.0)
const PATH_COLOR := Color(0.46, 0.35, 0.22, 1.0)
const STONE_COLOR := Color(0.42, 0.41, 0.37, 1.0)
const WOOD_COLOR := Color(0.28, 0.16, 0.08, 1.0)
const OLIVE_COLOR := Color(0.27, 0.38, 0.17, 1.0)
const CANVAS_COLOR := Color(0.68, 0.58, 0.39, 1.0)

func _ready() -> void:
	_build_ground()
	_build_pilgrim_camp()
	_build_olive_path()
	_build_ancient_ruins()
	_build_landmarks()

func _build_ground() -> void:
	_add_box("Ground", Vector3(0, -0.2, 0), Vector3(80, 0.4, 80), GROUND_COLOR, true)

	for z in range(24, -29, -4):
		_add_box(
			"Path_%d" % z,
			Vector3(0, 0.03, float(z)),
			Vector3(5.0, 0.08, 3.6),
			PATH_COLOR,
			false
		)

func _build_pilgrim_camp() -> void:
	# Entrada e pequenas tendas. Sao geometria de prototipo e serao trocadas por assets CC0.
	_add_box("CampGateLeft", Vector3(-5.5, 1.1, 27), Vector3(0.45, 2.2, 0.45), WOOD_COLOR, true)
	_add_box("CampGateRight", Vector3(5.5, 1.1, 27), Vector3(0.45, 2.2, 0.45), WOOD_COLOR, true)
	_add_box("CampGateTop", Vector3(0, 2.1, 27), Vector3(11.4, 0.35, 0.35), WOOD_COLOR, true)

	_add_tent(Vector3(-8, 0.7, 20), 0.0)
	_add_tent(Vector3(8, 0.7, 20), 0.0)
	_add_tent(Vector3(-9, 0.7, 13), 0.12)
	_add_tent(Vector3(9, 0.7, 13), -0.12)

	_add_cylinder("CampfireRing", Vector3(0, 0.12, 19), 0.9, 0.9, 0.22, STONE_COLOR)
	_add_cylinder("Campfire", Vector3(0, 0.34, 19), 0.35, 0.28, 0.42, Color(0.72, 0.28, 0.06, 1.0))

	for x in [-12.0, -6.0, 6.0, 12.0]:
		_add_olive_tree(Vector3(x, 0, 29))

func _build_olive_path() -> void:
	var tree_positions := [
		Vector3(-7, 0, 9), Vector3(8, 0, 7),
		Vector3(-9, 0, 1), Vector3(7, 0, -2),
		Vector3(-8, 0, -9), Vector3(9, 0, -12),
		Vector3(-7, 0, -18), Vector3(8, 0, -20)
	]
	for position in tree_positions:
		_add_olive_tree(position)

	# Pedras laterais ajudam a leitura do caminho sem criar paredes invisiveis.
	for z in range(10, -21, -6):
		_add_box("RoadStoneL_%d" % z, Vector3(-4.2, 0.25, z), Vector3(0.8, 0.5, 0.9), STONE_COLOR, true)
		_add_box("RoadStoneR_%d" % z, Vector3(4.2, 0.25, z - 2), Vector3(0.9, 0.5, 0.8), STONE_COLOR, true)

func _build_ancient_ruins() -> void:
	_add_box("RuinFloor", Vector3(0, 0.12, -28), Vector3(18, 0.24, 14), Color(0.34, 0.34, 0.31, 1.0), false)

	for x in [-7.0, -3.5, 3.5, 7.0]:
		_add_box("RuinPillar_%s" % str(x), Vector3(x, 1.6, -30), Vector3(0.9, 3.2, 0.9), STONE_COLOR, true)

	_add_box("RuinBackWallL", Vector3(-5.5, 1.25, -34), Vector3(7, 2.5, 0.7), STONE_COLOR, true)
	_add_box("RuinBackWallR", Vector3(5.5, 1.25, -34), Vector3(7, 2.5, 0.7), STONE_COLOR, true)
	_add_box("RuinLintel", Vector3(0, 3.0, -30), Vector3(15, 0.6, 0.8), STONE_COLOR, true)

	_add_cylinder("RuinAltar", Vector3(0, 0.65, -31.8), 1.4, 1.1, 1.3, Color(0.37, 0.35, 0.31, 1.0))

func _build_landmarks() -> void:
	_add_sign(Vector3(2.8, 1.0, 25), "Acampamento do Peregrino")
	_add_sign(Vector3(3.2, 1.0, 3), "Caminho dos Olivais")
	_add_sign(Vector3(3.5, 1.0, -23), "Ruinas Antigas")

func _add_tent(position: Vector3, yaw: float) -> void:
	var tent := Node3D.new()
	tent.name = "Tent"
	tent.position = position
	tent.rotation.y = yaw
	add_child(tent)

	_add_box_to(tent, "TentBody", Vector3.ZERO, Vector3(4.2, 1.4, 3.0), CANVAS_COLOR, false)
	_add_box_to(tent, "TentPoleLeft", Vector3(-1.8, 0, 0), Vector3(0.12, 2.5, 0.12), WOOD_COLOR, false)
	_add_box_to(tent, "TentPoleRight", Vector3(1.8, 0, 0), Vector3(0.12, 2.5, 0.12), WOOD_COLOR, false)

func _add_olive_tree(position: Vector3) -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = position
	add_child(tree)

	_add_cylinder_to(tree, "Trunk", Vector3(0, 1.15, 0), 0.22, 0.34, 2.3, WOOD_COLOR)
	_add_sphere_to(tree, "CrownA", Vector3(0, 2.7, 0), 1.25, OLIVE_COLOR)
	_add_sphere_to(tree, "CrownB", Vector3(0.75, 2.5, 0.2), 0.85, OLIVE_COLOR)
	_add_sphere_to(tree, "CrownC", Vector3(-0.65, 2.45, -0.15), 0.8, OLIVE_COLOR)

func _add_sign(position: Vector3, text: String) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "LandmarkSign"
	sign_root.position = position
	add_child(sign_root)

	_add_box_to(sign_root, "Post", Vector3(0, 0, 0), Vector3(0.12, 2.0, 0.12), WOOD_COLOR, false)
	var label := Label3D.new()
	label.position = Vector3(0, 1.25, 0)
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.outline_size = 6
	label.modulate = Color(0.96, 0.88, 0.66, 1.0)
	sign_root.add_child(label)

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

func _add_cylinder(name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color) -> void:
	_add_cylinder_to(self, name, position, top_radius, bottom_radius, height, color)

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

func _add_sphere_to(parent: Node, name: String, position: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5

	var instance := MeshInstance3D.new()
	instance.name = name
	instance.position = position
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)

func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material
