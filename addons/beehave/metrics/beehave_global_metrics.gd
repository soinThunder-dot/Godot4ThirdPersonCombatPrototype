extends Node

## 全域行為樹指標統計節點：負責追蹤專案中所有 BeehaveTree 的數量與啟用狀態，並透過 Performance 監控器顯示。

var _tree_count: int = 0
var _active_tree_count: int = 0
var _registered_trees: Array = []


func _enter_tree() -> void:
	# 註冊自定義效能監控項目，用於 Godot 編輯器的 Debugger 中顯示
	Performance.add_custom_monitor("beehave/total_trees", _get_total_trees)
	Performance.add_custom_monitor("beehave/total_enabled_trees", _get_total_enabled_trees)


func register_tree(tree) -> void:
	# 若該行為樹已註冊過，直接返回，避免重複計算
	if _registered_trees.has(tree):
		return
	
	_registered_trees.append(tree)
	_tree_count += 1
	
	# 若該行為樹目前為啟用狀態，增加啟用中的樹計數
	if tree.enabled:
		_active_tree_count += 1
	
	# 監聽行為樹的啟用/停用信號，以便即時更新統計數據
	tree.tree_enabled.connect(_on_tree_enabled)
	tree.tree_disabled.connect(_on_tree_disabled)


func unregister_tree(tree) -> void:
	# 若該行為樹未註冊過，直接返回
	if not _registered_trees.has(tree):
		return
	
	_registered_trees.erase(tree)
	_tree_count -= 1
	
	# 若該行為樹目前為啟用狀態，減少啟用中的樹計數
	if tree.enabled:
		_active_tree_count -= 1
	
	# 解除信號連結，避免引用已移除的行為樹
	tree.tree_enabled.disconnect(_on_tree_enabled)
	tree.tree_disabled.disconnect(_on_tree_disabled)


func _get_total_trees() -> int:
	# 回傳目前已註冊的行為樹總數
	return _tree_count


func _get_total_enabled_trees() -> int:
	# 回傳目前啟用中的行為樹數量
	return _active_tree_count
