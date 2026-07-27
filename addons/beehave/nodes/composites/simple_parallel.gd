@tool
@icon("../../icons/simple_parallel.svg")
class_name SimpleParallelComposite extends Composite

## Simple Parallel nodes will attampt to execute all chidren at same time and
## can only have exactly two children. First child as primary node, second
## child as secondary node.
## This node will always report primary node's state, and continue tick while
## primary node return 'RUNNING'. The state of secondary node will be ignored
## and executed like a subtree.
## If primary node return 'SUCCESS' or 'FAILURE', this node will interrupt
## secondary node and return primary node's result.
## If this node is running under delay mode, it will wait seconday node
## finish its action after primary node terminates.

#how many times should secondary node repeat, zero means loop forever
# 次要節點應重複多少次，0 代表無限循環
@export var secondary_node_repeat_count:int = 0

#wether to wait secondary node finish its current action after primary node finished
# 主節點結束後是否要等待次要節點完成目前動作
@export var delay_mode:bool = false

var delayed_result := SUCCESS
var main_task_finished:bool = false
var secondary_node_running:bool = false
var secondary_node_repeat_left:int = 0


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()

	# 必須恰好有兩個子節點
	if get_child_count() != 2:
		warnings.append("SimpleParallel should have exactly two child nodes.")

	# 第一個子節點必須是動作叶節點
	if not get_child(0) is ActionLeaf:
		warnings.append("SimpleParallel should have an action leaf node as first child node.")

	return warnings


func tick(actor, blackboard: Blackboard):
	for c in get_children():
		var node_index = c.get_index()
		if node_index == 0 and not main_task_finished:
			# 主節點（第一個子節點）尚未完成時，執行它
			if c != running_child:
				c.before_run(actor, blackboard)

			var response = c.tick(actor, blackboard)
			if can_send_message(blackboard):
				BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

			delayed_result = response
			match response:
				SUCCESS,FAILURE:
					# 主節點已結束（成功或失敗）
					_cleanup_running_task(c, actor, blackboard)
					c.after_run(actor, blackboard)
					main_task_finished = true
					# 非延遲模式下，立即中斷次要節點並回傳主節點結果
					if not delay_mode:
						if secondary_node_running:
							get_child(1).interrupt(actor, blackboard)
						_reset()
						return delayed_result
				RUNNING:
					# 主節點仍在執行中，記錄為目前執行中的子節點
					running_child = c
					if c is ActionLeaf:
						blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		elif node_index == 1:
			# 次要節點（第二個子節點）：若尚有剩餘重複次數或無限循環，則執行它
			if secondary_node_repeat_count == 0 or secondary_node_repeat_left > 0:
				if not secondary_node_running:
					c.before_run(actor, blackboard)

				var subtree_response = c.tick(actor, blackboard)
				if subtree_response != RUNNING:
					secondary_node_running = false
					c.after_run(actor, blackboard)
					# 若是延遲模式且主節點已結束，則現在可以回傳結果了
					if delay_mode and main_task_finished:
						_reset()
						return delayed_result
					elif secondary_node_repeat_left > 0:
						secondary_node_repeat_left -= 1
				else:
					secondary_node_running = true

	return RUNNING


func before_run(actor: Node, blackboard:Blackboard) -> void:
	# 重置次要節點的剩餘重複次數
	secondary_node_repeat_left = secondary_node_repeat_count
	super(actor, blackboard)


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	# 中斷主節點與次要節點
	if not main_task_finished:
		get_child(0).interrupt(actor, blackboard)
	if secondary_node_running:
		get_child(1).interrupt(actor, blackboard)
	_reset()
	super(actor, blackboard)


func after_run(actor: Node, blackboard: Blackboard) -> void:
	_reset()
	super(actor, blackboard)


func _reset() -> void:
	# 重置主節點與次要節點的狀態標記
	main_task_finished = false
	secondary_node_running = false


## Changes `running_action` and `running_child` after the node finishes executing.
## 當節點執行完成後，更新 `running_action` 與 `running_child`
func _cleanup_running_task(finished_action: Node, actor: Node, blackboard: Blackboard):
	var blackboard_name = str(actor.get_instance_id())
	if finished_action == running_child:
		running_child = null
	if finished_action == blackboard.get_value("running_action", null, blackboard_name):
		blackboard.set_value("running_action", null, blackboard_name)


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SimpleParallelComposite")
	return classes
