class_name WeaponData
extends Resource

## 무기 데이터 리소스
## 무기 스탯, 레벨별 설명, 인스턴스 씬 및 진화 조건을 정의합니다.

@export_group("기본 정보")
@export var id: String = ""
@export var weapon_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var weapon_scene: PackedScene = null
@export var max_level: int = 8

@export_group("스탯")
@export var base_damage: float = 12.0
@export var base_cooldown: float = 1.2
@export var base_speed: float = 450.0
@export var base_pierce: int = 1
@export var base_projectile_count: int = 1
@export var area_scale: float = 1.0
@export var knockback: float = 100.0

@export_group("레벨업 설명")
@export var level_descriptions: Array[String] = []

@export_group("진화 (Phase 3 준비)")
@export var evolution_weapon: WeaponData = null
@export var required_passive: Resource = null

## 특정 레벨로 업그레이드 시 표시될 설명 반환
func get_upgrade_description(target_level: int) -> String:
	var idx = target_level - 2 # 레벨 2 업그레이드 설명은 인덱스 0
	if idx >= 0 and idx < level_descriptions.size():
		return level_descriptions[idx]
	return "무기 위력 증가"

## 진화 조건 충족 여부 확인 (EquipmentManager 기준)
func can_evolve(em: Node) -> bool:
	if not evolution_weapon or not required_passive:
		return false
	if not ("equipped_weapons" in em) or not ("equipped_passives" in em):
		return false
	
	# 1. 원본 무기가 최대 레벨(Lv 8)에 도달했는지 확인
	if not em.equipped_weapons.has(id):
		return false
	if em.equipped_weapons[id].level < max_level:
		return false
	
	# 2. 조합에 필요한 패시브 아이템을 최소 1레벨 이상 보유하고 있는지 확인
	var passive_id = required_passive.get("id")
	if not em.equipped_passives.has(passive_id):
		return false
	
	return true
