# ==========================================================
# 【檔案說明】player_idle_state.gd
# 這是玩家待機狀態，玩家沒有移動輸入時會留在此狀態。
# 它會依輸入切換到跳躍、閃避、攻擊、防禦、背刺或行走狀態，並在待機時
# 面向鎖定目標、更新待機／移動動畫；鎖定目標改變時也會短暫處理原地轉身動畫。
# 此狀態是 PlayerStateMachine 的子類別，透過父狀態執行狀態切換。
# ==========================================================

# 註冊為 PlayerIdleState 類別，供其他腳本指定待機狀態。
class_name PlayerIdleState
# 繼承玩家狀態機，取得共用的狀態生命週期與父狀態參照。
extends PlayerStateMachine


# 行走輸入出現時要切換到的狀態。
@export var walk_state: PlayerWalkState
# 按下 run 輸入時要切換到的閃避狀態。
@export var dodge_state: PlayerDodgeState
# 符合地面條件並按下跳躍時要切換到的狀態。
@export var jump_state: PlayerJumpState
# 按下攻擊時要切換到的狀態。
@export var attack_state: PlayerAttackState
# 持續按住防禦輸入時要切換到的狀態。
@export var block_state: PlayerBlockState
# 剛按下防禦輸入時要切換到的招架狀態。
@export var parry_state: PlayerParryState
# 背刺系統找到有效目標時要切換到的狀態。
@export var backstab_state: PlayerBackstabState

# 記錄玩家是否正因為鎖定目標改變而原地轉身，用來選擇對應的動畫方向。
var _locked_on_turning_in_place: bool = false

# 取得全域鎖定系統，供本狀態接收鎖定目標變更訊號。
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system


# _ready：節點就緒時先初始化狀態機，再訂閱鎖定目標變更訊號。
func _ready():
	# 執行父類別的初始化，建立此節點的子狀態資訊。
	super._ready()
	# 目標鎖定時呼叫本類別的回呼，處理原地轉身狀態。
	lock_on_system.lock_on.connect(_on_lock_on_system_lock_on)

# enter：進入待機狀態時停止移動方向，並允許旋轉元件調整朝向。
func enter() -> void:
	player.rotation_component.move_direction = Vector3.ZERO
	player.rotation_component.can_rotate = true

# process_player：檢查玩家輸入及背刺目標，必要時切換離開待機狀態。
func process_player() -> void:
	# 只有剛按下跳躍且角色在地面時才開始跳躍。
	if Input.is_action_just_pressed("jump") and \
	player.is_on_floor():
		parent_state.change_state(jump_state)
		return
	
	# 剛按下 run 輸入時切換到指定的閃避狀態。
	if Input.is_action_just_pressed("run"):
		parent_state.change_state(dodge_state)
		return
	
	# 剛按下攻擊輸入時進入攻擊狀態。
	if Input.is_action_just_pressed("attack"):
		parent_state.change_state(attack_state)
		return
	
	# 剛按下防禦輸入時優先進入招架狀態。
	if Input.is_action_just_pressed("block"):
		parent_state.change_state(parry_state)
		return
	
	# 若防禦輸入仍處於按住狀態，進入持續防禦狀態。
	if Input.is_action_pressed("block"):
		parent_state.change_state(block_state)
		return
	
	# 有有效背刺目標時，切換到背刺狀態。
	if Globals.backstab_system.backstab_victim:
		parent_state.change_state(backstab_state)
		return
	
	# 輸入方向長度大於零代表玩家有移動輸入，因此離開待機進入行走。
	if player.input_direction.length() > 0:
		parent_state.change_state(walk_state)
		return
	
	# 沒有上述轉換條件時，持續將面向目標設定為鎖定對象並嘗試轉向。
	player.set_rotation_target_to_lock_on_target()
	player.set_rotate_towards_target_if_lock_on_target()


# process_movement_animations：依鎖定轉身狀態與玩家目標更新待機及移動動畫參數。
func process_movement_animations() -> void:
	# 通常使用玩家輸入方向；原地轉向時改用前方作為動畫方向。
	var _animation_input_dir: Vector3 = player.input_direction
	if _locked_on_turning_in_place:
		_animation_input_dir = Vector3.FORWARD
	
	# 有鎖定目標時啟用待機動畫，並將選定的方向交給移動動畫控制器。
	player.character.idle_animations.active = player.lock_on_target != null
	player.character.movement_animations.dir = _animation_input_dir


# _on_lock_on_system_lock_on：鎖定系統發出 lock_on 訊號時執行。
# target 是新鎖定的目標元件；無目標時不需啟動轉身處理。
func _on_lock_on_system_lock_on(target: LockOnComponent) -> void:
	# 沒有目標就直接結束回呼。
	if not target: return
	
	# 計算玩家目前朝向與新鎖定目標之間的角度差。
	var rotation_difference: float = player\
		.rotation_component\
		.get_rotation_difference(target)
	
	# 角度差小於門檻時視為不必特別播放原地轉身流程。
	if rotation_difference < 0.1: return
	
	# 標記正在原地轉身，讓動畫處理函式暫時採用轉身方向。
	_locked_on_turning_in_place = true
	
	# 角度差換算成短暫時間，並限制在 0.1 到 0.18 秒之間。
	var duration: float = clamp(rotation_difference / PI * 0.18, 0.1, 0.18)
	# 建立一次性等待時間；SceneTreeTimer.timeout 是時間到時發出的訊號。
	var pressed_lock_on_timer: SceneTreeTimer = get_tree()\
		.create_timer(duration)
	
	# （回呼內容）計時器結束後清除原地轉身標記，讓動畫方向回到玩家輸入方向。
	pressed_lock_on_timer.timeout.connect(
		func():
			_locked_on_turning_in_place = false
	)
