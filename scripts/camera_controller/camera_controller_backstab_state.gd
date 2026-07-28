# ==============================================================
# 兩面刀相機狀態 (Backstab Camera State)
#
# 這個狀態負責當玩家對敵人發動「兩面刀」(backstab)攻擊時，
# 播放的專屬相機演出。與 dizzy_finisher 類似，
# 會把鏡頭拉近、以側面角度環繞殖読銀敊特寫演出。
#
# 內部使用兩個計時器來管理轉場時序：
# - _before_transition_out_timer: 目標消失後延遲 0.5 秒才關閉特寫演出
# - _late_transition_timer: 特寫關閉後延遲 0.5 秒才清除保存的目標節點
# ==============================================================
class_name CameraControllerBackstabState
extends CameraControllerStateMachine

# 一般狀態的相機節點，兩面刀演出結束後要切回這個狀態
@export var normal_state: CameraControllerNormalState

# 保存兩面刀目標節點，因為目標被打死後 BackstabComponent 會馬上變 null，
# 但演出收尾時仍需要目標的位置資訊
# used because backstab victim becomes null
# immediately after being killed
var _saved_backstab_victim: BackstabComponent

# 是否正在播放「拉近鏡頭特寫偏移」的兩面刀演出
# whether to do the offset zoom in thing
var _backstab_behaviour: bool = false

# 攝影機繞繞方向：1 代表往右偏移，-1 代表往左偏移
# 1 offsets the camera right
# -1 offset the camera left
var _cam_right_or_left: int = 1

# 第一個計時器：目標消失後延遲關閉特寫演出的等候時間
var _before_transition_out_timer: Timer
var _before_transition_out_length: float = 0.5

# 第二個計時器：特寫演出關閉後延遲清除保存目標的等候時間
var _late_transition_timer: Timer
var _late_transition_length: float = 0.5

# 從全局物件 Globals 取得兩面刀系統
@onready var backstab_system: BackstabSystem = Globals.backstab_system


# 初始化時建立并連線兩個計時器節點
func _ready():
	super._ready()

	# 建立「延遲關閉特寫演出」用的計時器
	_before_transition_out_timer = Timer.new()
	_before_transition_out_timer.autostart = false
	_before_transition_out_timer.one_shot = true
	_before_transition_out_timer.wait_time = _before_transition_out_length
	_before_transition_out_timer.timeout.connect(
		func():
			_backstab_behaviour = false
	)
	add_child(_before_transition_out_timer)

	# 建立「延遲清除保存目標」用的計時器
	_late_transition_timer = Timer.new()
	_late_transition_timer.autostart = false
	_late_transition_timer.one_shot = true
	_late_transition_timer.wait_time = _late_transition_length
	_late_transition_timer.timeout.connect(
		func():
			_saved_backstab_victim = null
	)
	add_child(_late_transition_timer)

# 進入這個狀態時執行一次：決定攝影機左右偏移方向，並重置兩個計時器
func enter() -> void:
	# 計算攝影機跟玩家朝向差來決定鏡頭应往哪邊繞
	var diff_in_rotation: float = wrapf(
		camera_controller.rotation_degrees.y - player.rotation_degrees.y,
		0.0,
		360.0
	)

	if 182 < diff_in_rotation and diff_in_rotation < 345:
		_cam_right_or_left = -1
	else:
		_cam_right_or_left = 1

	# 重置兩個計時器，避免上一次入場未完成的計時器影響本次進入
func enter() -> void:
	var diff_in_rotation: float = wrapf(
		camera_controller.rotation_degrees.y - player.rotation_degrees.y,
		0.0,
		360.0
	)

	if 182 < diff_in_rotation and diff_in_rotation < 345:
		_cam_right_or_left = -1
	else:
		_cam_right_or_left = 1

	_before_transition_out_timer.stop()
	_late_transition_timer.stop()
