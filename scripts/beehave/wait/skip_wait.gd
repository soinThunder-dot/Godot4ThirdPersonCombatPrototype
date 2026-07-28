# 跳過等待節點：將指定編號的等待狀態設為假，以跳過該次等待
class_name SkipWait
extends ActionLeaf

# 要跳過的等待編號
@export var wait_id: int

func tick(_actor: Node, blackboard: Blackboard) -> int:
	# 在黑板上設定對應的等待標記為假，表示不需要再等待
	blackboard.set_value("wait_" + str(wait_id), false)
	return SUCCESS
