@tool
@icon("../../icons/selector_reactive.svg")
class_name SelectorReactiveComposite extends Composite

## Selector Reactive nodes will attempt to execute each of its children until one of
## them return `SUCCESS`. If all children return `FAILURE`, this node will also
## return `FAILURE`.
## If a child returns `RUNNING` it will restart.

func tick(actor: Node, blackboard: Blackboard) -> int:
	# 依序遍歷每一個子節點
	for c in get_children():
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
				# 中斷之前正在 RUNNING 的子節點
				# Interrupt any child that was RUNNING before.
				if c != running_child:
					interrupt(actor, blackboard)
				c.after_run(actor, blackboard)
				return SUCCESS
			FAILURE:
				# 失敗則繼續嘗試下一個子節點
				c.after_run(actor, blackboard)
			RUNNING:
				# 若回傳 RUNNING，記錄為目前執行中的子節點並立即回傳
				if c != running_child:
					interrupt(actor, blackboard)
					running_child = c
				if c is ActionLeaf:
					blackboard.set_value("running_action", c, str(actor.get_instance_id()))
				return RUNNING

	# 所有子節點都失敗時，回傳 FAILURE
	return FAILURE


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SelectorReactiveComposite")
	return classes
