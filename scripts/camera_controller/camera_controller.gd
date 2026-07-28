# ==============================================================
# 一般相機控制器主檔 (Camera Controller)
#
# 這是整個相機系統的根節點（繼承自 SpringArm3D），
# 負責初始化相機參數、接收輸入事件，並把每幀的攝影機邏輯交給
# 子節點 StateMachine (camera_controller_state_machine.gd) 來處理，
# 它自己只負責提供基礎數值與工具方法。
# ==============================================================
class_name CameraController
extends SpringArm3D

# 總開關：如果關閉，相機就不會執行任何邏輯與接收輸入
@export var enabled: bool = true

@export_category("Camera Settings")
# 攝影機跟玩家之間的距離（SpringArm 的彈臂長度）
@export var camera_distance: float = 2.0
# 攝影機相對玩家的垂直高度偏移
@export var vertical_offset: float = 1.5
# 攝影機初始角度（目前未在 _ready 中使用，保留給其他狀態使用）
@export var camera_angle: float = 0.0
# 一般狀態下的視野角度(FOV)
@export var camera_fov: float = 75.0

@export_category("Mouse Settings")
# 鼠標控制相機的敏感度
@export var mouse_sensitivity: float = 5.0

@export_category("Spin Around Speed")
## The speed the camera tries to spin around
## to be behind the player when their are not running
# 玩家步行時，相機自動旋轉回到玩家背後的速度
@export var not_running_spin_speed: float = 4.0
## The speed the camera tries to spin around
## to be behind the player when their are running
# 玩家跡跑時，相機自動旋轉回到玩家背後的速度（比步行時快）
@export var running_spin_speed: float = 5.0

@export_category("Controller Settings")
# 手柄控制相機的敏感度
@export var controller_sensitivity: float = 14.0
# 手柄摸杆的死區(deadzone)，小於這個值的輸入会被忽略
@export var controller_deadzone: float = 0.2

@export_category("Lock On Settings")
# 鎖定模式下，希望目標在螢幕上的位置（用於計算相機要轉到哪裡才能把目標放在這個位字）
@export var desired_unproject_pos: float = 175.0

# 標記玩家是否正在手動控制鼠標/摇杆回頲相機（若為 true，就不自動旋轉回玩家背後）
var looking_around: bool

# 從全局物件 Globals 取得玩家節點參考
@onready var player: Player = Globals.player
# 從全局物件 Globals 取得目前的暈眩系統(DizzySystem)，用於查詢目標狀態
@onready var dizzy_system: DizzySystem = Globals.dizzy_system
# 子節點：实際的 Camera3D 節點，用來調整 FOV 等真正的鏡頭參數
@onready var cam: Camera3D = $Camera3D
# 子節點：相機狀態機，真正的相機邏輯都在這裡面執行
@onready var state_machine: CameraControllerStateMachine = $StateMachine


# 節點初始化時執行，設定初始相機參數並進入狀態機
func _ready() -> void:
	top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# 初始位置設在玩家上方(vertical_offset)的位字
	global_position = player.global_position + Vector3(
		0,
		vertical_offset,
		0
	)

	# SpringArm3D 的彈臂長度，決定攝影機跟玩家的距離
	spring_length = camera_distance

	cam.fov = camera_fov

	# 將敏感度數值縮放到合理的实作範圍(乘上 10^-3 或 10^-2/2)
	mouse_sensitivity = mouse_sensitivity * pow(10, -3)
	controller_sensitivity = controller_sensitivity * pow(10, -2) / 2

	# 通知狀態機正式進入運作，開始執行它的初始狀態
	state_machine.enter_state_machine()

# 每一物理影格執行，把相機邏輯交給狀態機處理
func _physics_process(_delta: float) -> void:
	# print(state_machine.current_state)
	if not enabled:
		return

	state_machine.process_camera_state_machine()

# 每次未被其他 UI 或元件拦截的輸入事件都会進入這裡，交給狀態機處理
func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	state_machine.process_unhandled_input_state_machine(event)

# 重置相機回到預設狀態（例如玩家從虛無空間彾復活時呼叫）
func reset() -> void:
	state_machine.transition_to_default_state()
	rotation_degrees.x = -20.0

# 玩家移動時呼叫，讓相機自動往玩家背後旋轉（除非玩家正在手動控制鏡頭）
func player_moving(move_direction: Vector3, running: bool, delta: float) -> void:
	if not looking_around:
		var new_rotation: float
		if running:
			# 跡跑時，依玩家横向移動方向，以跡跑速度翻轉目標角度
			new_rotation = rotation.y - sign(move_direction.x) * delta * running_spin_speed
		else:
			# 步行時，依玩家横向移動方向，以步行速度翻轉目標角度
			new_rotation = rotation.y - sign(move_direction.x) * delta * not_running_spin_speed
		# 平滑插值旋轉到新角度，避免鏡頭線段跳動
		rotation.y = lerp(rotation.y, new_rotation, 0.3)

# 計算指定目標在螢幕上的投影位置，用於鎖定目標UI顯示等需要
func get_lock_on_position(target: Node3D) -> Vector2:
	var pos = cam.unproject_position(target.global_position)
	return pos

