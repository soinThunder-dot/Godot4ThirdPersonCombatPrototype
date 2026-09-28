# ==========================================================
# 【檔案說明】player_dodge_state.gd
# 這是玩家的「閃避狀態」腳本，負責啟動閃避意圖、暫時關閉碰撞箱受擊判定，
# 並調整移動速度。閃避期間可以在地面上跳躍，也可以依持續跑步輸入切換至跑步；
# 閃避完成後則回到預設狀態。
# 它是 PlayerStateMachine 的子狀態，透過 parent_state 通知上層狀態機切換狀態。
# ==========================================================

# 註冊為可供其他腳本引用的 PlayerDodgeState 類別。
class_name PlayerDodgeState
# 繼承 PlayerStateMachine，沿用玩家狀態機的生命週期及狀態轉換功能。
extends PlayerStateMachine


# run_state：閃避期間仍持續按住跑步時要切換到的跑步狀態。
@export var run_state: PlayerRunState
# jump_state：閃避期間在地面上剛按下跳躍時要切換到的跳躍狀態。
@export var jump_state: PlayerJumpState


# _ready() 在節點準備完成時由 Godot 呼叫；此處沿用父狀態機初始化。
func _ready():
	super._ready()


# enter() 在進入閃避狀態時呼叫；中斷攻擊、啟動閃避意圖並調整碰撞與速度。
func enter() -> void:
	# 避免閃避期間仍延續先前的近戰攻擊。
	player.melee_component.interrupt_attack()
	# 告知閃避元件玩家有意開始閃避。
	player.dodge_component.intent_to_dodge = true
	# 閃避期間暫時停用碰撞箱，避免一般受擊判定生效。
	player.hitbox_component.enabled = false
	# 將此狀態使用的移動速度設為 5。
	player.locomotion_component.speed = 5


# process_player() 逐次處理閃避期間的跳躍、跑步、完成條件與面向。
func process_player() -> void:
	# 剛按下跳躍鍵且玩家位於地面時，切換到跳躍狀態。
	if Input.is_action_just_pressed("jump") and \
	player.is_on_floor():
		parent_state.change_state(jump_state)
		return
	
	# 跑步狀態記錄仍按住跑步鍵時，接續切換至跑步狀態。
	if run_state.holding_down_run:
		parent_state.change_state(run_state)
		return
	
	# 閃避元件表示閃避動作已結束時，回到上層狀態機的預設狀態。
	if not player.dodge_component.dodging:
		parent_state.transition_to_default_state()
		return
	
	# 閃避進行中時，持續將玩家旋轉目標設為鎖定目標。
	player.set_rotation_target_to_lock_on_target()


# process_movement_animations() 將玩家輸入轉成閃避期間角色移動動畫的方向。
func process_movement_animations() -> void:
	# 取得玩家目前的輸入方向，作為角色動畫方向的候選值。
	var _animation_input_dir: Vector3 = player.input_direction
	# 輸入方向幾乎為零時，改用前方作為動畫方向，避免方向向量過小。
	if _animation_input_dir.length() < 0.1:
		_animation_input_dir = Vector3.FORWARD
	
	# 有鎖定目標時啟用閒置動畫的鎖定模式。
	player.character.idle_animations.active = player.lock_on_target != null
	# 將處理後的方向交給角色移動動畫系統。
	player.character.movement_animations.dir = _animation_input_dir


# exit() 在離開閃避狀態時呼叫，重新啟用碰撞箱。
func exit() -> void:
	# 恢復碰撞箱，讓玩家離開閃避後重新參與一般受擊判定。
	player.hitbox_component.enabled = true
