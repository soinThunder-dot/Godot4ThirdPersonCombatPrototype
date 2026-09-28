# ==========================================================
# 【檔案說明】player_checkpoint_state.gd
# 這是玩家在檢查點坐下並使用檢查點介面的狀態。
# 它作為 PlayerStateMachine 的子狀態，在玩家互動且目前檢查點允許坐下時進入；
# 進入後暫停一般移動與受擊，顯示檢查點選單，離開時再恢復玩家控制與 HUD。
# ==========================================================

# 註冊這個狀態的全域類別名稱，供其他腳本辨識與引用。
class_name PlayerCheckpointState
# 繼承玩家狀態機，沿用 enter、exit、process_player 等狀態生命週期流程。
extends PlayerStateMachine


# 記錄是否已開始離開檢查點；此旗標可供其他邏輯判斷離開流程。
var _exiting: bool = false

# 取得全域使用者介面，供本狀態操作 HUD 與檢查點選單。
@onready var user_interface: UserInterface = Globals.user_interface
# 取得全域相機控制器；此腳本目前保留此參照。
@onready var camera_controller: CameraController = Globals.camera_controller
# 取得全域鎖定系統；此腳本目前保留此參照。
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system
# 取得全域檢查點系統，用來讀取目前檢查點並管理提示與存檔。
@onready var checkpoint_system: CheckpointSystem = Globals.checkpoint_system


# _ready：節點加入場景並完成初始設定時呼叫；先執行父狀態機的初始化，再接上相關訊號。
func _ready():
	# 呼叫 PlayerStateMachine 的 _ready，初始化父子狀態機關係。
	super()
	
	# （回呼內容）坐下動畫抵達坐下姿勢時，如果本狀態仍是目前狀態，就顯示檢查點選單。
	player.character.sit_animations.sat_down.connect(
		func():
			if parent_state.current_state == self:
				user_interface.checkpoint_interface.show_menu()
	)
	
	# （回呼內容）坐下動畫播放完成時，如果本狀態仍有效，就切回父狀態機的預設狀態。
	player.character.sit_animations.finished.connect(
		func():
			if parent_state.current_state == self:
				parent_state.transition_to_default_state()
	)
	
	# （回呼內容）檢查點介面發出離開訊號時，呼叫本狀態的起身處理函式。
	user_interface.checkpoint_interface.exit_checkpoint.connect(
		_stand_up
	)


# _process：每個影格檢查互動輸入；只有條件都成立時才切換到檢查點狀態。
func _process(_delta: float) -> void:
	# 按下互動鍵、玩家不在死亡狀態、目前尚未使用檢查點，且有可坐下的目前檢查點時進入本狀態。
	if Input.is_action_just_pressed("interact") and \
	not parent_state.current_state is PlayerDeathState and \
	parent_state.current_state != self and \
	checkpoint_system.current_checkpoint and \
	checkpoint_system.current_checkpoint.can_sit_at_checkpoint:
		parent_state.change_state(self)


# enter：狀態切入時執行；開始坐下、停用一般受擊與 HUD，並儲存目前檢查點。
func enter() -> void:
	# 新進入檢查點時，清除正在離開的標記。
	_exiting = false
	
	# 播放坐下動畫，並改用根運動策略配合動畫控制位移。
	player.character.sit_animations.sit_down()
	player.locomotion_component.set_active_strategy("root_motion")
	# 坐下期間關閉碰撞受擊盒，避免玩家在選單中受到攻擊。
	player.hitbox_component.enabled = false
	# 將旋轉目標設為目前檢查點，並啟用朝向目標的旋轉。
	player.rotation_component.target = checkpoint_system.current_checkpoint
	
	player.rotation_component.rotate_towards_target = true
	# 使用檢查點時清除鎖定目標，避免沿用戰鬥中的鎖定。
	Globals.lock_on_system.reset_target()
	
	
	# 隱藏檢查點提示並儲存目前檢查點。
	checkpoint_system.disable_hint()
	checkpoint_system.save_current_checkpoint()
	
	# 隱藏遊戲 HUD，讓檢查點介面成為目前主要介面。
	user_interface.hud.enabled = false


# process_player：此狀態不需要額外的逐影格玩家邏輯，因此保留空實作。
func process_player() -> void:
	pass


# process_movement_animations：更新待機與移動動畫參數；坐著時將移動方向設為零。
func process_movement_animations() -> void:
	# 若玩家有鎖定目標，待機動畫系統維持啟用；沒有目標則停用該待機分支。
	player.character.idle_animations.active = player.lock_on_target != null
	player.character.movement_animations.dir = Vector3.ZERO


# exit：離開此狀態時恢復一般移動、受擊、提示與 HUD，並清除旋轉目標。
func exit() -> void:
	# 切回程式控制移動，重新允許旋轉與受擊。
	player.locomotion_component.set_active_strategy("programmatic")
	player.rotation_component.can_rotate = true
	player.hitbox_component.enabled = true
	
	# 重新顯示檢查點提示與 HUD，並關閉檢查點介面。
	checkpoint_system.enable_hint()
	
	user_interface.hud.enabled = true
	user_interface.checkpoint_interface.visible = false
	
	# 離開檢查點時停止自動朝向檢查點，並清除旋轉目標參照。
	player.rotation_component.rotate_towards_target = false
	player.rotation_component.target = null
	


# _stand_up：由檢查點介面的離開訊號呼叫；播放起身動畫、收起選單並標記離開流程。
func _stand_up() -> void:
	player.character.sit_animations.stand_up()
	user_interface.checkpoint_interface.hide_menu()
	# 捕捉滑鼠以恢復遊戲操作；此設定使用 Godot 的滑鼠模式常數。
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_exiting = true
