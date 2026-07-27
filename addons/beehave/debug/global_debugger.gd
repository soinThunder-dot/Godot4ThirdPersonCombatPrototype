extends Node

var _registered_trees: Dictionary
var _active_tree


func _enter_tree() -> void:
	# 於進入場景樹時，向 EngineDebugger 註冊 "beehave" 訊息的接收函式
	EngineDebugger.register_message_capture("beehave", _on_debug_message)


func _on_debug_message(message: String, data: Array) -> bool:
	if message == "activate_tree":
		# 編輯器要求切換至指定的行為樹進行追蹤
		_set_active_tree(data[0])
		return true
	if message == "visibility_changed":
		# 依照除錯面板是否可見，決定當前行為樹是否需要繼續傳送追蹤訊息
		if _active_tree && is_instance_valid(_active_tree):
			_active_tree._can_send_message = data[0]
		return true
	return false


func _set_active_tree(tree_id: int) -> void:
	var tree = _registered_trees.get(tree_id, null)
	if not tree:
		return
	# 先關閉舊的活躍行為樹的訊息傳送，再切換到新的行為樹
	if _active_tree && is_instance_valid(_active_tree):
		_active_tree._can_send_message = false
	_active_tree = tree
	_active_tree._can_send_message = true


func register_tree(tree) -> void:
	# 將行為樹以其 instance id 為鍵值註冊到追蹤字典中
	_registered_trees[tree.get_instance_id()] = tree
