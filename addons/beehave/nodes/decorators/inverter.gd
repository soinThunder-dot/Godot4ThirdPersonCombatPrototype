@tool
@icon("../../icons/inverter.svg")
class_name InverterDecorator extends Decorator

## An inverter will return `FAILURE` in case it's child returns a `SUCCESS` status
## code or `SUCCESS` in case its child returns a `FAILURE` status code.
## 反轉裝飾器：若子節點回傳 SUCCESS 則轉為 FAILURE，若回傳 FAILURE 則轉為 SUCCESS

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

	    # 依照回傳狀態進行反轉處理
    match response:
		SUCCESS: # 若子節點成功，則後處理並回傳 FAILURE
			c.after_run(actor, blackboard)
			return FAILURE
		FAILURE: # 若子節點失敗，則後處理並回傳 SUCCESS
			c.after_run(actor, blackboard)
			return SUCCESS
		RUNNING: # 若子節點仍在執行中，則記錄為目前執行中的子節點並回傳 RUNNING
			running_child = c
			if c is ActionLeaf:
				blackboard.set_value("running_action", c, str(actor.get_instance_id()))
			return RUNNING
		_: # 不應發生的情況，若發生則輸出錯誤
			push_error("This should be unreachable")
			return -1


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"InverterDecorator")
	return classes
