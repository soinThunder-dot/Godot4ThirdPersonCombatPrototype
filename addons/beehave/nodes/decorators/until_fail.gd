@tool
@icon("../../icons/until_fail.svg")
class_name UntilFailDecorator
extends Decorator

## The UntilFail Decorator will return `RUNNING` if its child returns
## `SUCCESS` or `RUNNING` or it will return `SUCCESS` if its child returns
## `FAILURE`
## UntilFail 裝飾器：若子節點回傳 `SUCCESS` 或 `RUNNING`，則本節點回傳 `RUNNING`；
## 若子節點回傳 `FAILURE`，則本節點回傳 `SUCCESS`

func tick(actor: Node, blackboard: Blackboard) -> int:
	var c = get_child(0)

	# 若子節點不是目前執行中的節點，先執行 before_run
	if c != running_child:
		c.before_run(actor, blackboard)

	# 執行子節點並取得其回傳狀態
	var response = c.tick(actor, blackboard)
	if can_send_message(blackboard):
		BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

	# 若子節點是條件節點，則記錄最後的條件與其結果
	if c is ConditionLeaf:
		blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
		blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

	# 若回傳 RUNNING，記錄為目前執行中的子節點並繼續回傳 RUNNING
	if response == RUNNING:
		running_child = c
		if c is ActionLeaf:
			blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		return RUNNING
	# 若回傳 SUCCESS，仍繼續回傳 RUNNING（尚未失敗）
	if response == SUCCESS:
		return RUNNING

	# 子節點失敗時，本節點回傳 SUCCESS
	return SUCCESS
