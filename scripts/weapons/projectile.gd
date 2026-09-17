class_name Projectile
extends HitboxComponent

## 발사체 기본 클래스
## 직선 이동, 관통 횟수(pierce), 수명(lifetime)을 처리합니다.

@export var speed: float = 450.0
@export var lifetime: float = 3.5
@export var pierce: int = 1

var direction: Vector2 = Vector2.RIGHT
var _hit_targets: Array[Node] = []
var _elapsed_lifetime: float = 0.0

func _ready() -> void:
	# Layer 4 (PlayerProjectile = 8)
	collision_layer = 8
	# Hurtbox 쪽에서 Hitbox를 감지하므로 mask는 기본 0
	collision_mask = 0

## 풀링 재사용 시 발사체 파라미터 초기화
func pool_reset(origin: Vector2, dir: Vector2, spd: float, dmg: float, prc: int, src: Node, wpn: Node) -> void:
	global_position = origin
	direction = dir
	speed = spd
	damage = dmg
	pierce = prc
	source = src
	weapon = wpn
	_hit_targets.clear()
	_elapsed_lifetime = 0.0
	collision_layer = 8
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation = direction.angle()
	queue_redraw()
	
	_elapsed_lifetime += delta
	if _elapsed_lifetime >= lifetime:
		_recycle()

## Hurtbox에 닿았을 때 HurtboxComponent에서 호출
func on_hit_target(target: Node) -> void:
	if target in _hit_targets:
		return
	_hit_targets.append(target)
	
	pierce -= 1
	if pierce <= 0:
		_recycle()

func _recycle() -> void:
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.despawn(self)
	else:
		queue_free()

func _draw() -> void:
	# 발광하는 매직 미사일 연출
	# 외부 은은한 글로우
	draw_circle(Vector2.ZERO, 7.0, Color(0.2, 0.6, 1.0, 0.4))
	# 내부 밝은 청록색 코어
	draw_circle(Vector2.ZERO, 4.5, Color(0.3, 0.9, 1.0, 0.9))
	# 중심 화이트 하이라이트
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
	# 궤적 꼬리 (방향 반대쪽)
	draw_line(Vector2.ZERO, Vector2(-12, 0), Color(0.3, 0.8, 1.0, 0.5), 3.0)
	draw_line(Vector2.ZERO, Vector2(-18, 0), Color(0.1, 0.5, 1.0, 0.2), 1.5)
