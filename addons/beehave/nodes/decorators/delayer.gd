@tool
@icon("../../icons/delayer.svg")
extends Decorator
class_name DelayDecorator

## The Delay Decorator will return 'RUNNING' for a set amount of time
## before executing its child.
## The timer resets when both it and its child are not `RUNNING`
## 延遲裝飾器：在執行子節點前，先在設定的時間內回傳 RUNNING（延遲中）。若它與子節點都不是 RUNNING 狀態，時間將重新計算

# 延遲時間（秒）
## The wait time in seconds
@export var wait_time: = 0.0

# 快取鍵：用於在 blackboard 中儲存每個實例已經過的時間
@onready var cache_key = 'time_limiter_%s' % self.get_instance_id()

# 每幀執行：若尚未達到延遲時間則回傳 RUNNING，否則執行子節點
func tick(actor: Node, blackboard: Blackboard) -> int:
	var c = get_child(0)
	var total_time = blackboard.get_value(cache_key, 0.0, str(actor.get_instance_id()))
	var response
	
	        # 若子節點不是目前執行中的節點，則先執行 before_run
        if c != running_child:
		c.before_run(actor, blackboard)
	
	        # 若尚未達到延遲時間，回傳 RUNNING 並累加已過時間
        if total_time < wait_time:
		response = RUNNING
		
		total_time += get_physics_process_delta_time()
		blackboard.set_value(cache_key, total_time, str(actor.get_instance_id()))
		
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(self.get_instance_id(), response)
	        # 否則執行子節點並取得其回傳狀態
    else:
		response = c.tick(actor, blackboard)
		
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)
		
		        # 若子節點是條件節點，則記錄最後的條件與其結果
        if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))
		
		        # 若回傳狀態為 RUNNING 且子節點為動作節點，則記錄為目前執行中的子節點
        if response == RUNNING and c is ActionLeaf:
			running_child = c
			blackboard.set_value("running_action", c, str(actor.get_instance_id()))
		
		        # 若回傳狀態不是 RUNNING，則重設已過時間為 0
        if response != RUNNING:
			blackboard.set_value(cache_key, 0.0, str(actor.get_instance_id()))
	
	        # 回傳最終執行結果
        return response

