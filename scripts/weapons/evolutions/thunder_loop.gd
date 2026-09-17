class_name ThunderLoop
extends WeaponBase

## 천둥의 고리 (진화 무기: 번개 반지 + 시금치)
## 4줄기의 강력한 벼락을 내리치며, 각 타격 지점에서 2차 연쇄 전기 고리 폭발을 일으킵니다.

@export var strike_scene: PackedScene = preload("res://scenes/weapons/lightning_strike.tscn")

func _ready() -> void:
	base_cooldown = 1.4
	base_damage = 70.0
	base_projectile_count = 4
	super._ready()

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
				target_pos = global_position + Vector2(randf_range(-300, 300), randf_range(-250, 250))
		else:
			target_pos = global_position + Vector2(randf_range(-300, 300), randf_range(-250, 250))
		
		# 1차 번개 타격
		_spawn_strike(target_pos, final_damage, 55.0)
		
		# 0.15초 뒤 해당 지점에서 2차 연쇄 폭발
		get_tree().create_timer(0.15).timeout.connect(func():
			_spawn_strike(target_pos, final_damage * 0.75, 75.0)
		)
		
		if i < strikes - 1:
			await get_tree().create_timer(0.06).timeout

func _spawn_strike(pos: Vector2, dmg: float, rad: float) -> void:
	play_shoot_sound(0.15, 0.0)
	var strike = strike_scene.instantiate() as LightningStrike
	if not strike:
		return
	
	strike.global_position = pos
	strike.damage = dmg
	strike.radius = rad
	strike.knockback_force = knockback # WeaponBase에서 상속받은 넉백 수치
	strike.source = get_source_node()
	strike.weapon = self
	
	# 천둥의 고리는 푸른빛-보랏빛 번개로 변환
	strike.modulate = Color(0.7, 0.4, 1.0, 1.0)
	
	var root = get_tree().current_scene
	if root:
		root.add_child(strike)
	else:
		add_child(strike)
