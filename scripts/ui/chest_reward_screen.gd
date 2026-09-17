class_name ChestRewardScreen
extends Control

## 보물상자 개봉 시 슬롯머신/룰렛 연출과 함께 장비 무료 레벨업(1~3개) 및 골드를 지급하는 화면

@onready var chest_box: Control = $CenterContainer/VBoxContainer/ChestVisual
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var jackpot_label: Label = $CenterContainer/VBoxContainer/JackpotLabel
@onready var rewards_container: VBoxContainer = $CenterContainer/VBoxContainer/RewardsContainer
@onready var gold_label: Label = $CenterContainer/VBoxContainer/GoldLabel
@onready var confirm_button: Button = $CenterContainer/VBoxContainer/ConfirmButton

var player: Player = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

## 보물상자 개봉 연출 시작
func open_chest(p_player: Player) -> void:
	player = p_player
	if not is_instance_valid(player) or not player.equipment_manager:
		return
	
	visible = true
	get_tree().paused = true
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("chest")
	
	_ensure_nodes()
	
	# 초기화
	if rewards_container:
		for child in rewards_container.get_children():
			child.queue_free()
		rewards_container.visible = false
	
	if confirm_button:
		confirm_button.visible = false
	if gold_label:
		gold_label.visible = false
	if jackpot_label:
		jackpot_label.text = ""
	if title_label:
		title_label.text = "보물상자를 개봉하는 중..."
	
	# 1~3개 업그레이드 수량 확률 결정 (70%: 1개, 25%: 3개, 5%: 5개 잭팟)
	var roll = randf()
	var upgrade_target = 1
	if roll < 0.05:
		upgrade_target = 5
		if jackpot_label:
			jackpot_label.text = "★ SUPER JACKPOT! (5개 장비 대량 강화) ★"
	elif roll < 0.30:
		upgrade_target = 3
		if jackpot_label:
			jackpot_label.text = "★ JACKPOT! (3개 장비 동시 강화) ★"
	else:
		if jackpot_label:
			jackpot_label.text = "보물상자 발견!"
	
	# 상자 흔들림 연출
	_play_chest_shake_animation(upgrade_target)

func _play_chest_shake_animation(upgrade_target: int) -> void:
	chest_box.scale = Vector2.ONE
	var shake_tween = create_tween()
	for i in range(8):
		var offset = 12.0 if (i % 2 == 0) else -12.0
		shake_tween.tween_property(chest_box, "rotation_degrees", offset, 0.06)
	shake_tween.tween_property(chest_box, "rotation_degrees", 0.0, 0.05)
	shake_tween.tween_callback(func(): _reveal_rewards(upgrade_target))

func _reveal_rewards(upgrade_target: int) -> void:
	var em = player.equipment_manager
	var evolvables = em.check_evolvable_weapons()
	var gold_earned: int = 0
	
	# 진화 조건 충족 시 진화 우선 처리
	if evolvables.size() > 0:
		if title_label:
			title_label.text = "★ WEAPON EVOLUTION! ★"
		if jackpot_label:
			jackpot_label.text = "무기가 궁극의 형태로 각성했습니다!"
		
		var base_weapon = evolvables[0]
		var evo_weapon = em.evolve_weapon(base_weapon)
		
		var card_panel = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		
		var name_lbl = Label.new()
		name_lbl.text = "⚡ %s  ▶  %s ⚡" % [base_weapon.weapon_name, evo_weapon.weapon_name]
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		name_lbl.add_theme_font_size_override("font_size", 18)
		
		var desc_lbl = Label.new()
		desc_lbl.text = evo_weapon.description
		desc_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		vbox.add_child(name_lbl)
		vbox.add_child(desc_lbl)
		margin.add_child(vbox)
		card_panel.add_child(margin)
		if rewards_container:
			rewards_container.add_child(card_panel)
		
		gold_earned = 300 + randi_range(50, 150)
		player.add_gold(gold_earned)
		if gold_label:
			gold_label.text = "+ %d GOLD 획득!" % gold_earned
			gold_label.visible = true
		
		if rewards_container:
			rewards_container.visible = true
			rewards_container.scale = Vector2(0.8, 0.8)
			var tween = create_tween().set_parallel(true)
			tween.tween_property(rewards_container, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if confirm_button:
			confirm_button.visible = true
		return
	
	if title_label:
		title_label.text = "TREASURE UNLOCKED!"
	var candidates: Array[Dictionary] = []
	
	# 현재 장착 중인 무기 중 만렙이 아닌 항목
	for id in em.equipped_weapons.keys():
		var info = em.equipped_weapons[id]
		var data = info.data as WeaponData
		if info.level < data.max_level:
			candidates.append({"type": "weapon", "data": data, "level": info.level})
	
	# 현재 장착 중인 패시브 중 만렙이 아닌 항목
	for id in em.equipped_passives.keys():
		var info = em.equipped_passives[id]
		var data = info.data as PassiveData
		if info.level < data.max_level:
			candidates.append({"type": "passive", "data": data, "level": info.level})
	
	candidates.shuffle()
	var actual_upgrades = mini(upgrade_target, candidates.size())
	
	if actual_upgrades == 0:
		# 모든 장비가 이미 만렙인 경우
		var empty_lbl = Label.new()
		empty_lbl.text = "모든 보유 장비가 이미 최고 레벨입니다!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_container.add_child(empty_lbl)
	else:
		for i in range(actual_upgrades):
			var item = candidates[i]
			var card_panel = PanelContainer.new()
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 16)
			margin.add_theme_constant_override("margin_right", 16)
			margin.add_theme_constant_override("margin_top", 10)
			margin.add_theme_constant_override("margin_bottom", 10)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 16)
			
			var name_lbl = Label.new()
			var next_lvl = item.level + 1
			var desc_text = ""
			
			if item.type == "weapon":
				var w = item.data as WeaponData
				name_lbl.text = "%s  ▶  Lv. %d" % [w.weapon_name, next_lvl]
				desc_text = w.get_upgrade_description(next_lvl)
				em.equip_or_upgrade_weapon(w)
			else:
				var p = item.data as PassiveData
				name_lbl.text = "%s  ▶  Lv. %d" % [p.passive_name, next_lvl]
				desc_text = p.get_upgrade_description(next_lvl)
				em.equip_or_upgrade_passive(p)
			
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
			
			var desc_lbl = Label.new()
			desc_lbl.text = desc_text
			desc_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
			
			hbox.add_child(name_lbl)
			hbox.add_child(desc_lbl)
			margin.add_child(hbox)
			card_panel.add_child(margin)
			rewards_container.add_child(card_panel)
	
	# 골드 지급
	gold_earned = (100 * (actual_upgrades if actual_upgrades > 0 else 2)) + randi_range(20, 80)
	player.add_gold(gold_earned)
	if gold_label:
		gold_label.text = "+ %d GOLD 획득!" % gold_earned
		gold_label.visible = true
	
	# UI 노출 및 팝업 트윈
	if rewards_container:
		rewards_container.visible = true
		rewards_container.scale = Vector2(0.8, 0.8)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(rewards_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if confirm_button:
		confirm_button.visible = true
	if gold_label:
		var gold_tween = create_tween()
		gold_tween.tween_property(gold_label, "scale", Vector2(1.2, 1.2), 0.15)
		gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.1)

func _on_confirm_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	visible = false
	get_tree().paused = false

func _ensure_nodes() -> void:
	if not chest_box:
		chest_box = find_child("ChestVisual", true, false) as Control
	if not title_label:
		title_label = find_child("TitleLabel", true, false) as Label
	if not jackpot_label:
		jackpot_label = find_child("JackpotLabel", true, false) as Label
	if not rewards_container:
		rewards_container = find_child("RewardsContainer", true, false) as VBoxContainer
	if not gold_label:
		gold_label = find_child("GoldLabel", true, false) as Label
	if not confirm_button:
		confirm_button = find_child("ConfirmButton", true, false) as Button
