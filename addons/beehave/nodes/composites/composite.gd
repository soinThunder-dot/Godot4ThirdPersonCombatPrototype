@tool
@icon("../../icons/category_composite.svg")
class_name Composite extends BeehaveNode

## A Composite node controls the flow of execution of its children in a specific manner.
## 組合節點以特定方式控制其子節點的執行流程。

# 目前正在執行中的子節點（若無則為 null）
var running_child: BeehaveNode = null


# 檢查組合節點的配置是否合法（至少需要兩個子節點才有意義）
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super._get_configuration_warnings()

	if get_children().filter(func(x): return x is BeehaveNode).size() < 2:
		warnings.append("Any composite node should have at least two children. Otherwise it is not useful.")

	return warnings


# 中斷行為樹：若目前有執行中的子節點，則將其中斷並清除參考
func interrupt(actor: Node, blackboard: Blackboard) -> void:
	if running_child != null:
		running_child.interrupt(actor, blackboard)
		running_child = null


# 每次執行完畢後呼叫：清除目前執行中的子節點參考
func after_run(actor: Node, blackboard: Blackboard) -> void:
	running_child = null


# 回傳此節點的自訂類別名稱陣列（於父類基礎上加入 Composite）
func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"Composite")
	return classes
