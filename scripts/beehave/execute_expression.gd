# 執行表達式節點：執行一段 GDScript 表達式，依執行結果回報成功或失敗
class_name LeafExecuteExpression
extends Leaf

# 是否啟用此節點
@export var enabled: bool = true
# 要執行的表達式字串
@export_placeholder(EXPRESSION_PLACEHOLDER) var expression_string: String = ""

# 在準備就緒時將字串解析為可執行的表達式
@onready var _expression: Expression = _parse_expression(expression_string)


func tick(_actor: Node, blackboard: Blackboard) -> int:
	if not enabled:
		return FAILURE
	
	# 執行表達式，黑板作為執行上下文
	_expression.execute([], blackboard)
	
	if _expression.has_execute_failed():
		return FAILURE
	
	return SUCCESS
