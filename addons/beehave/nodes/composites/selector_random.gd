@tool
@icon("../../icons/selector_random.svg")
class_name SelectorRandomComposite extends RandomizedComposite

## This node will attempt to execute all of its children just like a
## [code]SelectorStar[/code] would, with the exception that the children
## will be executed in a random order.
## 隨機選擇組合節點：行為與選擇組合節點相同，但會以隨機順序執行子節點

## A shuffled list of the children that will be executed in reverse order.
## 存放已洗牌的子節點清單，會以反向順序執行
var _children_bag: Array[Node] = []
var c: Node

# 節點準備就緒時執行，確保隨機種子已初始化
func _ready() -> void:
	super()
	if random_seed == 0:
		randomize()

# 每幀執行：若子節點袋為空則重新洗牌，然後依反向順序依序執行各子節點

func tick(actor: Node, blackboard: Blackboard) -> int:
	if _children_bag.is_empty():
		_reset()

	# We need to traverse the array in reverse since we will be manipulating it.
# 必須從後往前遍歷，因為這個陣列在執行過程中會被修改
	for i in _get_reversed_indexes():
		c = _children_bag[i]

		if c != running_child:
			c.before_run(actor, blackboard)

		var response = c.tick(actor, blackboard)
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

		if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		match response:
			SUCCESS:
				_children_bag.erase(c)
				c.after_run(actor, blackboard)
				return SUCCESS
			FAILURE:
				_children_bag.erase(c)
				c.after_run(actor, blackboard)
			RUNNING:
				running_child = c
				if c is ActionLeaf:
					blackboard.set_value("running_action", c, str(actor.get_instance_id()))
				return RUNNING

	return FAILURE


# 執行完成後重新洗牌並重置子節點袋，以便下次執行
func after_run(actor: Node, blackboard: Blackboard) -> void:
	_reset()
	super(actor, blackboard)


# 節點被中斷時重新洗牌並重置子節點袋
func interrupt(actor: Node, blackboard: Blackboard) -> void:
	_reset()
	super(actor, blackboard)

# 回報子節點袋的反向索引陣列（用於從後往前遍歷）

func _get_reversed_indexes() -> Array[int]:
	var reversed: Array[int]
	reversed.assign(range(_children_bag.size()))
	reversed.reverse()
	return reversed


# 重新洗牌子節點並重建反向的子節點袋
func _reset() -> void:
	var new_order = get_shuffled_children()
	_children_bag = new_order.duplicate()
	_children_bag.reverse() # It needs to run the children in reverse order.

# 回報此節點的類別名稱陣列（用於編輯器與除錯輸出識別）

func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SelectorRandomComposite")
	return classes
