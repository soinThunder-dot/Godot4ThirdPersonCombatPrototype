@tool
@icon("../icons/tree.svg")
class_name BeehaveTree extends Node

## Controls the flow of execution of the entire behavior tree.
## 控制整個行為樹的執行流程。

enum { SUCCESS, FAILURE, RUNNING }

enum ProcessThread { IDLE, PHYSICS }
# 處理線程類型：IDLE 為每幀更新，PHYSICS 為物理更新
# 行為樹節點執行後可能返回的三種狀態（成功、失敗、執行中）

signal tree_enabled
signal tree_disabled

## Whether this behavior tree should be enabled or not.
## 此行為樹是否啟用。
@export var enabled: bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled and process_thread == ProcessThread.PHYSICS)
		set_process(enabled and process_thread == ProcessThread.IDLE)
		if value:
			tree_enabled.emit()
		else:
			interrupt()
			tree_disabled.emit()

	get:
		return enabled

## How often the tree should tick, in frames. The default value of 1 means
## tick() runs every frame.
## 行為樹多久 tick 一次（以幀數計算），默認 1 表示每幀都執行 tick()
@export var tick_rate: int = 1

## An optional node path this behavior tree should apply to.
## 行為樹適用的目標節點路徑（選填）。
@export_node_path var actor_node_path: NodePath:
	set(anp):
		actor_node_path = anp
		if actor_node_path != null and str(actor_node_path) != "..":
			actor = get_node(actor_node_path)
		else:
			actor = get_parent()
		if Engine.is_editor_hint():
			update_configuration_warnings()

## Whether to run this tree in a physics or idle thread.
## 此行為樹要在物理或閒置線程中執行。
@export var process_thread: ProcessThread = ProcessThread.PHYSICS:
	set(value):
		process_thread = value
		set_physics_process(enabled and process_thread == ProcessThread.PHYSICS)
		set_process(enabled and process_thread == ProcessThread.IDLE)

## Custom blackboard node. An internal blackboard will be used
## if no blackboard is provided explicitly.
## 自訂黑板節點。若未明確提供黑板，將使用內部黑板。
@export var blackboard: Blackboard:
	set(b):
		blackboard = b
		if blackboard and _internal_blackboard:
			remove_child(_internal_blackboard)
			_internal_blackboard.free()
			_internal_blackboard = null
		elif not blackboard and not _internal_blackboard:
			_internal_blackboard = Blackboard.new()
			add_child(_internal_blackboard, false, Node.INTERNAL_MODE_BACK)
	get:
		# in case blackboard is accessed before this node is,
		# we need to ensure that the internal blackboard is used.
		if not blackboard and not _internal_blackboard:
			_internal_blackboard = Blackboard.new()
			add_child(_internal_blackboard, false, Node.INTERNAL_MODE_BACK)
		return blackboard if blackboard else _internal_blackboard

## When enabled, this tree is tracked individually
## as a custom monitor.
## 啟用後，此行為樹將被單獨追蹤作為自訂監控項目。
@export var custom_monitor = false:
	set(b):
		custom_monitor = b
		if custom_monitor and _process_time_metric_name != "":
			Performance.add_custom_monitor(
				_process_time_metric_name, _get_process_time_metric_value
			)
			_get_global_metrics().register_tree(self)
		else:
			if _process_time_metric_name != "":
				# Remove tree metric from the engine
				Performance.remove_custom_monitor(_process_time_metric_name)
				_get_global_metrics().unregister_tree(self)

			BeehaveDebuggerMessages.unregister_tree(get_instance_id())

@export var actor: Node:
	set(a):
		actor = a
		if actor == null:
			actor = get_parent()
		if Engine.is_editor_hint():
			update_configuration_warnings()

var status: int = -1
var last_tick: int = 0

# 內部黑板節點（未提供外部黑板時自動建立）
var _internal_blackboard: Blackboard
var _process_time_metric_name: String
var _process_time_metric_value: float = 0.0
var _can_send_message: bool = false


## 節點就緒時初始化：連接場景樹節點新增/移除信號，並設定預設處理線程、演员與黑板
func _ready() -> void:
	if not get_tree().is_connected("node_added", _on_scene_tree_node_added_removed.bind(true)):
		get_tree().node_added.connect(_on_scene_tree_node_added_removed.bind(true))
	if not get_tree().is_connected("node_removed", _on_scene_tree_node_added_removed.bind(false)):
		get_tree().node_removed.connect(_on_scene_tree_node_added_removed.bind(false))


	if not process_thread:
		process_thread = ProcessThread.PHYSICS

	if not actor:
		if actor_node_path:
			actor = get_node(actor_node_path)
		else:
			actor = get_parent()

	if not blackboard:
		# invoke setter to auto-initialise the blackboard.
		self.blackboard = null

	# Get the name of the parent node name for metric
	_process_time_metric_name = (
		"beehave [microseconds]/process_time_%s-%s" % [actor.name, get_instance_id()]
	)

	set_physics_process(enabled and process_thread == ProcessThread.PHYSICS)
	set_process(enabled and process_thread == ProcessThread.IDLE)

	# Register custom metric to the engine
	if custom_monitor and not Engine.is_editor_hint():
		Performance.add_custom_monitor(_process_time_metric_name, _get_process_time_metric_value)
		_get_global_metrics().register_tree(self)

	if Engine.is_editor_hint():
		update_configuration_warnings.call_deferred()
	else:
		_get_global_debugger().register_tree(self)
		BeehaveDebuggerMessages.register_tree(_get_debugger_data(self))

	# Randomize at what frames tick() will happen to avoid stutters
	last_tick = randi_range(0, tick_rate - 1)


## 當場景樹中新增或移除節點時呼叫，用於重新檢查子節點結構並更新行為樹狀態
func _on_scene_tree_node_added_removed(node: Node, is_added: bool) -> void:
	if Engine.is_editor_hint():
		return

	if node is BeehaveNode and is_ancestor_of(node):
		var sgnal := node.ready if is_added else node.tree_exited
		if is_added:
			sgnal.connect(
				func() -> void: BeehaveDebuggerMessages.register_tree(_get_debugger_data(self)),
				CONNECT_ONE_SHOT
			)
		else:
			sgnal.connect(
				func() -> void:
					BeehaveDebuggerMessages.unregister_tree(get_instance_id())
					request_ready()
			)


## 物理幀更新回調，交由內部處理函式執行
func _physics_process(_delta: float) -> void:
	_process_internally()


func _process(_delta: float) -> void:
## 閒置幀更新回調，交由內部處理函式執行
	_process_internally()


func _process_internally() -> void:
## 實際執行行為樹 tick 邏輯的核心函式，包含隔幀控制、性能量測與除錯器訊息回報
	if Engine.is_editor_hint():
		return

	if last_tick < tick_rate - 1:
		last_tick += 1
		return

	last_tick = 0

	# Start timing for metric
	var start_time = Time.get_ticks_usec()

	blackboard.set_value("can_send_message", _can_send_message)

	if _can_send_message:
		BeehaveDebuggerMessages.process_begin(get_instance_id())

	if self.get_child_count() == 1:
		tick()

	if _can_send_message:
		BeehaveDebuggerMessages.process_end(get_instance_id())

	# Check the cost for this frame and save it for metric report
	_process_time_metric_value = Time.get_ticks_usec() - start_time


## 執行行為樹的單次 tick，呼叫根節點的 tick 並回傳執行結果狀態
func tick() -> int:
	if actor == null or get_child_count() == 0:
		return FAILURE
	var child := self.get_child(0)
	if status != RUNNING:
		child.before_run(actor, blackboard)

	status = child.tick(actor, blackboard)
	if _can_send_message:
		BeehaveDebuggerMessages.process_tick(child.get_instance_id(), status)
		BeehaveDebuggerMessages.process_tick(get_instance_id(), status)

	# Clear running action if nothing is running
	if status != RUNNING:
		blackboard.set_value("running_action", null, str(actor.get_instance_id()))
		child.after_run(actor, blackboard)

	return status


func _get_configuration_warnings() -> PackedStringArray:
## 檢查行為樹本身的設定是否正確，並在編輯器中顯示相應警告（例如未設定演員、無子節點等）
	var warnings: PackedStringArray = []

	if actor == null:
		warnings.append("Configure target node on tree")

	if get_children().any(func(x): return not (x is BeehaveNode)):
		warnings.append("All children of this node should inherit from BeehaveNode class.")

	if get_child_count() != 1:
		warnings.append("BeehaveTree should have exactly one child node.")

	return warnings


## Returns the currently running action
## 回傳目前正在執行中的動作節點
func get_running_action() -> ActionLeaf:
	return blackboard.get_value("running_action", null, str(actor.get_instance_id()))


## Returns the last condition that was executed
## 回傳最後一次執行的條件節點
func get_last_condition() -> ConditionLeaf:
	return blackboard.get_value("last_condition", null, str(actor.get_instance_id()))


## Returns the status of the last executed condition
## 回傳最後一次執行條件節點的狀態結果
func get_last_condition_status() -> String:
	if blackboard.has_value("last_condition_status", str(actor.get_instance_id())):
		var status = blackboard.get_value(
			"last_condition_status", null, str(actor.get_instance_id())
		)
		if status == SUCCESS:
			return "SUCCESS"
		elif status == FAILURE:
			return "FAILURE"
		else:
			return "RUNNING"
	return ""


## interrupts this tree if anything was running
## 如果目前有執行中的節點，則中斷整個行為樹
func interrupt() -> void:
	if self.get_child_count() != 0:
		var first_child = self.get_child(0)
		if "interrupt" in first_child:
			first_child.interrupt(actor, blackboard)


## Enables this tree.
## 啟用此行為樹
func enable() -> void:
	self.enabled = true


## Disables this tree.
## 停用此行為樹
func disable() -> void:
	self.enabled = false


## 節點離開場景樹時清理：移除自訂監控器登記、取消除錯器追蹤
func _exit_tree() -> void:
	if custom_monitor:
		if _process_time_metric_name != "":
			# Remove tree metric from the engine
			Performance.remove_custom_monitor(_process_time_metric_name)
			_get_global_metrics().unregister_tree(self)

		BeehaveDebuggerMessages.unregister_tree(get_instance_id())


# Called by the engine to profile this tree
# 由引擎呼叫以分析此行為樹的性能
func _get_process_time_metric_value() -> int:
	return int(_process_time_metric_value)


# 遞迴建立節點及其子節點的除錯訊息資料（供外部除錯工具使用）
func _get_debugger_data(node: Node) -> Dictionary:
	if not (node is BeehaveTree or node is BeehaveNode):
		return {}

	var data := {
		path = node.get_path(),
		name = node.name,
		type = node.get_class_name(),
		id = str(node.get_instance_id())
	}
	if node.get_child_count() > 0:
		data.children = []
	for child in node.get_children():
		var child_data := _get_debugger_data(child)
		if not child_data.is_empty():
			data.children.push_back(child_data)
	return data


# 回傳此節點所屬的自訂類別名稱陣列（供除錯與型別識別使用）
func get_class_name() -> Array[StringName]:
	return [&"BeehaveTree"]


# 避免在初始載入時因 autoload 載入順序問題而發生生命周期錯誤
# 取得全局性能監控器（BeehaveGlobalMetrics）節點參考
# required to avoid lifecycle issues on initial load
# due to loading order problems with autoloads
func _get_global_metrics() -> Node:
	return get_tree().root.get_node("BeehaveGlobalMetrics")


# 取得全局除錯器（BeehaveGlobalDebugger）節點參考
# required to avoid lifecycle issues on initial load
# due to loading order problems with autoloads
func _get_global_debugger() -> Node:
	return get_tree().root.get_node("BeehaveGlobalDebugger")
