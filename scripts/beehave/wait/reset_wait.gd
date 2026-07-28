# 重置等待節點：將指定編號的等待狀態重新設為真
class_name ResetWait
extends ActionLeaf

# 要重置的等待編號
@export var wait_id: int

func tick(_actor: Node, blackboard: Blackboard) -> int:
	# 在黑板上設定對應的等待標記為真
	blackboard.set_value("wait_" + str(wait_id), true)
	return SUCCESS
