class_name EnemyBase
extends CharacterBody2D

## 몬스터 기본 베이스 클래스
## 플레이어 추적 이동, 피격 넉백/플래시, 공격 판정, 사망 처리를 담당합니다.

signal enemy_died(enemy: EnemyBase)

@export_group("스탯")
@export var move_speed: float = 80.0
@export var contact_damage: float = 8.0
@export var max_health: float = 20.0
@export var knockback_decay: float = 600.0
@export var experience_value: int = 1

@export_group("드랍 아이템")
@export var drop_gem_scene: PackedScene = preload("res://scenes/pickups/exp_gem.tscn")

const HIT_FLASH_SHADER = preload("res://shaders/hit_flash.gdshader")
const DAMAGE_NUMBER_SCENE = preload("res://scenes/ui/floating_damage_number.tscn")
const DEATH_PARTICLES_SCENE = preload("res://scenes/effects/death_particles.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent

var player: Node2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var _flash_tween: Tween
var _dir_update_timer: float = 0.0
var _cached_move_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemy")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# 피격 플래시 셰이더 적용
	if sprite:
		var mat = ShaderMaterial.new()
		mat.shader = HIT_FLASH_SHADER
		sprite.material = mat
	
	# 플레이어 참조 획득
	_find_player()
	
	# 컴포넌트 초기화 및 시그널 연결
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.health_depleted.connect(_on_death)
	
	hitbox_component.damage = contact_damage
	hitbox_component.source = self
	
	hurtbox_component.hit_received.connect(_on_hit_received)

## 풀링 재사용 시 몬스터 상태 초기화
func pool_reset(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	scale = Vector2.ONE
	if sprite:
		sprite.modulate.a = 1.0
	knockback_velocity = Vector2.ZERO
	_cached_move_dir = Vector2.ZERO
	_dir_update_timer = randf_range(0.0, 0.2)
	
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.is_dead = false
	
	if hitbox_component:
		hitbox_component.set_deferred("monitoring", true)
		hitbox_component.set_deferred("monitorable", true)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", true)
		hurtbox_component.set_deferred("monitorable", true)
	
	set_physics_process(true)
	visible = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
	
	# 넉백 감쇄
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	var dist_sq = global_position.distance_squared_to(player.global_position)
	
	# 1. 뱀서 스타일 화면 반대편 텔레포트 (플레이어 후방 1400px 이상 이탈 시 전방 스폰 지점으로 리포지셔닝)
	if not (self is EnemyBoss) and dist_sq > (1400.0 * 1400.0):
		var warp_angle = randf() * TAU
		if player.has_method("get_movement_vector"):
			var p_dir = player.get_movement_vector()
			if p_dir.length_squared() > 0.1:
				warp_angle = p_dir.angle() + randf_range(-0.7, 0.7)
		var warp_dist = randf_range(750.0, 850.0)
		global_position = player.global_position + Vector2(cos(warp_angle), sin(warp_angle)) * warp_dist
		dist_sq = warp_dist * warp_dist
		_cached_move_dir = (player.global_position - global_position).normalized()
	
	# 2. 화면 밖 800px 이상일 경우 추적 방향 계산 Throttling (0.25초 간격)
	var is_offscreen = dist_sq > (800.0 * 800.0)
	if is_offscreen:
		_dir_update_timer += delta
		if _dir_update_timer >= 0.25:
			_dir_update_timer = 0.0
			_cached_move_dir = (player.global_position - global_position).normalized()
	else:
		_cached_move_dir = (player.global_position - global_position).normalized()
		if _cached_move_dir.x != 0.0:
			sprite.flip_h = _cached_move_dir.x < 0.0
	
	velocity = (_cached_move_dir * move_speed) + knockback_velocity
	
	# 3. 화면 밖에서는 무거운 물리 충돌 검사(move_and_slide) 대신 가벼운 직접 위치 이동 수행
	if is_offscreen:
		global_position += velocity * delta
	else:
		move_and_slide()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		player = players[0]

## 피격 시 넉백, 셰이더 플래시, 데미지 텍스트 및 타격감 피드백
func _on_hit_received(hitbox: HitboxComponent) -> void:
	# 1. 넉백 적용
	var knock_dir = hitbox.get_knockback_direction(global_position)
	knockback_velocity = knock_dir * hitbox.knockback_force
	
	# 2. 화이트 셰이더 플래시 효과
	if sprite and sprite.material is ShaderMaterial:
		var mat = sprite.material as ShaderMaterial
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		mat.set_shader_parameter("flash_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter("flash_modifier", 1.0)
		_flash_tween = create_tween()
		_flash_tween.tween_method(func(val): mat.set_shader_parameter("flash_modifier", val), 1.0, 0.0, 0.07)
	
	# 3. 플로팅 데미지 숫자 표출
	_spawn_damage_number(hitbox.damage, hitbox.is_critical)
	
	# 4. 피격 SFX 재생
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit", 0.15)
	
	# 5. 강타격(35 이상 피해) 또는 엘리트/보스 피격 시 카메라 셰이크 및 히트스탑
	if hitbox.damage >= 35.0 or (self is EnemyBoss):
		if is_instance_valid(player):
			if player.has_method("apply_camera_shake"):
				player.apply_camera_shake(2.8)
			if player.has_method("trigger_hit_stop"):
				player.trigger_hit_stop(0.04, 0.05)

## 사망 처리
func _on_death() -> void:
	enemy_died.emit(self)
	
	# 플레이어 처치 카운트 누적
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("record_kill"):
		players[0].record_kill()
	
	# 사망 버스트 파티클 생성
	_spawn_death_particles()
	
	# 물리 쿼리 플러싱 완료 후 안전하게 보석/아이템 드랍 (Deferred)
	_drop_loot.call_deferred()
	
	# 사망 시 충돌 및 물리 비활성화 (지연 호출로 플러싱 중단 에러 방지)
	set_physics_process(false)
	if hitbox_component:
		hitbox_component.set_deferred("monitoring", false)
		hitbox_component.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
		hurtbox_component.set_deferred("monitorable", false)
	
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	death_tween.chain().tween_callback(_recycle)

func _recycle() -> void:
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.despawn(self)
	else:
		queue_free()

## 플로팅 데미지 숫자 스폰 (풀링 적용)
func _spawn_damage_number(dmg: float, is_critical: bool) -> void:
	if not DAMAGE_NUMBER_SCENE:
		return
	
	var root = get_tree().current_scene
	var spawn_pos = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-22.0, -10.0))
	
	var pm = get_node_or_null("/root/PoolManager")
	var num: FloatingDamageNumber = null
	if pm:
		num = pm.spawn(DAMAGE_NUMBER_SCENE, root) as FloatingDamageNumber
	else:
		num = DAMAGE_NUMBER_SCENE.instantiate() as FloatingDamageNumber
		if root:
			root.add_child(num)
		else:
			get_parent().add_child(num)
	
	if num:
		num.global_position = spawn_pos
		num.setup(dmg, is_critical)

## 사망 소멸 파티클 스폰 (풀링 적용)
func _spawn_death_particles() -> void:
	if not DEATH_PARTICLES_SCENE:
		return
	
	var root = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	var p: DeathParticles = null
	if pm:
		p = pm.spawn(DEATH_PARTICLES_SCENE, root) as DeathParticles
	else:
		p = DEATH_PARTICLES_SCENE.instantiate() as DeathParticles
		if root:
			root.add_child(p)
		else:
			get_parent().add_child(p)
	
	if not p:
		return
	
	p.global_position = global_position
	
	var col = sprite.modulate if sprite else Color(0.95, 0.25, 0.25, 1.0)
	col.a = 1.0
	var scale_mult = 1.0
	if self is EnemyBoss:
		scale_mult = 2.4
		col = Color(1.0, 0.8, 0.25, 1.0)
	elif max_health >= 70.0:
		scale_mult = 1.35
	
	p.setup_color(col, scale_mult)

## 경험치 보석 드랍 (풀링 적용)
func _drop_loot() -> void:
	if not drop_gem_scene:
		return
	
	var root_scene = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	var gem: ExpGem = null
	if pm:
		gem = pm.spawn(drop_gem_scene, root_scene) as ExpGem
	else:
		gem = drop_gem_scene.instantiate() as ExpGem
		if root_scene:
			root_scene.add_child(gem)
		else:
			get_parent().add_child(gem)
	
	if gem:
		gem.pool_reset(global_position, experience_value)
