extends Node3D
class_name FantasyAtmosphere

## Camada visual original de fantasia MMORPG.
## Nao possui colisao nem regra de gameplay: apenas luz, runas e leitura visual.
## Os efeitos foram desenhados para hardware fraco: poucas luzes, sem sombras e
## meshes emissivas simples no lugar de sistemas de particulas caros.

const GOLD := Color(0.95, 0.67, 0.20, 1.0)
const CYAN := Color(0.18, 0.82, 1.0, 1.0)
const VIOLET := Color(0.55, 0.28, 0.92, 1.0)
const JADE := Color(0.18, 0.88, 0.56, 1.0)
const STONE := Color(0.18, 0.21, 0.24, 1.0)

var _time := 0.0
var _animated_fx: Array[Dictionary] = []

func _ready() -> void:
	_build_ruins_focus()
	_build_valley_focus()
	_build_camp_lights()
	_build_path_sigils()
	_build_fantasy_beacons()
	_build_wisps()

func _process(delta: float) -> void:
	_time += delta
	for fx in _animated_fx:
		var node := fx.get("node") as Node3D
		if not is_instance_valid(node):
			continue
		var speed := float(fx.get("speed", 1.0))
		var phase := float(fx.get("phase", 0.0))
		var amplitude := float(fx.get("amplitude", 0.08))
		var base_y := float(fx.get("base_y", node.position.y))
		var spin := float(fx.get("spin", 0.0))
		node.position.y = base_y + sin(_time * speed + phase) * amplitude
		node.rotation.y += delta * spin
		var pulse := 1.0 + sin(_time * speed * 1.35 + phase) * 0.045
		node.scale = Vector3.ONE * pulse

func _build_ruins_focus() -> void:
	_add_magic_disc("RuinsRuneOuter", Vector3(0, 0.055, -34.5), 2.8, 0.035, VIOLET, 1.7)
	_add_magic_disc("RuinsRuneInner", Vector3(0, 0.075, -34.5), 1.55, 0.028, CYAN, 1.9)
	_add_light("RuinsAura", Vector3(0, 1.8, -34.5), VIOLET, 2.0, 7.0)
	_add_light("RuinsTorchLeft", Vector3(-3.2, 1.7, -34.2), GOLD, 1.5, 4.5)
	_add_light("RuinsTorchRight", Vector3(3.2, 1.7, -34.2), GOLD, 1.5, 4.5)

func _build_valley_focus() -> void:
	_add_magic_disc("ValleyRuneOuter", Vector3(120, 0.055, -17), 3.35, 0.032, CYAN, 1.8)
	_add_magic_disc("ValleyRuneInner", Vector3(120, 0.075, -17), 1.75, 0.025, Color(0.48, 0.94, 0.82, 1.0), 1.6)
	_add_light("ValleyAura", Vector3(120, 1.7, -17), CYAN, 2.15, 8.0)

func _build_camp_lights() -> void:
	_add_light("CampWarmth", Vector3(0, 1.25, 15.2), GOLD, 1.35, 6.0)
	_add_light("CampTorchLeft", Vector3(-2.4, 1.6, 15.2), GOLD, 1.05, 3.5)
	_add_light("CampTorchRight", Vector3(2.4, 1.6, 15.2), GOLD, 1.05, 3.5)

func _build_path_sigils() -> void:
	# Pequenas marcas no Caminho dos Olivais criam ritmo visual sem poluir a rota.
	for entry in [
		["PathSigilA", Vector3(-1.7, 0.035, 7.0), GOLD],
		["PathSigilB", Vector3(1.7, 0.035, -2.0), CYAN],
		["PathSigilC", Vector3(-1.7, 0.035, -12.0), GOLD],
		["PathSigilD", Vector3(1.7, 0.035, -23.0), VIOLET]
	]:
		_add_magic_disc(String(entry[0]), entry[1], 0.42, 0.018, entry[2], 0.9)

func _build_fantasy_beacons() -> void:
	# Acampamento: dois guardioes de luz marcam a entrada da area segura.
	_add_crystal_beacon("CampWardLeft", Vector3(-4.6, 0.0, 11.7), GOLD, 0.82)
	_add_crystal_beacon("CampWardRight", Vector3(4.6, 0.0, 11.7), GOLD, 0.82)

	# Ruinas: violeta/ciano reforca o perigo sobrenatural e conduz o olhar ao portal.
	_add_crystal_beacon("RuinsBeaconLeft", Vector3(-4.9, 0.0, -31.0), VIOLET, 0.95)
	_add_crystal_beacon("RuinsBeaconRight", Vector3(4.9, 0.0, -31.0), CYAN, 0.95)

	# Vale: tons de jade distinguem imediatamente a segunda regiao.
	_add_crystal_beacon("ValleyBeaconLeft", Vector3(115.1, 0.0, -14.5), JADE, 0.92)
	_add_crystal_beacon("ValleyBeaconRight", Vector3(124.9, 0.0, -14.5), CYAN, 0.92)

func _build_wisps() -> void:
	_add_wisp("CampWispA", Vector3(-3.2, 1.15, 13.8), GOLD, 0.11, 0.0)
	_add_wisp("CampWispB", Vector3(3.0, 1.35, 16.2), GOLD, 0.09, 1.8)
	_add_wisp("RuinsWispA", Vector3(-2.2, 1.2, -33.5), VIOLET, 0.12, 0.7)
	_add_wisp("RuinsWispB", Vector3(2.0, 1.55, -35.2), CYAN, 0.10, 2.6)
	_add_wisp("ValleyWispA", Vector3(118.0, 1.35, -16.5), JADE, 0.11, 1.2)
	_add_wisp("ValleyWispB", Vector3(122.1, 1.7, -18.0), CYAN, 0.10, 3.1)

func _add_crystal_beacon(node_name: String, world_position: Vector3, color: Color, size_scale: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = world_position
	add_child(root)

	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.34 * size_scale
	base_mesh.bottom_radius = 0.46 * size_scale
	base_mesh.height = 0.22 * size_scale
	base_mesh.radial_segments = 8
	var base_instance := MeshInstance3D.new()
	base_instance.position.y = 0.11 * size_scale
	base_instance.mesh = base_mesh
	base_instance.material_override = _solid_material(STONE)
	base_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(base_instance)

	var crystal_root := Node3D.new()
	crystal_root.name = "Crystal"
	crystal_root.position.y = 0.78 * size_scale
	root.add_child(crystal_root)

	var lower := CylinderMesh.new()
	lower.top_radius = 0.0
	lower.bottom_radius = 0.25 * size_scale
	lower.height = 0.72 * size_scale
	lower.radial_segments = 4
	var lower_instance := MeshInstance3D.new()
	lower_instance.position.y = 0.18 * size_scale
	lower_instance.mesh = lower
	lower_instance.material_override = _emissive_material(color, 2.0, 0.92)
	lower_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crystal_root.add_child(lower_instance)

	var upper := CylinderMesh.new()
	upper.top_radius = 0.25 * size_scale
	upper.bottom_radius = 0.0
	upper.height = 0.42 * size_scale
	upper.radial_segments = 4
	var upper_instance := MeshInstance3D.new()
	upper_instance.position.y = -0.39 * size_scale
	upper_instance.mesh = upper
	upper_instance.material_override = _emissive_material(color, 1.7, 0.88)
	upper_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crystal_root.add_child(upper_instance)

	_animated_fx.append({
		"node": crystal_root,
		"base_y": crystal_root.position.y,
		"speed": 1.5 + float(_animated_fx.size() % 3) * 0.2,
		"phase": float(_animated_fx.size()) * 0.8,
		"amplitude": 0.055,
		"spin": 0.45,
	})

func _add_wisp(node_name: String, world_position: Vector3, color: Color, radius: float, phase: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	var wisp := MeshInstance3D.new()
	wisp.name = node_name
	wisp.position = world_position
	wisp.mesh = mesh
	wisp.material_override = _emissive_material(color, 2.4, 0.9)
	wisp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wisp)
	_animated_fx.append({
		"node": wisp,
		"base_y": world_position.y,
		"speed": 1.25,
		"phase": phase,
		"amplitude": 0.18,
		"spin": 0.0,
	})

func _add_magic_disc(node_name: String, world_position: Vector3, radius: float, height: float, color: Color, emission_energy: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.34)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy

	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.position = world_position
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

func _add_light(node_name: String, world_position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = world_position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	add_child(light)

func _emissive_material(color: Color, energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _solid_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
