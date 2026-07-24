@tool
class_name RandomizedComposite extends Composite
## 隨機組合節點：以隨機順序（可選搼帶權重）執行子節點

const WEIGHTS_PREFIX = "Weights/"  # 權重屬性前綴名稱，用於在編輯器中顯示每個子節點的權重輸入框

## Sets a predicable seed
## 設定可預測的隨機種子
@export var random_seed: int = 0:
	set(rs):
		random_seed = rs
		if random_seed != 0:
			seed(random_seed)
		else:
			randomize()

## Wether to use weights for every child or not.
## 是否對每個子節點使用權重
@export var use_weights: bool:
	set(value):
		use_weights = value
		if use_weights:
			_update_weights(get_children())
			_connect_children_changing_signals()
		notify_property_list_changed()

# 存放每個子節點名稱對應的權重值
var _weights: Dictionary
var _exiting_tree: bool  # 標記行為樹是否正在離開場景樹（避免離開時重複更新權重）


# 節點進入場景樹時，確保子節點變更監聽信號已連接
func _ready():
	_connect_children_changing_signals()


# 連接子節點新增/移除的信號，以便自動更新權重資料
func _connect_children_changing_signals():
	if not child_entered_tree.is_connected(_on_child_entered_tree):
		child_entered_tree.connect(_on_child_entered_tree)
	
	if not child_exiting_tree.is_connected(_on_child_exiting_tree):
		child_exiting_tree.connect(_on_child_exiting_tree)


# 回傳打亂順序後的子節點陣列（若使用權重則依權重進行加權洗牌）
func get_shuffled_children() -> Array[Node]:
	var children_bag: Array[Node] = get_children().duplicate()
	if use_weights:
		var weights: Array[int]
		weights.assign(children_bag.map(func (child): return _weights[child.name]))
		children_bag.assign(_weighted_shuffle(children_bag, weights))
	else:
		children_bag.shuffle()
	return children_bag


## Returns a shuffled version of a given array using the supplied array of weights. 
## Think of weights as the chance of a given item being the first in the array.
## 根據權重進行加權隨機排序（權重越高越有可能排在前面）
func _weighted_shuffle(items: Array, weights: Array[int]) -> Array:
	if len(items) != len(weights):
		push_error("items and weights size mismatch: expected %d weights, got %d instead." % [len(items), len(weights)])
		return items
	
	# This method is based on the weighted random sampling algorithm 
	# by Efraimidis, Spirakis; 2005. This runs in O(n log(n)).（於此基礎上實現 A-Res 加權隨機抽樣演算法）
	
	# For each index, it will calculate random_value^(1/weight).
	var chance_calc = func(i): return [i, randf() ** (1.0 / weights[i])]
	var random_distribuition = range(len(items)).map(chance_calc)
	
	# Now we just have to order by the calculated value, descending.
	random_distribuition.sort_custom(func(a, b): return a[1] > b[1])
	
	return random_distribuition.map(func(dist): return items[dist[0]])


# 動態提供每個子節點的權重屬性，供編輯器中顯示與調整
func _get_property_list():
	var properties = []

	if use_weights:
		for key in _weights.keys():
			properties.append({
				"name": WEIGHTS_PREFIX + key,
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "1,100"
			})
		
	return properties
	
	
# 處理編輯器中設定權重屬性時的寫入事件
func _set(property: StringName, value: Variant) -> bool:
	if property.begins_with(WEIGHTS_PREFIX):
		var weight_name = property.trim_prefix(WEIGHTS_PREFIX)
		_weights[weight_name] = value
		return true
	
	return false


# 處理編輯器中讀取權重屬性時的事件
func _get(property: StringName):
	if property.begins_with(WEIGHTS_PREFIX):
		var weight_name = property.trim_prefix(WEIGHTS_PREFIX)
		return _weights[weight_name]
	
	return null


# 根據目前子節點名單更新權重資料（新子節點默認權重為 1）
func _update_weights(children: Array[Node]) -> void:
	var new_weights = {}
	for c in children:
		if _weights.has(c.name):
			new_weights[c.name] = _weights[c.name]
		else:
			new_weights[c.name] = 1
	_weights = new_weights
	notify_property_list_changed()


# 節點離開場景樹時，標記正在離開以避免重複更新權重
func _exit_tree() -> void:
	_exiting_tree = true


# 節點重新進入場景樹時，取消離開中狀態標記
func _enter_tree() -> void:
	_exiting_tree = false


# 當子節點進入場景樹時，更新權重並連接重命名、離樹等相關信號
func _on_child_entered_tree(node: Node):
	_update_weights(get_children())

	var renamed_callable = _on_child_renamed.bind(node.name, node)
	if not node.renamed.is_connected(renamed_callable):
		node.renamed.connect(renamed_callable)
	
	if not node.tree_exited.is_connected(_on_child_tree_exited):
		node.tree_exited.connect(_on_child_tree_exited.bind(node))


# 當子節點離開場景樹時，斷開重命名信號連接
func _on_child_exiting_tree(node: Node):
	var renamed_callable = _on_child_renamed.bind(node.name, node)
	if node.renamed.is_connected(renamed_callable):
		node.renamed.disconnect(renamed_callable)


# 當子節點真正離開場景樹時呼叫：從子節點列表中移除該節點
func _on_child_tree_exited(node: Node) -> void:
					# don't erase the individual child if the whole tree is exiting together（若整棵樹同步離開，則不單独刪除此子節點）
	if not _exiting_tree:
		var children = get_children()
		children.erase(node)
		_update_weights(children)
	
	if node.tree_exited.is_connected(_on_child_tree_exited):
		node.tree_exited.disconnect(_on_child_tree_exited)


# 當子節點名稱變更時呼叫：重新連接重命名信號以維持權重對應關係
func _on_child_renamed(old_name: String, renamed_child: Node):
	if old_name == renamed_child.name:
		return # No need to update the weights.（名稱未變更，無需更新權重）
	
	# Disconnect signal with old name...（先斷開舊名稱的信號連接）
	renamed_child.renamed\
			.disconnect(_on_child_renamed.bind(old_name, renamed_child))
	# ...and connect with the new name.（再以新名稱重新連接）
	renamed_child.renamed\
			.connect(_on_child_renamed.bind(renamed_child.name, renamed_child))
	
	# 將舊名稱的權重轉移給新名稱，並通知編輯器屬性已變更
	var original_weight = _weights[old_name]
	_weights.erase(old_name)
	_weights[renamed_child.name] = original_weight
	notify_property_list_changed()


# 回傳此節點的自訂類別名稱陣列（於父類基礎上加入 RandomizedComposite）
func get_class_name() -> Array[StringName]:
	var classes := super()
	classes.push_back(&"RandomizedComposite")
	return classes
