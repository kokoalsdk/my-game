extends Node

## 세이브/로드 및 영구 강화(메타 프로그레션) 데이터 관리 싱글톤
## user://save_data.json 기반 영구 저장

signal data_loaded
signal data_saved
signal gold_changed(total_gold: int, delta: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal upgrades_refunded(refunded_gold: int)

const SAVE_FILE_PATH: String = "user://save_data.json"

## 영구 강화 항목 설정 메타데이터
const UPGRADE_CONFIGS: Dictionary = {
	"might": {
		"name": "공격력",
		"description": "기본 공격 피해량 +5% 증가",
		"base_cost": 100,
		"cost_mult": 1.5,
		"max_level": 5,
		"bonus_per_level": 0.05,
		"unit": "%"
	},
	"health": {
		"name": "최대 체력",
		"description": "최대 체력 +10 HP 증가",
		"base_cost": 80,
		"cost_mult": 1.4,
		"max_level": 5,
		"bonus_per_level": 10.0,
		"unit": "HP"
	},
	"speed": {
		"name": "이동 속도",
		"description": "플레이어 이동 속도 +5% 증가",
		"base_cost": 100,
		"cost_mult": 1.5,
		"max_level": 5,
		"bonus_per_level": 0.05,
		"unit": "%"
	},
	"magnet": {
		"name": "자석 범위",
		"description": "아이템 획득 반경 +10% 증가",
		"base_cost": 90,
		"cost_mult": 1.4,
		"max_level": 5,
		"bonus_per_level": 0.10,
		"unit": "%"
	},
	"exp_gain": {
		"name": "경험치 획득량",
		"description": "보석 획득 경험치 +5% 증가",
		"base_cost": 120,
		"cost_mult": 1.6,
		"max_level": 5,
		"bonus_per_level": 0.05,
		"unit": "%"
	}
}

var _data: Dictionary = {
	"gold": 0,
	"permanent_upgrades": {
		"might": 0,
		"health": 0,
		"speed": 0,
		"magnet": 0,
		"exp_gain": 0
	},
	"unlocked_weapons": [
		"magic_wand",
		"orbit_orb",
		"lightning_ring",
		"garlic_aura"
	],
	"stats": {
		"total_games": 0,
		"total_kills": 0,
		"total_gold_earned": 0,
		"best_survival_time": 0.0,
		"best_level": 1
	}
}

func _ready() -> void:
	load_game()

## 기본 데이터 복사본 생성
func _get_default_data() -> Dictionary:
	return {
		"gold": 0,
		"permanent_upgrades": {
			"might": 0,
			"health": 0,
			"speed": 0,
			"magnet": 0,
			"exp_gain": 0
		},
		"unlocked_weapons": [
			"magic_wand",
			"orbit_orb",
			"lightning_ring",
			"garlic_aura"
		],
		"stats": {
			"total_games": 0,
			"total_kills": 0,
			"total_gold_earned": 0,
			"best_survival_time": 0.0,
			"best_level": 1
		}
	}

## 게임 데이터 저장 (JSON)
func save_game() -> bool:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		push_error("세이브 파일 생성 실패: %s" % FileAccess.get_open_error())
		return false
	
	var json_str = JSON.stringify(_data, "\t")
	file.store_string(json_str)
	file.close()
	data_saved.emit()
	return true

## 게임 데이터 로드 (JSON)
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		_data = _get_default_data()
		save_game()
		data_loaded.emit()
		return true
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_warning("세이브 파일 열기 실패. 기본 데이터 사용.")
		_data = _get_default_data()
		return false
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		push_error("JSON 파싱 에러 (줄 %d): %s. 기본 데이터로 대체합니다." % [json.get_error_line(), json.get_error_message()])
		_data = _get_default_data()
		return false
	
	if json.data is Dictionary:
		_merge_loaded_data(json.data)
		data_loaded.emit()
		return true
	else:
		_data = _get_default_data()
		return false

## 로드된 데이터와 기본 스키마 병합 (누락된 키 방지)
func _merge_loaded_data(loaded: Dictionary) -> void:
	var default_data = _get_default_data()
	
	_data["gold"] = int(loaded.get("gold", default_data["gold"]))
	
	# 영구 강화 레벨 병합
	var loaded_upgrades: Dictionary = loaded.get("permanent_upgrades", {})
	for key in default_data["permanent_upgrades"].keys():
		_data["permanent_upgrades"][key] = int(loaded_upgrades.get(key, 0))
	
	# 해금 목록
	_data["unlocked_weapons"] = loaded.get("unlocked_weapons", default_data["unlocked_weapons"])
	
	# 통계 데이터 병합
	var loaded_stats: Dictionary = loaded.get("stats", {})
	_data["stats"]["total_games"] = int(loaded_stats.get("total_games", 0))
	_data["stats"]["total_kills"] = int(loaded_stats.get("total_kills", 0))
	_data["stats"]["total_gold_earned"] = int(loaded_stats.get("total_gold_earned", 0))
	_data["stats"]["best_survival_time"] = float(loaded_stats.get("best_survival_time", 0.0))
	_data["stats"]["best_level"] = int(loaded_stats.get("best_level", 1))

## 세이브 데이터 초기화
func reset_save_data() -> void:
	_data = _get_default_data()
	save_game()
	data_loaded.emit()

# --- 골드 관련 ---
func get_gold() -> int:
	return _data.get("gold", 0)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_data["gold"] += amount
	gold_changed.emit(_data["gold"], amount)
	save_game()

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	if _data["gold"] < amount:
		return false
	_data["gold"] -= amount
	gold_changed.emit(_data["gold"], -amount)
	save_game()
	return true

# --- 영구 업그레이드 관련 ---
func get_upgrade_level(upgrade_id: String) -> int:
	return _data.get("permanent_upgrades", {}).get(upgrade_id, 0)

func get_max_upgrade_level(upgrade_id: String) -> int:
	if UPGRADE_CONFIGS.has(upgrade_id):
		return UPGRADE_CONFIGS[upgrade_id]["max_level"]
	return 5

func get_upgrade_cost(upgrade_id: String) -> int:
	if not UPGRADE_CONFIGS.has(upgrade_id):
		return -1
	var lvl = get_upgrade_level(upgrade_id)
	var cfg = UPGRADE_CONFIGS[upgrade_id]
	if lvl >= cfg["max_level"]:
		return -1 # 이미 최고 레벨
	return int(round(cfg["base_cost"] * pow(cfg["cost_mult"], lvl)))

func can_purchase_upgrade(upgrade_id: String) -> bool:
	var cost = get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false
	return _data["gold"] >= cost

func purchase_upgrade(upgrade_id: String) -> bool:
	var cost = get_upgrade_cost(upgrade_id)
	if cost < 0 or _data["gold"] < cost:
		return false
	
	_data["gold"] -= cost
	var cur_lvl = get_upgrade_level(upgrade_id)
	_data["permanent_upgrades"][upgrade_id] = cur_lvl + 1
	
	gold_changed.emit(_data["gold"], -cost)
	upgrade_purchased.emit(upgrade_id, cur_lvl + 1)
	save_game()
	return true

## 모든 영구 업그레이드 100% 골드 환불
func refund_all_upgrades() -> int:
	var total_refund = 0
	for up_id in UPGRADE_CONFIGS.keys():
		var lvl = get_upgrade_level(up_id)
		var cfg = UPGRADE_CONFIGS[up_id]
		for l in range(lvl):
			total_refund += int(round(cfg["base_cost"] * pow(cfg["cost_mult"], l)))
		_data["permanent_upgrades"][up_id] = 0
	
	if total_refund > 0:
		_data["gold"] += total_refund
		gold_changed.emit(_data["gold"], total_refund)
	
	upgrades_refunded.emit(total_refund)
	save_game()
	return total_refund

## 강화 보너스 수치 반환 (레벨 * bonus_per_level)
func get_upgrade_bonus(upgrade_id: String) -> float:
	if not UPGRADE_CONFIGS.has(upgrade_id):
		return 0.0
	var lvl = get_upgrade_level(upgrade_id)
	return lvl * UPGRADE_CONFIGS[upgrade_id]["bonus_per_level"]

## 플레이어에게 영구 스탯 적용
func apply_to_player(player: Node) -> void:
	if not is_instance_valid(player):
		return
	
	# 체력 보너스
	var hp_bonus = get_upgrade_bonus("health")
	if hp_bonus > 0 and "health_component" in player and player.health_component:
		player.health_component.max_health += hp_bonus
		player.health_component.current_health = player.health_component.max_health
	
	# 공격력 보너스
	var might_bonus = get_upgrade_bonus("might")
	if might_bonus > 0 and "damage_multiplier" in player:
		player.damage_multiplier += might_bonus
	
	# 이동 속도 보너스
	var speed_bonus = get_upgrade_bonus("speed")
	if speed_bonus > 0 and "max_speed" in player:
		player.max_speed *= (1.0 + speed_bonus)
	
	# 자석 범위 보너스
	var magnet_bonus = get_upgrade_bonus("magnet")
	if magnet_bonus > 0 and "pickup_radius" in player:
		player.pickup_radius *= (1.0 + magnet_bonus)
	
	# 경험치 보너스
	var exp_bonus = get_upgrade_bonus("exp_gain")
	if exp_bonus > 0 and "exp_multiplier" in player:
		player.exp_multiplier += exp_bonus

# --- 런 결과 기록 ---
func record_run_results(survival_time: float, kills: int, gold_earned: int, level: int) -> void:
	var stats: Dictionary = _data["stats"]
	stats["total_games"] = stats.get("total_games", 0) + 1
	stats["total_kills"] = stats.get("total_kills", 0) + kills
	stats["total_gold_earned"] = stats.get("total_gold_earned", 0) + gold_earned
	stats["best_survival_time"] = maxf(stats.get("best_survival_time", 0.0), survival_time)
	stats["best_level"] = maxi(stats.get("best_level", 1), level)
	
	if gold_earned > 0:
		_data["gold"] += gold_earned
		gold_changed.emit(_data["gold"], gold_earned)
	
	save_game()

func get_stats() -> Dictionary:
	return _data.get("stats", {})
