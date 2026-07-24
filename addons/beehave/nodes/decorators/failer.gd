@tool
@icon("../../icons/failer.svg")
class_name AlwaysFailDecorator extends Decorator

## A Failer node will always return a `FAILURE` status code.
## 失敗裝飾器：無論子節點執行結果為何，最後都回傳 FAILURE（除非仍在 RUNNING中）

func tick(actor: Node, blackboard: Blackboard) -> int:
	var c = get_child(0)

        # 若子節點不是目前執行中的節點，先執行 before_run
	    if c != running_child:
		c.before_run(actor, blackboard)

	    # 執行子節點並取得其回傳狀態
    var response = c.tick(actor, blackboard)
	if can_send_message(blackboard):
		BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

    # 若子節點是條件節點，則記錄最後的條件與結果
	    if c is ConditionLeaf:
		blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
		blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

    # 若回傳狀態為 RUNNING，則記錄為目前執行中的子節點並回傳 RUNNING
	    if response == RUNNING:
		running_child = c
		if c is ActionLeaf:
			blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		return RUNNING
	    # 否則執行子節點的後處理並回傳 FAILURE
    else:
		c.after_run(actor, blackboard)
		return FAILURE


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"AlwaysFailDecorator")
	return classes
