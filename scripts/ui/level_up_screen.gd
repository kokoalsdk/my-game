class_name LevelUpScreen
extends Control

## 레벨업 시 3~4개의 무작위 선택 카드를 제시하고 일시정지 및 장비 적용을 관리하는 화면

@export var card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

@export_group("아이템 풀")
@export var all_weapons: Array[WeaponData] = [
	preload("res://resources/weapons/magic_wand.tres"),
	preload("res://resources/weapons/orbit_orb.tres"),
	preload("res://resources/weapons/lightning_ring.tres"),
	preload("res://resources/weapons/garlic_aura.tres")
]

@export var all_passives: Array[PassiveData] = [
	preload("res://resources/passives/might.tres"),
	preload("res://resources/passives/speed.tres"),
	preload("res://resources/passives/cooldown.tres"),
	preload("res://resources/passives/magnet.tres")
]

@onready var cards_container: HBoxContainer = $CenterContainer/VBoxContainer/CardsContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

var player: Player = null
var level_up_queue: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func queue_level_up(p_player: Player) -> void:
	player = p_player
	if visible:
		# 이미 열려있다면 큐에 누적
		level_up_queue += 1
	else:
		show_selection()

func show_selection() -> void:
	if not is_instance_valid(player) or not player.equipment_manager:
		return
	
	# 기존 카드 정리
	for child in cards_container.get_children():
		child.queue_free()
	
	var em = player.equipment_manager
	var candidates: Array[Resource] = em.get_available_upgrades(all_weapons, all_passives)
	
	# 후보 목록 무작위 셔플
	candidates.shuffle()
	
	# 최대 3~4개 선택
	var pick_count = mini(3, candidates.size())
	
	if pick_count == 0:
		# 모든 스킬 만렙 시 골드 회복 등 대체 보상 처리 후 닫기
		_close_and_resume()
		return
	
	for i in range(pick_count):
		var res = candidates[i]
		var card = card_scene.instantiate() as UpgradeCard
		cards_container.add_child(card)
		
		# 현재 레벨 확인
		var cur_level = 0
		if res is WeaponData and em.equipped_weapons.has((res as WeaponData).id):
			cur_level = em.equipped_weapons[(res as WeaponData).id].level
		elif res is PassiveData and em.equipped_passives.has((res as PassiveData).id):
			cur_level = em.equipped_passives[(res as PassiveData).id].level
		
		card.setup(res, cur_level)
		card.selected.connect(_on_card_selected)
		
		# 카드 팝업 등장 애니메이션
		card.scale = Vector2(0.8, 0.8)
		var pop_tween = create_tween().set_parallel(true)
		pop_tween.tween_property(card, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	visible = true
	get_tree().paused = true

func _on_card_selected(chosen: Resource) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("ui_click")
	
	if not is_instance_valid(player) or not player.equipment_manager:
		_close_and_resume()
		return
	
	var em = player.equipment_manager
	if chosen is WeaponData:
		em.equip_or_upgrade_weapon(chosen as WeaponData)
	elif chosen is PassiveData:
		em.equip_or_upgrade_passive(chosen as PassiveData)
	
	# 큐에 대기 중인 레벨업이 더 있다면 다음 선택창 표시
	if level_up_queue > 0:
		level_up_queue -= 1
		show_selection()
	else:
		_close_and_resume()

func _close_and_resume() -> void:
	visible = false
	get_tree().paused = false
