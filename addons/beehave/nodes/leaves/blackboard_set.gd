@tool
class_name BlackboardSetAction extends ActionLeaf

## Sets the specified key to the specified value.
## Returns [code]FAILURE[/code] if expression execution fails, otherwise [code]SUCCESS[/code].
## 設定黑板鍵值的動作節點：將指定的鍵設定為指定的值。
## 若表達式執行失敗則回傳 `FAILURE`，否則回傳 `SUCCESS`。

## Expression representing a blackboard key.
## 代表黑板鍵值的表達式。
@export_placeholder(EXPRESSION_PLACEHOLDER) var key: String = ""
## Expression representing a blackboard value to assign to the specified key.
## 代表要分配給指定鍵的黑板值的表達式。
@export_placeholder(EXPRESSION_PLACEHOLDER) var value: String = ""


@onready var _key_expression: Expression = _parse_expression(key)
@onready var _value_expression: Expression = _parse_expression(value)


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 執行表達式以取得鍵名
	var key_value: Variant = _key_expression.execute([], blackboard)

	# 若鍵的表達式執行失敗，回傳 FAILURE
	if _key_expression.has_execute_failed():
		return FAILURE

	# 執行表達式以取得要設定的值
	var value_value: Variant = _value_expression.execute([], blackboard)

	# 若值的表達式執行失敗，回傳 FAILURE
	if _value_expression.has_execute_failed():
		return FAILURE

						# 將鍵值對寫入黑板
		blackboard.set_value(key_value, value_value)

	return SUCCESS


func _get_expression_sources() -> Array[String]:
	# 回傳此節點使用的表達式來源，供編輯器顯示
	return [key, value]
