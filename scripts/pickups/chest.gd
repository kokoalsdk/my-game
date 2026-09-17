class_name Chest
extends Area2D

## 엘리트/보스 처치 시 드랍되는 보물상자

signal chest_opened(collector: Node2D)

var is_collected: bool = false
var _float_time: float = 0.0

func _ready() -> void:
	add_to_group("pickup")
	# Layer 5 (Pickup = 16)
	collision_layer = 16
	collision_mask = 0
	
	# 드랍 팝업 트윈
	scale = Vector2(0.2, 0.2)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_float_time += delta * 4.0
	queue_redraw()

func collect_by(collector: Node2D) -> void:
	if is_collected:
		return
	is_collected = true
	
	chest_opened.emit(collector)
	
	if collector.has_method("collect_chest"):
		collector.call("collect_chest", self)
	elif collector.has_signal("chest_collected"):
		collector.emit_signal("chest_collected", self)
	elif collector.has_method("on_chest_collected"):
		collector.call("on_chest_collected", self)
	
	# 상자 획득 시 화려한 황금빛 팝업 후 소멸
	var pop_tween = create_tween().set_parallel(true)
	pop_tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	pop_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	pop_tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var float_offset = sin(_float_time) * 3.0
	var center = Vector2(0, float_offset)
	
	# 1. 황금빛 외곽 광채
	draw_circle(center, 18.0, Color(1.0, 0.85, 0.2, 0.3))
	draw_circle(center, 14.0, Color(1.0, 0.9, 0.4, 0.45))
	
	# 2. 상자 몸체 (갈색 / 목재 톤)
	var body_rect = Rect2(center.x - 12, center.y - 6, 24, 16)
	draw_rect(body_rect, Color(0.65, 0.42, 0.2), true)
	
	# 3. 상자 뚜껑 (황금 림)
	var lid_rect = Rect2(center.x - 13, center.y - 12, 26, 8)
	draw_rect(lid_rect, Color(0.95, 0.75, 0.2), true)
	draw_rect(lid_rect, Color(1.0, 0.9, 0.5), false, 2.0)
	
	# 4. 자물쇠 (황금 잠금장치)
	draw_circle(Vector2(center.x, center.y - 4), 3.0, Color(1.0, 0.95, 0.6))
	draw_circle(Vector2(center.x, center.y - 4), 1.5, Color(0.2, 0.15, 0.05))
