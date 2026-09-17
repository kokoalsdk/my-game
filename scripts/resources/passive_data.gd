class_name PassiveData
extends Resource

## 패시브 아이템 데이터 리소스
## 스탯 강화 종류, 레벨당 증가 수치, 레벨업 설명을 정의합니다.

enum PassiveType {
	MIGHT,            ## 공격력 배수 증가 (+10% / Lv)
	MOVE_SPEED,       ## 이동 속도 증가 (+10% / Lv)
	COOLDOWN,         ## 쿨다운 감소 (-8% / Lv)
	MAGNET,           ## 자석 반경 증가 (+25% / Lv)
	MAX_HEALTH,       ## 최대 체력 증가 (+20 / Lv)
	PROJECTILE_COUNT  ## 투사체 수 증가 (+1 / Lv)
}

@export_group("기본 정보")
@export var id: String = ""
@export var passive_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var max_level: int = 5

@export_group("스탯 효과")
@export var passive_type: PassiveType = PassiveType.MIGHT
@export var bonus_value_per_level: float = 0.1
@export var level_descriptions: Array[String] = []

## 특정 레벨로 업그레이드 시 표시될 설명 반환
func get_upgrade_description(target_level: int) -> String:
	var idx = target_level - 2
	if idx >= 0 and idx < level_descriptions.size():
		return level_descriptions[idx]
	return "%s 효과 증대" % passive_name
