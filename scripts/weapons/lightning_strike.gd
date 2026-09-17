class_name LightningStrike
extends HitboxComponent

## 지면에 내리꽂히는 번개 낙뢰 이펙트 및 광역 피격체

@export var radius: float = 45.0

var _lifetime: float = 0.25
var _elapsed: float = 0.0
var _bolt_points: PackedVector2Array = []

func _ready() -> void:
	# Layer 4 (PlayerProjectile = 8)
	collision_layer = 8
	collision_mask = 0
	
	# 낙뢰 지그재그 좌표 생성 (하늘 위에서 지면 (0,0)까지)
	_generate_lightning_path()

func _generate_lightning_path() -> void:
	_bolt_points.clear()
	var start = Vector2(randf_range(-40, 40), -400.0)
	var current = start
	_bolt_points.append(current)
	
	var segments = 6
	for i in range(1, segments):
		var t = float(i) / segments
		var target_y = lerpf(start.y, 0.0, t)
		var jitter_x = randf_range(-25.0, 25.0)
		current = Vector2(jitter_x, target_y)
		_bolt_points.append(current)
	
	_bolt_points.append(Vector2.ZERO)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var alpha = clampf(1.0 - (_elapsed / _lifetime), 0.0, 1.0)
	
	# 1. 지면 충격파 링 (파란빛/보랏빛 전기 파동)
	var ring_radius = lerpf(10.0, radius, _elapsed / _lifetime)
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(0.4, 0.7, 1.0, alpha * 0.8), 3.0)
	draw_circle(Vector2.ZERO, ring_radius * 0.7, Color(0.2, 0.5, 1.0, alpha * 0.25))
	
	# 2. 하늘에서 떨어지는 지그재그 번개 줄기
	if _bolt_points.size() > 1:
		# 외곽 발광
		draw_polyline(_bolt_points, Color(0.3, 0.7, 1.0, alpha * 0.7), 5.0)
		# 내부 백색 코어
		draw_polyline(_bolt_points, Color(1.0, 1.0, 1.0, alpha), 2.0)
