@tool
class_name BeehaveNode extends Node

## A node in the behavior tree. Every node must return `SUCCESS`, `FAILURE` or
## `RUNNING` when ticked.
## 行為樹中的一個節點。每個節點在 tick 時必須回傳 `SUCCESS`、`FAILURE` 或 `RUNNING`。

enum { SUCCESS, FAILURE, RUNNING }


# 檢查此節點的設定是否正確，並在編輯器中顯示警告訊息（例如子節點類別不符合規範）
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if get_children().any(func(x): return not (x is BeehaveNode)):
		warnings.append("All children of this node should inherit from BeehaveNode class.")

	return warnings


## Executes this node and returns a status code.
## This method must be overwritten.
## 執行此節點並回傳狀態碼。此方法必須被重寫。
func tick(actor: Node, blackboard: Blackboard) -> int:
	return SUCCESS


## Called when this node needs to be interrupted before it can return FAILURE or SUCCESS.
## 當此節點需要在回傳 FAILURE 或 SUCCESS 之前被中斷時呼叫。
func interrupt(actor: Node, blackboard: Blackboard) -> void:
	pass


## Called before the first time it ticks by the parent.
## 在父節點第一次呼叫此節點前被呼叫。
func before_run(actor: Node, blackboard: Blackboard) -> void:
	pass


## Called after the last time it ticks and returns
## [code]SUCCESS[/code] or [code]FAILURE[/code].
## 在最後一次呼叫並回傳 SUCCESS 或 FAILURE 後被呼叫。
func after_run(actor: Node, blackboard: Blackboard) -> void:
	pass


func get_class_name() -> Array[StringName]:
	return [&"BeehaveNode"]


func can_send_message(blackboard: Blackboard) -> bool:
	return blackboard.get_value("can_send_message", false)
