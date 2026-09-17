class_name HealthComponent
extends Node

## 체력 및 데미지/회복 처리를 담당하는 공용 컴포넌트

signal health_changed(current_hp: float, max_hp: float)
signal health_depleted
signal damaged(amount: float)
signal healed(amount: float)

@export var max_health: float = 100.0 : set = set_max_health
@export var current_health: float = 100.0

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func set_max_health(value: float) -> void:
	max_health = max(1.0, value)
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func damage(amount: float) -> void:
	if is_dead or amount <= 0:
		return
	
	current_health = max(0.0, current_health - amount)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0 and not is_dead:
		is_dead = true
		health_depleted.emit()

func heal(amount: float) -> void:
	if is_dead or amount <= 0:
		return
	
	current_health = min(max_health, current_health + amount)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)

func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
