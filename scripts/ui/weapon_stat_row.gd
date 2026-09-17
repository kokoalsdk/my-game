class_name WeaponStatRow
extends PanelContainer

## 정산 화면에서 개별 무기의 데미지 통계를 표시하는 행 스크립트

@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel
@onready var name_label: Label = $MarginContainer/HBoxContainer/NameVBox/NameLabel
@onready var level_label: Label = $MarginContainer/HBoxContainer/NameVBox/LevelLabel
@onready var damage_label: Label = $MarginContainer/HBoxContainer/DamageVBox/DamageLabel
@onready var dps_label: Label = $MarginContainer/HBoxContainer/DamageVBox/DPSLabel
@onready var percent_bar: ProgressBar = $MarginContainer/HBoxContainer/PercentVBox/ProgressBar
@onready var percent_label: Label = $MarginContainer/HBoxContainer/PercentVBox/PercentLabel

const WEAPON_EMOJIS: Dictionary = {
	"magic_wand": "🪄",
	"orbit_orb": "📖",
	"lightning_ring": "⚡",
	"garlic_aura": "🧄",
	"holy_wand": "✨",
	"unholy_vespers": "🩸",
	"thunder_loop": "🌩️",
	"soul_eater": "🖤"
}

func setup(stat_data: Dictionary) -> void:
	_ensure_nodes()
	var w_id = stat_data.get("id", "")
	var w_name = stat_data.get("name", "무기")
	var w_lvl = stat_data.get("level", 1)
	var dmg = stat_data.get("damage", 0.0)
	var dps = stat_data.get("dps", 0.0)
	var pct = stat_data.get("damage_percent", 0.0)
	
	if icon_label:
		icon_label.text = WEAPON_EMOJIS.get(w_id, "⚔️")
	if name_label:
		name_label.text = w_name
	if level_label:
		level_label.text = "Lv. %d" % w_lvl
	if damage_label:
		damage_label.text = _format_number(int(round(dmg)))
	if dps_label:
		dps_label.text = "%.1f /s" % dps
	if percent_bar:
		percent_bar.value = pct
	if percent_label:
		percent_label.text = "%.1f%%" % pct

func _ensure_nodes() -> void:
	if not icon_label:
		icon_label = find_child("IconLabel", true, false) as Label
	if not name_label:
		name_label = find_child("NameLabel", true, false) as Label
	if not level_label:
		level_label = find_child("LevelLabel", true, false) as Label
	if not damage_label:
		damage_label = find_child("DamageLabel", true, false) as Label
	if not dps_label:
		dps_label = find_child("DPSLabel", true, false) as Label
	if not percent_bar:
		percent_bar = find_child("ProgressBar", true, false) as ProgressBar
	if not percent_label:
		percent_label = find_child("PercentLabel", true, false) as Label

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
