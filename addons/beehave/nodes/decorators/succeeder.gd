@tool
@icon("../../icons/succeeder.svg")
class_name AlwaysSucceedDecorator extends Decorator

## A succeeder node will always return a `SUCCESS` status code.
## 永成功裝飾器：無論子節點回傳結果為何，皆一律回傳 SUCCESS

func tick(actor: Node, blackboard: Blackboard) -> int:
	var c = get_child(0)

	if c != running_child:
		c.before_run(actor, blackboard)

	var response = c.tick(actor, blackboard)
	if can_send_message(blackboard):
		BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

	if c is ConditionLeaf:
		blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
		blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

	if response == RUNNING:
			# 若子節點仍在執行中，則記錄為目前執行中的子節點並回傳 RUNNING
		running_child = c
		if c is ActionLeaf:
			blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		return RUNNING
	else:
			# 若子節點已完成（非 RUNNING），則進行後處理並回傳 SUCCESS
		c.after_run(actor, blackboard)
		return SUCCESS


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"AlwaysSucceedDecorator")
	return classes
