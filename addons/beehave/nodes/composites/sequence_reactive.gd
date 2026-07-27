@tool
@icon("../../icons/sequence_reactive.svg")
class_name SequenceReactiveComposite extends Composite

## Reactive Sequence nodes will attempt to execute all of its children and report
## `SUCCESS` in case all of the children report a `SUCCESS` status code.
## If at least one child reports a `FAILURE` status code, this node will also
## return `FAILURE` and restart.
## In case a child returns `RUNNING` this node will restart.

# 記錄目前已成功執行到的子節點索引
var successful_index: int = 0


func tick(actor: Node, blackboard: Blackboard) -> int:
	for c in get_children():
		# 跳過已經成功執行過的子節點
		if c.get_index() < successful_index:
			continue

		# 若子節點不是目前執行中的節點，先執行 before_run
		if c != running_child:
			c.before_run(actor, blackboard)

		var response = c.tick(actor, blackboard)
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

		# 若子節點是條件節點，則記錄最後的條件與其結果
		if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		match response:
			SUCCESS:
				# 成功則前進到下一個子節點
				successful_index += 1
				c.after_run(actor, blackboard)
			FAILURE:
				# 只要有一個子節點失敗，整個序列即失敗並重置
				# Interrupt any child that was RUNNING before.
				interrupt(actor, blackboard)
				c.after_run(actor, blackboard)
				return FAILURE
			RUNNING:
				# 因為是反應式（Reactive），每次都重新從頭開始，所以先重置成功索引
				_reset()
				if running_child != c:
					interrupt(actor, blackboard)
					running_child = c
				if c is ActionLeaf:
					blackboard.set_value("running_action", c, str(actor.get_instance_id()))
				return RUNNING

	# 所有子節點都成功完成時，重置並回傳 SUCCESS
	_reset()
	return SUCCESS


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	_reset()
	super(actor, blackboard)


func _reset() -> void:
	# 重置成功索引，下次從第一個子節點重新開始
	successful_index = 0


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SequenceReactiveComposite")
	return classes
