extends Node

## 사운드 시스템 오토로드 싱글톤
## BGM 크로스페이드 재생, 16채널 SFX 풀링, 절차적 8비트 아케이드 신스 오디오 생성기 내장

signal bgm_changed(bgm_name: String)

const SAMPLE_RATE: int = 22050

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 16
var _current_sfx_idx: int = 0

var _bgm_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}

var _current_bgm: String = ""
var _bgm_tween: Tween

var bgm_volume_db: float = -6.0
var sfx_volume_db: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_setup_audio_nodes()
	_generate_all_procedural_sounds()

func _setup_audio_nodes() -> void:
	# BGM 플레이어 생성
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = bgm_volume_db
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# SFX 플레이어 풀 생성 (동시 재생 지원)
	for i in range(_sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.volume_db = sfx_volume_db
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

# ==========================================
# 볼륨 설정 API
# ==========================================

func set_bgm_volume_linear(val: float) -> void:
	val = clampf(val, 0.0, 1.0)
	if val <= 0.001:
		bgm_volume_db = -80.0
	else:
		bgm_volume_db = linear_to_db(val)
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = bgm_volume_db

func set_sfx_volume_linear(val: float) -> void:
	val = clampf(val, 0.0, 1.0)
	if val <= 0.001:
		sfx_volume_db = -80.0
	else:
		sfx_volume_db = linear_to_db(val)
	for p in sfx_players:
		if is_instance_valid(p):
			p.volume_db = sfx_volume_db

func get_bgm_volume_linear() -> float:
	if bgm_volume_db <= -70.0:
		return 0.0
	return clampf(db_to_linear(bgm_volume_db), 0.0, 1.0)

func get_sfx_volume_linear() -> float:
	if sfx_volume_db <= -70.0:
		return 0.0
	return clampf(db_to_linear(sfx_volume_db), 0.0, 1.0)

# ==========================================
# BGM 제어 API
# ==========================================

func play_bgm(bgm_name: String, fade_duration: float = 0.6) -> void:
	if _current_bgm == bgm_name and bgm_player.playing:
		return
	
	_current_bgm = bgm_name
	var stream: AudioStream = _get_bgm_stream(bgm_name)
	if not stream:
		return
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	
	if bgm_player.playing:
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration * 0.5)
		_bgm_tween.tween_callback(func():
			bgm_player.stream = stream
			bgm_player.play()
		)
		_bgm_tween.tween_property(bgm_player, "volume_db", bgm_volume_db, fade_duration * 0.5)
	else:
		bgm_player.stream = stream
		bgm_player.volume_db = -30.0
		bgm_player.play()
		_bgm_tween = create_tween()
		_bgm_tween.tween_property(bgm_player, "volume_db", bgm_volume_db, fade_duration)
	
	bgm_changed.emit(bgm_name)

func stop_bgm(fade_duration: float = 0.4) -> void:
	_current_bgm = ""
	if not bgm_player.playing:
		return
	
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(bgm_player, "volume_db", -45.0, fade_duration)
	_bgm_tween.tween_callback(func():
		bgm_player.stop()
		bgm_player.volume_db = bgm_volume_db
	)

func _get_bgm_stream(bgm_name: String) -> AudioStream:
	# 1. 외부 파일 우선 확인
	var ext_path = "res://assets/audio/bgm_%s.ogg" % bgm_name
	if ResourceLoader.exists(ext_path):
		return load(ext_path) as AudioStream
	
	# 2. 내장 절차적 합성 BGM 반환
	if _bgm_cache.has(bgm_name):
		return _bgm_cache[bgm_name]
	
	return null

# ==========================================
# SFX 제어 API
# ==========================================

func play_sfx(sfx_name: String, pitch_jitter: float = 0.08, vol_offset: float = 0.0) -> void:
	var stream = _get_sfx_stream(sfx_name)
	if not stream:
		return
	
	var player = sfx_players[_current_sfx_idx]
	_current_sfx_idx = (_current_sfx_idx + 1) % _sfx_pool_size
	
	player.stream = stream
	player.volume_db = sfx_volume_db + vol_offset
	if pitch_jitter > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	else:
		player.pitch_scale = 1.0
	
	player.play()

func _get_sfx_stream(sfx_name: String) -> AudioStream:
	# 1. 외부 파일 우선 확인
	var ext_path = "res://assets/audio/sfx_%s.wav" % sfx_name
	if ResourceLoader.exists(ext_path):
		return load(ext_path) as AudioStream
	
	# 2. 내장 절차적 합성 SFX 반환
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	
	return null

# ==========================================
# 절차적 8비트 아케이드 신시사이저 오디오 생성
# ==========================================

func _generate_all_procedural_sounds() -> void:
	# SFX 생성
	_sfx_cache["shoot"] = _synth_shoot()
	_sfx_cache["hit"] = _synth_hit()
	_sfx_cache["gem"] = _synth_gem()
	_sfx_cache["levelup"] = _synth_levelup()
	_sfx_cache["chest"] = _synth_chest()
	_sfx_cache["player_hurt"] = _synth_player_hurt()
	_sfx_cache["boss_warning"] = _synth_boss_warning()
	_sfx_cache["game_over"] = _synth_game_over()
	_sfx_cache["stage_clear"] = _synth_stage_clear()
	_sfx_cache["ui_click"] = _synth_ui_click()
	
	# BGM 루프 생성
	_bgm_cache["menu"] = _synth_bgm_menu()
	_bgm_cache["battle"] = _synth_bgm_battle()
	_bgm_cache["boss"] = _synth_bgm_boss()

## 기본 파형 생성 유틸리티 (AudioStreamWAV 8-bit unsigned PCM)
func _create_wav(samples: PackedByteArray, loop: bool = false) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = samples
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav

# 1. 사격음: 고주파에서 저주파로 빠르게 하강하는 칩튠 사운드
func _synth_shoot() -> AudioStreamWAV:
	var duration = 0.08
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		var freq = lerpf(750.0, 180.0, t)
		phase += freq / SAMPLE_RATE
		var val = sin(phase * TAU)
		# 구형파 믹스
		val = (1.0 if val > 0.0 else -1.0) * 0.6 + val * 0.4
		var env = (1.0 - t) * 0.7
		bytes[i] = int(clampf((val * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 2. 타격음: 저주파 펀치 + 노이즈 크런치
func _synth_hit() -> AudioStreamWAV:
	var duration = 0.09
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		var freq = lerpf(160.0, 45.0, t)
		phase += freq / SAMPLE_RATE
		var sine_val = sin(phase * TAU)
		var noise = randf_range(-1.0, 1.0) * (1.0 - t)
		var val = sine_val * 0.65 + noise * 0.35
		var env = (1.0 - t * t) * 0.8
		bytes[i] = int(clampf((val * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 3. 보석 획득 챠링음: 맑은 고주파 2단 차임
func _synth_gem() -> AudioStreamWAV:
	var duration = 0.16
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase1 = 0.0
	var phase2 = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		var freq1 = 880.0 if t < 0.35 else 1320.0
		var freq2 = 1760.0
		phase1 += freq1 / SAMPLE_RATE
		phase2 += freq2 / SAMPLE_RATE
		var val = sin(phase1 * TAU) * 0.7 + sin(phase2 * TAU) * 0.3
		var env = pow(1.0 - t, 1.5) * 0.75
		bytes[i] = int(clampf((val * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 4. 레벨업 팡파레: C5 -> E5 -> G5 -> C6 아르페지오
func _synth_levelup() -> AudioStreamWAV:
	var notes = [523.25, 659.25, 783.99, 1046.5] # C5, E5, G5, C6
	var note_dur = 0.1
	var total_samples = int(notes.size() * note_dur * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		var phase = 0.0
		var start_s = int(n_idx * note_dur * SAMPLE_RATE)
		var note_len = int(note_dur * SAMPLE_RATE)
		for i in range(note_len):
			var idx = start_s + i
			if idx >= total_samples: break
			var t = float(i) / note_len
			phase += freq / SAMPLE_RATE
			var s = sin(phase * TAU)
			var square = (1.0 if s > 0.0 else -1.0) * 0.4
			var val = s * 0.6 + square
			var env = (1.0 - t * 0.7) * 0.75
			bytes[idx] = int(clampf((val * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 5. 상자 개봉 잭팟 사운드: 고속 상승 글리산도 및 팡파레
func _synth_chest() -> AudioStreamWAV:
	var duration = 0.65
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		var freq = lerpf(300.0, 1400.0, pow(t, 0.7))
		phase += freq / SAMPLE_RATE
		var s = sin(phase * TAU)
		var tremolo = 0.8 + 0.2 * sin(t * 40.0 * TAU)
		var val = s * tremolo
		var env = (1.0 - t * 0.4) * 0.75
		bytes[i] = int(clampf((val * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 6. 플레이어 피격음: 경고성 충격음
func _synth_player_hurt() -> AudioStreamWAV:
	var duration = 0.12
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		var freq = lerpf(220.0, 60.0, t)
		phase += freq / SAMPLE_RATE
		var s = (1.0 if sin(phase * TAU) > 0.0 else -1.0) * 0.6
		var noise = randf_range(-1.0, 1.0) * 0.4
		var env = (1.0 - t) * 0.8
		bytes[i] = int(clampf(((s + noise) * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 7. 보스 경고 사이렌
func _synth_boss_warning() -> AudioStreamWAV:
	var duration = 0.8
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		# 2회 왕복 사이렌
		var siren_t = absf(fmod(t * 3.0, 1.0) - 0.5) * 2.0
		var freq = lerpf(440.0, 880.0, siren_t)
		phase += freq / SAMPLE_RATE
		var s = sin(phase * TAU)
		var env = (1.0 - t * 0.3) * 0.7
		bytes[i] = int(clampf((s * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 8. 게임오버 하강음
func _synth_game_over() -> AudioStreamWAV:
	var notes = [440.0, 392.0, 349.23, 261.63] # A4 -> G4 -> F4 -> C4
	var note_dur = 0.2
	var total_samples = int(notes.size() * note_dur * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		var phase = 0.0
		var start_s = int(n_idx * note_dur * SAMPLE_RATE)
		var note_len = int(note_dur * SAMPLE_RATE)
		for i in range(note_len):
			var idx = start_s + i
			if idx >= total_samples: break
			var t = float(i) / note_len
			phase += freq / SAMPLE_RATE
			var s = sin(phase * TAU)
			var env = (1.0 - t) * 0.7
			bytes[idx] = int(clampf((s * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 9. 스테이지 클리어 팡파레
func _synth_stage_clear() -> AudioStreamWAV:
	var notes = [523.25, 659.25, 783.99, 1046.5, 1318.5] # C5, E5, G5, C6, E6
	var note_dur = 0.15
	var total_samples = int(notes.size() * note_dur * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		var phase = 0.0
		var start_s = int(n_idx * note_dur * SAMPLE_RATE)
		var note_len = int(note_dur * SAMPLE_RATE)
		for i in range(note_len):
			var idx = start_s + i
			if idx >= total_samples: break
			var t = float(i) / note_len
			phase += freq / SAMPLE_RATE
			var s = sin(phase * TAU) * 0.65 + (1.0 if sin(phase * 2.0 * TAU) > 0.0 else -1.0) * 0.35
			var env = (1.0 - t * 0.4) * 0.8
			bytes[idx] = int(clampf((s * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# 10. UI 클릭음: 짧고 산뜻한 블립
func _synth_ui_click() -> AudioStreamWAV:
	var duration = 0.025
	var total_samples = int(duration * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	
	for i in range(total_samples):
		var t = float(i) / total_samples
		phase += 1200.0 / SAMPLE_RATE
		var s = sin(phase * TAU)
		var env = (1.0 - t) * 0.65
		bytes[i] = int(clampf((s * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes)

# ==========================================
# BGM 절차적 합성 루프 (8~16초 무한 루프)
# ==========================================

# 메인 메뉴 BGM: 신비로운 아르페지오 앰비언트 루프
func _synth_bgm_menu() -> AudioStreamWAV:
	var melody = [220.0, 261.63, 329.63, 392.0, 329.63, 261.63, 220.0, 196.0]
	var step_dur = 0.3
	var total_len = melody.size() * step_dur
	var total_samples = int(total_len * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var time = float(i) / SAMPLE_RATE
		var note_idx = int(time / step_dur) % melody.size()
		var freq = melody[note_idx]
		var note_t = fmod(time, step_dur) / step_dur
		
		phase += freq / SAMPLE_RATE
		var bass = sin((freq * 0.5) / SAMPLE_RATE * i * TAU) * 0.4
		var s = sin(phase * TAU) * 0.5 + bass
		var env = pow(1.0 - note_t, 1.2) * 0.4
		bytes[i] = int(clampf((s * env + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes, true)

# 인게임 서바이벌 BGM: 템포감 있는 펄스 베이스라인 루프
func _synth_bgm_battle() -> AudioStreamWAV:
	var bass_notes = [110.0, 110.0, 130.81, 146.83, 110.0, 110.0, 164.81, 146.83]
	var step_dur = 0.18
	var total_len = bass_notes.size() * step_dur
	var total_samples = int(total_len * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var time = float(i) / SAMPLE_RATE
		var step = int(time / step_dur) % bass_notes.size()
		var freq = bass_notes[step]
		var note_t = fmod(time, step_dur) / step_dur
		
		phase += freq / SAMPLE_RATE
		# 펄스 베이스 + 가벼운 비트 클릭
		var pulse = (1.0 if sin(phase * TAU) > 0.0 else -1.0) * 0.4
		var beat = randf_range(-1.0, 1.0) * 0.2 if note_t < 0.1 else 0.0
		var s = (pulse + beat) * (1.0 - note_t * 0.6) * 0.45
		bytes[i] = int(clampf((s + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes, true)

# 보스전 BGM: 극적이고 빠른 하이 텐션 인텐시티 루프
func _synth_bgm_boss() -> AudioStreamWAV:
	var boss_notes = [82.41, 98.0, 110.0, 123.47, 82.41, 130.81, 123.47, 98.0]
	var step_dur = 0.13
	var total_len = boss_notes.size() * step_dur
	var total_samples = int(total_len * SAMPLE_RATE)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var time = float(i) / SAMPLE_RATE
		var step = int(time / step_dur) % boss_notes.size()
		var freq = boss_notes[step]
		var note_t = fmod(time, step_dur) / step_dur
		
		phase += freq / SAMPLE_RATE
		var saw = (fmod(phase, 1.0) * 2.0 - 1.0) * 0.45
		var sub = sin(phase * 0.5 * TAU) * 0.35
		var s = (saw + sub) * (1.0 - note_t * 0.5) * 0.5
		bytes[i] = int(clampf((s + 1.0) * 127.5, 0.0, 255.0))
	
	return _create_wav(bytes, true)
