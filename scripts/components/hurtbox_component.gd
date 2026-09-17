class_name HurtboxComponent
extends Area2D

## 피격 판정을 담당하는 Area2D 컴포넌트
## HitboxComponent와 접촉 시 HealthComponent에 데미지를 전달하고 피격/무적 이벤트를 처리합니다.

signal hit_received(hitbox: HitboxComponent)
signal invincibility_started
signal invincibility_ended

@export var health_component: HealthComponent
## 피격 후 무적 지속 시간(초). 0이면 무적 없이 지속 피격
@export var invincibility_duration: float = 0.0

var is_invincible: bool = false
var _invincibility_timer: Timer

func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	
	_invincibility_timer = Timer.new()
	_invincibility_timer.one_shot = true
	_invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(_invincibility_timer)

func _on_area_entered(area: Area2D) -> void:
	if not (area is HitboxComponent):
		return
	
	take_hit(area as HitboxComponent)

func take_hit(hitbox: HitboxComponent) -> void:
	if is_invincible:
		return
	
	# 체력 컴포넌트가 연결되어 있다면 데미지 처리
	if health_component and not health_component.is_dead:
		health_component.damage(hitbox.damage)
		hitbox.record_damage(hitbox.damage)
	
	hit_received.emit(hitbox)
	
	# 투사체 등 Hitbox 측에 피격 대상 알림 (관통/파괴 처리)
	if hitbox.has_method("on_hit_target"):
		hitbox.call("on_hit_target", self)
	
	# 무적 시간 적용
	if invincibility_duration > 0.0:
		start_invincibility(invincibility_duration)

func start_invincibility(duration: float) -> void:
	is_invincible = true
	invincibility_started.emit()
	_invincibility_timer.start(duration)

func _on_invincibility_timeout() -> void:
	is_invincible = false
	invincibility_ended.emit()
	
	# 무적이 끝났을 때 이미 겹쳐있는 Hitbox가 있다면 다시 피격 판정
	for area in get_overlapping_areas():
		if area is HitboxComponent and not is_invincible:
			take_hit(area as HitboxComponent)
			break
