# ==============================================================
# 自由觀察相機狀態 (Free Look Camera State)
#
# 這是相機系統的預設狀態，玩家可以用滑鼠或搖桿自由環顧四周。
# 當偵測到鎖定系統鎖定目標時，會切換到 LockedOnState。
# ==============================================================
class_name CameraControllerFreeLookState
extends CameraControllerStateMachine

# 鎖定狀態的相機節點，鎖定目標後要切換到這個狀態
@export var lock_on_state: CameraControllerLockedOnState

# 是否正在用滑鼠移動視角
var _mouse_moving: bool = false
# 是否正在用搖桿移動視角
var _joystick_moving: bool = false

# 初始化時監聽鎖定系統的鎖定事件
func _ready():
	super._ready()

	lock_on_system.lock_on.connect(
		func(target: LockOnComponent):
			if not target:
				return

			parent_state.change_state(
				lock_on_state
			)
	)

# 每幀處理相機：讀取搖桿輸入來旋轉相機視角
func process_camera() -> void:
	var controller_look: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)

	if controller_look.length() > camera_controller.controller_deadzone:

		_joystick_moving = true

		var new_rotation_x: float = camera_controller.rotation.x \
			- controller_look.y \
			* camera_controller.controller_sensitivity

		camera_controller.rotation.x = lerp(
			camera_controller.rotation.x,
			new_rotation_x,
			0.8
		)

		camera_controller.rotation_degrees.x = clamp(
			camera_controller.rotation_degrees.x,
			-90.0,
			30.0
		)

		var new_rotation_y: float = camera_controller.rotation.y \
			- controller_look.x \
			* camera_controller.controller_sensitivity

		camera_controller.rotation.y = lerp(
			camera_controller.rotation.y,
			new_rotation_y,
			0.8
		)

		camera_controller.rotation_degrees.y = wrapf(
			camera_controller.rotation_degrees.y,
			0.0,
			360.0
		)
	else:
		_joystick_moving = false

	if _mouse_moving or _joystick_moving:
		camera_controller.looking_around = true
	else:
		camera_controller.looking_around = false

# 處理未被其他節點消耗的輸入事件：判斷滑鼠移動來旋轉相機視角
func process_unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		_mouse_moving = false
		return

	_mouse_moving = true

	var new_rotation_x: float = camera_controller.rotation.x \
		- event.relative.y * camera_controller.mouse_sensitivity

	camera_controller.rotation.x = lerp(
		camera_controller.rotation.x,
		new_rotation_x,
		0.8
	)

	camera_controller.rotation_degrees.x = clamp(
		camera_controller.rotation_degrees.x,
		-90.0,
		30.0
	)

	var new_rotation_y: float = camera_controller.rotation.y \
		- event.relative.x * camera_controller.mouse_sensitivity

	camera_controller.rotation.y = lerp(
		camera_controller.rotation.y,
		new_rotation_y,
		0.8
	)

	camera_controller.rotation_degrees.y = wrapf(
		camera_controller.rotation_degrees.y,
		0.0,
		360.0
	)
