class_name ExpGem
extends Area2D

## 적 처치 시 드랍되는 경험치 보석
## 플레이어 자석 반경에 진입하면 플레이어에게 가속하며 흡수됩니다.

signal collected(value: int)

@export var experience_value: int = 1
@export var initial_speed: float = 160.0
@export var acceleration: float = 900.0

var target: Node2D = null
var current_speed: float = 0.0
var is_collected: bool = false
var _gem_color: Color = Color(0.2, 0.9, 0.4) # 기본 초록 보석

func _ready() -> void:
	add_to_group("pickup")
	monitoring = false
	# Layer 5 (Pickup = 16)
	collision_layer = 16
	collision_mask = 0
	
	_update_color()
	
	# 드랍 시 살짝 튀어오르는 부드러운 스폰 연출
	scale = Vector2(0.2, 0.2)
	var spawn_tween = create_tween()
	spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_color() -> void:
	if experience_value >= 20:
		_gem_color = Color(1.0, 0.25, 0.25) # 빨강 (대형)
	elif experience_value >= 5:
		_gem_color = Color(0.25, 0.6, 1.0) # 파랑 (중형)
	else:
		_gem_color = Color(0.2, 0.95, 0.4) # 초록 (일반)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	
	if is_instance_valid(target):
		# 플레이어를 향해 점점 빨라지는 가속 이동
		var dir = (target.global_position - global_position).normalized()
		current_speed += acceleration * delta
		position += dir * current_speed * delta
		
		# 플레이어와 충분히 가까워지면 습득
		if global_position.distance_squared_to(target.global_position) <= (22.0 * 22.0):
			_on_collected()

## 플레이어의 PickupArea가 감지했을 때 호출
func start_homing(collector: Node2D) -> void:
	if is_collected or is_instance_valid(target):
		return
	
	target = collector
	current_speed = initial_speed
	# 중복 감지 방지를 위해 충돌 레이어 해제
	collision_layer = 0

## 풀링 재사용 시 상태 초기화
func pool_reset(spawn_pos: Vector2, exp_val: int) -> void:
	global_position = spawn_pos
	experience_value = exp_val
	is_collected = false
	target = null
	current_speed = 0.0
	modulate.a = 1.0
	scale = Vector2(0.2, 0.2)
	monitoring = false
	collision_layer = 16
	_update_color()
	
	var spawn_tween = create_tween()
	spawn_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_collected() -> void:
	if is_collected:
		return
	is_collected = true
	
	if is_instance_valid(target) and target.has_method("gain_experience"):
		target.call("gain_experience", experience_value)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("gem", 0.12, -4.0)
	
	collected.emit(experience_value)
	
	# 습득 팝업 연출 후 풀로 반환
	var pop_tween = create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	pop_tween.tween_property(self, "modulate:a", 0.0, 0.08)
	pop_tween.chain().tween_callback(_recycle)

func _recycle() -> void:
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.despawn(self)
	else:
		queue_free()

func _draw() -> void:
	# 다이아몬드 형상의 보석 렌더링
	var points = PackedVector2Array([
		Vector2(0, -7),
		Vector2(6, 0),
		Vector2(0, 7),
		Vector2(-6, 0)
	])
	
	# 외곽 은은한 글로우
	draw_circle(Vector2.ZERO, 7.5, Color(_gem_color.r, _gem_color.g, _gem_color.b, 0.35))
	
	# 보석 몸체
	draw_colored_polygon(points, _gem_color)
	
	# 보석 상단 하이라이트 (빛 반사 느낌)
	var highlight = PackedVector2Array([
		Vector2(0, -6),
		Vector2(4, 0),
		Vector2(0, 2),
		Vector2(-4, 0)
	])
	draw_colored_polygon(highlight, Color.WHITE.lerp(_gem_color, 0.4))
