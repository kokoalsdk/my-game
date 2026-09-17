class_name LightningRing
extends WeaponBase

## 광역 낙뢰 무기 (Lightning Ring 스타일)
## 주기적으로 무작위 적들의 머리 위에 번개를 떨어뜨려 광역 피해를 입힙니다.

@export var strike_scene: PackedScene = preload("res://scenes/weapons/lightning_strike.tscn")
@export var strike_radius: float = 45.0

func attack() -> void:
	if not strike_scene:
		return
	
	var strikes = base_projectile_count + (player.extra_projectiles if player else 0)
	var final_damage = base_damage * (player.damage_multiplier if player else 1.0)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var candidates: Array[Node2D] = []
	for e in enemies:
		if is_instance_valid(e) and e is Node2D:
			if e.has_node("HealthComponent"):
				var hp = e.get_node("HealthComponent") as HealthComponent
				if hp and hp.is_dead:
					continue
			candidates.append(e as Node2D)
	
	for i in range(strikes):
		var target_pos = Vector2.ZERO
		if candidates.size() > 0:
			var rand_idx = randi() % candidates.size()
			var picked = candidates[rand_idx]
			if is_instance_valid(picked):
				target_pos = picked.global_position
			else:
				target_pos = global_position + Vector2(randf_range(-250, 250), randf_range(-200, 200))
		else:
			# 적이 없으면 플레이어 주변 무작위 타격
			target_pos = global_position + Vector2(randf_range(-250, 250), randf_range(-200, 200))
		
		_spawn_strike(target_pos, final_damage)
		
		if i < strikes - 1:
			await get_tree().create_timer(0.09).timeout

func _spawn_strike(pos: Vector2, dmg: float) -> void:
	play_shoot_sound(0.12, -1.0)
	var strike = strike_scene.instantiate() as LightningStrike
	if not strike:
		return
	
	strike.global_position = pos
	strike.damage = dmg
	strike.radius = strike_radius
	strike.knockback_force = knockback # WeaponBase에서 상속받은 넉백 수치
	strike.source = get_source_node()
	strike.weapon = self
	
	var root = get_tree().current_scene
	if root:
		root.add_child(strike)
	else:
		add_child(strike)

func upgrade_to(new_level: int) -> void:
	level = new_level
	match level:
		2:
			base_projectile_count += 1
		3:
			base_damage *= 1.25
			strike_radius += 8.0
		4:
			base_projectile_count += 1
		5:
			base_cooldown *= 0.85
		6:
			base_projectile_count += 1
		7:
			base_damage *= 1.3
		8:
			base_projectile_count += 2
	update_cooldown()
