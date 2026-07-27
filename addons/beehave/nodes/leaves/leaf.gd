@tool
@icon("../../icons/category_leaf.svg")
class_name Leaf extends BeehaveNode

## Base class for all leaf nodes of the tree.
## 行為樹中所有葉節點的基底類別。

const EXPRESSION_PLACEHOLDER: String = "Insert an expression..."


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	# 取得此節點的子節點以進行驗證
	var children: Array[Node] = get_children()

	# 若存在任何行為樹子節點，顯示警告，因為葉節點不應有子節點
	if children.any(func(x): return x is BeehaveNode):
		warnings.append("Leaf nodes should not have any child nodes. They won't be ticked.")

	# 逐一檢查每個表達式來源是否有語法錯誤
	for source in _get_expression_sources():
		var error_text: String = _parse_expression(source).get_error_text()
		if not error_text.is_empty():
			warnings.append("Expression `%s` is invalid! Error text: `%s`" % [source, error_text])

	return warnings


func _parse_expression(source: String) -> Expression:
	# 將字串轉換為 Expression 物件以便於 tick() 中執行
	var result: Expression = Expression.new()
	var error: int = result.parse(source)

	# 若非編輯器模式且解析失敗，輸出錯誤訊息
	if not Engine.is_editor_hint() and error != OK:
		push_error(
			"[Leaf] Couldn't parse expression with source: `%s` Error text: `%s`" %\
			[source, result.get_error_text()]
		)

	return result


func _get_expression_sources() -> Array[String]: # virtual
	# 供子類覆寫，回傳需要驗證的表達式來源清單
	return []


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"Leaf")
	return classes
