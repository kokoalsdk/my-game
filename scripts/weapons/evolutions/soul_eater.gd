class_name SoulEater
extends WeaponBase

## 영혼 포식자 (진화 무기: 마늘 오라 + 자석)
## 거대한 암흑 핏빛 오라를 형성하여 적을 학살하고, 적중 시 플레이어의 체력을 지속 흡수하여 치유합니다.

@export var aura_radius: float = 110.0
@onready var hitbox_area: Area2D = $HitboxArea
@onready var collision_shape: CollisionShape2D = $HitboxArea/CollisionShape2D

var _pulse_tween: Tween
var _pulse_alpha: float = 0.35
var _hit_counter: int = 0

func _ready() -> void:
	base_damage = 22.0
	base_cooldown = 0.45
	knockback = 160.0
	super._ready()
	_update_shape()

func _process(_delta: float) -> void:
	queue_redraw()

func _update_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = aura_radius

func attack() -> void:
	play_shoot_sound(0.1, -4.0)
	var final_damage = base_damage * (player.damage_multiplier if player else 1.0)
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	_pulse_alpha = 0.75
	_pulse_tween.tween_property(self, "_pulse_alpha", 0.3, 0.22)
	
	var enemies = hitbox_area.get_overlapping_bodies()
	var damaged_count = 0
	
	for body in enemies:
		if body is EnemyBase:
			var enemy = body as EnemyBase
			if enemy.health_component and not enemy.health_component.is_dead:
				enemy.health_component.damage(final_damage)
				record_damage(final_damage)
				damaged_count += 1
				
				# 넉백 적용
				var dir = (enemy.global_position - global_position).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.RIGHT
				enemy.knockback_velocity = dir * knockback # WeaponBase에서 상속받은 넉백 수치
	
	# 흡혈 치유 메커니즘 (적에게 8회 이상 타격 누적 시 플레이어 체력 +1 회복)
	if damaged_count > 0 and is_instance_valid(player) and player.health_component:
		_hit_counter += damaged_count
		if _hit_counter >= 8:
			_hit_counter = 0
			player.health_component.heal(1.0)

func _draw() -> void:
	# 핏빛과 암자색이 뒤섞인 영혼 흡수 장판 연출
	draw_arc(Vector2.ZERO, aura_radius, 0, TAU, 64, Color(0.9, 0.15, 0.35, _pulse_alpha + 0.2), 2.5)
	draw_circle(Vector2.ZERO, aura_radius, Color(0.6, 0.05, 0.25, _pulse_alpha * 0.3))
	# 내부 보랏빛 코어
	draw_circle(Vector2.ZERO, aura_radius * 0.5, Color(0.4, 0.0, 0.5, _pulse_alpha * 0.2))
