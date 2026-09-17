class_name ShopUI
extends Control

## 영구 강화 상점 메인 UI 스크립트

signal closed

@export var slot_scene: PackedScene = preload("res://scenes/ui/shop_item_slot.tscn")

@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderHBox/GoldLabel
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemsVBox
@onready var refund_button: Button = $Panel/MarginContainer/VBoxContainer/FooterHBox/RefundButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/FooterHBox/CloseButton

func _ready() -> void:
	refund_button.pressed.connect(_on_refund_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_signal("gold_changed"):
		save_mgr.gold_changed.connect(func(total, _d): _update_gold(total))
	
	_populate_items()
	_update_gold()

## 상점 열기
func open() -> void:
	visible = true
	_update_gold()
	_refresh_all()

## 상점 닫기
func close() -> void:
	visible = false
	closed.emit()

func _populate_items() -> void:
	# 기존 슬롯 제거
	for child in items_container.get_children():
		child.queue_free()
	
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr:
		return
	
	# SaveManager에 등록된 5종 업그레이드 순회 등록
	for upgrade_id in save_mgr.UPGRADE_CONFIGS.keys():
		var slot = slot_scene.instantiate() as ShopItemSlot
		items_container.add_child(slot)
		slot.setup(upgrade_id)

func _refresh_all() -> void:
	for slot in items_container.get_children():
		if slot is ShopItemSlot:
			slot.refresh()

func _update_gold(total: int = -1) -> void:
	var cur_gold = total
	if cur_gold < 0:
		var save_mgr = get_node_or_null("/root/SaveManager")
		cur_gold = save_mgr.get_gold() if save_mgr else 0
	
	if gold_label:
		gold_label.text = "🪙 보유 골드: %s G" % _format_number(cur_gold)

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

func _on_refund_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("refund_all_upgrades"):
		save_mgr.refund_all_upgrades()
		_update_gold()
		_refresh_all()

func _on_close_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	close()
