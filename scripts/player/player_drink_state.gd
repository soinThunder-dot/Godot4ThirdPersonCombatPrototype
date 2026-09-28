# ==========================================================
# 【檔案說明】player_drink_state.gd
# 這是玩家使用生命補充道具的狀態。
# 它作為 PlayerStateMachine 的子狀態，在玩家按下使用道具時開始消耗補充量，
# 暫時降低移動速度並播放步行動畫；補充動作完成或狀態結束時回到一般狀態並還原設定。
# ==========================================================

# 註冊這個狀態的全域類別名稱，供其他腳本辨識與引用。
class_name PlayerDrinkState
# 繼承玩家狀態機，使用共用的狀態切換與生命週期流程。
extends PlayerStateMachine


# 可在 Inspector 指定移動元件，用來在飲用期間調整玩家移動速度。
@export var locomotion_component: LocomotionComponent
# 可在 Inspector 指定生命補充元件，負責消耗補充量並發出飲用完成訊號。
@export var health_charge_component: HealthChargeComponent
# 可在 Inspector 指定移動動畫資料，用來暫存並調整動畫播放速度。
@export var movement_animations: MovementAnimations

# 保存進入飲用狀態前的移動動畫速度，離開時用來還原。
var _prev_walk_speed: float


# _ready：節點初始化時呼叫；初始化父狀態機並連接飲用完成訊號。
func _ready():
	# 執行父狀態機的初始化。
	super()
	# （回呼內容）生命補充元件完成飲用時，請父狀態機切回預設狀態。
	health_charge_component.finished_drinking.connect(
		func(): parent_state.transition_to_default_state()
	)


# _process：每個影格檢查道具輸入；符合條件時切換到飲用狀態。
func _process(_delta: float) -> void:
	# 按下使用道具鍵，且目前不是飲用狀態或檢查點狀態，才開始飲用。
	if Input.is_action_just_pressed("consume_item") and \
	parent_state.current_state != PlayerDrinkState and \
	not parent_state.current_state is PlayerCheckpointState:
		parent_state.change_state(self)


# enter：進入飲用狀態時消耗生命補充量、停用頭部轉動，並調整移動速度。
func enter() -> void:
	# 啟動生命補充流程，並暫時停用頭部旋轉以配合飲用動作。
	health_charge_component.consume_health_charge()
	player.head_rotation_component.enabled = false
	# 飲用期間降低實際移動速度，並記住原本的動畫速度。
	locomotion_component.speed = 0.8
	_prev_walk_speed = movement_animations.speed


# process_player：逐影格將玩家旋轉目標設為鎖定目標，並依鎖定狀況更新朝向。
func process_player() -> void:
	player.set_rotation_target_to_lock_on_target()
	player.set_rotate_towards_target_if_lock_on_target()


# process_movement_animations：飲用期間保持玩家輸入方向並播放較慢的步行動畫。
func process_movement_animations() -> void:
	# 有鎖定目標時啟用相應待機動畫，並將動畫移動方向設為玩家輸入方向。
	player.character.idle_animations.active = player.lock_on_target != null
	player.character.movement_animations.dir = player.input_direction
	# 指定步行動畫狀態，並將動畫速度降低至 0.5。
	player.character.movement_animations.set_state("walk")
	movement_animations.speed = 0.5


# exit：離開飲用狀態時重新啟用頭部旋轉、中斷補充流程並恢復原動畫速度。
func exit() -> void:
	player.head_rotation_component.enabled = true
	# 若補充動作尚未完成，呼叫元件的中斷方法；名稱依原始程式保留為 interupt。
	player.health_charge_component.interupt()
	movement_animations.speed = _prev_walk_speed
