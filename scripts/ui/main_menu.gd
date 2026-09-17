class_name MainMenu
extends Control

## 메인 타이틀 및 로비 화면 스크립트

@onready var start_button: Button = $CenterContainer/MenuVBox/ButtonsVBox/StartButton
@onready var shop_button: Button = $CenterContainer/MenuVBox/ButtonsVBox/ShopButton
@onready var quit_button: Button = $CenterContainer/MenuVBox/ButtonsVBox/QuitButton

@onready var stats_label: Label = $CenterContainer/MenuVBox/StatsPanel/MarginContainer/StatsLabel
@onready var gold_label: Label = $TopRightContainer/GoldLabel
@onready var shop_ui: ShopUI = $ShopUI

func _ready() -> void:
	# 일시정지 상태가 남아있을 경우 해제
	get_tree().paused = false
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_bgm("menu")
	
	start_button.pressed.connect(_on_start_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	shop_ui.closed.connect(_on_shop_closed)
	shop_ui.visible = false
	
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr:
		if save_mgr.has_signal("gold_changed"):
			save_mgr.gold_changed.connect(func(_g, _d): _refresh_stats())
		if save_mgr.has_signal("data_loaded"):
			save_mgr.data_loaded.connect(_refresh_stats)
	
	_refresh_stats()

func _refresh_stats() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	var gold = 0
	var best_time = 0.0
	var best_lvl = 1
	var total_kills = 0
	var total_games = 0
	
	if save_mgr:
		gold = save_mgr.get_gold()
		var stats: Dictionary = save_mgr.get_stats()
		best_time = stats.get("best_survival_time", 0.0)
		best_lvl = stats.get("best_level", 1)
		total_kills = stats.get("total_kills", 0)
		total_games = stats.get("total_games", 0)
	
	var minutes: int = int(best_time / 60.0)
	var seconds = int(best_time) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	
	if stats_label:
		stats_label.text = "🏆 최고 생존 시간 : %s  |  최고 레벨 : LV. %d\n💀 누적 처치 수 : %s 마리  |  총 플레이 : %d 회" % [
			time_str, best_lvl, _format_number(total_kills), total_games
		]
	
	if gold_label:
		gold_label.text = "🪙 %s G" % _format_number(gold)

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

func _on_start_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_shop_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	if shop_ui:
		shop_ui.open()

func _on_shop_closed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	_refresh_stats()

func _on_quit_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	get_tree().quit()
