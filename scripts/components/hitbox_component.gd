class_name HitboxComponent
extends Area2D

## 공격 판정을 담당하는 Area2D 컴포넌트 (투사체, 무기, 몬스터 접촉 공격 등)

@export var damage: float = 10.0
@export var knockback_force: float = 100.0
@export var is_critical: bool = false

## 공격 주체 노드 (넉백 방향 계산 등에 활용)
var source: Node2D = null
## 피해 통계를 기록할 무기 인스턴스 참조
var weapon: WeaponBase = null

func record_damage(amount: float) -> void:
	if weapon and is_instance_valid(weapon):
		weapon.record_damage(amount)

func _init() -> void:
	monitoring = true
	monitorable = true

## 피격 대상 위치를 기준으로 밀려날 넉백 방향 벡터 계산
func get_knockback_direction(target_position: Vector2) -> Vector2:
	var origin: Vector2 = source.global_position if is_instance_valid(source) else global_position
	var dir: Vector2 = (target_position - origin).normalized()
	return dir if dir != Vector2.ZERO else Vector2.RIGHT
