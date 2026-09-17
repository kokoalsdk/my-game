class_name EquipmentManager
extends Node

## 무기 및 패시브 장비 슬롯 관리 매니저
## 장착, 레벨업, 스탯 재계산 및 유효한 업그레이드 목록 필터링을 담당합니다.

signal equipment_updated
signal weapon_acquired(data: WeaponData, level: int)
signal passive_acquired(data: PassiveData, level: int)

@export var max_weapon_slots: int = 4
@export var max_passive_slots: int = 4

## 시작 기본 무기 데이터
@export var starting_weapon: WeaponData = preload("res://resources/weapons/magic_wand.tres")

## { "id": { "data": WeaponData, "instance": WeaponBase, "level": int } }
var equipped_weapons: Dictionary = {}

## { "id": { "data": PassiveData, "level": int } }
var equipped_passives: Dictionary = {}

## 진화 전 무기들의 피해량 아카이브
var archived_weapons: Array[Dictionary] = []

var player: Player = null

func _ready() -> void:
	if get_parent() is Player:
		player = get_parent() as Player
	
	# 시작 기본 무기 등록
	if starting_weapon:
		equip_or_upgrade_weapon(starting_weapon)

## 무기 장착 또는 레벨업 가능 여부
func can_equip_weapon(data: WeaponData) -> bool:
	if not data:
		return false
	if equipped_weapons.has(data.id):
		return equipped_weapons[data.id].level < data.max_level
	return equipped_weapons.size() < max_weapon_slots

## 패시브 장착 또는 레벨업 가능 여부
func can_equip_passive(data: PassiveData) -> bool:
	if not data:
		return false
	if equipped_passives.has(data.id):
		return equipped_passives[data.id].level < data.max_level
	return equipped_passives.size() < max_passive_slots

## 무기 획득 / 레벨업
func equip_or_upgrade_weapon(data: WeaponData) -> bool:
	if not can_equip_weapon(data):
		return false
	
	if equipped_weapons.has(data.id):
		var info = equipped_weapons[data.id]
		info.level += 1
		if info.instance and info.instance.has_method("upgrade_to"):
			info.instance.upgrade_to(info.level)
		weapon_acquired.emit(data, info.level)
	else:
		# 신규 무기 생성
		var instance: WeaponBase = null
		if data.weapon_scene:
			instance = data.weapon_scene.instantiate() as WeaponBase
			var weapons_container = player.get_node_or_null("Weapons")
			if weapons_container:
				weapons_container.add_child(instance)
			else:
				player.add_child(instance)
		
		equipped_weapons[data.id] = {
			"data": data,
			"instance": instance,
			"level": 1
		}
		weapon_acquired.emit(data, 1)
	
	recalculate_stats()
	equipment_updated.emit()
	return true

## 현재 진화 조건을 충족한 무기 목록 반환
func check_evolvable_weapons() -> Array[WeaponData]:
	var evolvables: Array[WeaponData] = []
	for id in equipped_weapons.keys():
		var info = equipped_weapons[id]
		var w_data = info.data as WeaponData
		if w_data and w_data.can_evolve(self):
			evolvables.append(w_data)
	return evolvables

## 무기 진화 실행 (기존 무기 인스턴스 제거 -> 진화 무기 장착)
func evolve_weapon(base_data: WeaponData) -> WeaponData:
	if not base_data or not base_data.evolution_weapon:
		return null
	
	var evo_data = base_data.evolution_weapon
	
	# 기존 무기 인스턴스 정보 아카이빙 및 제거
	if equipped_weapons.has(base_data.id):
		var old_info = equipped_weapons[base_data.id]
		var old_dmg = 0.0
		if is_instance_valid(old_info.instance) and "total_damage" in old_info.instance:
			old_dmg = old_info.instance.total_damage
		archived_weapons.append({
			"id": base_data.id,
			"name": base_data.weapon_name,
			"level": old_info.level,
			"damage": old_dmg,
			"icon": base_data.icon
		})
		if is_instance_valid(old_info.instance):
			old_info.instance.queue_free()
		equipped_weapons.erase(base_data.id)
	
	# 진화 무기 인스턴스 생성 및 부착
	var instance: WeaponBase = null
	if evo_data.weapon_scene and is_instance_valid(player):
		instance = evo_data.weapon_scene.instantiate() as WeaponBase
		var weapons_container = player.get_node_or_null("Weapons")
		if weapons_container:
			weapons_container.add_child(instance)
		else:
			player.add_child(instance)
	
	equipped_weapons[evo_data.id] = {
		"data": evo_data,
		"instance": instance,
		"level": 1
	}
	
	recalculate_stats()
	weapon_acquired.emit(evo_data, 1)
	equipment_updated.emit()
	return evo_data

## 패시브 획득 / 레벨업
func equip_or_upgrade_passive(data: PassiveData) -> bool:
	if not can_equip_passive(data):
		return false
	
	if equipped_passives.has(data.id):
		var info = equipped_passives[data.id]
		info.level += 1
		passive_acquired.emit(data, info.level)
	else:
		equipped_passives[data.id] = {
			"data": data,
			"level": 1
		}
		passive_acquired.emit(data, 1)
	
	recalculate_stats()
	equipment_updated.emit()
	return true

## 플레이어 스탯 재계산
func recalculate_stats() -> void:
	if not is_instance_valid(player):
		return
	
	# 기본 베이스 스탯 초기화
	var dmg_mult = 1.0
	var spd = 180.0
	var cd_mult = 1.0
	var radius = 70.0
	var extra_proj = 0
	var extra_hp = 0.0
	
	for id in equipped_passives.keys():
		var info = equipped_passives[id]
		var data = info.data as PassiveData
		var lvl = info.level as int
		var total_bonus = lvl * data.bonus_value_per_level
		
		match data.passive_type:
			PassiveData.PassiveType.MIGHT:
				dmg_mult += total_bonus
			PassiveData.PassiveType.MOVE_SPEED:
				spd += 180.0 * total_bonus
			PassiveData.PassiveType.COOLDOWN:
				cd_mult = maxf(0.2, cd_mult - total_bonus)
			PassiveData.PassiveType.MAGNET:
				radius += 70.0 * total_bonus
			PassiveData.PassiveType.MAX_HEALTH:
				extra_hp += lvl * 20.0
			PassiveData.PassiveType.PROJECTILE_COUNT:
				extra_proj += int(total_bonus)
	
	player.damage_multiplier = dmg_mult
	player.max_speed = spd
	player.cooldown_multiplier = cd_mult
	player.set_pickup_radius(radius)
	player.extra_projectiles = extra_proj
	
	if extra_hp > 0 and player.health_component:
		player.health_component.max_health = 100.0 + extra_hp
	
	# 장착된 모든 무기에 쿨다운 갱신 전달
	for id in equipped_weapons.keys():
		var info = equipped_weapons[id]
		if info.instance and info.instance.has_method("update_cooldown"):
			info.instance.update_cooldown()

## 레벨업 선택지 후보 필터링
func get_available_upgrades(all_weapons: Array[WeaponData], all_passives: Array[PassiveData]) -> Array[Resource]:
	var candidates: Array[Resource] = []
	
	for w in all_weapons:
		if can_equip_weapon(w):
			candidates.append(w)
	
	for p in all_passives:
		if can_equip_passive(p):
			candidates.append(p)
	
	return candidates

## 무기별 총 피해량 및 DPS 정산 목록 반환
func get_weapon_stats_summary(survival_time: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_all_dmg: float = 0.0
	
	# 1. 아카이브된 진화 전 무기들
	for arch in archived_weapons:
		var dmg = float(arch.get("damage", 0.0))
		total_all_dmg += dmg
		result.append({
			"id": arch.get("id", ""),
			"name": arch.get("name", "무기"),
			"level": int(arch.get("level", 1)),
			"damage": dmg,
			"icon": arch.get("icon", null)
		})
	
	# 2. 현재 장착 중인 무기들
	for w_id in equipped_weapons.keys():
		var info = equipped_weapons[w_id]
		var data = info.data as WeaponData
		var inst = info.instance
		var lvl = int(info.level)
		var dmg = 0.0
		if is_instance_valid(inst) and "total_damage" in inst:
			dmg = float(inst.total_damage)
		total_all_dmg += dmg
		result.append({
			"id": w_id,
			"name": data.weapon_name if data else w_id,
			"level": lvl,
			"damage": dmg,
			"icon": data.icon if data else null
		})
	
	# 3. DPS 및 점유율 계산
	var s_time = maxf(1.0, survival_time)
	for item in result:
		var d = float(item["damage"])
		item["dps"] = d / s_time
		if total_all_dmg > 0.0:
			item["damage_percent"] = (d / total_all_dmg) * 100.0
		else:
			item["damage_percent"] = 0.0
	
	# 피해량 내림차순 정렬
	result.sort_custom(func(a, b): return a["damage"] > b["damage"])
	return result
