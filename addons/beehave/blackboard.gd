@icon("icons/blackboard.svg")
class_name Blackboard extends Node

const DEFAULT = "default"

## The blackboard is an object that can be used to store and access data between
## multiple nodes of the behavior tree.
## 黑板物件：用於在行為樹的多個節點之間儲存與存取共享資料。
@export var blackboard: Dictionary = {}:
	set(b):
		blackboard = b
		# 當在編輯器中設定 blackboard 語法糖時，同步更新到黑板名稱空間中
		_data[DEFAULT] = blackboard

var _data:Dictionary = {}


func _ready():
	# 節點就緒時，將匯出的 blackboard 資料寫入預設名稱空間
	_data[DEFAULT] = blackboard


func keys() -> Array[String]:
	# 回傳目前所有黑板名稱空間的鍵名清單
	var keys: Array[String]
	keys.assign(_data.keys().duplicate())
	return keys


func set_value(key: Variant, value: Variant, blackboard_name: String = DEFAULT) -> void:
	# 若指定的名稱空間尚不存在，先建立空字典
	if not _data.has(blackboard_name):
		_data[blackboard_name] = {}

	# 將鍵值對寫入指定名稱空間中
	_data[blackboard_name][key] = value


func get_value(key: Variant, default_value: Variant = null, blackboard_name: String = DEFAULT) -> Variant:
	# 若鍵值存在，回傳其對應值，否則回傳預設值
	if has_value(key, blackboard_name):
		return _data[blackboard_name].get(key, default_value)
	return default_value


func has_value(key: Variant, blackboard_name: String = DEFAULT) -> bool:
	# 確認指定名稱空間存在、鍵存在且值不為 null
	return _data.has(blackboard_name) and _data[blackboard_name].has(key) and _data[blackboard_name][key] != null


func erase_value(key: Variant, blackboard_name: String = DEFAULT) -> void:
	# 將指定鍵的值設為 null，以達到清除的效果
	if _data.has(blackboard_name):
		_data[blackboard_name][key] = null
