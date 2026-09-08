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

	var skeleton := main_instance.get_node_or_null("SkeletonRaider")
	if skeleton == null:
		failures.append("SkeletonRaider ausente")
	else:
		await _validate_skeleton_visual(skeleton)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_skeleton_visual(skeleton: Node) -> void:
	var adapter := skeleton.get_node_or_null("VisualAdapter")
	if adapter == null:
		failures.append("Esqueleto sem VisualAdapter")
		return
	if not adapter.has_method("has_loaded_model") or not adapter.has_loaded_model():
		failures.append("Esqueleto nao carregou o GLB")
		return
	if not adapter.has_method("get_render_guard_mesh_count"):
		failures.append("ModelAdapter nao expoe protecao de culling")
		return

	var guarded_count := int(adapter.get_render_guard_mesh_count())
	if guarded_count <= 0:
		failures.append("Nenhuma mesh do esqueleto recebeu render guard")

	var imported := adapter.get_node_or_null("ImportedModel")
	if imported == null:
		failures.append("ImportedModel do esqueleto ausente")
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(imported, meshes)
	if meshes.is_empty():
		failures.append("Esqueleto importado nao possui MeshInstance3D")
		return

	for mesh_instance in meshes:
		if not mesh_instance.visible:
			failures.append("Mesh iniciou invisivel: %s" % mesh_instance.name)
		if mesh_instance.extra_cull_margin < 2.9:
			failures.append("Mesh sem margem de culling suficiente: %s" % mesh_instance.name)
		if mesh_instance.custom_aabb.size.length() <= mesh_instance.get_aabb().size.length():
			failures.append("AABB nao foi expandido: %s" % mesh_instance.name)

	# Reproduz as trocas de animacao mais comuns do bug observado: locomocao + ataque.
	if adapter.has_method("play_move"):
		adapter.play_move()
	for _frame in range(8):
		await process_frame
	if adapter.has_method("are_loaded_meshes_visible") and not adapter.are_loaded_meshes_visible():
		failures.append("Mesh desapareceu durante locomocao")

	if adapter.has_method("play_attack"):
		adapter.play_attack(0.35)
	for _frame in range(18):
		await process_frame
	if adapter.has_method("are_loaded_meshes_visible") and not adapter.are_loaded_meshes_visible():
		failures.append("Mesh desapareceu durante ataque")

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)

func _finish() -> void:
	if failures.is_empty():
		print("ANIMATED_RENDER_GUARD_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("ANIMATED_RENDER_GUARD: %s" % failure)
	quit(1)
