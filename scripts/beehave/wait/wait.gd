@tool
# 等待節點：讓行為樹在此停留一段時間，可由黑板控制是否開始/重置等待
class_name Wait
extends ActionLeaf

# 等待時間（秒）
@export var time: float
# 完成後是否自動重置等待標記
@export var reset_wait_after: bool = false
# 此等待節點的唯一編號，用於黑板查詢
@export var wait_id: int
# 在編輯器中勾選此項可自動產生隨機 wait_id
@export var generate_wait_id: bool

var _timer: Timer = Timer.new()
var _finished: bool = false
var _waiting: bool = false


func _ready():
	if not Engine.is_editor_hint():
		# 計時器時間到後標記為完成
		_timer.timeout.connect(
			func():
				_finished = true
		)
		_timer.wait_time = time
		_timer.one_shot = true
		add_child(_timer)


func _process(_delta):
	# 編輯器模式下，若勾選了產生 wait_id，則隨機產生一個唯一編號
	if Engine.is_editor_hint() and generate_wait_id:
		generate_wait_id = false
		var rng = RandomNumberGenerator.new()
		wait_id = rng.randi_range(10000000, 99999999)


## Executes this node and returns a status code.
## This method must be overwritten.
func tick(_actor: Node, blackboard: Blackboard) -> int:
	if blackboard.get_value("wait_" + str(wait_id), true):
		# id in blackboard is true. this means start waiting.
		# 黑板中對應 id 為真，表示需要開始等待
		_finished = false
		if not _waiting:
			_waiting = true
			_timer.start()
			blackboard.set_value("wait_" + str(wait_id), false)
	elif not _waiting:
		# success if id is false and no waiting.
		# just a failsafe if the _finished flag doesn't work.
		# 若 id 為假且未在等待，直接返回成功（保陨機制）
		return SUCCESS
	
	if _finished:
		# timer finished
		# 計時器已完成，依需求重置等待標記並結束等待狀態
		blackboard.set_value("wait_" + str(wait_id), reset_wait_after)
		_waiting = false
		return SUCCESS
	
	return RUNNING
