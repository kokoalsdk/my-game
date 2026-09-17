class_name PoolManagerNode
extends Node

## 대규모 엔티티 성능 최적화를 위한 범용 오브젝트 풀링 싱글톤
## 투사체, 보석, 몬스터, 파티클, 데미지 숫자의 빈번한 instantiate() / queue_free() 방지

var _pools: Dictionary = {} # Dictionary[String, Array[Node]]
var _active_counts: Dictionary = {} # Dictionary[String, int]
var _total_spawned_count: int = 0
var _total_reused_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 풀에서 인스턴스를 가져오거나 새로 생성
func spawn(packed_scene: PackedScene, parent: Node = null) -> Node:
	if not packed_scene:
		return null
	
	var scene_key = packed_scene.resource_path
	if scene_key == "":
		scene_key = str(packed_scene.get_instance_id())
	
	if not _pools.has(scene_key):
		_pools[scene_key] = []
		_active_counts[scene_key] = 0
	
	var pool_list: Array = _pools[scene_key]
	var instance: Node = null
	
	# 유효한 비활성 인스턴스 검색
	while pool_list.size() > 0:
		var candidate = pool_list.pop_back()
		if is_instance_valid(candidate):
			instance = candidate
			_total_reused_count += 1
			break
	
	# 풀에 가용 인스턴스가 없으면 새로 인스턴스화
	if not instance:
		instance = packed_scene.instantiate()
		instance.set_meta("pool_scene_key", scene_key)
		_total_spawned_count += 1
	
	_active_counts[scene_key] = _active_counts.get(scene_key, 0) + 1
	
	# 부모 노드에 부착
	var target_parent = parent
	if not target_parent:
		target_parent = get_tree().current_scene
	
	if instance.get_parent() != target_parent:
		if instance.get_parent():
			instance.get_parent().remove_child(instance)
		if target_parent:
			_prepare_area_monitoring(instance)
			target_parent.add_child(instance)
	
	# 프로세스 및 표시 복원
	instance.visible = true
	instance.set_process(true)
	instance.set_physics_process(true)
	
	# CollisionShape2D 활성화 (있는 경우)
	_toggle_collisions(instance, false)
	
	return instance

## 사용이 끝난 인스턴스를 풀로 반환
func despawn(instance: Node) -> void:
	if not is_instance_valid(instance):
		return
	
	if not instance.has_meta("pool_scene_key"):
		# 풀에서 생성되지 않은 객체는 표준 queue_free()
		instance.queue_free()
		return
	
	var scene_key: String = instance.get_meta("pool_scene_key")
	if not _pools.has(scene_key):
		_pools[scene_key] = []
	
	# 이미 풀에 반환되어 있는지 중복 체크
	var pool_list: Array = _pools[scene_key]
	if instance in pool_list:
		return
	
	# 프로세스 및 표시 비활성화
	instance.visible = false
	instance.set_process(false)
	instance.set_physics_process(false)
	
	# 충돌체 비활성화 (부하 방지)
	_toggle_collisions(instance, true)
	
	pool_list.append(instance)
	
	if _active_counts.has(scene_key) and _active_counts[scene_key] > 0:
		_active_counts[scene_key] -= 1

## 충돌체 활성/비활성화 처리
func _toggle_collisions(node: Node, disabled_state: bool) -> void:
	if node is CollisionShape2D:
		(node as CollisionShape2D).set_deferred("disabled", disabled_state)
	elif node is CollisionPolygon2D:
		(node as CollisionPolygon2D).set_deferred("disabled", disabled_state)
	
	for child in node.get_children():
		_toggle_collisions(child, disabled_state)

## Area2D 노드가 물리 쿼리 플러싱 도중 씬 트리에 추가될 때 모니터링 상태 충돌 에러 방지
func _prepare_area_monitoring(node: Node) -> void:
	if node is Area2D and (node as Area2D).monitoring:
		(node as Area2D).monitoring = false
		(node as Area2D).set_deferred("monitoring", true)
	for child in node.get_children():
		_prepare_area_monitoring(child)

## 모든 풀 초기화 (씬 전환 시 호출)
func clear_all() -> void:
	for scene_key in _pools.keys():
		var pool_list: Array = _pools[scene_key]
		for item in pool_list:
			if is_instance_valid(item):
				item.queue_free()
	_pools.clear()
	_active_counts.clear()

## 성능 모니터링용 통계 반환
func get_stats() -> Dictionary:
	var total_pooled = 0
	var total_active = 0
	for k in _pools.keys():
		total_pooled += _pools[k].size()
		total_active += _active_counts.get(k, 0)
	
	return {
		"total_pooled": total_pooled,
		"total_active": total_active,
		"total_spawned": _total_spawned_count,
		"total_reused": _total_reused_count,
		"pools_count": _pools.size()
	}
