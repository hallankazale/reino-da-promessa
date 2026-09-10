extends Node3D
class_name FantasyAtmosphere

## Camada visual original de fantasia MMORPG.
## Nao possui colisao nem regra de gameplay: apenas luz, runas e leitura visual.

const GOLD := Color(0.95, 0.67, 0.20, 1.0)
const CYAN := Color(0.18, 0.82, 1.0, 1.0)
const VIOLET := Color(0.55, 0.28, 0.92, 1.0)

func _ready() -> void:
	_build_ruins_focus()
	_build_valley_focus()
	_build_camp_lights()

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
