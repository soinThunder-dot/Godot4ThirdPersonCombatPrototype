# ==========================================================
# 【檔案說明】player_run_state.gd
# 這是玩家跑步狀態，負責提高移動速度、確認跑步鍵是否持續按住，並更新跑步動畫。
# 玩家進入此狀態後會依輸入切換到跳躍、閃避、攻擊、防禦、背刺、行走或待機；
# 符合跑步狀態時則依鎖定目標與輸入方向調整旋轉。
# 此狀態繼承 PlayerStateMachine，並以 Timer 區分短按與持續按住跑步輸入。
# ==========================================================

# 註冊為 PlayerRunState 類別，讓其他狀態可參照跑步狀態。
class_name PlayerRunState
# 繼承玩家狀態機的通用生命週期與狀態切換能力。
extends PlayerStateMachine


# 此狀態使用的移動元件；進入時會透過它設定跑步速度。
@export var locomotion_component: LocomotionComponent

# 移動停止時要切換到的待機狀態。
@export var idle_state: PlayerIdleState
# 跑步鍵不再持續按住時要返回的行走狀態。
@export var walk_state: PlayerWalkState
# 符合地面條件並按下跳躍時要切換到的狀態。
@export var jump_state: PlayerJumpState
# 剛按下 run 輸入時要切換到的閃避狀態。
@export var dodge_state: PlayerDodgeState
# 按下攻擊時要切換到的狀態。
@export var attack_state: PlayerAttackState
# 持續按住防禦輸入時要切換到的狀態。
@export var block_state: PlayerBlockState
# 剛按下防禦輸入時要切換到的招架狀態。
@export var parry_state: PlayerParryState
# 背刺系統找到有效目標時要切換到的狀態。
@export var backstab_state: PlayerBackstabState

# 記錄跑步鍵是否已持續按住計時門檻；由計時器回呼更新。
var holding_down_run: bool = false
# 用來延遲確認跑步鍵是否持續按住的 Timer 節點。
var _holding_down_run_timer: Timer


# _ready：節點就緒時建立 Timer，並連接計時結束後確認持續按住的回呼。
func _ready() -> void:
	# 建立 Timer 節點供本狀態計算跑步按鍵的持續時間。
	_holding_down_run_timer = Timer.new()
	# （回呼內容）計時到時若跑步鍵仍按住，就記錄已持續按住；若已放開則不更新。
	_holding_down_run_timer.timeout.connect(
		func():
			if not Input.is_action_pressed("run"): return
			holding_down_run = true
	)
	# 將 Timer 加入場景樹，讓它能正常計時並發出 timeout 訊號。
	add_child(_holding_down_run_timer)


# _process：每影格檢查跑步按鍵狀態；_delta 是引擎提供的影格經過秒數，本函式未使用。
func _process(_delta: float) -> void:
	# （以下原有英文註解的中文說明：確認玩家確實持續按住跑步鍵，才將其視為跑步。）
	# make sure the user is actually holding down
	# the run key to make the player run
	# 跑步鍵仍按住且計時器停止時，啟動 0.25 秒的確認計時。
	if Input.is_action_pressed("run") and \
	_holding_down_run_timer.is_stopped():
		_holding_down_run_timer.start(0.25)
	# 偵測到跑步鍵剛放開時停止計時，並清除持續按住的旗標。
	if Input.is_action_just_released("run"):
		_holding_down_run_timer.stop()
		holding_down_run = false


# enter：進入跑步狀態時將移動速度設定為 5。
func enter() -> void:
	locomotion_component.speed = 5


# process_player：依照玩家輸入與目前跑步按住狀態，執行必要的狀態轉換。
func process_player() -> void:
	# 只有剛按下跳躍且角色在地面時才進入跳躍狀態。
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
	
	# 持續按住防禦輸入時進入防禦狀態。
	if Input.is_action_pressed("block"):
		parent_state.change_state(block_state)
		return
	
	# 有有效背刺目標時，切換到背刺狀態。
	if Globals.backstab_system.backstab_victim:
		parent_state.change_state(backstab_state)
		return
	
	# 跑步按住確認旗標消失時返回行走狀態。
	if not holding_down_run:
		parent_state.change_state(walk_state)
		return
	
	# 移動輸入長度低於 0.2 時視為停止移動，返回待機狀態。
	if player.input_direction.length() < 0.2:
		parent_state.change_state(idle_state)
		return
	
	# 留在跑步狀態時，持續更新鎖定目標作為旋轉目標。
	player.set_rotation_target_to_lock_on_target()
	
	# 有鎖定目標且輸入方向的 z 分量不大於零時朝目標旋轉，否則關閉此旋轉模式。
	player.rotation_component.rotate_towards_target = true if (
		player.lock_on_target and player.input_direction.z <= 0
	) else false


# process_movement_animations：設定鎖定待機旗標、移動方向，並指定播放跑步動畫狀態。
func process_movement_animations() -> void:
	# 存在鎖定目標時啟用待機動畫控制器。
	player.character.idle_animations.active = player.lock_on_target != null
	# 有鎖定目標時使用玩家輸入方向，沒有鎖定目標則使用前方方向。
	player.character.movement_animations.dir = \
		player.input_direction if player.lock_on_target else Vector3.FORWARD
	# 將移動動畫控制器切換至 run 狀態。
	player.character.movement_animations.set_state("run")
