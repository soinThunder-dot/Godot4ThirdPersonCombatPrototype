## 重複裝飾器 (Repeater Decorator)
## 功能：反覆執行子節點，直到子節點被執行「repetitions」次為止。
## - 若子節點在次數內持續回傳 SUCCESS，達到次數上限後，本節點回傳 SUCCESS。
## - 若子節點在任何一次執行中回傳 FAILURE，本節點立即回傳 FAILURE（不會繼續重複）。
## - 若子節點回傳 RUNNING，本節點也回傳 RUNNING，等待下一次 tick 繼續執行。
@tool
@icon("../../icons/repeater.svg")
class_name RepeaterDecorator extends Decorator

# repetitions：需要重複執行子節點的目標次數，可在編輯器中設定，預設為 1 次
@export var repetitions: int = 1
# current_count：記錄目前已經成功執行（完成）子節點的次數
var current_count: int = 0


# before_run：每次「重新開始」執行此節點時會呼叫一次，用來重置計數器
func before_run(actor: Node, blackboard: Blackboard):
	current_count = 0  # 重置已執行次數為 0，準備開始新一輪的重複執行


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 取得本節點唯一的子節點（Repeater 只能有一個子節點）
	var child = get_child(0)

	# 若尚未達到設定的重複次數，才繼續執行子節點
	if current_count < repetitions:

		# 若目前沒有正在執行中的子節點（代表這是新的一輪），
		# 就先呼叫 before_run 初始化子節點狀態
		if running_child == null:
			child.before_run(actor, blackboard)

		# 實際執行子節點一次 tick，取得其回傳狀態（SUCCESS / FAILURE / RUNNING）
		var response = child.tick(actor, blackboard)

		# 若偵錯器有在監聽，將這次 tick 的結果傳送給偵錯視窗顯示
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(child.get_instance_id(), response)

		# 若子節點是條件節點 (ConditionLeaf)，記錄最後一次條件判斷的結果，
		# 方便偵錯器或其他節點查詢「最近一次條件」的狀態
		if child is ConditionLeaf:
			blackboard.set_value("last_condition", child, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		# 情況一：子節點仍在執行中 (RUNNING)
		if response == RUNNING:
			# 記住目前正在執行的子節點，下次 tick 時會直接沿用，不會重新呼叫 before_run
			running_child = child
			# 若子節點是行為節點 (ActionLeaf)，記錄目前正在執行的行為，供偵錯器顯示
			if child is ActionLeaf:
				blackboard.set_value("running_action", child, str(actor.get_instance_id()))
			# 本節點同樣回傳 RUNNING，等待下一次 tick 再繼續
			return RUNNING

		# 情況二：子節點這一次執行「結束」了（回傳 SUCCESS 或 FAILURE）
		# 累加已完成次數，並呼叫 after_run 讓子節點做收尾處理
		current_count += 1
		child.after_run(actor, blackboard)

		# 清除「正在執行中的子節點」記錄，因為這一輪已經跑完了
		if running_child != null:
			running_child = null

		# 情況二之一：子節點失敗 (FAILURE) → 整個重複裝飾器立即回傳 FAILURE，
		# 不會再繼續重複剩餘次數
		if response == FAILURE:
			return FAILURE

	# 若已經達到（或超過）設定的重複次數上限，代表整個重複流程順利完成，
	# 回傳 SUCCESS 給父節點
	if current_count >= repetitions:
		return SUCCESS

	# 尚未達到重複次數上限，但這次 tick 已處理完一次子節點執行，
	# 回傳 RUNNING，等待下一次 tick 繼續進行剩餘的重複次數
	return RUNNING
