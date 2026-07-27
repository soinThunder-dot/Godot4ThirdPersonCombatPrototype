@tool
class_name BeehaveDebuggerTab extends PanelContainer

## 行為樹偵錯面板：在編輯器偵錯器中顯示所有運行中的行為樹清單及其對應的視覺化圖形。

const BeehaveUtils := preload("res://addons/beehave/utils/utils.gd")

signal make_floating

const BeehaveGraphEdit := preload("graph_edit.gd")
const TREE_ICON := preload("../icons/tree.svg")

var container: HSplitContainer
var item_list: ItemList
var graph: BeehaveGraphEdit
var message: Label

var active_trees: Dictionary
var active_tree_id: int = -1
var session: EditorDebuggerSession


func _ready() -> void:
	# 建立左右分割容器，左側放行為樹列表，右側放圖形顯示區
	container = HSplitContainer.new()
	add_child(container)

	item_list = ItemList.new()
	item_list.custom_minimum_size = Vector2(200, 0)
	item_list.item_selected.connect(_on_item_selected)
	container.add_child(item_list)

	graph = BeehaveGraphEdit.new(BeehaveUtils.get_frames())
	container.add_child(graph)

	# 建立提示標籤，在尚未運行專案時顯示提示訊息
	message = Label.new()
	message.text = "Run Project for debugging"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.set_anchors_preset(Control.PRESET_CENTER)
	add_child(message)

	# 建立「浮動」按鈕，供使用者將面板分離成浮動視窗
	var button := Button.new()
	button.flat = true
	button.name = "MakeFloatingButton"
	button.icon = get_theme_icon(&"ExternalLink", &"EditorIcons")
	button.pressed.connect(func(): make_floating.emit())
	button.tooltip_text = "Make floating"
	button.focus_mode = Control.FOCUS_NONE
	graph.get_menu_container().add_child(button)

	# 建立「切換面板」按鈕，供顯示/隱藏左側行為樹列表
	var toggle_button := Button.new()
	toggle_button.flat = true
	toggle_button.name = "TogglePanelButton"
	toggle_button.icon = get_theme_icon(&"Back", &"EditorIcons")
	toggle_button.pressed.connect(_on_toggle_button_pressed.bind(toggle_button))
	toggle_button.tooltip_text = "Toggle Panel"
	toggle_button.focus_mode = Control.FOCUS_NONE
	graph.get_menu_container().add_child(toggle_button)
	graph.get_menu_container().move_child(toggle_button, 0)

	# 預設為停止狀態，並監聽可見性變化事件
	stop()
	visibility_changed.connect(_on_visibility_changed)


func start() -> void:
	# 偵錯導運行時，顯示容器並隱藏提示訊息
	container.visible = true
	message.visible = false


func stop() -> void:
	# 偵錯導停止時，隱藏容器並顯示提示訊息，並清除所有已註冊的行為樹資料
	container.visible = false
	message.visible = true

	active_trees.clear()
	item_list.clear()
	graph.beehave_tree = {}


func register_tree(data: Dictionary) -> void:
	# 若該行為樹尚未註冊，將其加入左側列表中顯示
	if not active_trees.has(data.id):
		var idx := item_list.add_item(data.name, TREE_ICON)
		item_list.set_item_tooltip(idx, data.path)
		item_list.set_item_metadata(idx, data.id)

	active_trees[data.id] = data

	# 若新註冊的行為樹即為當前選中的樹，即時更新圖形顯示內容
	if active_tree_id == data.id.to_int():
		graph.beehave_tree = data


func unregister_tree(instance_id: int) -> void:
	# 從列表中移除对應的項目
	var id := str(instance_id)
	for i in item_list.item_count:
		if item_list.get_item_metadata(i) == id:
			item_list.remove_item(i)
			break

	active_trees.erase(id)

	# 若被移除的正是當前顯示中的行為樹，清空圖形顯示
	if graph.beehave_tree.get("id", "") == id:
		graph.beehave_tree = {}


func _on_toggle_button_pressed(toggle_button: Button) -> void:
	# 切換左側列表的可見性，並切換按鈕圖標方向
	item_list.visible = !item_list.visible
	toggle_button.icon = get_theme_icon(
		&"Back" if item_list.visible else &"Forward", &"EditorIcons"
	)


func _on_item_selected(idx: int) -> void:
	# 當使用者選擇左側列表中的行為樹項目時，切換圖形顯示至对應的行為樹
	var id: StringName = item_list.get_item_metadata(idx)
	graph.beehave_tree = active_trees.get(id, {})

	active_tree_id = id.to_int()
	# 通知運行中的專案，現在转換至哪一個行為樹進行追蹤
	if session != null:
		session.send_message("beehave:activate_tree", [active_tree_id])


func _on_visibility_changed() -> void:
	# 通知運行中的專案，偵錯面板的可見性是否變化，以決定是否需要繼續傳送追蹤資料
	if session != null:
		session.send_message("beehave:visibility_changed", [visible and is_visible_in_tree()])
