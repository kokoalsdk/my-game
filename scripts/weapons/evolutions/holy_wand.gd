class_name HolyWand
extends WeaponBase

## 신성한 지팡이 (진화 무기: 매직 완드 + 빈 책)
## 쿨다운 없이 멈추지 않고 가장 가까운 적들에게 관통 황금 미사일을 연속 난사합니다.

func _ready() -> void:
	base_cooldown = 0.12
	base_speed = 650.0
	base_pierce = 3
	base_damage = 28.0
	super._ready()

func attack() -> void:
	if not projectile_scene:
		return
	
	var shoot_origin = global_position
	var target_enemy = get_closest_enemy(shoot_origin, 900.0)
	
	var shoot_dir = Vector2.RIGHT
	if target_enemy:
		shoot_dir = (target_enemy.global_position - shoot_origin).normalized()
	elif player and player.velocity.length() > 0.1:
		shoot_dir = player.velocity.normalized()
	else:
		shoot_dir = Vector2.RIGHT.rotated(randf() * TAU)
	
	var final_damage = base_damage * (player.damage_multiplier if player else 1.0)
	play_shoot_sound(0.12, -4.0)
	
	var root = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	var proj: Projectile = null
	if pm:
		proj = pm.spawn(projectile_scene, root) as Projectile
	else:
		proj = projectile_scene.instantiate() as Projectile
		if root:
			root.add_child(proj)
		else:
			add_child(proj)
	
	if proj:
		proj.knockback_force = knockback
		proj.pool_reset(shoot_origin, shoot_dir, base_speed, final_damage, base_pierce, get_source_node(), self)
