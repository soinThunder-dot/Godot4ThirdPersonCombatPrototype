class_name Player
extends CharacterBody3D
## 玩家角色類別，繼承自 CharacterBody3D（具備物理碰撞與移動功能的 3D 角色主體）


@export_category("Mechanisms")
## 匯出分類：核心機制元件
@export var state_machine: PlayerStateMachine
## 玩家狀態機，負責管理角色所有狀態的切換與流程
@export var character: PlayerAnimations
## 玩家動畫控制器，負責播放與管理角色動畫
@export var locomotion_component: LocomotionComponent
## 移動元件，處理角色的移動邏輯（含次要移動）
@export var hitbox_component: HitboxComponent
## 受擊判定元件，偵測角色受到攻擊的範圍
@export var health_component: HealthComponent
## 生命值元件，管理角色生命值增減與死亡邏輯
@export var instability_component: InstabilityComponent
## 不穩定值元件（暈眩/失衡系統），累積後觸發暈眩狀態
@export var jump_component: JumpComponent
## 跳躍元件，處理角色跳躍相關邏輯
@export var shield_component: ShieldComponent
## 護盾元件，處理格擋/護盾相關機制
@export var dodge_component: DodgeComponent
## 閃避元件，處理翻滾/閃避動作邏輯
@export var rotation_component: PlayerRotationComponent
## 角色身體旋轉元件，控制角色朝向目標旋轉
@export var head_rotation_component: HeadRotationComponent
## 頭部旋轉元件，控制角色頭部朝向目標
@export var melee_component: MeleeComponent
## 近戰攻擊元件，處理近戰攻擊邏輯與判定
@export var parry_component: ParryComponent
## 招架（格擋反擊）元件，處理招架判定與時機
@export var fade_component: FadeComponent
## 淡出/隱身元件，處理角色淡入淡出效果
@export var health_charge_component: HealthChargeComponent
## 生命充能元件，處理蓄力回復生命值的邏輯

@export_category("Character")
## 匯出分類：角色相關資源
@export var weapon: DamageSource
## 武器（傷害來源），角色目前裝備的武器物件
@export var lock_on_attachment_point: Node3D
## 鎖定攝影機/UI 的附著點，用於鎖定目標時的視覺定位

@export_category("Audio")
## 匯出分類：音效相關
@export var footsteps: AudioFootsteps
## 腳步聲元件，依據角色移動狀態播放對應腳步音效

var input_direction: Vector3 = Vector3.ZERO
## 玩家輸入方向向量（依當前輸入即時更新）
var last_input_on_ground: Vector3 = Vector3.ZERO
## 記錄最後一次角色在地面時的輸入方向，用於空中保持慣性方向

var lock_on_target: LockOnComponent = null
## 目前鎖定中的目標（鎖定元件），無鎖定則為 null
var locked_on_turning_in_place: bool = false
## 是否在原地轉身（鎖定目標時使用），供動畫或旋轉邏輯判斷

@onready var drink_state: PlayerDrinkState = $StateMachine/Drink
## 飲用（喝藥/回復）狀態節點參照
@onready var checkpoint_state: PlayerCheckpointState = $StateMachine/Checkpoint
## 檢查點（存檔點）狀態節點參照

@onready var backstab_system: BackstabSystem = Globals.backstab_system
## 背刺系統全域參照，處理背刺判定與觸發
@onready var checkpoint_system: CheckpointSystem = Globals.checkpoint_system
## 檢查點系統全域參照，管理存檔點狀態


func _ready() -> void:
	## 節點進入場景樹時執行的初始化流程
	Globals.lock_on_system.lock_on.connect(
		func(target: LockOnComponent): lock_on_target = target
	)
	## 訂閱鎖定系統的 lock_on 訊號：當鎖定新目標時，更新 lock_on_target
	
	Globals.dizzy_system.dizzy_victim_killed.connect(
		func(): instability_component.instability = 0.0
	)
	## 訂閱暈眩系統的受害者被擊殺訊號：重置角色的不穩定值為 0
	
	Globals.void_death_system.fallen_into_the_void.connect(
		func(body: Node3D):
			if not (body is Player): return
			health_component.deal_max_damage = true
			health_component.decrement_health(1)
	)
	## 訂閱掉落虛空死亡系統訊號：若掉落者為玩家本身，則觸發最大傷害並扣除生命值（即刻死亡處理）
	
	melee_component.can_rotate.connect(
		func(flag: bool): rotation_component.can_rotate = flag
	)
	## 訂閱近戰元件的可旋轉訊號：同步更新旋轉元件是否允許旋轉（例如攻擊中禁止轉向）
	
	state_machine.enter_state_machine()
	## 啟動狀態機，進入初始狀態


func _physics_process(_delta: float) -> void:
	## 每個物理幀執行的處理函式（固定時間步長更新）
	
	## State Machine（狀態機處理）
	state_machine.process_player_state_machine()
	## 執行玩家主狀態機邏輯（狀態切換與行為處理）
	state_machine.process_movement_animations_state_machine()
	## 執行移動動畫子狀態機邏輯（處理走路/跑步等動畫狀態）
	
	
	## Utility Inputs（功能性輸入處理）
	if Input.is_action_just_pressed("exit"):
		## 按下「退出」鍵時，結束遊戲程式
		get_tree().quit()
	elif Input.is_action_just_pressed("ui_text_backspace"):
		## 按下「退格」鍵時，將滑鼠模式設為可見（例如開啟選單時）
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.is_action_just_pressed("attack") and \
	not checkpoint_system.at_checkpoint:
		## 若按下「攻擊」鍵且角色不在檢查點上，則將滑鼠模式設為鎖定捕獲（隱藏並鎖定於視窗中央，回到遊戲操作狀態）
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
	## Player Movement Inputs（玩家移動輸入處理）
	## 計算 X 軸方向輸入強度（右減左）
	input_direction.x = Input.get_action_strength("right") - \
		Input.get_action_strength("left")
	## 計算 Z 軸方向輸入強度（後退減前進）
	input_direction.z = Input.get_action_strength("backward") - \
		Input.get_action_strength("forward")
	## 若角色在地面上，更新最後地面輸入方向；否則維持在空中前的最後方向（保留慣性方向）
	last_input_on_ground = input_direction if is_on_floor() else \
		last_input_on_ground
	
	
	## Head Rotation（頭部旋轉處理）
	if rotation_component.rotate_towards_target and \
	rotation_component.target != null and \
	not state_machine.current_state is PlayerDizzyState:
		## 若旋轉元件設定需朝向目標旋轉，且目標存在，且目前並非處於暈眩狀態，
		## 則將頭部旋轉的目標位置設為旋轉元件所指定目標的世界座標
		head_rotation_component.desired_target_pos = \
			rotation_component.target.global_position
	elif backstab_system.backstab_victim != null:
		## 否則，若背刺系統中存在背刺受害者，則讓頭部朝向該受害者位置（優先呈現背刺互動的注視效果）
		head_rotation_component.desired_target_pos = \
			backstab_system.backstab_victim.global_position
	else:
		## 若無任何旋轉目標，將頭部目標位置設為無限值（Vector3.INF），代表不進行特定注視
		head_rotation_component.desired_target_pos = Vector3.INF
	
	
	## Footsteps（腳步聲處理）
	## 同步更新腳步聲元件是否在地面上的狀態
	footsteps.on_floor = is_on_floor()
	## 判斷目前狀態機是否為奔跑狀態，同步給腳步聲元件以播放對應音效
	footsteps.running = state_machine.current_state is PlayerRunState


func set_rotation_target_to_lock_on_target() -> void:
	## 將旋轉元件的目標設定為目前鎖定的目標
	rotation_component.target = lock_on_target


func set_rotate_towards_target_if_lock_on_target() -> void:
	## 若存在鎖定目標，設定旋轉元件為「朝向目標旋轉」；若無鎖定目標，則關閉此行為
	rotation_component.rotate_towards_target = \
		true if lock_on_target else false


func process_default_movement_animations() -> void:
	## 處理預設（一般）移動動畫的邏輯
	## 預設方向為目前輸入方向
	var dir: Vector3 = input_direction
	## 若有鎖定目標，預設啟用待機（面向敵人時的站立）動畫狀態
	var idle_active: bool = lock_on_target != null
	
	if locomotion_component.has_secondary_movement():
		## 若目前有次要移動狀態（例如翻滾、攻擊移動等），則方向歸零，不套用一般移動方向
		dir = Vector3.ZERO
		## 並強制啟用待機動畫狀態，避免與次要移動動畫衝突
		idle_active = true
	
	## 套用待機動畫的啟用狀態
	character.idle_animations.active = idle_active
	## 套用移動動畫的方向
	character.movement_animations.dir = dir
	## 依據是否為待機狀態，切換移動動畫為「走路（walk，鎖定目標時較慢移動）」或「小跑（jog，一般移動）」
	character.movement_animations.set_state(
		"walk" if idle_active else "jog"
	)


func _on_lock_on_system_lock_on(target: LockOnComponent) -> void:
	## 鎖定系統發出 lock_on 訊號時的回呼函式：更新目前鎖定目標
	lock_on_target = target
