class_name HUD
extends CanvasLayer

## 인게임 HUD 및 게임오버 UI 제어 스크립트

@onready var exp_bar: ProgressBar = $Control/TopBar/ExpProgressBar
@onready var level_label: Label = $Control/TopBar/LevelLabel
@onready var time_label: Label = $Control/TopBar/TimeLabel
@onready var health_bar: ProgressBar = $Control/HealthContainer/HealthProgressBar
@onready var health_label: Label = $Control/HealthContainer/HealthLabel

@onready var result_screen: ResultScreen = $Control/ResultScreen
@onready var level_up_screen: LevelUpScreen = $Control/LevelUpScreen
@onready var chest_reward_screen: ChestRewardScreen = $Control/ChestRewardScreen
@onready var pause_menu: PauseMenu = $Control/PauseMenu
@onready var warning_banner: PanelContainer = $Control/WarningBanner
@onready var warning_label: Label = $Control/WarningBanner/WarningLabel
@onready var kill_label: Label = $Control/TopBar/RightStats/KillLabel
@onready var gold_label: Label = $Control/TopBar/RightStats/GoldLabel

var player: Player = null
var survival_time: float = 0.0
var is_game_over: bool = false
var _warning_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if result_screen:
		result_screen.visible = false
	if warning_banner:
		warning_banner.visible = false
	if pause_menu:
		pause_menu.visible = false
	
	_connect_to_player()
	_connect_to_spawner()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		# 결과창, 레벨업 창, 상자 개봉 창이 열려있으면 ESC 일시정지 무시
		if is_game_over or (result_screen and result_screen.visible) or (level_up_screen and level_up_screen.visible) or (chest_reward_screen and chest_reward_screen.visible):
			return
		
		get_viewport().set_input_as_handled()
		if pause_menu:
			if pause_menu.visible:
				pause_menu.close()
			else:
				pause_menu.open(player, survival_time)

func _connect_to_spawner() -> void:
	var spawners = get_tree().get_nodes_in_group("spawner")
	if spawners.size() > 0:
		var spawner = spawners[0]
		if spawner.has_signal("warning_announced"):
			spawner.warning_announced.connect(show_warning)
		if spawner.has_signal("stage_cleared"):
			spawner.stage_cleared.connect(_on_stage_cleared)

func _connect_to_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		player = players[0] as Player
		player.health_updated.connect(_on_player_health_updated)
		player.exp_updated.connect(_on_player_exp_updated)
		player.level_up.connect(_on_player_level_up)
		player.chest_collected.connect(_on_player_chest_collected)
		player.gold_changed.connect(_on_player_gold_changed)
		player.kill_count_changed.connect(_on_player_kill_count_changed)
		player.player_died.connect(_on_player_died)
		
		# 초기값 반영
		_on_player_health_updated(player.health_component.current_health, player.health_component.max_health)
		_on_player_exp_updated(player.current_exp, player.required_exp, player.current_level)
		_on_player_gold_changed(player.current_gold, 0)
		_on_player_kill_count_changed(player.kill_count)

func _process(delta: float) -> void:
	if not is_game_over:
		survival_time += delta
		var minutes: int = int(survival_time / 60.0)
		var seconds: int = int(survival_time) % 60
		if time_label:
			time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_player_health_updated(current_hp: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	if health_label:
		health_label.text = "%d / %d" % [int(ceil(current_hp)), int(max_hp)]

func _on_player_exp_updated(current_exp: int, required_exp: int, level: int) -> void:
	if exp_bar:
		exp_bar.max_value = required_exp
		exp_bar.value = current_exp
	if level_label:
		level_label.text = "LV. %d" % level

func _on_player_gold_changed(total_gold: int, _gained: int) -> void:
	if gold_label:
		gold_label.text = "🪙 %d" % total_gold

func _on_player_kill_count_changed(total_kills: int) -> void:
	if kill_label:
		kill_label.text = "💀 %d" % total_kills

func _on_player_level_up(_new_level: int) -> void:
	if level_up_screen and is_instance_valid(player):
		level_up_screen.queue_level_up(player)

func _on_player_chest_collected(_chest: Node) -> void:
	if chest_reward_screen and is_instance_valid(player):
		chest_reward_screen.open_chest(player)

func _on_player_died() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	if pause_menu:
		pause_menu.visible = false
	
	# 사망 후 짧은 딜레이 후 결과 창 표시
	await get_tree().create_timer(0.4).timeout
	if result_screen and is_instance_valid(player):
		result_screen.show_results(player, survival_time, false)

func _on_stage_cleared() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	if pause_menu:
		pause_menu.visible = false
	
	await get_tree().create_timer(0.5).timeout
	if result_screen and is_instance_valid(player):
		result_screen.show_results(player, survival_time, true)

## 경고 알림 배너 표시 (포위 무리, 보스 출현 등)
func show_warning(text: String, duration: float = 2.8) -> void:
	if not warning_banner or not warning_label:
		return
	
	warning_label.text = text
	warning_banner.visible = true
	
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()
	
	warning_banner.modulate.a = 0.0
	_warning_tween = create_tween()
	_warning_tween.tween_property(warning_banner, "modulate:a", 1.0, 0.25)
	_warning_tween.tween_interval(duration)
	_warning_tween.tween_property(warning_banner, "modulate:a", 0.0, 0.35)
	_warning_tween.tween_callback(func(): warning_banner.visible = false)
