class_name EnemyBoss
extends EnemyBase

## 엘리트 / 보스 몬스터
## 대형 체력, 넉백 저항, 전용 체력 게이지 및 사망 시 보물상자 드랍

@export var chest_scene: PackedScene = preload("res://scenes/pickups/chest.tscn")
@export var boss_name: String = "거대 골렘 (BOSS)"

@onready var health_bar: ProgressBar = $BossUI/HealthBar
@onready var boss_name_label: Label = $BossUI/NameLabel

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = max_health
		health_component.health_changed.connect(_on_boss_health_changed)
	if is_instance_valid(boss_name_label):
		boss_name_label.text = boss_name

func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_hp
		health_bar.value = current_hp

## 보스 피격 시 넉백 저항 (80% 감쇄)
func _on_hit_received(hitbox: HitboxComponent) -> void:
	super._on_hit_received(hitbox)
	knockback_velocity *= 0.2

## 사망 시 경험치 보석 외에 확정 보물상자 드랍
func _drop_loot() -> void:
	super._drop_loot()
	
	if not chest_scene:
		return
	
	var chest = chest_scene.instantiate() as Node2D
	if not chest:
		return
	
	chest.global_position = global_position
	var root = get_tree().current_scene
	if root:
		root.add_child(chest)
	else:
		get_parent().add_child(chest)
