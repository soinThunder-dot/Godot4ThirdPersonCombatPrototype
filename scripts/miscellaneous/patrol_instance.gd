# ==============================================================
# 巡邏實例 (PatrolInstance)
#
# 控制角色沿著 Path 進行巡邏移動，支援三種模式：
# 直線往返（LINEAR）、來回搖擺（OSCILLATE）、繫圈循環（CIRCUIT）。
# ==============================================================
class_name PatrolInstance
extends PathFollow3D

# 當巡邏狀態變化（開始/停止移動）時發出的訊號
signal move(flag: bool)

# 巡邏類型：直線、搖擺、循環
enum PatrolType {LINEAR, OSCILLATE, CIRCUIT}

# 是否顯示節點網格（偵除用）
@export var show_mesh: bool = false
# 巡邏類型
@export var patrol_type: PatrolType
# 是否正在巡邏
@export var patrol: bool = true
# 巡邏移動速度
@export var speed: float = 1.0
# 搖擺模式下，到達端點後停留的時間
@export var stationary_time: float = 8.0
# 開始巡邏前的延遲時間
@export var initial_delay: float = 0.0

# 目前移動方向（1 或 -1）
var direction: int = 1

# 上一次移動的方向（用於搖擺模式判斷下一次方向）
var _previous_direction: int
# 是否可以發出 move 訊號（避免重複發出）
var _can_emit_move: bool = true
# 搖擺模式下用於停留計時的 Timer
var _stationary_timer: Timer

# 初始化：設定網格可見性、建立停留計時器，並處理初始延遲﹣
func _ready():
	$Mesh.visible = show_mesh
	
	if patrol_type != PatrolType.CIRCUIT:
		loop = false
	
	_stationary_timer = Timer.new()
	_stationary_timer.autostart = false
	_stationary_timer.wait_time = stationary_time
	_stationary_timer.one_shot = true
	_stationary_timer.timeout.connect(
		func():
			move.emit(true)
			if _previous_direction == 1:
				direction = -1
			elif _previous_direction == -1:
				direction = 1
	)
	add_child(_stationary_timer)
	
	if initial_delay > 0:
		patrol = false
		get_tree().create_timer(initial_delay).timeout.connect(
			func(): patrol = true
		)
	
	move.emit(true)

# 每幀更新：根據巡邏類型呼叫對應的處理函式
func _process(delta: float) -> void:
	if not patrol: return
	match patrol_type:
		PatrolType.LINEAR: _handle_linear_patrol(delta)
		PatrolType.OSCILLATE: _handle_oscillate_patrol(delta)
		PatrolType.CIRCUIT: _handle_circuit_patrol(delta)

# 處理直線往返巡邏：到達終點後發出停止訊號
func _handle_linear_patrol(delta: float) -> void:
	if progress_ratio < 1.0:
		progress += direction * speed * delta
	elif _can_emit_move:
		move.emit(false)
		_can_emit_move = false

# 處理來回搖擺巡邏：到達端點後停留一段時間冗後反向
func _handle_oscillate_patrol(delta: float) -> void:
	if (direction == 1 and progress_ratio >= 1) or \
	(direction == -1 and progress_ratio <= 0):
		_previous_direction = direction
		direction = 0
		if _can_emit_move:
			_can_emit_move = false
			move.emit(false)
			_stationary_timer.start()
	else:
		progress += direction * speed * delta
		_can_emit_move = true

# 處理繫圈循環巡邏：持續沿路徑循環移動
func _handle_circuit_patrol(delta: float) -> void:
	progress += direction * speed * delta
