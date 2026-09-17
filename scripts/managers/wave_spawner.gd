class_name WaveSpawner
extends Node2D

## 타임테이블 기반 웨이브 스폰 및 포위(Swarm) 이벤트 제어 시스템

signal warning_announced(message: String)
signal stage_cleared

@export var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_basic.tscn")
@export var enemy_fast_scene: PackedScene = preload("res://scenes/enemies/enemy_fast.tscn")
@export var enemy_boss_scene: PackedScene = preload("res://scenes/enemies/enemy_boss.tscn")

@export var base_spawn_interval: float = 1.2
@export var min_spawn_interval: float = 0.2
@export var spawn_distance_min: float = 720.0
@export var spawn_distance_max: float = 850.0
@export var max_enemies_count: int = 300

var player: Node2D = null
var spawn_timer: Timer
var elapsed_time: float = 0.0

## 시간대별 이벤트 타임테이블 정의
var _timeline: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("spawner")
	_init_timeline()
	_setup_timer()
	_find_player()

func _setup_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = base_spawn_interval
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

## 웨이브 타임테이블 초기화
func _init_timeline() -> void:
	_timeline = [
		# 1분: 첫 번째 포위 무리 (박쥐 32마리 원형 포위)
		{
			"time": 60.0,
			"type": "swarm",
			"scene": enemy_scene,
			"count": 32,
			"warning": "⚠️ 경고: 대규모 몬스터 무리가 사방에서 포위해옵니다! ⚠️",
			"triggered": false
		},
		# 2분: 첫 번째 보스 출현 (거대 골렘)
		{
			"time": 120.0,
			"type": "boss",
			"name": "거대 골렘 (BOSS)",
			"hp_mult": 1.0,
			"dmg_mult": 1.0,
			"warning": "⚠️ 경고: 거대 골렘 보스가 출현했습니다! ⚠️",
			"triggered": false
		},
		# 3분: 신속 포위 무리 (가고일 36마리 원형 포위)
		{
			"time": 180.0,
			"type": "swarm",
			"scene": enemy_fast_scene,
			"count": 36,
			"warning": "⚠️ 경고: 신속한 가고일 떼가 급습합니다! ⚠️",
			"triggered": false
		},
		# 5분: 중간 보스 출현 (고대 수호자, 체력 2배)
		{
			"time": 300.0,
			"type": "boss",
			"name": "고대 수호자 (MID BOSS)",
			"hp_mult": 2.0,
			"dmg_mult": 1.25,
			"warning": "⚠️ 경고: 고대 수호자가 깨어났습니다! ⚠️",
			"triggered": false
		},
		# 7분: 초대형 혼합 포위 무리 (48마리)
		{
			"time": 420.0,
			"type": "swarm",
			"scene": enemy_fast_scene,
			"count": 48,
			"warning": "⚠️ 위험: 사방에서 대규모 습격이 시작됩니다! ⚠️",
			"triggered": false
		},
		# 10분: 최종 보스 출현 (파멸의 군주, 체력 4배)
		{
			"time": 600.0,
			"type": "boss",
			"name": "파멸의 군주 (FINAL BOSS)",
			"hp_mult": 4.0,
			"dmg_mult": 1.6,
			"warning": "☠️ 경고: 파멸의 군주가 강림했습니다! ☠️",
			"triggered": false
		}
	]

var _gem_merge_timer: float = 0.0

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# 점진적 스폰 간격 단축 (10분에 걸쳐 최고 난이도 도달)
	var difficulty_factor = clampf(elapsed_time / 600.0, 0.0, 1.0)
	spawn_timer.wait_time = lerpf(base_spawn_interval, min_spawn_interval, difficulty_factor)
	
	# 타임테이블 이벤트 감지
	_check_timeline_events()
	
	# 경험치 보석 과다 스폰 방지 및 가치 병합 (2.5초 주기)
	_gem_merge_timer += delta
	if _gem_merge_timer >= 2.5:
		_gem_merge_timer = 0.0
		_process_gem_merging()

func _check_timeline_events() -> void:
	for ev in _timeline:
		if not ev.triggered and elapsed_time >= ev.time:
			ev.triggered = true
			_execute_timeline_event(ev)

func _execute_timeline_event(ev: Dictionary) -> void:
	if ev.has("warning") and ev.warning != "":
		warning_announced.emit(ev.warning)
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("boss_warning")
		if is_instance_valid(player) and player.has_method("apply_camera_shake"):
			player.apply_camera_shake(5.0)
	
	match ev.type:
		"swarm":
			_spawn_swarm_ring(ev.scene, ev.count)
		"boss":
			_spawn_boss(ev.name, ev.hp_mult, ev.dmg_mult)

## 원형 포위 무리(Swarm Ring) 소환 (풀링 적용)
func _spawn_swarm_ring(scene: PackedScene, count: int, radius: float = 750.0) -> void:
	if not scene or not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
	
	var root = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	
	for i in range(count):
		var angle = (TAU / count) * i
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * radius
		var enemy: EnemyBase = null
		if pm:
			enemy = pm.spawn(scene, root) as EnemyBase
		else:
			enemy = scene.instantiate() as EnemyBase
			if root:
				root.add_child(enemy)
			else:
				get_parent().add_child(enemy)
		
		if enemy:
			enemy.pool_reset(spawn_pos)

## 보스 소환
func _spawn_boss(boss_name_str: String = "거대 골렘 (BOSS)", hp_mult: float = 1.0, dmg_mult: float = 1.0) -> void:
	if not enemy_boss_scene:
		return
	
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
	
	var boss = enemy_boss_scene.instantiate() as EnemyBoss
	if not boss:
		return
	
	boss.boss_name = boss_name_str
	boss.max_health *= hp_mult
	boss.contact_damage *= dmg_mult
	boss.global_position = _get_random_spawn_position()
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_bgm("boss")
	
	boss.enemy_died.connect(func(_b):
		var remaining_bosses = get_tree().get_nodes_in_group("boss")
		if remaining_bosses.size() <= 1:
			var sm2 = get_node_or_null("/root/SoundManager")
			if sm2:
				sm2.play_bgm("battle")
	)
	
	if boss_name_str.contains("FINAL BOSS"):
		boss.enemy_died.connect(func(_b):
			stage_cleared.emit()
		)
	
	var root = get_tree().current_scene
	if root:
		root.add_child(boss)
	else:
		get_parent().add_child(boss)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		player = players[0]

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player):
		_find_player()
		if not is_instance_valid(player):
			return
	
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	if current_enemies.size() >= max_enemies_count:
		return
	
	# 시간 경과에 따른 배치 스폰 수량 증가 (1~5마리)
	var batch_count = 1 + int(elapsed_time / 90.0)
	batch_count = mini(batch_count, 5)
	
	for i in range(batch_count):
		_spawn_single_enemy()

## 단일 몬스터 스폰 (풀링 적용)
func _spawn_single_enemy() -> void:
	# 45초 이후 35% 확률로 빠른 적 소환
	var scene_to_spawn = enemy_scene
	if elapsed_time >= 45.0 and randf() < 0.35 and enemy_fast_scene:
		scene_to_spawn = enemy_fast_scene
	
	if not scene_to_spawn:
		return
	
	var root = get_tree().current_scene
	var pm = get_node_or_null("/root/PoolManager")
	var enemy: EnemyBase = null
	if pm:
		enemy = pm.spawn(scene_to_spawn, root) as EnemyBase
	else:
		enemy = scene_to_spawn.instantiate() as EnemyBase
		if root:
			root.add_child(enemy)
		else:
			get_parent().add_child(enemy)
	
	if enemy:
		enemy.pool_reset(_get_random_spawn_position())

## 바닥의 보석 수가 과다해질 경우(>180개) 먼 보석들을 가까운 보석으로 압축 병합
func _process_gem_merging() -> void:
	if not is_instance_valid(player):
		return
	
	var pickups = get_tree().get_nodes_in_group("pickup")
	var gems: Array[ExpGem] = []
	for p in pickups:
		if p is ExpGem and not p.is_collected:
			gems.append(p as ExpGem)
	
	const MAX_ACTIVE_GEMS = 180
	if gems.size() <= MAX_ACTIVE_GEMS:
		return
	
	# 플레이어 기준 거리 정렬 (먼 것부터 앞쪽)
	var p_pos = player.global_position
	gems.sort_custom(func(a: ExpGem, b: ExpGem):
		return a.global_position.distance_squared_to(p_pos) > b.global_position.distance_squared_to(p_pos)
	)
	
	var overflow_count = gems.size() - MAX_ACTIVE_GEMS
	var absorbed_xp = 0
	var pm = get_node_or_null("/root/PoolManager")
	
	for i in range(overflow_count):
		var far_gem = gems[i]
		if is_instance_valid(far_gem) and not far_gem.is_collected:
			absorbed_xp += far_gem.experience_value
			far_gem.is_collected = true
			if pm:
				pm.despawn(far_gem)
			else:
				far_gem.queue_free()
	
	# 남은 보석 중 플레이어와 가장 가까운 보석에 경험치 가치 누적 합산
	if gems.size() > overflow_count and absorbed_xp > 0:
		var target_gem = gems[gems.size() - 1]
		if is_instance_valid(target_gem):
			target_gem.experience_value += absorbed_xp
			target_gem._update_color()

func _get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	var origin = player.global_position if is_instance_valid(player) else Vector2.ZERO
	return origin + Vector2(cos(angle), sin(angle)) * distance
