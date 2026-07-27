@tool
@icon("../../icons/limiter.svg")
class_name TimeLimiterDecorator extends Decorator

## The Time Limit Decorator will give its `RUNNING` child a set amount of time to finish
## before interrupting it and return a `FAILURE` status code. 
## The timer resets the next time that a child is not `RUNNING`

# 限時時長（秒）
@export var wait_time: = 0.0

# 快取鍵：用於 blackboard 中儲存每個實例已經過的時間
@onready var cache_key = 'time_limiter_%s' % self.get_instance_id()


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 必須恰好有一個子節點，否則直接失敗
	if not get_child_count() == 1:
		return FAILURE

	var child = self.get_child(0)
	# 取得目前已經過的時間，預設為 0.0
	var time_left = blackboard.get_value(cache_key, 0.0, str(actor.get_instance_id()))

	# 若尚未超過限時時長，則繼續執行子節點
	if time_left < wait_time:
		time_left += get_physics_process_delta_time()
		blackboard.set_value(cache_key, time_left, str(actor.get_instance_id()))
		var response = child.tick(actor, blackboard)
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(child.get_instance_id(), response)

		# 若子節點是條件節點，則記錄最後的條件與其結果
		if child is ConditionLeaf:
			blackboard.set_value("last_condition", child, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		# 若回傳 RUNNING，記錄為目前執行中的子節點
		if response == RUNNING:
			running_child = child
			if child is ActionLeaf:
				blackboard.set_value("running_action", child, str(actor.get_instance_id()))
		else:
			# 若不是 RUNNING，則執行 after_run
			child.after_run(actor, blackboard)
		return response
	else:
		# 已超過限時時長，中斷子節點並回傳 FAILURE
		interrupt(actor, blackboard)
		child.after_run(actor, blackboard)
		return FAILURE


func before_run(actor: Node, blackboard: Blackboard) -> void:
	# 重置已經過的時間
	blackboard.set_value(cache_key, 0.0, str(actor.get_instance_id()))
	if get_child_count() > 0:
		get_child(0).before_run(actor, blackboard)


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"TimeLimiterDecorator")
	return classes


func _get_configuration_warnings() -> PackedStringArray:
	# 必須恰好有一個子節點，否則顯示警告
	if not get_child_count() == 1:
		return ["Requires exactly one child node"]
	return []
