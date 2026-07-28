# ==============================================================
# 虛無深渊相機狀態 (Void Camera State)
#
# 當玩家掉入虛無深渊時，這個狀態會接手控制相機，
# 讓相機自動面向玩家並拉回預設視野角(FOV)。
# ==============================================================
class_name CameraControllersVoidState
extends CameraControllerStateMachine

# 初始化時監聽虛無死亡系統，玩家掉入虛無時切換到自己
func _ready():
	super._ready()

	Globals.void_death_system.fallen_into_the_void.connect(
		func(body: Node3D):
			if body is Player:
				parent_state.change_state(self)
	)

# 進入這個狀態時不做任何額外行為
func enter() -> void:
	pass

# 每幀處理相機：讓相機自動面向玩家並逐步拉回預設 FOV
func process_camera() -> void:
	camera.fov = move_toward(
		camera.fov,
		camera_controller.camera_fov,
		2
	)

	var _player: Player = Globals.player

	var _looking_direction: Vector3 = camera_controller\
		.global_position\
		.direction_to(
			_player.global_position
		)
	_looking_direction = -_looking_direction

	var _target_look: float = atan2(
		_looking_direction.x,
		_looking_direction.z
	)

	var desired_rotation_y: float = lerp_angle(
		camera_controller.rotation.y,
		_target_look,
		0.05
	)

	camera_controller.rotation.y = lerp(
		camera_controller.rotation.y,
		desired_rotation_y,
		0.8
	)

	var dist_to_target: float = camera\
		.global_position\
		.distance_to(
			_player.global_position
		)

	var project_desired_pos: Vector3 = camera.project_position(
		Vector2(
			get_viewport().size.x / 2,
			get_viewport().size.y / 2
		),
		dist_to_target
	)

	var desired_rotation_x: float = camera_controller.rotation.x \
		+ atan2(
			_player.global_position.y - project_desired_pos.y,
			dist_to_target
		)

	desired_rotation_x = rad_to_deg(desired_rotation_x)

	camera_controller.rotation_degrees.x = lerp(
		camera_controller.rotation_degrees.x,
		desired_rotation_x,
		0.1
	)

# 這個狀態不處理任何輸入事件
func process_unhandled_input(_event: InputEvent) -> void:
	pass

# 離開這個狀態時不做任何額外行為
func exit() -> void:
	pass
