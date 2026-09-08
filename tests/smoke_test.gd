extends SceneTree

const LOOT_TABLE = preload("res://scripts/loot/loot_table.gd")
const PICKUP_SCENE: PackedScene = preload("res://scenes/loot/world_pickup.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var required_resources := [
		"res://scenes/world/main.tscn",
		"res://scenes/world/first_region.tscn",
		"res://scenes/world/second_region.tscn",
		"res://scenes/world/region_gate.tscn",
		"res://scenes/ui/damage_popup.tscn",
		"res://scenes/ui/inventory_panel.tscn",
		"res://scenes/ui/game_hud.tscn",
		"res://scenes/loot/world_pickup.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/enemies/enemy_base.tscn",
		"res://scenes/npcs/eliabe.tscn",
		"res://scenes/npcs/miriam.tscn",
		"res://scenes/npcs/benaya.tscn",
		"res://scripts/player/player_controller.gd",
		"res://scripts/enemies/enemy_base.gd",
		"res://scripts/art/model_adapter.gd",
		"res://scripts/art/knight_fallback.gd",
		"res://scripts/npcs/quest_giver.gd",
		"res://scripts/npcs/story_npc.gd",
		"res://scripts/quests/quest_manager.gd",
		"res://scripts/world/first_region_builder.gd",
		"res://scripts/world/second_region_builder.gd",
		"res://scripts/world/region_gate.gd",
		"res://scripts/world/world_presentation.gd",
		"res://scripts/inventory/item_catalog.gd",
		"res://scripts/inventory/inventory.gd",
		"res://scripts/loot/loot_table.gd",
		"res://scripts/loot/loot_manager.gd",
		"res://scripts/loot/world_pickup.gd",
		"res://scripts/ui/damage_popup.gd",
		"res://scripts/ui/inventory_panel.gd",
		"res://scripts/ui/hud.gd",
		"res://assets/third_party/quaternius/pilgrim_guardian.glb",
		"res://assets/third_party/quaternius/wasteland_specter.glb",
		"res://assets/third_party/quaternius/skeleton_raider.glb",
		"res://assets/third_party/quaternius/ruins_demon.glb"
	]

	for path in required_resources:
		_check_resource(path)

	for action in ["move_forward", "move_back", "move_left", "move_right", "target_next", "attack", "interact", "inventory"]:
		if not InputMap.has_action(action):
			failures.append("Input ausente: %s" % action)

	if not failures.is_empty():
		_finish()
		return

	var main_scene: PackedScene = load("res://scenes/world/main.tscn")
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)

	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var player := main_instance.get_node_or_null("Player")
	var inventory := main_instance.get_node_or_null("Player/Inventory")
	var loot_manager := main_instance.get_node_or_null("LootManager")
	var inventory_panel := main_instance.get_node_or_null("InventoryPanel")
	var hud := main_instance.get_node_or_null("HUD")
	var quest_manager := main_instance.get_node_or_null("QuestManager")
	var eliabe := main_instance.get_node_or_null("Eliabe")
	var miriam := main_instance.get_node_or_null("Miriam")
	var benaya := main_instance.get_node_or_null("Benaya")
	var first_region := main_instance.get_node_or_null("FirstRegion")
	var second_region := main_instance.get_node_or_null("SecondRegion")
	var gate := main_instance.get_node_or_null("RegionGate")
	var return_gate := main_instance.get_node_or_null("ReturnGate")
	var quest_title := main_instance.get_node_or_null("HUD/QuestPanel/Panel/VBox/Title")
	var region_label := main_instance.get_node_or_null("HUD/RegionBanner/Panel/Label")
	var target_panel := main_instance.get_node_or_null("HUD/TargetPanel")
	var prompt_panel := main_instance.get_node_or_null("HUD/PromptPanel")
	var player_panel := main_instance.get_node_or_null("HUD/PlayerPanel")
	var enemies := get_nodes_in_group("enemies")
	var interactables := get_nodes_in_group("interactables")

	if player == null:
		failures.append("Player nao foi instanciado")
	if inventory == null:
		failures.append("Player nao possui Inventory")
	if loot_manager == null:
		failures.append("LootManager nao foi instanciado")
	if inventory_panel == null:
		failures.append("InventoryPanel nao foi instanciado")
	elif inventory_panel.get_node_or_null("Panel") == null:
		failures.append("InventoryPanel nao possui painel visual")
	if hud == null or player_panel == null or target_panel == null or prompt_panel == null:
		failures.append("HUD modular nao possui seus paineis essenciais")
	if quest_manager == null:
		failures.append("QuestManager nao foi instanciado")

	for npc in [eliabe, miriam, benaya]:
		if npc == null:
			failures.append("NPC de historia ausente")
		elif not npc.has_method("get_interaction_prompt"):
			failures.append("%s nao expoe prompt contextual" % npc.name)

	if first_region == null:
		failures.append("Primeira regiao nao foi instanciada")
	elif first_region.get_node_or_null("Ground") == null:
		failures.append("Primeira regiao nao construiu o terreno")
	if second_region == null:
		failures.append("Vale das Fontes nao foi instanciado")
	else:
		if second_region.get_node_or_null("Ground") == null:
			failures.append("Vale das Fontes nao construiu o terreno")
		if second_region.get_node_or_null("ArrivalMarker") == null:
			failures.append("Vale das Fontes nao possui ArrivalMarker")
	if gate == null or return_gate == null:
		failures.append("Passagens entre regioes nao foram instanciadas")
	elif not gate.has_method("get_interaction_prompt"):
		failures.append("RegionGate nao expoe prompt contextual")
	if quest_title == null or region_label == null:
		failures.append("HUD nao possui labels essenciais")
	if enemies.size() != 5:
		failures.append("Esperados 5 inimigos, encontrados %d" % enemies.size())
	if interactables.size() < 5:
		failures.append("Esperados 3 NPCs + 2 passagens como interactables")

	if player != null:
		_validate_player_knight(player)

	for enemy in enemies:
		_validate_visual_adapter(enemy, enemy.get_display_name() if enemy.has_method("get_display_name") else enemy.name)
		if not enemy.has_signal("loot_requested"):
			failures.append("%s nao expoe loot_requested" % enemy.name)

	if inventory != null and player != null:
		_test_inventory_domain(inventory)
		await _test_pickup_interaction(main_instance, player, inventory)
		_test_loot_table()

	if player != null and inventory != null and quest_manager != null and gate != null and return_gate != null and eliabe != null and miriam != null and benaya != null:
		_test_story_progression(player, inventory, quest_manager, enemies, gate, return_gate)

	main_instance.queue_free()
	await process_frame
	_finish()

func _test_inventory_domain(inventory: Node) -> void:
	inventory.clear()
	var remaining: int = inventory.add_item("bone_fragment", 25)
	if remaining != 0:
		failures.append("Inventario recusou itens com espaco disponivel")
	if inventory.count_item("bone_fragment") != 25:
		failures.append("Empilhamento deveria manter 25 Fragmentos de Osso")
	if inventory.used_slots() != 2:
		failures.append("25 itens com stack 20 deveriam ocupar 2 slots")

	inventory.add_gold(7)
	if inventory.gold != 7:
		failures.append("Ouro nao foi adicionado corretamente")
	if not inventory.spend_gold(3) or inventory.gold != 4:
		failures.append("Gasto de ouro falhou")
	if inventory.spend_gold(10):
		failures.append("Inventario permitiu gastar ouro inexistente")

	var removed: int = inventory.remove_item("bone_fragment", 6)
	if removed != 6 or inventory.count_item("bone_fragment") != 19:
		failures.append("Remocao de itens falhou")

	inventory.clear()

func _test_pickup_interaction(main_instance: Node, player: Node, inventory: Node) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	main_instance.add_child(pickup)
	pickup.configure_item("wisp_essence", 2)
	await process_frame
	if not pickup.has_method("get_interaction_prompt"):
		failures.append("Pickup nao expoe prompt contextual")

	pickup.interact(player)
	await process_frame
	if inventory.count_item("wisp_essence") != 2:
		failures.append("Pickup nao adicionou item ao inventario")

	var gold_pickup := PICKUP_SCENE.instantiate()
	main_instance.add_child(gold_pickup)
	gold_pickup.configure_gold(5)
	await process_frame
	gold_pickup.interact(player)
	await process_frame
	if inventory.gold != 5:
		failures.append("Pickup de ouro nao atualizou a carteira")

	inventory.clear()

func _test_loot_table() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123456
	var drops: Array[Dictionary] = LOOT_TABLE.roll("ruins_demon", rng)
	var found_gold := false
	var found_shard := false
	for drop in drops:
		if drop.has("gold") and int(drop["gold"]) >= 5:
			found_gold = true
		if String(drop.get("item_id", "")) == "ruin_shard":
			found_shard = true
	if not found_gold or not found_shard:
		failures.append("Demonio das Ruinas nao gerou seu loot garantido")

	var shade_drops := LOOT_TABLE.roll("spring_shade", rng)
	var shade_has_gold := false
	for drop in shade_drops:
		if drop.has("gold"):
			shade_has_gold = true
	if not shade_has_gold:
		failures.append("Sombra da Fonte deveria gerar ouro")

func _validate_player_knight(player: Node) -> void:
	_validate_visual_adapter(player, "jogador")
	var visual := player.get_node_or_null("Visual")
	if visual == null:
		failures.append("Cavaleiro nao possui visual procedural")
		return
	for child_path in ["Cape", "Helmet", "LeftArmPivot/Shield", "RightArmPivot/SwordBlade"]:
		if visual.get_node_or_null(child_path) == null:
			failures.append("Cavaleiro sem componente visual: %s" % child_path)
	for method in ["play_attack", "play_death", "reset_state"]:
		if not visual.has_method(method):
			failures.append("Cavaleiro nao expoe animacao semantica: %s" % method)

func _validate_visual_adapter(entity: Node, entity_label: String) -> void:
	var adapter := entity.get_node_or_null("VisualAdapter")
	if adapter == null:
		failures.append("%s nao possui VisualAdapter" % entity_label)
		return

	if adapter.has_method("is_using_fallback") and adapter.is_using_fallback():
		var fallback := entity.get_node_or_null("Visual") as Node3D
		if fallback == null or not fallback.visible:
			failures.append("%s deveria exibir fallback visual estavel" % entity_label)
		else:
			print("ART FALLBACK OK %s" % entity_label)
		return

	if not adapter.has_method("has_loaded_model") or not adapter.has_loaded_model():
		failures.append("%s nao carregou o modelo 3D importado" % entity_label)
		return

	if not adapter.has_method("get_animation_names"):
		failures.append("%s nao expoe lista de animacoes" % entity_label)
		return

	var animations: PackedStringArray = adapter.get_animation_names()
	if animations.is_empty():
		failures.append("%s carregou sem animacoes" % entity_label)
	else:
		print("ART OK %s: %s" % [entity_label, ", ".join(animations)])

func _test_story_progression(player: Node, inventory: Node, quest_manager: Node, enemies: Array[Node], gate: Node, return_gate: Node) -> void:
	inventory.clear()
	var initial_position: Vector3 = player.global_position
	if gate.has_method("is_unlocked") and gate.is_unlocked():
		failures.append("Passagem iniciou desbloqueada antes da missao")
	if quest_manager.get_npc_marker("eliabe") != "!":
		failures.append("Eliabe deveria iniciar com marcador de nova missao")

	gate.interact(player)
	if player.global_position.distance_to(initial_position) > 0.05:
		failures.append("Passagem moveu o jogador antes da missao ser concluida")

	quest_manager.interact_with_npc("eliabe")
	if quest_manager.quest_state != 1 or quest_manager.get_current_quest_id() != "clear_path":
		failures.append("Primeira missao nao iniciou corretamente")

	var first_region_enemies: Array[Node] = []
	var spring_shades: Array[Node] = []
	for enemy in enemies:
		if String(enemy.enemy_kind) == "spring_shade":
			spring_shades.append(enemy)
		else:
			first_region_enemies.append(enemy)

	for enemy in first_region_enemies:
		enemy.defeated.emit(enemy.enemy_kind)

	if quest_manager.progress != 3 or quest_manager.quest_state != 2:
		failures.append("Limpe o Caminho nao chegou ao estado de entrega")
	if quest_manager.get_npc_marker("eliabe") != "?":
		failures.append("Eliabe deveria mostrar marcador de entrega")

	quest_manager.interact_with_npc("eliabe")
	if not quest_manager.is_quest_completed("clear_path"):
		failures.append("Limpe o Caminho nao foi registrada como concluida")
	if quest_manager.get_current_quest_id() != "spring_shadows" or quest_manager.quest_state != 0:
		failures.append("Cadeia nao avancou para A Fonte Profanada")
	if gate.has_method("is_unlocked") and not gate.is_unlocked():
		failures.append("Passagem nao desbloqueou apos a primeira missao")
	if quest_manager.get_npc_marker("miriam") != "!":
		failures.append("Miriam deveria receber marcador da segunda missao")

	gate.interact(player)
	var valley_spawn := Vector3(120.0, 1.15, 22.0)
	if player.global_position.distance_to(valley_spawn) > 0.10:
		failures.append("Jogador nao chegou ao Vale das Fontes")

	quest_manager.interact_with_npc("miriam")
	if quest_manager.quest_state != 1:
		failures.append("A Fonte Profanada nao iniciou")
	for shade in spring_shades:
		shade.defeated.emit(shade.enemy_kind)
	if quest_manager.progress != 2 or quest_manager.quest_state != 2:
		failures.append("Sombras da Fonte nao completaram a segunda missao")
	quest_manager.interact_with_npc("miriam")
	if not quest_manager.is_quest_completed("spring_shadows"):
		failures.append("A Fonte Profanada nao foi concluida")
	if quest_manager.get_current_quest_id() != "watch_weapons":
		failures.append("Cadeia nao avancou para Armas para a Vigilia")
	if quest_manager.get_npc_marker("benaya") != "!":
		failures.append("Benaya deveria receber marcador da terceira missao")

	return_gate.interact(player)
	var ruins_return := Vector3(0.0, 1.15, -34.0)
	if player.global_position.distance_to(ruins_return) > 0.10:
		failures.append("Passagem de retorno nao levou o jogador as Ruinas Antigas")

	inventory.add_item("bone_fragment", 2)
	inventory.add_item("ruin_shard", 1)
	quest_manager.interact_with_npc("benaya")
	if quest_manager.quest_state != 2:
		failures.append("Missao de Benaya deveria ficar pronta com materiais existentes")
	quest_manager.interact_with_npc("benaya")
	if not quest_manager.is_quest_completed("watch_weapons"):
		failures.append("Armas para a Vigilia nao foi concluida")
	if quest_manager.quest_state != 3 or quest_manager.get_current_quest_id() != "":
		failures.append("Cadeia de tres missoes nao finalizou")
	if inventory.count_item("bone_fragment") != 0 or inventory.count_item("ruin_shard") != 0:
		failures.append("Materiais da missao de Benaya nao foram consumidos")
	if inventory.gold < 33:
		failures.append("Recompensas de ouro da cadeia nao foram aplicadas")

func _check_resource(path: String) -> void:
	if load(path) == null:
		failures.append("Falha ao carregar: %s" % path)

func _finish() -> void:
	if failures.is_empty():
		print("SMOKE TEST OK: cavaleiro, 3 NPCs, cadeia de 3 missoes, arte, regioes, inventario e loot validados.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
