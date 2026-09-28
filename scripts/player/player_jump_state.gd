# ==========================================================
# 【檔案說明】player_jump_state.gd
# 這是玩家跳躍狀態，進入時啟動跳躍元件，並在落地訊號到達後返回父狀態的預設狀態。
# 跳躍期間仍可依玩家輸入切換至攻擊、招架或防禦狀態，也會更新鎖定目標朝向。
# 若跳躍前處於行走狀態，會調整移動元件速度；若跳躍前處於跑步狀態，則依條件
# 停止朝鎖定目標旋轉。此狀態繼承 PlayerStateMachine。
# ==========================================================

# 註冊為 PlayerJumpState 類別，讓其他狀態可參照跳躍狀態。
class_name PlayerJumpState
# 繼承玩家狀態機的通用生命週期與狀態切換能力。
extends PlayerStateMachine


# 此狀態使用的移動元件；從行走狀態跳起時會調整它的速度。
@export var locomotion_component: LocomotionComponent

# 用來判斷跳躍前是否處於行走狀態，並在此情況調整速度。
@export var walk_state: PlayerWalkState
# 按下攻擊時要切換到的狀態。
@export var attack_state: PlayerAttackState
# 持續按住防禦輸入時要切換到的狀態。
@export var block_state: PlayerBlockState
# 剛按下防禦輸入時要切換到的招架狀態。
@export var parry_state: PlayerParryState


# _ready：節點就緒時先執行父類別初始化，再訂閱跳躍元件的落地訊號。
func _ready():
	# 執行父類別初始化，設定此狀態機的子狀態資料。
	super._ready()
	
	# （回呼內容）角色落地時，只有當跳躍仍是父狀態目前選中的狀態，才返回預設狀態。
	player.jump_component.just_landed.connect(
		func():
			if parent_state.current_state == self:
				parent_state.transition_to_default_state()
	)


# enter：進入跳躍狀態時啟動跳躍；若前一狀態是行走，將移動速度設為 3.5。
func enter() -> void:
	player.jump_component.start_jump()
	
	# 從行走狀態起跳時套用此速度；其他前一狀態不在此處改變速度。
	if parent_state.previous_state == walk_state:
		locomotion_component.speed = 3.5


# process_player：跳躍期間檢查攻擊與防禦輸入，並處理對鎖定目標的旋轉設定。
func process_player() -> void:
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
	
	# 更新旋轉目標，使角色可依目前鎖定對象調整朝向。
	player.set_rotation_target_to_lock_on_target()
	
	# 前一狀態是跑步或沒有鎖定目標時關閉朝目標旋轉；否則啟用。
	player.rotation_component.rotate_towards_target = false if (
		parent_state.previous_state is PlayerRunState or \
		not player.lock_on_target
	) else true
