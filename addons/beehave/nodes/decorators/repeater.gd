## The repeater will execute its child until it returns `SUCCESS` a certain amount of times.
## When the number of maximum ticks is reached, it will return a `SUCCESS` status code.
## If the child returns `FAILURE`, the repeater will return `FAILURE` immediately.
## 重複裝飾器：子節點回傳 SUCCESS 達到指定次數後回傳 SUCCESS；若子節點回傳 FAILURE 則立即回傳 FAILURE
@tool
@icon("../../icons/repeater.svg")
class_name RepeaterDecorator extends Decorator

@export var repetitions: int = 1
var current_count: int = 0


func before_run(actor: Node, blackboard: Blackboard):
	current_count = 0


func tick(actor: Node, blackboard: Blackboard) -> int:
	var child = get_child(0)

    # 若尚未達到重複次數，則執行子節點
	
	if current_count < repetitions:
		if running_child == null: # 若目前没有執行中的子節點，先執行 before_run
			child.before_run(actor, blackboard)

		var response = child.tick(actor, blackboard)
		
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(child.get_instance_id(), response)

		if child is ConditionLeaf:
			blackboard.set_value("last_condition", child, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		if response == RUNNING:
			running_child = child
			if child is ActionLeaf:
				blackboard.set_value("running_action", child, str(actor.get_instance_id()))
			return RUNNING

		current_count += 1
		child.after_run(actor, blackboard)

		if running_child != null:
			running_child = null
		
		    # 若子節點失敗，則直接回傳 FAILURE
    if response == FAILURE:
			return FAILURE
		
    # 若已達重複次數上限，則回傳 SUCCESS
		if current_count >= repetitions:
			return SUCCESS
		
		return RUNNING
	else:
		return SUCCESS


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"LimiterDecorator")
	return classes
