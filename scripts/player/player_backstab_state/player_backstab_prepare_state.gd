# ==========================================================
# 【檔案說明】player_backstab_prepare_state.gd
# 這是玩家背刺流程中的準備子狀態，讀取閃避、跳躍、攻擊與防禦等輸入。
# 玩家可在此階段取消背刺並切往一般動作；按下攻擊則進入背刺攻擊子狀態。
# 若背刺目標消失，會請上層玩家狀態機回到預設狀態；有目標時則讓玩家朝向目標。
# 此狀態位於 PlayerBackstabState 之下，利用 PlayerStateMachine 的 parent_state 管理切換。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerBackstabPrepareState 類別。
class_name PlayerBackstabPrepareState
# 繼承玩家狀態機節點，使用共用的進入、更新與離開流程。
extends PlayerStateMachine


# 玩家在準備背刺時按下奔跑鍵，可切換到的閃避狀態。
@export var dodge_state: PlayerDodgeState
# 玩家在地面按下跳躍鍵時可切換到的跳躍狀態。
@export var jump_state: PlayerJumpState
# 一般近戰攻擊狀態；本腳本目前只保留此引用，實際攻擊輸入會改進背刺攻擊。
@export var attack_state: PlayerAttackState
# 持續按住防禦時可切換到的格擋狀態。
@export var block_state: PlayerBlockState
# 剛按下防禦鍵時可切換到的招架狀態。
@export var parry_state: PlayerParryState
# 按下攻擊鍵後要進入的背刺攻擊子狀態。
@export var backstab_attack_state: PlayerBackstabAttackState

# main_state：保存玩家主要狀態機，用於從本子狀態直接切換到閃避、跳躍等一般狀態。
var main_state : PlayerStateMachine

# _ready：節點初始化時呼叫；先讓父類別設定子狀態機與父狀態引用。
func _ready():
	super._ready()


# enter：進入背刺準備狀態時呼叫；沿父子狀態機關係取得玩家主要狀態機。
func enter() -> void:
	main_state = parent_state.parent_state


# process_player：每次玩家狀態更新時讀取輸入、檢查背刺目標並控制面向。
func process_player() -> void:
	# 若本影格剛按下奔跑鍵，就切到一般閃避狀態並結束本次更新。
	if Input.is_action_just_pressed("run"):
		main_state.change_state(dodge_state)
		return
	
	# 若剛按下跳躍鍵且角色目前站在地面上，就切到跳躍狀態。
	# 反斜線讓同一個 if 條件接續到下一行；註解因此放在條件之前。
	if Input.is_action_just_pressed("jump") and \
	player.is_on_floor():
		main_state.change_state(jump_state)
		return
	
	# 若剛按下攻擊鍵，切換本背刺流程的子狀態以執行背刺攻擊。
	if Input.is_action_just_pressed("attack"):
		parent_state.change_state(backstab_attack_state)
		return
	
	# 若剛按下防禦鍵，優先切換到招架狀態，並結束本次更新。
	if Input.is_action_just_pressed("block"):
		main_state.change_state(parry_state)
		return
	
	# 若防禦鍵仍處於按住狀態（不只剛按下），切換到格擋狀態。
	if Input.is_action_pressed("block"):
		main_state.change_state(block_state)
		return
	
	# 背刺系統沒有可用目標時，請玩家主要狀態機回到預設狀態。
	if not Globals.backstab_system.backstab_victim:
		main_state.transition_to_default_state()
	
	# 讀取目前背刺目標；若存在就以該目標作為旋轉目標。
	var victim: = Globals.backstab_system.backstab_victim
	if victim:
		player.rotation_component.target = victim
	# 沒有背刺目標時改以鎖定系統目標作為面向依據。
	else:
		player.set_rotation_target_to_lock_on_target()
	
	# 若鎖定系統有目標，讓角色朝向目前的鎖定目標。
	player.set_rotate_towards_target_if_lock_on_target()


# process_movement_animations：更新準備背刺時的待機與移動動畫參數。
func process_movement_animations() -> void:
	# 啟用角色待機動畫控制。
	player.character.idle_animations.active = true
	# 將玩家輸入方向交給移動動畫，讓動畫反映目前的操作方向。
	player.character.movement_animations.dir = player.input_direction


# exit：離開準備狀態時呼叫；此狀態目前沒有需要還原或清除的資料。
func exit() -> void:
	pass
