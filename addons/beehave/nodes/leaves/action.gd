@tool
@icon("../../icons/action.svg")
class_name ActionLeaf extends Leaf

## Actions are leaf nodes that define a task to be performed by an actor.
## Their execution can be long running, potentially being called across multiple
## frame executions. In this case, the node should return `RUNNING` until the
## action is completed.
## 動作葉節點：定義一個由行為主體（actor）執行的任務。
## 其執行可能持續多幀，此時應回傳 `RUNNING`，直到動作完成為止。

func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"ActionLeaf")
	return classes
