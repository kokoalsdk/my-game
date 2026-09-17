class_name DeathParticles
extends CPUParticles2D

## 몬스터 사망 시 폭발하며 흩어지는 버스트 파티클

func _ready() -> void:
	finished.connect(_recycle)

func setup_color(col: Color, scale_mult: float = 1.0) -> void:
	color = col
	scale_amount_min = 2.0 * scale_mult
	scale_amount_max = 4.5 * scale_mult
	amount = int(18 * scale_mult)
	restart()
	emitting = true

func _recycle() -> void:
	var pm = get_node_or_null("/root/PoolManager")
	if pm:
		pm.despawn(self)
	else:
		queue_free()
