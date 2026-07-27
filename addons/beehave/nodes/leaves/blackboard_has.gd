@tool
class_name BlackboardHasCondition extends ConditionLeaf

## Returns [code]FAILURE[/code] if expression execution fails or the specified key doesn't exist.
## Returns [code]SUCCESS[/code] if blackboard has the specified key.
## 黑板鍵值存在判斷條件節點：
## 若表達式執行失敗或指定鍵值不存在，回傳 `FAILURE`；
## 若黑板存在該鍵值，回傳 `SUCCESS`。

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

	# 根據黑板是否存在該鍵值，回傳 SUCCESS 或 FAILURE
	return SUCCESS if blackboard.has_value(key_value) else FAILURE


func _get_expression_sources() -> Array[String]:
	# 回傳此節點使用的表達式來源，供編輯器顯示
	return [key]
