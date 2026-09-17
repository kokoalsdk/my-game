class_name GarlicAura
extends WeaponBase

## 마늘 오라 (Garlic Aura)
## 플레이어 주변에 지속적인 오라 장판을 형성하여 범위 내 모든 적에게 주기적으로 피해를 주고 밀어냅니다.

@export var aura_radius: float = 65.0
@onready var hitbox_area: Area2D = $HitboxArea
@onready var collision_shape: CollisionShape2D = $HitboxArea/CollisionShape2D

var _pulse_tween: Tween
var _pulse_alpha: float = 0.25

func _ready() -> void:
	super._ready()
	_update_shape()

func _process(_delta: float) -> void:
	queue_redraw()

func _update_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = aura_radius

func attack() -> void:
	play_shoot_sound(0.08, -6.0)
	var final_damage = base_damage * (player.damage_multiplier if player else 1.0)
	
	# 펄스 연출 트윈
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	
	_pulse_tween = create_tween()
	_pulse_alpha = 0.6
	_pulse_tween.tween_property(self, "_pulse_alpha", 0.2, 0.2)
	
	# 범위 내 감지된 적들에게 광역 피해 및 넉백 부여
	var overlapping_bodies = hitbox_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is EnemyBase:
			var enemy = body as EnemyBase
			if enemy.health_component and not enemy.health_component.is_dead:
				enemy.health_component.damage(final_damage)
				record_damage(final_damage)
				
				# 넉백 적용
				var dir = (enemy.global_position - global_position).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.RIGHT
				enemy.knockback_velocity = dir * knockback # WeaponBase에서 상속받은 넉백 수치

func _draw() -> void:
	# 은은하게 진동하는 영기(Aura) 렌더링
	draw_arc(Vector2.ZERO, aura_radius, 0, TAU, 48, Color(0.7, 1.0, 0.5, _pulse_alpha + 0.2), 2.0)
	draw_circle(Vector2.ZERO, aura_radius, Color(0.6, 1.0, 0.4, _pulse_alpha * 0.25))

func upgrade_to(new_level: int) -> void:
	level = new_level
	match level:
		2:
			aura_radius += 12.0
			base_damage *= 1.15
		3:
			aura_radius += 12.0
			base_cooldown *= 0.9
		4:
			base_damage *= 1.2
			knockback += 30.0
		5:
			aura_radius += 15.0
		6:
			base_damage *= 1.25
			base_cooldown *= 0.9
		7:
			aura_radius += 15.0
			base_damage *= 1.3
		8:
			base_damage *= 1.35
			knockback += 50.0
	_update_shape()
	update_cooldown()
