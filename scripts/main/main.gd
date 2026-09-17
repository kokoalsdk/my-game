class_name Main
extends Node2D

## 메인 게임 씬 컨트롤러
## 플레이어 이동 시 공간감을 주는 배경 그리드를 렌더링합니다.

@export var grid_size: float = 64.0
@export var grid_color: Color = Color(0.18, 0.22, 0.28, 0.7)

func _ready() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_bgm("battle")
	
	# F3 성능 모니터링 오버레이 추가
	var perf_mon = PerformanceMonitor.new()
	add_child(perf_mon)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam = get_viewport().get_camera_2d()
	var center = cam.global_position if cam else Vector2.ZERO
	var view_size = get_viewport_rect().size * 1.5
	
	var start_x = int((center.x - view_size.x) / grid_size) * grid_size
	var end_x = int((center.x + view_size.x) / grid_size) * grid_size
	var start_y = int((center.y - view_size.y) / grid_size) * grid_size
	var end_y = int((center.y + view_size.y) / grid_size) * grid_size
	
	for x in range(int(start_x), int(end_x) + int(grid_size), int(grid_size)):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
	for y in range(int(start_y), int(end_y) + int(grid_size), int(grid_size)):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
