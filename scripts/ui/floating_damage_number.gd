class_name FloatingDamageNumber
extends Node2D

## 타격 시 몬스터 머리 위에 튀어오르며 나타나는 플로팅 데미지 숫자

@onready var label: Label = $Label

var velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 0.55
var _elapsed: float = 0.0

func setup(amount: float, is_critical: bool = false, is_heal: bool = false) -> void:
	if not label:
		label = get_node_or_null("Label")
	if not label and not is_node_ready():
		await ready
	if not label:
		label = get_node_or_null("Label")
	if not label:
		return
	
	if not label.label_settings:
		label.label_settings = LabelSettings.new()
	else:
		label.label_settings = label.label_settings.duplicate()
	
	# 수치 및 색상 포맷
	if is_heal:
		label.text = "+%d" % int(round(amount))
		label.label_settings.font_color = Color(0.35, 1.0, 0.45, 1.0) # 힐 녹색
		label.label_settings.font_size = 14
	elif is_critical or amount >= 35.0:
		label.text = "%d!" % int(round(amount))
		label.label_settings.font_color = Color(1.0, 0.35, 0.15, 1.0) # 강타/치명타 오렌지-적색
		label.label_settings.font_size = 18
	else:
		label.text = "%d" % int(round(amount))
		label.label_settings.font_color = Color(1.0, 0.95, 0.85, 1.0) # 기본 백색/연노랑
		label.label_settings.font_size = 14
	
	_elapsed = 0.0
	modulate.a = 1.0
	
	# 초기 팝업 애니메이션 (스케일 바운스)
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	var target_scale = Vector2(1.35, 1.35) if (is_critical or amount >= 35.0) else Vector2(1.15, 1.15)
	tween.tween_property(self, "scale", target_scale, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN)
	
	# 부유 속도 초기화
	velocity = Vector2(randf_range(-35.0, 35.0), randf_range(-100.0, -135.0))

func _process(delta: float) -> void:
	_elapsed += delta
	position += velocity * delta
	velocity.y += 180.0 * delta # 감속/중력 효과
	velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
	
	# 서서히 페이드아웃 후 소멸
	if _elapsed >= _lifetime * 0.5:
		var alpha = clampf(1.0 - (_elapsed - _lifetime * 0.5) / (_lifetime * 0.5), 0.0, 1.0)
		modulate.a = alpha
	
	if _elapsed >= _lifetime:
		_recycle()

func _recycle() -> void:
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.despawn(self)
	else:
		queue_free()
