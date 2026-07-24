@tool
@icon("../../icons/selector.svg")
class_name SelectorComposite extends Composite

## Selector nodes will attempt to execute each of its children until one of
## them return `SUCCESS`. If all children return `FAILURE`, this node will also
## return `FAILURE`.
## If a child returns `RUNNING` it will tick again.
## 選擇組合節點：依序執行子節點，直到有一個回傳 SUCCESS；若全部失敗則回傳 FAILURE，若遇到 RUNNING 則下次繼續從同一點執行

# 記錄上次執行到的子節點索引（用於 RUNNING 狀態下繼續從同一點執行）
var last_execution_index: int = 0

# 每幀執行一次行為樹邏輯：依序遍歷子節點並執行，處理成功/失敗/執行中三種狀態

func tick(actor: Node, blackboard: Blackboard) -> int:
	for c in get_children():
		if c.get_index() < last_execution_index:
			continue

		if c != running_child:
			c.before_run(actor, blackboard)

		var response = c.tick(actor, blackboard)
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

		if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		match response:
			SUCCESS:
				_cleanup_running_task(c, actor, blackboard)
				c.after_run(actor, blackboard)
				return SUCCESS
			FAILURE:
				_cleanup_running_task(c, actor, blackboard)
				last_execution_index += 1
				c.after_run(actor, blackboard)
			RUNNING:
				running_child = c
				if c is ActionLeaf:
					blackboard.set_value("running_action", c, str(actor.get_instance_id()))
				return RUNNING

	return FAILURE


# 執行結束後重置索引，讓下次執行從第一個子節點開始
func after_run(actor: Node, blackboard: Blackboard) -> void:
	last_execution_index = 0
	super(actor, blackboard)


# 節點被中斷時重置索引，讓下次執行從第一個子節點開始
func interrupt(actor: Node, blackboard: Blackboard) -> void:
	last_execution_index = 0
	super(actor, blackboard)


## Changes `running_action` and `running_child` after the node finishes executing.
## 當子節點完成執行後，更新 running_action 與 running_child 的狀態
func _cleanup_running_task(finished_action: Node, actor: Node, blackboard: Blackboard):
	var blackboard_name = str(actor.get_instance_id())
	if finished_action == running_child:
		running_child = null
		if finished_action == blackboard.get_value("running_action", null, blackboard_name):
			blackboard.set_value("running_action", null, blackboard_name)


# 回報此節點的類別名稱陣列（用於編輯器與除錯輸出識別）
func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SelectorComposite")
	return classes
