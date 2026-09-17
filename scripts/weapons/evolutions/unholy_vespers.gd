class_name UnholyVespers
extends WeaponBase

## 불경한 기도 (진화 무기: 성스러운 오브 + 날개)
## 8개의 암흑 회전 구체가 멈추지 않고 극초고속으로 회전하여 완벽한 방어와 학살의 장벽을 형성합니다.

@export var rotate_speed: float = 4.8
@export var orbit_radius: float = 95.0
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/orbit_bullet.tscn")

var current_rotation: float = 0.0
var active_bullets: Array[OrbitBullet] = []

func _ready() -> void:
	base_damage = 25.0
	base_projectile_count = 8
	knockback = 220.0
	super._ready()
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
	
	var count = 8
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
		
		# 진화 구체는 핏빛/보라빛 발광 틴트 부여
		b.modulate = Color(1.0, 0.2, 0.4, 1.0)
		
		var root = get_tree().current_scene
		if root:
			root.add_child(b)
		else:
			add_child(b)
		active_bullets.append(b)

func _exit_tree() -> void:
	for b in active_bullets:
		if is_instance_valid(b):
			b.queue_free()
	active_bullets.clear()
