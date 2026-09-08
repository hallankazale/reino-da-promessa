extends Node

## Presentation-only polish for procedural regions.
## This layer never changes collisions, quests, combat or progression. It is safe
## to disable independently if profiling ever shows a cost on very weak GPUs.

func _ready() -> void:
	call_deferred("_apply_presentation")

func _apply_presentation() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	_hide_landmark_billboards(scene_root)
	var first_region := scene_root.get_node_or_null("FirstRegion")
	if first_region != null:
		_add_instanced_grass(first_region)
		_add_instanced_pebbles(first_region)

func _hide_landmark_billboards(node: Node) -> void:
	if node is Label3D:
		var parent := node.get_parent()
		if parent != null and parent.name == "LandmarkSign":
			(node as Label3D).visible = false

	for child in node.get_children():
		_hide_landmark_billboards(child)

func _add_instanced_grass(region: Node3D) -> void:
	if region.get_node_or_null("AmbientGrass") != null:
		return

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.55, 0.07)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.34, 0.16, 1.0)
	material.roughness = 1.0
	mesh.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 88

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260908
	for index in range(multimesh.instance_count):
		var x := rng.randf_range(-16.0, 16.0)
		if absf(x) < 4.6:
			x = (1.0 if x >= 0.0 else -1.0) * rng.randf_range(4.8, 15.5)
		var z := rng.randf_range(-22.0, 30.0)
		var scale_y := rng.randf_range(0.55, 1.25)
		var scale_xz := rng.randf_range(0.65, 1.3)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		basis = basis.scaled(Vector3(scale_xz, scale_y, scale_xz))
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, 0.28 * scale_y, z)))

	var instance := MultiMeshInstance3D.new()
	instance.name = "AmbientGrass"
	instance.multimesh = multimesh
	region.add_child(instance)

func _add_instanced_pebbles(region: Node3D) -> void:
	if region.get_node_or_null("AmbientPebbles") != null:
		return

	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.28
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.36, 0.34, 0.30, 1.0)
	material.roughness = 1.0
	mesh.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 34

	var rng := RandomNumberGenerator.new()
	rng.seed = 9082026
	for index in range(multimesh.instance_count):
		var side := -1.0 if index % 2 == 0 else 1.0
		var x := side * rng.randf_range(3.2, 7.2)
		var z := rng.randf_range(-21.0, 24.0)
		var scale := rng.randf_range(0.55, 1.35)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		basis = basis.scaled(Vector3(scale * 1.35, scale * 0.55, scale))
		multimesh.set_instance_transform(index, Transform3D(basis, Vector3(x, 0.08, z)))

	var instance := MultiMeshInstance3D.new()
	instance.name = "AmbientPebbles"
	instance.multimesh = multimesh
	region.add_child(instance)
