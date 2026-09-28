# ==========================================================
# 【檔案說明】player_walk_state.gd
# 這是玩家行走狀態，負責啟用一般移動並將速度設為行走速度。
# 每次處理玩家狀態時，會依跳躍、閃避、攻擊、防禦、背刺、移動量及跑步輸入
# 決定是否切換狀態；若仍在行走，則持續面向鎖定目標。
# 此狀態繼承 PlayerStateMachine，並透過父狀態執行狀態切換。
# ==========================================================

# 註冊為 PlayerWalkState 類別，讓其他狀態可參照行走狀態。
class_name PlayerWalkState
# 繼承玩家狀態機的通用生命週期與狀態切換能力。
extends PlayerStateMachine


# 此狀態使用的移動元件；進入時會透過它設定行走速度。
@export var locomotion_component: LocomotionComponent

# 沒有足夠移動輸入時要切換回的待機狀態。
@export var idle_state: PlayerIdleState
# 按下 run 輸入時要切換到的閃避狀態。
@export var dodge_state: PlayerDodgeState
# 持續按住跑步輸入時要切換到的跑步狀態。
@export var run_state: PlayerRunState
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


# enter：進入行走狀態時開啟玩家移動，並設定行走速度為 3。
func enter() -> void:
	player.locomotion_component.can_move = true
	locomotion_component.speed = 3


# process_player：檢查輸入、目標與跑步計時結果，並在符合條件時切換狀態。
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
	
	# 持續按住防禦輸入時進入防禦狀態；原程式此分支後沒有 return，
	# 因此同一次呼叫仍會繼續檢查後續條件。
	if Input.is_action_pressed("block"):
		parent_state.change_state(block_state)
	
	# 有有效背刺目標時，切換到背刺狀態。
	if Globals.backstab_system.backstab_victim:
		parent_state.change_state(backstab_state)
		return
	
	# 移動輸入長度低於 0.2 時視為停止行走，返回待機狀態。
	if player.input_direction.length() < 0.2:
		parent_state.change_state(idle_state)
		return
	
	# 跑步狀態已確認玩家持續按住跑步鍵時，切換到跑步狀態。
	if run_state.holding_down_run:
		parent_state.change_state(run_state)
		return
	
	# 留在行走狀態時，持續更新鎖定目標朝向並嘗試轉向。
	player.set_rotation_target_to_lock_on_target()
	player.set_rotate_towards_target_if_lock_on_target()
