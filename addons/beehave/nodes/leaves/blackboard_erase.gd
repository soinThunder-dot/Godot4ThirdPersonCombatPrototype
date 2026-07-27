@tool
class_name BlackboardEraseAction extends ActionLeaf

## Erases the specified key from the blackboard.
## Returns [code]FAILURE[/code] if expression execution fails, otherwise [code]SUCCESS[/code].
## 清除黑板鍵值的動作節點：從黑板中移除指定的鍵值。
## 若表達式執行失敗則回傳 `FAILURE`，否則回傳 `SUCCESS`。

## Expression representing a blackboard key.
## 代表黑板鍵值的表達式。
@export_placeholder(EXPRESSION_PLACEHOLDER) var key: String = ""

@onready var _key_expression: Expression = _parse_expression(key)


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 執行表達式以取得鍵名
	var key_value: Variant = _key_expression.execute([], blackboard)

	# 若表達式執行失敗，回傳 FAILURE
	if _key_expression.has_execute_failed():
		return FAILURE

	# 從黑板中移除該鍵值
	blackboard.erase_value(key_value)

	return SUCCESS


func _get_expression_sources() -> Array[String]:
	# 回傳此節點使用的表達式來源，供編輯器顯示
	return [key]
