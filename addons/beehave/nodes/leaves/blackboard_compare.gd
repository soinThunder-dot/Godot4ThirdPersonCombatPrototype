@tool
class_name BlackboardCompareCondition extends ConditionLeaf

## Compares two values using the specified comparison operator.
## Returns [code]FAILURE[/code] if any of the expression fails or the
## comparison operation returns [code]false[/code], otherwise it returns [code]SUCCESS[/code].
## 比較條件節點：使用指定的比較運算子比較兩個數值。
## 若任一運算式執行失敗則回傳 `FAILURE`，若比較結果為 `false` 也回傳 `FAILURE`，否則回傳 `SUCCESS`。

enum Operators {
	EQUAL,
	NOT_EQUAL,
	GREATER,
	LESS,
	GREATER_EQUAL,
	LESS_EQUAL,
}

## Expression represetning left operand.
## This value can be any valid GDScript expression.
## In order to use the existing blackboard keys for comparison,
## use get_value("key_name") e.g. get_value("direction").length()
## 左運算元的運算式，可為任意有效的 GDScript 表達式。
## 若要使用黑板中現有的鍵值進行比較，可使用 get_value("key_name")，例如 get_value("direction").length()
@export_placeholder(EXPRESSION_PLACEHOLDER) var left_operand: String = ""
## Comparison operator.
## 比較運算子。
@export_enum("==", "!=", ">", "<", ">=", "<=") var operator: int = 0
## Expression represetning right operand.
## This value can be any valid GDScript expression.
## In order to use the existing blackboard keys for comparison,
## use get_value("key_name") e.g. get_value("direction").length()
## 右運算元的運算式，可為任意有效的 GDScript 表達式。
## 若要使用黑板中現有的鍵值進行比較，可使用 get_value("key_name")，例如 get_value("direction").length()
@export_placeholder(EXPRESSION_PLACEHOLDER) var right_operand: String = ""

@onready var _left_expression: Expression = _parse_expression(left_operand)
@onready var _right_expression: Expression = _parse_expression(right_operand)


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 執行左運算元的表達式並取得結果
	var left: Variant = _left_expression.execute([], blackboard)

	# 若左運算式執行失敗，直接回傳 FAILURE
	if _left_expression.has_execute_failed():
		return FAILURE

	# 執行右運算元的表達式並取得結果
	var right: Variant = _right_expression.execute([], blackboard)

	# 若右運算式執行失敗，直接回傳 FAILURE
	if _right_expression.has_execute_failed():
		return FAILURE

	var result: bool = false

	# 根據指定的運算子執行對應的比較運算
	match operator:
		Operators.EQUAL:			result = left == right
		Operators.NOT_EQUAL:		result = left != right
		Operators.GREATER:			result = left > right
		Operators.LESS:				result = left < right
		Operators.GREATER_EQUAL:	result = left >= right
		Operators.LESS_EQUAL:		result = left <= right

	# 依比較結果回傳 SUCCESS 或 FAILURE
	return SUCCESS if result else FAILURE


func _get_expression_sources() -> Array[String]:
	# 回傳此節點使用的表達式來源，供編輯器顯示
	return [left_operand, right_operand]
