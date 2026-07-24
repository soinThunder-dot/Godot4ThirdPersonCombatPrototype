@tool
@icon("../../icons/cooldown.svg")
extends Decorator
class_name CooldownDecorator

## The Cooldown Decorator will return 'FAILURE' for a set amount of time
## after executing its child.
## The timer resets the next time its child is executed and it is not `RUNNING`
## 冷卻裝飾器：執行完子節點後，在設定的時間內回傳 FAILURE（冷卻中）。若子節點再次執行且不是 RUNNING 狀態，時間將重新計算

# 冷卻時間（秒）
## The wait time in seconds
@export var wait_time: = 0.0

# 每個實例專屬的快取鍵，用於在 blackboard 儲存冷卻剩餘時間
@onready var cache_key = 'cooldown_%s' % self.get_instance_id()


# 每幀執行：若冷卻尚未結束則回傳 FAILURE，否則執行子節點並在完成後重新設定冷卻時間
func tick(actor: Node, blackboard: Blackboard) -> int:
	var c = get_child(0)
	var remaining_time = blackboard.get_value(cache_key, 0.0, str(actor.get_instance_id()))
	var response
	
	if c != running_child:
		c.before_run(actor, blackboard)
	
	if remaining_time > 0:
		# 冷卻尚未結束，回傳 FAILURE 並減少剩餘時間
		response = FAILURE
		
		remaining_time -= get_physics_process_delta_time()
		blackboard.set_value(cache_key, remaining_time, str(actor.get_instance_id()))
		
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(self.get_instance_id(), response)
	else:  # 冷卻已結束，執行子節點
		response = c.tick(actor, blackboard)
		
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)
		
		if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))
		
		if response == RUNNING and c is ActionLeaf:
					# 子節點仍在執行中，記錄為 running_child
			running_child = c
			blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		
		if response != RUNNING:
				# 子節點已結束（非 RUNNING），重新設定冷卻時間為 wait_time
			blackboard.set_value(cache_key, wait_time, str(actor.get_instance_id()))
	
	# 回傳此次 tick 的執行結果
	return response


