extends Node3D

const GROUND_COLOR := Color(0.29, 0.43, 0.23, 1.0)
const GROUND_DARK := Color(0.23, 0.35, 0.19, 1.0)
const PATH_COLOR := Color(0.50, 0.39, 0.24, 1.0)
const PATH_EDGE_COLOR := Color(0.36, 0.29, 0.20, 1.0)
const STONE_COLOR := Color(0.48, 0.47, 0.42, 1.0)
const STONE_DARK := Color(0.34, 0.35, 0.33, 1.0)
const WOOD_COLOR := Color(0.27, 0.15, 0.07, 1.0)
const WOOD_LIGHT := Color(0.38, 0.23, 0.11, 1.0)
const OLIVE_COLOR := Color(0.31, 0.43, 0.20, 1.0)
const OLIVE_LIGHT := Color(0.39, 0.50, 0.24, 1.0)
const CANVAS_COLOR := Color(0.73, 0.63, 0.43, 1.0)
const CANVAS_DARK := Color(0.53, 0.42, 0.27, 1.0)
const FIRE_COLOR := Color(0.94, 0.34, 0.05, 1.0)

var _material_cache: Dictionary = {}

func _ready() -> void:
	_build_ground()
	_build_background_relief()
	_build_pilgrim_camp()
	_build_olive_path()
	_build_ancient_ruins()
	_build_landmarks()

func _build_ground() -> void:
	_add_box("Ground", Vector3(0, -0.2, 0), Vector3(80, 0.4, 80), GROUND_COLOR, true)

	# A estrada continua barata, mas deixa de parecer uma sequencia de placas retas.
	for z in range(24, -29, -4):
		var offset_x := sin(float(z) * 0.17) * 0.45
		var yaw := sin(float(z) * 0.11) * 2.8
		_add_box_to(
			self,
			"Path_%d" % z,
			Vector3(offset_x, 0.025, float(z)),
			Vector3(5.4, 0.06, 4.2),
			PATH_COLOR,
			false,
			Vector3(0, yaw, 0)
		)

	# Bordas irregulares ajudam a dar profundidade ao caminho sem custo de terrain shader.
	for z in range(22, -27, -5):
		var drift := sin(float(z) * 0.19) * 0.35
		_add_flat_rock(Vector3(-3.1 + drift, 0.12, float(z) + 0.6), 0.75, float(z) * 7.0)
		_add_flat_rock(Vector3(3.0 - drift, 0.11, float(z) - 0.4), 0.65, float(z) * -5.0)

func _build_background_relief() -> void:
	# Silhuetas baixas no limite do mapa quebram o horizonte plano sem geometrias pesadas.
	var hill_positions := [
		Vector3(-31, -1.8, 16), Vector3(-28, -2.1, -10), Vector3(-30, -2.0, -30),
		Vector3(31, -1.8, 12), Vector3(29, -2.0, -13), Vector3(32, -2.2, -31)
	]
	for index in range(hill_positions.size()):
		var hill := MeshInstance3D.new()
		hill.name = "BackgroundHill_%d" % index
		hill.position = hill_positions[index]
		var mesh := SphereMesh.new()
		mesh.radius = 5.5
		mesh.height = 11.0
		mesh.radial_segments = 10
		mesh.rings = 5
		hill.mesh = mesh
		hill.scale = Vector3(1.8, 0.72, 1.15)
		hill.material_override = _material(GROUND_DARK)
		add_child(hill)

	for position in [Vector3(-18, 0, 4), Vector3(18, 0, -5), Vector3(-20, 0, -22), Vector3(19, 0, 24)]:
		_add_rock_cluster(position, 1.25)

func _build_pilgrim_camp() -> void:
	# Portal de madeira com travessa e suportes diagonais.
	_add_box("CampGateLeft", Vector3(-5.5, 1.35, 27), Vector3(0.38, 2.7, 0.38), WOOD_COLOR, true)
	_add_box("CampGateRight", Vector3(5.5, 1.35, 27), Vector3(0.38, 2.7, 0.38), WOOD_COLOR, true)
	_add_box("CampGateTop", Vector3(0, 2.45, 27), Vector3(11.5, 0.34, 0.42), WOOD_LIGHT, true)
	_add_box_to(self, "CampGateBraceL", Vector3(-3.9, 1.15, 27), Vector3(0.18, 2.2, 0.18), WOOD_LIGHT, false, Vector3(0, 0, -34))
	_add_box_to(self, "CampGateBraceR", Vector3(3.9, 1.15, 27), Vector3(0.18, 2.2, 0.18), WOOD_LIGHT, false, Vector3(0, 0, 34))

	_add_tent(Vector3(-8, 0, 20), 3.0)
	_add_tent(Vector3(8, 0, 20), -4.0)
	_add_tent(Vector3(-9, 0, 13), 8.0)
	_add_tent(Vector3(9, 0, 13), -8.0)
	_add_supply_stack(Vector3(-5.2, 0, 16.0))
	_add_supply_stack(Vector3(5.5, 0, 16.5))
	_add_campfire(Vector3(0, 0, 19))

	for x in [-12.0, -6.0, 6.0, 12.0]:
		_add_olive_tree(Vector3(x, 0, 29), 0.9)

func _build_olive_path() -> void:
	var tree_positions := [
		Vector3(-7, 0, 9), Vector3(8, 0, 7),
		Vector3(-9, 0, 1), Vector3(7, 0, -2),
		Vector3(-8, 0, -9), Vector3(9, 0, -12),
		Vector3(-7, 0, -18), Vector3(8, 0, -20)
	]
	for index in range(tree_positions.size()):
		_add_olive_tree(tree_positions[index], 0.92 + float(index % 3) * 0.08)

	for z in range(10, -21, -7):
		_add_rock_cluster(Vector3(-5.0, 0, z), 0.72)
		_add_rock_cluster(Vector3(5.0, 0, z - 2), 0.68)

	# Pequenos marcos de pedra tornam a viagem legivel e criam ritmo visual.
	for z in [6.0, -6.0, -18.0]:
		_add_waystone(Vector3(-3.8, 0, z))

func _build_ancient_ruins() -> void:
	_add_box("RuinFloor", Vector3(0, 0.08, -29), Vector3(20, 0.16, 16), STONE_DARK, false)

	# Escadaria de entrada.
	for step in range(3):
		_add_box(
			"RuinStep_%d" % step,
			Vector3(0, 0.12 + step * 0.12, -23.3 - step * 0.55),
			Vector3(8.8 - step * 0.7, 0.22, 1.1),
			STONE_COLOR,
			true
		)

	# Colunas com base, eixo e capitel em vez de blocos simples.
	for x in [-7.0, -3.5, 3.5, 7.0]:
		_add_ruin_column(Vector3(x, 0, -30), 3.4)

	_add_broken_wall(Vector3(-6.2, 0, -34.0), 6.0)
	_add_broken_wall(Vector3(6.0, 0, -34.0), 5.4)
	_add_box("RuinLintel", Vector3(0, 3.35, -30), Vector3(15.3, 0.48, 0.72), STONE_COLOR, true)

	_add_cylinder("RuinAltarBase", Vector3(0, 0.28, -32.0), 1.7, 1.85, 0.55, STONE_DARK)
	_add_cylinder("RuinAltar", Vector3(0, 0.82, -32.0), 1.2, 1.45, 0.75, STONE_COLOR)

	# Moldura monumental da passagem para a proxima regiao.
	_add_box("GatePillarL", Vector3(-2.1, 1.75, -36.5), Vector3(0.75, 3.5, 0.9), STONE_COLOR, true)
	_add_box("GatePillarR", Vector3(2.1, 1.75, -36.5), Vector3(0.75, 3.5, 0.9), STONE_COLOR, true)
	_add_box("GateCrown", Vector3(0, 3.25, -36.5), Vector3(5.0, 0.55, 1.0), STONE_COLOR, true)

	_add_rock_cluster(Vector3(-8.3, 0, -26.0), 1.0)
	_add_rock_cluster(Vector3(8.5, 0, -27.5), 1.1)

func _build_landmarks() -> void:
	_add_sign(Vector3(2.8, 0, 25), "Acampamento do Peregrino")
	_add_sign(Vector3(3.2, 0, 3), "Caminho dos Olivais")
	_add_sign(Vector3(3.8, 0, -23), "Ruinas Antigas")

func _add_tent(position: Vector3, yaw_degrees: float) -> void:
	var tent := Node3D.new()
	tent.name = "PilgrimTent"
	tent.position = position
	tent.rotation_degrees.y = yaw_degrees
	add_child(tent)

	# Paredes baixas e duas abas inclinadas simulam lona sem mesh customizada.
	_add_box_to(tent, "BackCloth", Vector3(0, 0.75, -1.45), Vector3(4.2, 1.5, 0.12), CANVAS_DARK, false)
	_add_box_to(tent, "RoofLeft", Vector3(-1.05, 1.25, 0), Vector3(2.5, 0.10, 3.1), CANVAS_COLOR, false, Vector3(0, 0, 34))
	_add_box_to(tent, "RoofRight", Vector3(1.05, 1.25, 0), Vector3(2.5, 0.10, 3.1), CANVAS_COLOR, false, Vector3(0, 0, -34))
	_add_box_to(tent, "PoleFront", Vector3(0, 1.15, 1.42), Vector3(0.11, 2.3, 0.11), WOOD_LIGHT, false)
	_add_box_to(tent, "PoleBack", Vector3(0, 1.15, -1.42), Vector3(0.11, 2.3, 0.11), WOOD_LIGHT, false)
	_add_box_to(tent, "Bedroll", Vector3(0.8, 0.16, 0.2), Vector3(1.2, 0.28, 1.8), CANVAS_DARK, false)
	_add_collision_box_to(tent, "TentCollision", Vector3(0, 0.7, -0.15), Vector3(4.3, 1.4, 2.8))

func _add_supply_stack(position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Supplies"
	root.position = position
	add_child(root)
	_add_box_to(root, "CrateA", Vector3(0, 0.38, 0), Vector3(0.9, 0.76, 0.9), WOOD_LIGHT, true, Vector3(0, 11, 0))
	_add_box_to(root, "CrateB", Vector3(0.62, 0.28, 0.15), Vector3(0.65, 0.56, 0.65), WOOD_COLOR, true, Vector3(0, -9, 0))
	_add_cylinder_to(root, "WaterJar", Vector3(-0.62, 0.42, 0.1), 0.26, 0.35, 0.82, Color(0.43, 0.28, 0.16, 1.0))

func _add_campfire(position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Campfire"
	root.position = position
	add_child(root)

	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var rock_position := Vector3(cos(angle) * 0.72, 0.16, sin(angle) * 0.72)
		_add_sphere_to(root, "FireStone_%d" % index, rock_position, 0.22, STONE_COLOR, Vector3(1.2, 0.65, 0.95))

	_add_box_to(root, "LogA", Vector3(0, 0.22, 0), Vector3(1.15, 0.16, 0.18), WOOD_COLOR, false, Vector3(0, 35, 0))
	_add_box_to(root, "LogB", Vector3(0, 0.25, 0), Vector3(1.15, 0.16, 0.18), WOOD_COLOR, false, Vector3(0, -35, 0))
	_add_cylinder_to(root, "FlameOuter", Vector3(0, 0.65, 0), 0.07, 0.34, 0.88, FIRE_COLOR)
	_add_cylinder_to(root, "FlameInner", Vector3(0.05, 0.67, -0.02), 0.04, 0.18, 0.62, Color(1.0, 0.72, 0.12, 1.0))

	var light := OmniLight3D.new()
	light.name = "FireLight"
	light.position = Vector3(0, 1.0, 0)
	light.light_color = Color(1.0, 0.49, 0.18, 1.0)
	light.light_energy = 1.15
	light.omni_range = 6.0
	light.shadow_enabled = false
	root.add_child(light)

func _add_olive_tree(position: Vector3, size_scale: float = 1.0) -> void:
	var tree := Node3D.new()
	tree.name = "OliveTree"
	tree.position = position
	tree.scale = Vector3.ONE * size_scale
	add_child(tree)

	_add_cylinder_to(tree, "Trunk", Vector3(0, 1.12, 0), 0.20, 0.36, 2.25, WOOD_COLOR)
	_add_cylinder_to(tree, "BranchL", Vector3(-0.35, 2.05, 0), 0.10, 0.15, 1.15, WOOD_COLOR, Vector3(0, 0, -32))
	_add_cylinder_to(tree, "BranchR", Vector3(0.38, 2.0, 0.08), 0.10, 0.15, 1.08, WOOD_COLOR, Vector3(0, 0, 31))
	_add_sphere_to(tree, "CrownA", Vector3(0, 2.85, 0), 1.22, OLIVE_COLOR, Vector3(1.15, 0.80, 1.05))
	_add_sphere_to(tree, "CrownB", Vector3(0.82, 2.60, 0.22), 0.88, OLIVE_LIGHT, Vector3(1.2, 0.78, 1.0))
	_add_sphere_to(tree, "CrownC", Vector3(-0.72, 2.55, -0.18), 0.84, OLIVE_COLOR, Vector3(1.12, 0.75, 1.0))
	_add_collision_box_to(tree, "TrunkCollision", Vector3(0, 1.0, 0), Vector3(0.55, 2.0, 0.55))

func _add_ruin_column(position: Vector3, height: float) -> void:
	var root := Node3D.new()
	root.name = "RuinColumn"
	root.position = position
	add_child(root)
	_add_box_to(root, "Base", Vector3(0, 0.18, 0), Vector3(1.15, 0.36, 1.15), STONE_DARK, true)
	_add_cylinder_to(root, "Shaft", Vector3(0, height * 0.5 + 0.25, 0), 0.38, 0.47, height, STONE_COLOR)
	_add_box_to(root, "Capital", Vector3(0, height + 0.35, 0), Vector3(1.05, 0.32, 1.05), STONE_COLOR, true)
	_add_collision_box_to(root, "ColumnCollision", Vector3(0, height * 0.5 + 0.2, 0), Vector3(0.82, height + 0.4, 0.82))

func _add_broken_wall(position: Vector3, width: float) -> void:
	var root := Node3D.new()
	root.name = "BrokenWall"
	root.position = position
	add_child(root)
	_add_box_to(root, "WallLow", Vector3(0, 0.65, 0), Vector3(width, 1.3, 0.62), STONE_DARK, true)
	_add_box_to(root, "WallHigh", Vector3(-width * 0.23, 1.55, 0), Vector3(width * 0.44, 0.85, 0.62), STONE_COLOR, true)
	_add_flat_rock(position + Vector3(width * 0.36, 0.18, 0.5), 0.75, width * 13.0)

func _add_waystone(position: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Waystone"
	root.position = position
	add_child(root)
	_add_box_to(root, "Stone", Vector3(0, 0.55, 0), Vector3(0.55, 1.1, 0.40), STONE_DARK, true, Vector3(0, 0, 4))
	_add_box_to(root, "Mark", Vector3(0, 0.72, -0.22), Vector3(0.12, 0.42, 0.04), Color(0.78, 0.65, 0.28, 1.0), false)

func _add_rock_cluster(position: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.name = "RockCluster"
	root.position = position
	root.scale = Vector3.ONE * scale_value
	add_child(root)
	_add_sphere_to(root, "RockA", Vector3(0, 0.32, 0), 0.62, STONE_DARK, Vector3(1.25, 0.58, 0.95))
	_add_sphere_to(root, "RockB", Vector3(0.58, 0.22, 0.18), 0.42, STONE_COLOR, Vector3(1.0, 0.55, 1.18))
	_add_sphere_to(root, "RockC", Vector3(-0.46, 0.18, -0.15), 0.34, STONE_COLOR, Vector3(1.1, 0.48, 0.9))

func _add_flat_rock(position: Vector3, scale_value: float, yaw_degrees: float) -> void:
	var root := Node3D.new()
	root.name = "RoadRock"
	root.position = position
	root.rotation_degrees.y = yaw_degrees
	root.scale = Vector3.ONE * scale_value
	add_child(root)
	_add_sphere_to(root, "Rock", Vector3.ZERO, 0.48, PATH_EDGE_COLOR, Vector3(1.35, 0.32, 0.95))

func _add_sign(position: Vector3, text: String) -> void:
	var sign_root := Node3D.new()
	sign_root.name = "LandmarkSign"
	sign_root.position = position
	add_child(sign_root)

	_add_box_to(sign_root, "Post", Vector3(0, 1.0, 0), Vector3(0.12, 2.0, 0.12), WOOD_COLOR, false)
	_add_box_to(sign_root, "Board", Vector3(0, 1.78, 0), Vector3(2.6, 0.62, 0.10), WOOD_LIGHT, false)
	var label := Label3D.new()
	label.position = Vector3(0, 1.78, -0.07)
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 20
	label.outline_size = 4
	label.modulate = Color(0.96, 0.88, 0.66, 1.0)
	sign_root.add_child(label)

func _add_box(name: String, position: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	_add_box_to(self, name, position, size, color, collision)

func _add_box_to(parent: Node, name: String, position: Vector3, size: Vector3, color: Color, collision: bool, rotation_degrees_value: Vector3 = Vector3.ZERO) -> void:
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

func _add_cylinder(name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color) -> void:
	_add_cylinder_to(self, name, position, top_radius, bottom_radius, height, color)

func _add_cylinder_to(parent: Node, name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color, rotation_degrees_value: Vector3 = Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 9

	var instance := MeshInstance3D.new()
	instance.name = name
	instance.position = position
	instance.rotation_degrees = rotation_degrees_value
	instance.mesh = mesh
	instance.material_override = _material(color)
	parent.add_child(instance)

func _add_sphere_to(parent: Node, name: String, position: Vector3, radius: float, color: Color, scale_value: Vector3 = Vector3.ONE) -> void:
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
