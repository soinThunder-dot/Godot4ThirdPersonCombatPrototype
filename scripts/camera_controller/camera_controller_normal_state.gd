# ==============================================================
# 一般相機狀態 (Normal Camera State)
#
# 這是相機子狀態機的預設行為，持續跟隨玩家並重設 FOV 與旋轉。
# 若偵測到玩家進入昇迷終結技(dizzy)或兩面刀(backstab)演出，
# 會切換到對應的相機子狀態。
# ==============================================================
class_name CameraControllerNormalState
extends CameraControllerStateMachine

# 昇迷終結技相機狀態節點
@export var dizzy_finisher_state: CameraControllerDizzyFinisherState
# 兩面刀相機狀態節點
@export var backstab_state: CameraControllerBackstabState

# 每幀處理相機：檢查是否需要切換到兩面刀或昇迷演出，否則保持相機正常跟隨玩家
func process_camera() -> void:
	var dizzy_victim: DizzyComponent = Globals.dizzy_system.dizzy_victim
	if player.state_machine.current_state is PlayerDizzyFinisherState and \
	dizzy_victim != null:
		parent_state.change_state(
			dizzy_finisher_state
		)

	if Globals.backstab_system.backstab_victim != null and \
	player.state_machine.current_state is PlayerBackstabState and \
	player.state_machine.current_state.current_state is PlayerBackstabAttackState:
		parent_state.change_state(
			backstab_state
		)

	camera.fov = move_toward(
		camera.fov,
		camera_controller.camera_fov,
		2
	)

	camera_controller.global_position = camera_controller.global_position.lerp(
		player.global_position + Vector3(
			0,
			camera_controller.vertical_offset,
			0
		),
		0.1
	)

	camera.rotation = camera.rotation.lerp(Vector3.ZERO, 0.05)
