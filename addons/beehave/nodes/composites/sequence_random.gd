@tool
@icon("../../icons/sequence_random.svg")
class_name SequenceRandomComposite extends RandomizedComposite

## This node will attempt to execute all of its children just like a
## [code]SequenceStar[/code] would, with the exception that the children
## will be executed in a random order.

# 每當子節點被洗牌時發出的信號
# Emitted whenever the children are shuffled.
signal reset(new_order: Array[Node])

## Whether the sequence should start where it left off after a previous failure.
# 失敗後是否從上次中斷處繼續執行
@export var resume_on_failure: bool = false
## Whether the sequence should start where it left off after a previous interruption.
# 被中斷後是否從上次中斷處繼續執行
@export var resume_on_interrupt: bool = false

## A shuffled list of the children that will be executed in reverse order.
# 已洗牌並將以反向順序執行的子節點清單
var _children_bag: Array[Node] = []
var c: Node


func _ready() -> void:
	super()
	# 若未設定種子，則隨機初始化
	if random_seed == 0:
		randomize()


func tick(actor: Node, blackboard: Blackboard) -> int:
	# 若袋子空了，則重新洗牌
	if _children_bag.is_empty():
		_reset()

	# We need to traverse the array in reverse since we will be manipulating it.
	# 由於會邊遍歷邊修改陣列，所以需要以反向順序遍歷
	for i in _get_reversed_indexes():
		c = _children_bag[i]

		# 若子節點不是目前執行中的節點，先執行 before_run
		if c != running_child:
			c.before_run(actor, blackboard)

		var response = c.tick(actor, blackboard)
		if can_send_message(blackboard):
			BeehaveDebuggerMessages.process_tick(c.get_instance_id(), response)

		# 若子節點是條件節點，則記錄最後的條件與其結果
		if c is ConditionLeaf:
			blackboard.set_value("last_condition", c, str(actor.get_instance_id()))
			blackboard.set_value("last_condition_status", response, str(actor.get_instance_id()))

		match response:
			SUCCESS:
				# 成功則從袋中移除該子節點
				_children_bag.erase(c)
				c.after_run(actor, blackboard)
			FAILURE:
				# 失敗也從袋中移除該子節點
				_children_bag.erase(c)
				# Interrupt any child that was RUNNING before
				# but do not reset!
				# 中斷之前正在 RUNNING 的子節點，但不重置袋子
				super.interrupt(actor, blackboard)
				c.after_run(actor, blackboard)
				return FAILURE
			RUNNING:
				# 記錄為目前執行中的子節點並立即回傳
				running_child = c
				if c is ActionLeaf:
					blackboard.set_value("running_action", c, str(actor.get_instance_id()))
				return RUNNING

	# 所有子節點都成功完成，回傳 SUCCESS
	return SUCCESS


func after_run(actor: Node, blackboard: Blackboard) -> void:
	# 若不需要從失敗處恢復，則重置
	if not resume_on_failure:
		_reset()
	super(actor, blackboard)


func interrupt(actor: Node, blackboard: Blackboard) -> void:
	# 若不需要從中斷處恢復，則重置
	if not resume_on_interrupt:
		_reset()
	super(actor, blackboard)


func _get_reversed_indexes() -> Array[int]:
	# 產生反向順序的索引陣列
	var reversed: Array[int]
	reversed.assign(range(_children_bag.size()))
	reversed.reverse()
	return reversed


func _reset() -> void:
	# 重新洗牌子節點順序，並以反向順序儲存（因為需要反向執行）
	var new_order = get_shuffled_children()
	_children_bag = new_order.duplicate()
	_children_bag.reverse() # It needs to run the children in reverse order.
	reset.emit(new_order)


func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"SequenceRandomComposite")
	return classes
