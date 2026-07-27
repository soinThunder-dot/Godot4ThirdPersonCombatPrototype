@tool
@icon("../../icons/condition.svg")
class_name ConditionLeaf extends Leaf

## Conditions are leaf nodes that either return SUCCESS or FAILURE depending on
## a single simple condition. They should never return `RUNNING`.
## 條件葉節點：根據一個簡单的條件回傳 SUCCESS 或 FAILURE。
## 不應回傳 `RUNNING`。

func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"ConditionLeaf")
	return classes
