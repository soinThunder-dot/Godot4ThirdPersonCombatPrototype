@tool
@icon("../../icons/category_decorator.svg")
class_name Decorator extends BeehaveNode

## Decorator nodes are used to transform the result received by its child.
## Must only have one child.
## 裝飾節點（裝飾器）：用於轉換其子節點回傳的結果。必須只能有一個子節點

# 記錄目前正在執行中（RUNNING）的子節點
var running_child: BeehaveNode = null


# 回報此節點的設定警告，確保裝飾節點只有一個子節點
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()

	if get_child_count() != 1:
		warnings.append("Decorator should have exactly one child node.")

	return warnings


# 節點被中斷時，若有執行中的子節點則進行中斷並清除紀錄
func interrupt(actor: Node, blackboard: Blackboard) -> void:
	if running_child != null:
		running_child.interrupt(actor, blackboard)
		running_child = null


# 子節點執行完成後呼叫，清除 running_child 紀錄
func after_run(actor: Node, blackboard: Blackboard) -> void:
	running_child = null


# 回報此節點的類別名稱陣列（用於編輯器與除錯輸出識別）
func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"Decorator")
	return classes
