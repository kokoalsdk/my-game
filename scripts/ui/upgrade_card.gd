class_name UpgradeCard
extends Button

## 레벨업 시 표시되는 단일 스킬/패시브 선택 카드

signal selected(data: Resource)

@onready var name_label: Label = $MarginContainer/VBoxContainer/Header/NameLabel
@onready var tag_label: Label = $MarginContainer/VBoxContainer/Header/TagPanel/TagLabel
@onready var tag_panel: PanelContainer = $MarginContainer/VBoxContainer/Header/TagPanel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel
@onready var next_level_label: Label = $MarginContainer/VBoxContainer/NextLevelLabel

var upgrade_data: Resource = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_on_pressed)

func setup(data: Resource, current_level: int) -> void:
	_ensure_nodes()
	upgrade_data = data
	
	if data is WeaponData:
		var w = data as WeaponData
		if name_label:
			name_label.text = w.weapon_name
		if desc_label:
			desc_label.text = w.description
		if current_level == 0:
			if tag_label:
				tag_label.text = "신규!"
			if next_level_label:
				next_level_label.text = "★ 새로운 무기 장착"
		else:
			if tag_label:
				tag_label.text = "Lv. %d" % (current_level + 1)
			if next_level_label:
				next_level_label.text = "▶ " + w.get_upgrade_description(current_level + 1)
	elif data is PassiveData:
		var p = data as PassiveData
		if name_label:
			name_label.text = p.passive_name
		if desc_label:
			desc_label.text = p.description
		if current_level == 0:
			if tag_label:
				tag_label.text = "신규!"
			if next_level_label:
				next_level_label.text = "★ 새로운 패시브 장착"
		else:
			if tag_label:
				tag_label.text = "Lv. %d" % (current_level + 1)
			if next_level_label:
				next_level_label.text = "▶ " + p.get_upgrade_description(current_level + 1)

func _ensure_nodes() -> void:
	if not name_label:
		name_label = find_child("NameLabel", true, false) as Label
	if not tag_label:
		tag_label = find_child("TagLabel", true, false) as Label
	if not tag_panel:
		tag_panel = find_child("TagPanel", true, false) as PanelContainer
	if not desc_label:
		desc_label = find_child("DescLabel", true, false) as Label
	if not next_level_label:
		next_level_label = find_child("NextLevelLabel", true, false) as Label

func _on_pressed() -> void:
	if upgrade_data:
		selected.emit(upgrade_data)
