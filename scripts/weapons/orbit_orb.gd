class_name OrbitOrb
extends WeaponBase

## 궤도 회전형 무기 (Holy Bible / Orbiting Orbs 스타일)
## 플레이어를 중심으로 지속적으로 회전하며 접근하는 적에게 피해를 줍니다.

@export var rotate_speed: float = 2.8
@export var orbit_radius: float = 80.0
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/orbit_bullet.tscn")

var current_rotation: float = 0.0
var active_bullets: Array[OrbitBullet] = []

func _ready() -> void:
	super._ready()
	# 지속 회전 무기이므로 타이머 쿨다운 공격 대신 항상 활성화
	if cooldown_timer:
		cooldown_timer.stop()
	_rebuild_orbs()

func _process(delta: float) -> void:
	var speed_mult = 1.0
	if player:
		speed_mult = 1.0 / max(0.2, player.cooldown_multiplier)
	
	current_rotation += rotate_speed * speed_mult * delta
	if current_rotation >= TAU:
		current_rotation -= TAU
	
	var center = global_position
	if player:
		center = player.global_position
	
	var final_damage = base_damage * (player.damage_multiplier if player else 1.0)
	for b in active_bullets:
		if is_instance_valid(b):
			b.damage = final_damage
			b.source = get_source_node()
			b.rotation_radius = orbit_radius
			b.update_orbit_position(center, current_rotation)

func _rebuild_orbs() -> void:
	for b in active_bullets:
		if is_instance_valid(b):
			b.queue_free()
	active_bullets.clear()
	
	if not bullet_scene:
		return
	
	var count = base_projectile_count + (player.extra_projectiles if player else 0)
	for i in range(count):
		var b = bullet_scene.instantiate() as OrbitBullet
		if not b:
			continue
		b.angle_offset = (TAU / count) * i
		b.rotation_radius = orbit_radius
		b.damage = base_damage
		b.knockback_force = knockback # WeaponBase에서 상속받은 넉백 수치
		b.source = get_source_node()
		b.weapon = self
		
		# 최상위 씬에 추가
		var root = get_tree().current_scene
		if root:
			root.add_child(b)
		else:
			add_child(b)
		active_bullets.append(b)

func upgrade_to(new_level: int) -> void:
	level = new_level
	match level:
		2:
			base_projectile_count += 1
		3:
			base_damage *= 1.25
			orbit_radius += 10.0
		4:
			base_projectile_count += 1
		5:
			rotate_speed *= 1.3
		6:
			base_projectile_count += 1
		7:
			base_damage *= 1.3
		8:
			base_projectile_count += 1
			rotate_speed *= 1.2
	_rebuild_orbs()

func _exit_tree() -> void:
	for b in active_bullets:
		if is_instance_valid(b):
			b.queue_free()
	active_bullets.clear()
