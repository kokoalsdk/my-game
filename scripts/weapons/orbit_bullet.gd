class_name OrbitBullet
extends HitboxComponent

## 플레이어 주변을 회전하는 오브 투사체

@export var rotation_radius: float = 80.0
@export var angle_offset: float = 0.0

var _pulse_time: float = 0.0

func _ready() -> void:
	# Layer 4 (PlayerProjectile = 8)
	collision_layer = 8
	collision_mask = 0

func _process(delta: float) -> void:
	_pulse_time += delta * 6.0
	queue_redraw()

func update_orbit_position(center: Vector2, current_rotation: float) -> void:
	var total_angle = current_rotation + angle_offset
	global_position = center + Vector2(cos(total_angle), sin(total_angle)) * rotation_radius

func _draw() -> void:
	var pulse = (sin(_pulse_time) * 0.15) + 1.0
	# 황금빛 회전 구체 연출
	draw_circle(Vector2.ZERO, 9.0 * pulse, Color(1.0, 0.75, 0.2, 0.35))
	draw_circle(Vector2.ZERO, 6.0 * pulse, Color(1.0, 0.9, 0.4, 0.9))
	draw_circle(Vector2.ZERO, 3.5, Color.WHITE)
