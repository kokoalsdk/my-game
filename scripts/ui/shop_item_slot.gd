class_name ShopItemSlot
extends PanelContainer

## 영구 강화 상점의 개별 아이템 슬롯 스크립트

@export var upgrade_id: String = ""

@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel
@onready var name_label: Label = $MarginContainer/HBoxContainer/InfoVBox/HeaderHBox/NameLabel
@onready var desc_label: Label = $MarginContainer/HBoxContainer/InfoVBox/DescLabel
@onready var level_gauge_label: Label = $MarginContainer/HBoxContainer/InfoVBox/HeaderHBox/LevelGaugeLabel
@onready var bonus_label: Label = $MarginContainer/HBoxContainer/InfoVBox/BonusLabel
@onready var buy_button: Button = $MarginContainer/HBoxContainer/BuyButton

const UPGRADE_ICONS: Dictionary = {
	"might": "⚔️",
	"health": "❤️",
	"speed": "👟",
	"magnet": "🧲",
	"exp_gain": "💎"
}

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)
	
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr:
		if save_mgr.has_signal("gold_changed"):
			save_mgr.gold_changed.connect(func(_g, _d): refresh())
		if save_mgr.has_signal("upgrade_purchased"):
			save_mgr.upgrade_purchased.connect(func(_id, _lvl): refresh())
		if save_mgr.has_signal("upgrades_refunded"):
			save_mgr.upgrades_refunded.connect(func(_r): refresh())
	
	if upgrade_id != "":
		refresh()

## 슬롯 초기화
func setup(id: String) -> void:
	upgrade_id = id
	if is_node_ready():
		refresh()

## UI 정보 갱신
func refresh() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if not save_mgr or not save_mgr.UPGRADE_CONFIGS.has(upgrade_id):
		return
	
	var cfg: Dictionary = save_mgr.UPGRADE_CONFIGS[upgrade_id]
	var cur_lvl: int = save_mgr.get_upgrade_level(upgrade_id)
	var max_lvl: int = cfg.get("max_level", 5)
	var cost: int = save_mgr.get_upgrade_cost(upgrade_id)
	var cur_gold: int = save_mgr.get_gold()
	
	_ensure_nodes()
	
	# 아이콘 및 텍스트
	if icon_label:
		icon_label.text = UPGRADE_ICONS.get(upgrade_id, "✨")
	if name_label:
		name_label.text = cfg.get("name", upgrade_id)
	if desc_label:
		desc_label.text = cfg.get("description", "")
	
	# 게이지 바 생성 (예: [ ■ ■ ■ □ □ ] Lv 3/5)
	var gauge_str: String = "[ "
	for i in range(max_lvl):
		if i < cur_lvl:
			gauge_str += "■ "
		else:
			gauge_str += "□ "
	gauge_str += "]  Lv %d / %d" % [cur_lvl, max_lvl]
	if level_gauge_label:
		level_gauge_label.text = gauge_str
	
	# 현재 보너스 표기
	var bonus_val = cur_lvl * cfg.get("bonus_per_level", 0.0)
	var unit_str = cfg.get("unit", "")
	if bonus_label:
		if unit_str == "%":
			bonus_label.text = "현재 효과: +%d%%" % int(round(bonus_val * 100))
		else:
			bonus_label.text = "현재 효과: +%d %s" % [int(round(bonus_val)), unit_str]
	
	# 구매 버튼 상태
	if buy_button:
		if cur_lvl >= max_lvl:
			buy_button.text = "최대 레벨 (MAX)"
			buy_button.disabled = true
		else:
			buy_button.text = "🪙 %d G" % cost
			buy_button.disabled = (cur_gold < cost)

func _ensure_nodes() -> void:
	if not icon_label:
		icon_label = find_child("IconLabel", true, false) as Label
	if not name_label:
		name_label = find_child("NameLabel", true, false) as Label
	if not desc_label:
		desc_label = find_child("DescLabel", true, false) as Label
	if not level_gauge_label:
		level_gauge_label = find_child("LevelGaugeLabel", true, false) as Label
	if not bonus_label:
		bonus_label = find_child("BonusLabel", true, false) as Label
	if not buy_button:
		buy_button = find_child("BuyButton", true, false) as Button

func _on_buy_button_pressed() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("purchase_upgrade"):
		save_mgr.purchase_upgrade(upgrade_id)
