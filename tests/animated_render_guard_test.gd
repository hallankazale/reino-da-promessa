extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/world/main.tscn")
	if main_scene == null:
		failures.append("Cena principal nao carregou")
		_finish()
		return

	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	for _frame in range(5):
		await process_frame

	# Mantemos o nome interno SkeletonRaider por compatibilidade com saves/testes e
	# enemy_kind/loot. A apresentacao, porem, nao pode mais usar o GLB defeituoso.
	var raider := main_instance.get_node_or_null("SkeletonRaider")
	if raider == null:
		failures.append("Raider de compatibilidade ausente")
	else:
		await _validate_raider_visual(raider)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_raider_visual(raider: Node) -> void:
	var visual_scene := raider.get("visual_scene") as PackedScene
	if visual_scene == null:
		failures.append("Saqueador nao possui visual_scene")
		return
	var visual_path := visual_scene.resource_path
	if visual_path.contains("skeleton_raider.glb"):
		failures.append("GLB skeleton_raider quebrado voltou ao gameplay")
	if not visual_path.contains("kaykit_adventurers/Rogue_Hooded.glb"):
		failures.append("Saqueador deveria usar Rogue_Hooded KayKit; atual: %s" % visual_path)

	var adapter := raider.get_node_or_null("VisualAdapter")
	if adapter == null:
		failures.append("Saqueador sem VisualAdapter")
		return
	if not adapter.has_method("has_loaded_model") or not adapter.has_loaded_model():
		failures.append("Saqueador nao carregou o GLB substituto")
		return
	if not adapter.has_method("get_render_guard_mesh_count"):
		failures.append("ModelAdapter nao expoe protecao de culling")
		return

	var guarded_count := int(adapter.get_render_guard_mesh_count())
	if guarded_count <= 0:
		failures.append("Nenhuma mesh do saqueador recebeu render guard")

	var imported := adapter.get_node_or_null("ImportedModel")
	if imported == null:
		failures.append("ImportedModel do saqueador ausente")
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(imported, meshes)
	if meshes.is_empty():
		failures.append("Saqueador importado nao possui MeshInstance3D")
		return

	for mesh_instance in meshes:
		if not mesh_instance.visible:
			failures.append("Mesh iniciou invisivel: %s" % mesh_instance.name)
		if mesh_instance.extra_cull_margin < 2.9:
			failures.append("Mesh sem margem de culling suficiente: %s" % mesh_instance.name)
		if mesh_instance.custom_aabb.size.length() <= mesh_instance.get_aabb().size.length():
			failures.append("AABB nao foi expandido: %s" % mesh_instance.name)

	var skeleton_nodes: Array[Skeleton3D] = []
	_collect_skeletons(imported, skeleton_nodes)
	if skeleton_nodes.is_empty():
		failures.append("Saqueador KayKit nao possui Skeleton3D")
		return

	if not adapter.has_method("get_skeleton_root_anchor_count") or int(adapter.get_skeleton_root_anchor_count()) <= 0:
		failures.append("ModelAdapter nao capturou root bone do saqueador")
		return

	var rig := skeleton_nodes[0]
	var root_bone := _find_root_bone(rig)
	if root_bone < 0:
		failures.append("Saqueador nao possui bone raiz")
		return

	var anchored_root_position := rig.get_bone_pose_position(root_bone)
	rig.set_bone_pose_position(root_bone, anchored_root_position + Vector3(4.0, 2.0, -3.0))
	await process_frame
	if rig.get_bone_pose_position(root_bone).distance_to(anchored_root_position) > 0.001:
		failures.append("Root bone do saqueador nao foi estabilizado")

	if adapter.has_method("play_move"):
		adapter.play_move()
	for _frame in range(8):
		await process_frame
	if adapter.has_method("are_loaded_meshes_visible") and not adapter.are_loaded_meshes_visible():
		failures.append("Mesh desapareceu durante locomocao")
	if rig.get_bone_pose_position(root_bone).distance_to(anchored_root_position) > 0.001:
		failures.append("Locomocao deslocou o root bone do saqueador")

	if adapter.has_method("play_attack"):
		adapter.play_attack(0.35)
	for _frame in range(18):
		await process_frame
	if adapter.has_method("are_loaded_meshes_visible") and not adapter.are_loaded_meshes_visible():
		failures.append("Mesh desapareceu durante ataque")
	if rig.get_bone_pose_position(root_bone).distance_to(anchored_root_position) > 0.001:
		failures.append("Ataque deslocou o root bone do saqueador")

func _find_root_bone(skeleton: Skeleton3D) -> int:
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(bone_index) == -1:
			return bone_index
	return -1

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)

func _collect_skeletons(node: Node, output: Array[Skeleton3D]) -> void:
	if node is Skeleton3D:
		output.append(node as Skeleton3D)
	for child in node.get_children():
		_collect_skeletons(child, output)

func _finish() -> void:
	if failures.is_empty():
		print("ANIMATED_RENDER_GUARD_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("ANIMATED_RENDER_GUARD: %s" % failure)
	quit(1)
