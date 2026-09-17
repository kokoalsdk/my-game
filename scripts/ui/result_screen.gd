class_name ResultScreen
extends Control

## 게임오버 및 스테이지 클리어 종합 정산 결과 창

signal retry_requested
signal main_menu_requested

@export var stat_row_scene: PackedScene = preload("res://scenes/ui/weapon_stat_row.tscn")

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderVBox/TitleLabel
@onready var subtitle_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderVBox/SubtitleLabel

@onready var time_val_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryGrid/TimeBox/VBox/ValLabel
@onready var kill_val_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryGrid/KillBox/VBox/ValLabel
@onready var level_val_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryGrid/LevelBox/VBox/ValLabel
@onready var gold_val_label: Label = $Panel/MarginContainer/VBoxContainer/SummaryGrid/GoldBox/VBox/ValLabel

@onready var weapons_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/WeaponSection/ScrollContainer/WeaponsVBox

@onready var retry_button: Button = $Panel/MarginContainer/VBoxContainer/FooterHBox/RetryButton
@onready var main_menu_button: Button = $Panel/MarginContainer/VBoxContainer/FooterHBox/MainMenuButton

func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

## 결과 화면 표출
func show_results(player: Player, survival_time: float, is_clear: bool = false) -> void:
	# 사운드 제어: BGM 중단 및 결과 SFX 재생
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.stop_bgm(0.2)
		if is_clear:
			sm.play_sfx("stage_clear")
		else:
			sm.play_sfx("game_over")
	
	_ensure_nodes()
	
	# 1. 헤더 설정
	if title_label:
		if is_clear:
			title_label.text = "STAGE CLEAR"
			title_label.modulate = Color(1.0, 0.88, 0.35, 1.0) # 황금빛
		else:
			title_label.text = "GAME OVER"
			title_label.modulate = Color(1.0, 0.3, 0.3, 1.0) # 핏빛 적색
	
	if subtitle_label:
		if is_clear:
			subtitle_label.text = "모든 시련을 극복하고 밤의 군주를 처단했습니다!"
		else:
			subtitle_label.text = "어둠에 굴복하여 스러졌습니다..."
	
	# 2. 런 요약 데이터 추출
	var minutes: int = int(survival_time / 60.0)
	var seconds = int(survival_time) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	var kills = player.kill_count if is_instance_valid(player) else 0
	var lvl = player.current_level if is_instance_valid(player) else 1
	var run_gold = player.current_gold if is_instance_valid(player) else 0
	
	# 3. SaveManager 저장 및 총 골드 반영
	var total_bank_gold = run_gold
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("record_run_results"):
		save_mgr.record_run_results(survival_time, kills, run_gold, lvl)
		total_bank_gold = save_mgr.get_gold()
	
	# 요약 텍스트 갱신
	if time_val_label:
		time_val_label.text = time_str
	if kill_val_label:
		kill_val_label.text = "%s 마리" % _format_number(kills)
	if level_val_label:
		level_val_label.text = "LV. %d" % lvl
	if gold_val_label:
		gold_val_label.text = "+%s G (보유: %s G)" % [_format_number(run_gold), _format_number(total_bank_gold)]
	
	# 4. 무기별 데미지 통계 리스트 생성
	_populate_weapon_stats(player, survival_time)
	
	# 5. 창 표시 및 게임 일시정지
	visible = true
	get_tree().paused = true

func _populate_weapon_stats(player: Player, survival_time: float) -> void:
	for child in weapons_container.get_children():
		child.queue_free()
	
	if not is_instance_valid(player) or not player.equipment_manager:
		return
	
	var stat_list = player.equipment_manager.get_weapon_stats_summary(survival_time)
	for stat_data in stat_list:
		var row = stat_row_scene.instantiate() as WeaponStatRow
		weapons_container.add_child(row)
		row.setup(stat_data)

func _format_number(num: int) -> String:
	var s = str(num)
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return res

func _on_retry_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.clear_all()
	get_tree().paused = false
	retry_requested.emit()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.clear_all()
	get_tree().paused = false
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _ensure_nodes() -> void:
	if not title_label:
		title_label = find_child("TitleLabel", true, false) as Label
	if not subtitle_label:
		subtitle_label = find_child("SubtitleLabel", true, false) as Label
	if not time_val_label:
		var tb = find_child("TimeBox", true, false)
		time_val_label = (tb.find_child("ValLabel", true, false) as Label) if tb else null
	if not kill_val_label:
		var kb = find_child("KillBox", true, false)
		kill_val_label = (kb.find_child("ValLabel", true, false) as Label) if kb else null
	if not level_val_label:
		var lb = find_child("LevelBox", true, false)
		level_val_label = (lb.find_child("ValLabel", true, false) as Label) if lb else null
	if not gold_val_label:
		var gb = find_child("GoldBox", true, false)
		gold_val_label = (gb.find_child("ValLabel", true, false) as Label) if gb else null
	if not weapons_container:
		weapons_container = find_child("WeaponsVBox", true, false) as VBoxContainer
	if not retry_button:
		retry_button = find_child("RetryButton", true, false) as Button
	if not main_menu_button:
		main_menu_button = find_child("MainMenuButton", true, false) as Button
