class_name PerformanceMonitor
extends CanvasLayer

## 실시간 게임 성능 및 엔티티 풀링 모니터링 HUD
## F3 키를 눌러 오버레이를 켜고 끌 수 있습니다.

var _panel: PanelContainer
var _label: Label
var _update_timer: float = 0.0

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	visible = false # 기본 숨김, F3으로 토글

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			visible = not visible

func _setup_ui() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.position = Vector2(16, 75)
	
	# 반투명 어두운 배경 스타일박스
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.82)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.3, 0.6, 0.8, 0.5)
	_panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)
	
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	margin.add_child(_label)
	
	add_child(_panel)

func _process(delta: float) -> void:
	if not visible:
		return
	
	_update_timer += delta
	if _update_timer >= 0.15: # 0.15초마다 가볍게 갱신
		_update_timer = 0.0
		_refresh_display()

func _refresh_display() -> void:
	if not _label:
		return
	
	var fps = Engine.get_frames_per_second()
	var proc_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
	
	var enemies_count = get_tree().get_nodes_in_group("enemy").size()
	var pickups_count = get_tree().get_nodes_in_group("pickup").size()
	
	var pm = get_node_or_null("/root/PoolManager")
	var pool_active = 0
	var pool_cached = 0
	var total_reused = 0
	if pm:
		var st = pm.get_stats()
		pool_active = st.get("total_active", 0)
		pool_cached = st.get("total_pooled", 0)
		total_reused = st.get("total_reused", 0)
	
	_label.text = "⚡ PERFORMANCE DEBUG (F3 토글)\n" \
		+ "• FPS: %d (Proc: %.1fms | Phys: %.1fms)\n" % [fps, proc_time, phys_time] \
		+ "• Static Memory: %.2f MB\n" % mem_mb \
		+ "• Active Enemies: %d 마리\n" % enemies_count \
		+ "• Active Pickups: %d 개 (보석 병합 최적화 작동 중)\n" % pickups_count \
		+ "• Object Pool: 활성 %d개 / 대기 %d개 (누적 재사용 %d회)" % [pool_active, pool_cached, total_reused]
