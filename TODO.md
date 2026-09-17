# 뱀서라이크 개발 TODO List

> [PRD.md](./PRD.md) 기반 개발 단계별 세부 태스크 목록입니다.
> 완료된 항목은 `- [x]`로 체크하며 진행합니다.

---

## 📌 Phase 1: MVP 코어 프로토타입 (핵심 루프 검증)
> **목표**: 이동, 자동 공격, 적 스폰, 경험치 습득, 레벨업, 게임오버까지의 1회 플레이 사이클 완성

### 1.1. 프로젝트 기반 설정
- [x] 2D 픽셀/해상도 뷰포트 설정 (`project.godot` 윈도우 크기 및 스트레치 모드)
- [x] 충돌 레이어 및 마스크(Collision Layers & Masks) 정의
  - Layer 1: World / Boundary
  - Layer 2: Player
  - Layer 3: Enemy
  - Layer 4: PlayerProjectile
  - Layer 5: Pickup (Exp/Items)
- [x] 컴포넌트 기반 아키텍처 베이스 스크립트 생성
  - `HealthComponent.gd` (체력, 데미지 처리, 사망 시그널)
  - `HitboxComponent.gd` (공격 판정 Area2D, 데미지/넉백 수치 전달)
  - `HurtboxComponent.gd` (피격 판정 Area2D, Hitbox 감지 후 Health 연동)

### 1.2. 플레이어 (Player)
- [x] `Player.tscn` 생성 (CharacterBody2D + Sprite2D + CollisionShape2D)
- [x] 8방향 이동 로직 구현 (`Input.get_vector()` 활용, 부드러운 가감속)
- [x] 카메라 추적 (`Camera2D` 설정, 부드러운 스무딩 적용)
- [x] 피격 및 무적 시간(i-frame) 구현 (피격 시 짧은 무적 및 스프라이트 깜빡임)
- [x] 자석 반경 (`Area2D`) 설정 및 드랍 아이템 감지 영역 구성

### 1.3. 기본 무기 1종 (예: 단검 / Magic Wand)
- [x] 가장 가까운 적을 탐지하는 타겟팅 로직 구현 (`WeaponBase.gd`)
- [x] 투사체 씬 (`Projectile.tscn`) 생성 (직선 이동, 수명/관통 횟수 처리, 발광 연출)
- [x] 공격 쿨다운 타이머 및 자동 발사 루프 구현 (`MagicWand.gd`)

### 1.4. 기본 적 1종 및 스포너
- [x] 기본 적 씬 (`EnemyBasic.tscn`) 생성 (CharacterBody2D + 붉은 틴트 스프라이트)
- [x] 플레이어 위치를 향해 등속 추적 이동 로직 구현 (`EnemyBase.gd`)
- [x] 플레이어 접촉 시 지속 데미지 부여 처리 (`HitboxComponent` 연동)
- [x] 적 스포너 (`WaveSpawner.tscn`) 구현
  - 카메라 화면 밖 무작위 원형 테두리 좌표 계산 후 스폰
  - 시간 경과에 따른 스폰 간격 단축 및 무리 배치 스폰 지원

### 1.5. 드랍 & 경험치 수집
- [x] 경험치 보석 씬 (`ExpGem.tscn`) 생성 (다이아몬드 벡터 렌더링, 수치별 색상 변경)
- [x] 적 사망 시 지정 위치에 경험치 보석 인스턴스화 (`_drop_loot()`)
- [x] 플레이어 자석 범위 진입 시 플레이어를 향해 가속 이동 및 획득 처리 (`start_homing()`)

### 1.6. 기본 HUD & 게임 루프
- [x] 경험치 누적 및 필요 경험치 공식 적용 (레벨업 이벤트 발생)
- [x] 기본 인게임 HUD: 체력 바(HealthBar), 경험치 바(ExpBar), 생존 시간 타이머
- [x] 게임오버 처리: 플레이어 사망 시 일시정지 및 "재도전" 버튼 표시 (`get_tree().reload_current_scene()`)

---

## 📌 Phase 2: 빌드 다양성 & 파밍 시스템
> **목표**: 무기/패시브 다양화, 레벨업 선택 UI, 보스 및 보물상자 연출

### 2.1. 데이터 드리븐 시스템 구축 (Custom Resources)
- [x] `WeaponData.gd` 리소스 정의 (이름, 아이콘, 쿨다운, 데미지, 투사체 수, 관통력 등)
- [x] `PassiveData.gd` 리소스 정의 (스탯 증가 종류 및 수치)
- [x] `EnemyData.gd` 리소스 정의 (체력, 속도, 경험치량, 스프라이트)

### 2.2. 무기 및 패시브 라인업 확장 (최소 4종씩)
- [x] **무기 구현**
  - [x] 무기 1: 투사체형 (`MagicWand` - 가장 가까운 적 타겟팅 미사일)
  - [x] 무기 2: 궤도 회전형 (`OrbitOrb` - 플레이어 주변 회전 방어)
  - [x] 무기 3: 광역 폭발/낙뢰형 (`LightningRing` - 무작위 적 위치 번개)
  - [x] 무기 4: 오라/장판형 (`GarlicAura` - 플레이어 주변 지속 데미지 영역)
- [x] **패시브 아이템 구현**
  - [x] 공격력 증가 (Might: +10%/Lv)
  - [x] 이동 속도 증가 (Speed: +10%/Lv)
  - [x] 쿨다운 감소 (Cooldown: -8%/Lv)
  - [x] 자석 범위 증가 (Magnet: +25%/Lv)
- [x] `EquipmentManager` 구현: 무기 최대 4개, 패시브 최대 4개 슬롯 제한 및 레벨 관리, 스탯 실시간 재계산

### 2.3. 레벨업 선택 UI 시스템
- [x] 레벨업 시 게임 일시정지 (`get_tree().paused = true`, UI 노드 `process_mode = PROCESS_MODE_ALWAYS`)
- [x] 3~4개의 무작위 선택 카드 UI 생성 (신규 스킬 획득 or 기존 스킬 레벨업, 다중 레벨업 큐잉 지원)
- [x] 카드 호버 및 클릭 시 해당 스킬 적용 후 게임 재개 (`EquipmentManager` 자동 연동)

### 2.4. 적 다양화 및 엘리트/보스 몬스터
- [x] 빠른 기동형 적 추가 (`EnemyFast` / `enemy_fast.tscn`: 속도 150px/s, 보라색 가고일)
- [x] 엘리트/보스 몬스터 추가 (`EnemyBoss` / `enemy_boss.tscn`: 600HP, 2.75배 스케일, 80% 넉백 저항, 머리 위 체력바)
- [x] 보스 처치 시 보물상자 (`Chest.tscn`) 및 대량 경험치 보석 드랍 연동

### 2.5. 보물상자 연출
- [x] 상자 접촉 시 상자 개봉 팝업 오픈 (상자 흔들림/룰렛 연출, `ChestRewardScreen`)
- [x] 보유 중인 무기/패시브 즉시 무료 레벨업 (1~3개) 및 보너스 골드 지급 (플레이어 누적 및 사망 정산 표시)

---

## 📌 Phase 3: 완성도 & 메타 프로그레션
> **목표**: 무기 진화 조합, 웨이브 타임라인 설계, 로비 상점 및 영구 성장

### 3.1. 무기 진화(Evolution) 시스템
- [x] 무기 진화 레시피 4종 데이터 구조 정의 (`WeaponData.can_evolve()`, Lv8 무기 + 특정 패시브 조합)
- [x] 보물상자 개봉 시 진화 우선 변환 로직 구현 (`EquipmentManager.evolve_weapon()`)
- [x] 4종 진화 무기 특수 연출 및 압도적 성능 구현 (HolyWand, UnholyVespers, ThunderLoop, SoulEater)

### 3.2. 웨이브 타임테이블 고도화 (15분~20분 세션)
- [x] 시간별 스폰 테이블 구성 (0~1분: 기본 잡몹, 2분: 거대 골렘, 3분: 가고일 떼, 5분: 고대 수호자, 10분: 파멸의 군주 최종 보스)
- [x] 특정 시간대 화면 전체를 둘러싸는 포위 웨이브(Swarm Ring) 이벤트 및 경고 배너(`WarningBanner`) 연출 구현

### 3.3. 데이터 저장 및 로드 (Save/Load)
- [x] `SaveManager.gd` 생성 (`user://save_data.json` 기반 저장/로드/초기화 및 Autoload 싱글톤 등록)
- [x] 골드(재화), 해금 목록, 영구 업그레이드 레벨 저장 및 복원 (인게임 스탯 반영 및 사망 시 누적 저장 연동)

### 3.4. 메인 로비 & 영구 강화 상점 (Shop)
- [x] 메인 타이틀 씬 (`MainMenu.tscn`): 게임 시작, 상점, 종료 및 누적 통계/골드 표시
- [x] 상점 UI (`ShopUI.tscn` & `ShopItemSlot.tscn`):
  - 영구 스탯 항목 (최대 체력, 공격력, 이동속도, 자석, 추가 경험치)
  - 레벨별 골드 소모 및 구매/100% 전체 환불 기능
- [x] 인게임 시작 시 영구 스탯 값을 플레이어 기본 스탯에 반영 (`SaveManager.apply_to_player()`)

### 3.5. 정산 및 결과 화면 (Result Screen)
- [x] 클리어/사망 시 결과 창 출력 (`ResultScreen.tscn` / `ResultScreen.gd`, GAME OVER & STAGE CLEAR 2종 모드)
- [x] 생존 시간, 처치 수, 획득 골드, 무기별 총 데미지/DPS 및 점유율(%) 통계 표시 (`WeaponStatRow`)
- [x] 로비 복귀 및 재시작 버튼 연결 (SaveManager 자동 통계/골드 저장 연동)

---

## 📌 Phase 4: 폴리싱, 최적화 & 릴리즈
> **목표**: 손맛(Juice) 극대화, 대량 몬스터 최적화, 완성도 마감

### 4.1. 게임 필(Juice & Visual Feedback)
- [x] 몬스터 피격 시 하얀색/빨간색 플래시 셰이더 적용 (`hit_flash.gdshader`)
- [x] 플로팅 데미지 숫자(Floating Damage Numbers) 연출 (`FloatingDamageNumber`, 일반/치명타/회복)
- [x] 카메라 셰이크 (플레이어 피격, 보스 출현/경고, 대형 강타 시 화면 흔들림)
- [x] 히트스탑(Hit-stop / 0.04초 일시정지)으로 타격감 증대 (`Engine.time_scale` 동결)
- [x] 사망 시 소멸 파티클(DeathParticles / CPUParticles2D) 연출 (몬스터별 고유 색상 및 스케일)

### 4.2. 사운드 시스템 (BGM & SFX)
- [x] `SoundManager.gd` 오디오 오토로드 싱글톤 구성 (16채널 SFX 풀링, BGM 크로스페이드, 절차적 8비트 아케이드 신스 오디오 생성기 내장)
- [x] BGM 시스템 (메인 로비: `menu`, 인게임 전투: `battle`, 보스 출현: `boss`, 부드러운 페이드 전환)
- [x] SFX 시스템 (사격 `shoot`, 타격 `hit`, 보석 획득 `gem`, 레벨업 `levelup`, 상자 개봉 `chest`, 피격 `player_hurt`, 경고 `boss_warning`, 게임오버 `game_over`, 클리어 `stage_clear`, UI 클릭 `ui_click`)

### 4.3. 대규모 엔티티 성능 최적화
- [x] 오브젝트 풀링(Object Pooling) 적용 (`PoolManager.gd` 싱글톤, 경험치 보석, 투사체, 기본 몬스터, 데미지 숫자, 파티클 풀링)
- [x] 화면 밖 멀리 떨어진 몬스터 연산 경량화 (거리 > 800px 시 `move_and_slide()` 스킵 & 방향 Throttling, 거리 > 1400px 시 플레이어 전방 리포지셔닝)
- [x] 물리 연산 부하 모니터링 & 최적화 (보석 180개 초과 시 가치 병합(Gem Merging), F3 키 실시간 성능 모니터링 HUD `PerformanceMonitor.gd`)

### 4.4. 빌드 & 배포 준비
- [x] 일시정지 메뉴 (`PauseMenu.tscn` / `PauseMenu.gd`, ESC 키 일시정지, 런 스탯 확인, 실시간 BGM/SFX 볼륨 조절 슬라이더, 계속하기/재시작/로비 복귀)
- [x] Godot Export Preset 설정 (`export_presets.cfg`, Windows Desktop 64-bit .exe 빌드 프리셋, PCK 임베딩 및 메타데이터 완비)
