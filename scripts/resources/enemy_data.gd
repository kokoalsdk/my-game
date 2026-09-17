class_name EnemyData
extends Resource

## 몬스터 데이터 리소스
## 체력, 이동 속도, 접촉 데미지, 경험치량 및 외형 정보를 정의합니다.

@export_group("기본 정보")
@export var id: String = ""
@export var enemy_name: String = ""
@export var sprite_texture: Texture2D = null
@export var modulate_color: Color = Color(1.0, 0.6, 0.6, 1.0)
@export var scale_multiplier: float = 1.0

@export_group("전투 스탯")
@export var max_health: float = 20.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 8.0
@export var knockback_decay: float = 600.0
@export var knockback_resistance: float = 0.0 # 0.0: 보통, 1.0: 넉백 면역
@export var experience_value: int = 1

@export_group("드랍")
@export var drop_gem_scene: PackedScene = null

## EnemyBase 노드에 스펙 적용
func apply_to_enemy(enemy: EnemyBase) -> void:
	if not enemy:
		return
	
	enemy.max_health = max_health
	enemy.move_speed = move_speed
	enemy.contact_damage = contact_damage
	enemy.knockback_decay = knockback_decay
	enemy.experience_value = experience_value
	
	if drop_gem_scene:
		enemy.drop_gem_scene = drop_gem_scene
	
	if enemy.sprite:
		if sprite_texture:
			enemy.sprite.texture = sprite_texture
		enemy.sprite.modulate = modulate_color
		enemy.sprite.scale = Vector2(0.2, 0.2) * scale_multiplier
