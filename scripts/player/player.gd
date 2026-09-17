class_name Player
extends CharacterBody2D

## 뱀서라이크 플레이어 캐릭터
## 이동, 피격 및 무적 시간, 자석 반경 및 스탯을 제어합니다.

signal player_died
signal health_updated(current_hp: float, max_hp: float)
signal experience_gained(amount: int)
signal level_up(new_level: int)
signal exp_updated(current_exp: int, required_exp: int, level: int)
@warning_ignore("unused_signal")
signal chest_collected(chest: Node)
signal gold_changed(total_gold: int, gained: int)
signal kill_count_changed(total_kills: int)

@export_group("이동 스탯")
@export var max_speed: float = 180.0
@export var acceleration: float = 1400.0
@export var friction: float = 1200.0

@export_group("전투 & 수집 스탯")
@export var pickup_radius: float = 70.0 : set = set_pickup_radius
@export var damage_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var extra_projectiles: int = 0
@export var exp_multiplier: float = 1.0

@export_group("애니메이션 스탯")
@export var walk_anim_speed: float = 10.0 ## 걷기 애니메이션 프레임 재생 속도 (FPS)

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_collision_shape: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var equipment_manager: EquipmentManager = $EquipmentManager

var _blink_tween: Tween

var current_level: int = 1
var current_exp: int = 0
var required_exp: int = 5
var current_gold: int = 0
var kill_count: int = 0

var camera_shake_intensity: float = 0.0
var camera_shake_decay: float = 14.0
var _walk_anim_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	
	# SaveManager 메타 영구 강화 스탯 적용
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("apply_to_player"):
		save_mgr.apply_to_player(self)
	
	# 시그널 연결
	health_component.health_changed.connect(_on_health_changed)
	health_component.health_depleted.connect(_on_health_depleted)
	
	hurtbox_component.hit_received.connect(_on_hit_received)
	hurtbox_component.invincibility_started.connect(_on_invincibility_started)
	hurtbox_component.invincibility_ended.connect(_on_invincibility_ended)
	
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	
	# 자석 반경 초기화
	_update_pickup_shape()
	
	# 초기 체력 및 경험치 시그널 발생
	health_updated.emit(health_component.current_health, health_component.max_health)
	exp_updated.emit(current_exp, required_exp, current_level)

func _process(delta: float) -> void:
	if camera_shake_intensity > 0.0 and camera:
		camera_shake_intensity = move_toward(camera_shake_intensity, 0.0, camera_shake_decay * delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * camera_shake_intensity
	elif camera and camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

## 화면 진동(카메라 셰이크) 적용
func apply_camera_shake(intensity: float) -> void:
	camera_shake_intensity = maxf(camera_shake_intensity, intensity)

## 히트스탑 (미세 프레임 동결 연출)
func trigger_hit_stop(duration: float = 0.04, target_scale: float = 0.05) -> void:
	Engine.time_scale = target_scale
	var timer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func():
		if Engine.time_scale == target_scale:
			Engine.time_scale = 1.0
	)

func _physics_process(delta: float) -> void:
	handle_movement(delta)

## 8방향 부드러운 가감속 이동
func handle_movement(delta: float) -> void:
	var move_dir: Vector2 = get_movement_vector()
	
	if move_dir != Vector2.ZERO:
		velocity = velocity.move_toward(move_dir * max_speed, acceleration * delta)
		# 이동 방향에 따라 스프라이트 좌우 반전
		if move_dir.x != 0.0:
			sprite.flip_h = move_dir.x < 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	# 발걸음 걷기 애니메이션 프레임 제어
	_update_walk_animation(delta)

## 걷기 / 정지 스프라이트 애니메이션 프레임 제어
func _update_walk_animation(delta: float) -> void:
	if not sprite or sprite.hframes <= 1:
		return
	
	# 캐릭터가 이동 중일 때 발걸음 애니메이션 진행
	if velocity.length_squared() > 100.0:
		var speed_factor: float = clampf(velocity.length() / max_speed, 0.5, 1.4)
		_walk_anim_timer += delta * walk_anim_speed * speed_factor
		sprite.frame = int(_walk_anim_timer) % sprite.hframes
	else:
		# 정지 상태: 0번 프레임(기본 기립 자세)으로 즉시 복귀
		_walk_anim_timer = 0.0
		sprite.frame = 0

## 키보드(WASD / 방향키 / UI Input) 입력 벡터 반환
func get_movement_vector() -> Vector2:
	var x: float = 0.0
	var y: float = 0.0
	
	# 커스텀 Action 매핑 확인 및 fallback
	if InputMap.has_action("move_left"):
		x = Input.get_axis("move_left", "move_right")
		y = Input.get_axis("move_up", "move_down")
	else:
		x = Input.get_axis("ui_left", "ui_right")
		y = Input.get_axis("ui_up", "ui_down")
	
	# WASD 직접 키 체크 fallback
	if x == 0.0 and y == 0.0:
		if Input.is_key_pressed(KEY_A): x -= 1.0
		if Input.is_key_pressed(KEY_D): x += 1.0
		if Input.is_key_pressed(KEY_W): y -= 1.0
		if Input.is_key_pressed(KEY_S): y += 1.0
	
	return Vector2(x, y).normalized()

## 자석 반경 설정
func set_pickup_radius(value: float) -> void:
	pickup_radius = value
	if is_node_ready():
		_update_pickup_shape()

func _update_pickup_shape() -> void:
	if pickup_collision_shape and pickup_collision_shape.shape is CircleShape2D:
		(pickup_collision_shape.shape as CircleShape2D).radius = pickup_radius

## 드랍 아이템(보석 등) 감지 시
func _on_pickup_area_entered(area: Area2D) -> void:
	# 드랍 아이템에 collect() 또는 start_homing() 호출
	if area.has_method("collect_by"):
		area.call("collect_by", self)
	elif area.has_method("start_homing"):
		area.call("start_homing", self)

## 피격 시 연출
func _on_hit_received(_hitbox: HitboxComponent) -> void:
	apply_camera_shake(6.5)
	trigger_hit_stop(0.04, 0.05)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("player_hurt", 0.05)
	
	# 피격 시 짧은 붉은 플래시 효과
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.05)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

## 무적 시작 (깜빡임 연출)
func _on_invincibility_started() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.08)
	_blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.08)

## 무적 종료 (원상 복구)
func _on_invincibility_ended() -> void:
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	sprite.modulate = Color.WHITE

func _on_health_changed(current_hp: float, max_hp: float) -> void:
	health_updated.emit(current_hp, max_hp)

func _on_health_depleted() -> void:
	player_died.emit()
	set_physics_process(false)

## 경험치 습득 및 레벨업 처리
func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	
	var gained = int(round(amount * exp_multiplier))
	if gained <= 0:
		gained = 1
	
	current_exp += gained
	experience_gained.emit(gained)
	
	var leveled_up: bool = false
	while current_exp >= required_exp:
		current_exp -= required_exp
		current_level += 1
		required_exp = _calc_required_exp(current_level)
		leveled_up = true
		level_up.emit(current_level)
	
	if leveled_up:
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("levelup")
	
	exp_updated.emit(current_exp, required_exp, current_level)

## 뱀서 스타일 점진적 필요 경험치 계산 공식
func _calc_required_exp(lvl: int) -> int:
	return int(5 + (lvl - 1) * 8 + pow(lvl - 1, 1.4) * 3)

## 골드 획득 처리
func add_gold(amount: int) -> void:
	if amount > 0:
		current_gold += amount
		gold_changed.emit(current_gold, amount)

## 적 처치 기록
func record_kill() -> void:
	kill_count += 1
	kill_count_changed.emit(kill_count)

## 보물상자 습득 처리
func collect_chest(chest: Node) -> void:
	chest_collected.emit(chest)
