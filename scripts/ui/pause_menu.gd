class_name PauseMenu
extends Control

## 게임 일시정지 및 설정(볼륨, 재시작, 로비 복귀) UI 컨트롤러

signal resume_requested
signal retry_requested
signal main_menu_requested

@onready var stats_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsPanel/MarginContainer/StatsLabel
@onready var bgm_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeVBox/BGMContainer/BGMSlider
@onready var bgm_val_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeVBox/BGMContainer/ValLabel
@onready var sfx_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeVBox/SFXContainer/SFXSlider
@onready var sfx_val_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/VolumeVBox/SFXContainer/ValLabel

@onready var resume_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsVBox/ResumeButton
@onready var retry_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsVBox/RetryButton
@onready var main_menu_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsVBox/MainMenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_button.pressed.connect(_on_resume_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		close()

## 일시정지 창 열기
func open(player: Player, survival_time: float) -> void:
	_ensure_nodes()
	visible = true
	get_tree().paused = true
	
	# 통계 갱신
	var minutes: int = int(survival_time / 60.0)
	var seconds = int(survival_time) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	var lvl = player.current_level if is_instance_valid(player) else 1
	var kills = player.kill_count if is_instance_valid(player) else 0
	var gold = player.current_gold if is_instance_valid(player) else 0
	
	if stats_label:
		stats_label.text = "⏱️ 생존 시간 : %s  |  ⭐ 레벨 : LV. %d\n💀 처치 수 : %s 마리  |  🪙 획득 골드 : %s G" % [
			time_str, lvl, _format_number(kills), _format_number(gold)
		]
	
	# 사운드 매니저 볼륨 슬라이더 동기화
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		var cur_bgm = sm.get_bgm_volume_linear()
		var cur_sfx = sm.get_sfx_volume_linear()
		if bgm_slider:
			bgm_slider.value = cur_bgm
		if sfx_slider:
			sfx_slider.value = cur_sfx
		_update_volume_labels(cur_bgm, cur_sfx)

## 일시정지 창 닫기
func close() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _update_volume_labels(bgm_val: float, sfx_val: float) -> void:
	if bgm_val_label:
		bgm_val_label.text = "%d%%" % int(round(bgm_val * 100.0))
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % int(round(sfx_val * 100.0))

func _on_bgm_slider_changed(value: float) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.set_bgm_volume_linear(value)
	_update_volume_labels(value, sfx_slider.value)

func _on_sfx_slider_changed(value: float) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.set_sfx_volume_linear(value)
	_update_volume_labels(bgm_slider.value, value)

func _on_resume_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	close()

func _on_retry_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.clear_all()
	
	get_tree().paused = false
	retry_requested.emit()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.clear_all()
	
	get_tree().paused = false
	main_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

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

func _ensure_nodes() -> void:
	if not stats_label:
		stats_label = find_child("StatsLabel", true, false) as Label
	if not bgm_slider:
		bgm_slider = find_child("BGMSlider", true, false) as HSlider
	if not bgm_val_label:
		var bgm_box = find_child("BGMContainer", true, false)
		bgm_val_label = (bgm_box.find_child("ValLabel", true, false) as Label) if bgm_box else null
	if not sfx_slider:
		sfx_slider = find_child("SFXSlider", true, false) as HSlider
	if not sfx_val_label:
		var sfx_box = find_child("SFXContainer", true, false)
		sfx_val_label = (sfx_box.find_child("ValLabel", true, false) as Label) if sfx_box else null
	if not resume_button:
		resume_button = find_child("ResumeButton", true, false) as Button
	if not retry_button:
		retry_button = find_child("RetryButton", true, false) as Button
	if not main_menu_button:
		main_menu_button = find_child("MainMenuButton", true, false) as Button
