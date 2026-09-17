class_name WeaponBase
extends Node2D

## 모든 무기의 베이스 클래스
## 쿨다운 타이머, 적 타겟팅 검색, 플레이어 스탯 연동을 담당합니다.

@export_group("기본 스탯")
@export var weapon_name: String = "Weapon"
@export var level: int = 1
@export var max_level: int = 8
@export var base_damage: float = 12.0
@export var base_cooldown: float = 1.2
@export var base_speed: float = 450.0
@export var base_pierce: int = 1
@export var base_projectile_count: int = 1
@export var max_range: float = 700.0
@export var knockback: float = 100.0

@export_group("리소스 연결")
@export var projectile_scene: PackedScene

var player: Player = null
var cooldown_timer: Timer
var total_damage: float = 0.0

## 피해량 누적
func record_damage(amount: float) -> void:
	if amount > 0.0:
		total_damage += amount

## 투사체/공격 판정에 전달할 소스 노드 (기본: 플레이어, 유효하지 않으면 무기 노드 자체)
func get_source_node() -> Node:
	if is_instance_valid(player):
		return player
	return self

func _ready() -> void:
	# 부모 노드가 플레이어이거나 부모의 부모가 플레이어인 경우 탐색
	if get_parent() is Player:
		player = get_parent() as Player
	elif get_parent() and get_parent().get_parent() is Player:
		player = get_parent().get_parent() as Player
	
	_setup_timer()

func _setup_timer() -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = false
	cooldown_timer.autostart = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)
	update_cooldown()

func update_cooldown() -> void:
	var cd = base_cooldown
	if player:
		cd *= player.cooldown_multiplier
	cooldown_timer.wait_time = max(0.08, cd)

func _on_cooldown_timeout() -> void:
	attack()

## 파생 클래스에서 구현하는 공격 함수
func attack() -> void:
	pass

## 사운드 효과 유틸리티
func play_shoot_sound(pitch_jitter: float = 0.08, vol_offset: float = -2.0) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("shoot", pitch_jitter, vol_offset)

## 무기 레벨업 처리 (파생 클래스에서 오버라이드 가능)
func upgrade_to(new_level: int) -> void:
	level = new_level
	update_cooldown()

## 가장 가까운 살아있는 몬스터 검색 ("enemy" 그룹 기준)
func get_closest_enemy(from_pos: Vector2, search_range: float = -1.0) -> Node2D:
	var limit_range: float = max_range if search_range < 0.0 else search_range
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest: Node2D = null
	var min_dist_sq: float = limit_range * limit_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		
		# 체력 컴포넌트가 있고 사망 상태인지 체크
		if enemy.has_node("HealthComponent"):
			var hp = enemy.get_node("HealthComponent") as HealthComponent
			if hp and hp.is_dead:
				continue
		
		var d_sq: float = from_pos.distance_squared_to((enemy as Node2D).global_position)
		if d_sq < min_dist_sq:
			min_dist_sq = d_sq
			closest = enemy as Node2D
	
	return closest
