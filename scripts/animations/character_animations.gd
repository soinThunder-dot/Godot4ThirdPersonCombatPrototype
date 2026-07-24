class_name CharacterAnimations
extends Node3D

## 角色動畫包裝器，負責初始化動畫系統並將方法呼叫轉發至子節點（例如動畫、音效子系統）

# debug：是否啟用除錯輸出
@export var debug: bool = false
# visibility_notifier：螢幕可見性通知器，用於根據角色是否在畫面內來啟用/停用動畫
@export var visibility_notifier: VisibleOnScreenNotifier3D
# can_set_anim_tree_active：是否允許根據可見性自動設定動畫樹圖/播放器的 active 狀態
@export var can_set_anim_tree_active: bool = true

# _recipients：存放可接收方法呼叫的子節點，以路徑字串為鍵值
var _recipients: Dictionary

@onready var animations: Node = $Animations
@onready var audio: Node = $Audio
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree


## _ready：初始化動畫播放器與動畫樹圖，建立接收者列表，並依螢幕可見性設定動畫啟用/停用
func _ready() -> void:
	anim_player.active = true
	anim_tree.active = true
	
	_add_base_recipient(animations)
	_add_base_recipient(audio)
	
	if debug:
		for i in _recipients:
			print(i)
		for i in anim_tree.get_property_list():
			print(i)
	
	if visibility_notifier:
		visibility_notifier.screen_entered.connect(
			func():
				if not can_set_anim_tree_active: return
				anim_player.active = true
				anim_tree.active = true
		)
		visibility_notifier.screen_exited.connect(
			func():
				if not can_set_anim_tree_active: return
				anim_player.active = false
				anim_tree.active = false
		)


## execute：根據目標路徑尋找對應節點，並呼叫其上的指定方法（用於外部觸發動畫/音效方法）
func execute(target: String, method: StringName, args) -> void:
	if debug: prints("EXECUTE", target, method, args)
	
	if not _recipients.has(target):
		if debug: prints("DOES NOT CONTAIN", target)
		return
	
	var node: Node = _recipients[target]
	
	if not node.has_method(method):
		if debug: prints(target, "HAS NO METHOD", method)
		return
	
	if args == null:
		args = []
	
	node.callv(method, args)


## _add_base_recipient：將指定節點作為基礎根節點，遞迴加入其所有子節點至接收者列表
func _add_base_recipient(node: Node) -> void:
	_add_recipients(node, node.get_parent())


## _add_recipients：遞迴遍歷節點樹，將符合類型（BaseAnimations 或 AudioStreamPlayer3D）的節點加入接收者列表
func _add_recipients(node: Node, root: Node) -> void:
	if node.get_parent() != root:
		if not (node is BaseAnimations or node is AudioStreamPlayer3D):
			return
		_recipients[str(root.get_path_to(node))] = node
	for child in node.get_children():
		_add_recipients(child, root)
