# ==============================================================
# 相機控制器狀態機基礎類 (Camera Controller State Machine Base)
#
# 這是所有相機子狀態(Normal/FreeLook/LockedOn/Backstab 等)的基礎類，
# 支援層級式嵌套狀態機，可當成標準狀態使用（無子狀態），
# 享可當容器使用（有子狀態，需要逐層向下呼叫 enter/process/exit）。
# ==============================================================
class_name CameraControllerStateMachine
extends Node

# 從屬的相機控制器節點
@export var camera_controller: CameraController
# 從屬的 3D 相機節點
@export var camera: Camera3D

# 目前所处的子狀態
var current_state: CameraControllerStateMachine
# 上層狀態（如果自己是子狀態機，這是自己的容器）
var parent_state: CameraControllerStateMachine
# 預設子狀態（通常是第一個子節點）
var default_state: CameraControllerStateMachine
# 是否含有子狀態（有子節點則為 true）
var has_sub_states: bool = false

# 玩家節點引用
@onready var player: Player =  Globals.player
# 鎖定系統引用
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system

# 初始化：判斷是否有子狀態，若有則設定預設狀態並把自己設為子狀態的 parent_state
func _ready():
	if get_child_count() > 0:
		has_sub_states = true
	else:
		return

	default_state = get_child(0)
	default_state.enter_state_machine()
	current_state = default_state

	for child in get_children():
		var sub_state: CameraControllerStateMachine = child
		sub_state.parent_state = self

# 切換回預設子狀態
func transition_to_default_state() -> void:
	if not default_state:
		return

	change_state(default_state)

# 切換到指定新子狀態：進入新狀態、離開舊狀態，並更新 current_state
func change_state(new_state: CameraControllerStateMachine) -> void:
	if not has_sub_states:
		return

	new_state.enter_state_machine()
	current_state.exit_state_machine()
	current_state = new_state

# 進入狀態機：先執行自己的 enter()，若有子狀態則逐層向下呼叫
func enter_state_machine() -> void:
	enter()

	if not has_sub_states:
		return

	current_state.enter_state_machine()

# 每幀處理相機：先執行自己的 process_camera()，若有子狀態則逐層向下呼叫
func process_camera_state_machine() -> void:
	process_camera()

	if not has_sub_states:
		return

	current_state.process_camera_state_machine()

# 處理未被消耗的輸入事件：先執行自己的 process_unhandled_input()，若有子狀態則逐層向下呼叫
func process_unhandled_input_state_machine(event: InputEvent) -> void:
	process_unhandled_input(event)

	if not has_sub_states:
		return

	current_state.process_unhandled_input_state_machine(event)

# 離開狀態機：先執行自己的 exit()，若有子狀態則逐層向下呼叫
func exit_state_machine() -> void:
	exit()

	if not has_sub_states:
		return

	current_state.exit_state_machine()

# 這些是供子類覆實的時機點函數，預設不做任何事
func enter() -> void:
	pass

func process_camera() -> void:
	pass

func process_unhandled_input(_event: InputEvent) -> void:
	pass

func exit() -> void:
	pass
