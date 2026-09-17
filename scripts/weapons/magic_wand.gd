class_name MagicWand
extends WeaponBase

## 매직 완드 (가장 가까운 적 자동 조준 마법 미사일 발사)

func upgrade_to(new_level: int) -> void:
	level = new_level
	match level:
		2: base_projectile_count += 1
		3: base_damage *= 1.2
		4:
			base_projectile_count += 1
			base_pierce += 1
		5: base_cooldown *= 0.85
		6: base_projectile_count += 1
		7: base_damage *= 1.25
		8: base_projectile_count += 2
	update_cooldown()

func attack() -> void:
	if not projectile_scene:
		return
	
	var count = base_projectile_count
	if player:
		count += player.extra_projectiles
	
	var final_damage = base_damage
	if player:
		final_damage *= player.damage_multiplier
	
	for i in range(count):
		# 발사 시점마다 가장 가까운 적을 다시 탐색 (이전 미사일로 적이 죽었을 수 있음)
		var shoot_origin = global_position
		var target_enemy = get_closest_enemy(shoot_origin)
		
		var shoot_dir = Vector2.RIGHT
		if target_enemy:
			shoot_dir = (target_enemy.global_position - shoot_origin).normalized()
		elif player and player.velocity.length() > 0.1:
			shoot_dir = player.velocity.normalized()
		else:
			# 무작위 방향
			shoot_dir = Vector2.RIGHT.rotated(randf() * TAU)
		
		_spawn_projectile(shoot_origin, shoot_dir, final_damage)
		
		# 여러 발 발사 시 약간의 시간차 연사 간격
		if i < count - 1:
			await get_tree().create_timer(0.08).timeout

func _spawn_projectile(origin: Vector2, dir: Vector2, dmg: float) -> void:
	play_shoot_sound(0.09, -2.0)
	var root_scene = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	var proj: Projectile = null
	if pm:
		proj = pm.spawn(projectile_scene, root_scene) as Projectile
	else:
		proj = projectile_scene.instantiate() as Projectile
		if root_scene:
			root_scene.add_child(proj)
		else:
			get_parent().add_child(proj)
	
	if proj:
		proj.knockback_force = knockback
		proj.pool_reset(origin, dir, base_speed, dmg, base_pierce, get_source_node(), self)
