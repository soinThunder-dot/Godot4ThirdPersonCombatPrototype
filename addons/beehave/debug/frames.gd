@tool
extends RefCounted

## 偵錯器圖形幀樣式資源：為行為樹編輯器偵錯面板中的節點圖提供不同狀態（成功/失敗/執行中）的樣式。

const BeehaveUtils := preload("res://addons/beehave/utils/utils.gd")

const SUCCESS_COLOR := Color("#07783a")
const NORMAL_COLOR := Color("#15181e")
const FAILURE_COLOR := Color("#82010b")
const RUNNING_COLOR := Color("#c29c06")

var panel_normal: StyleBoxFlat
var panel_success: StyleBoxFlat
var panel_failure: StyleBoxFlat
var panel_running: StyleBoxFlat

var titlebar_normal: StyleBoxFlat
var titlebar_success: StyleBoxFlat
var titlebar_failure: StyleBoxFlat
var titlebar_running: StyleBoxFlat


func _init() -> void:
	# 取得插件實例，若不存在則直接結束（例如在遊戲運行時）
	var plugin := BeehaveUtils.get_plugin()
	if not plugin:
		return
	
			# 從編輯器主題中取得 GraphNode 的標題列樣式作為基礎，並複製出四種狀態的樣式
	titlebar_normal = plugin.get_editor_interface().get_base_control().get_theme_stylebox(&"titlebar", &"GraphNode").duplicate()
	titlebar_success = titlebar_normal.duplicate()
	titlebar_failure = titlebar_normal.duplicate()
	titlebar_running = titlebar_normal.duplicate()
	
			# 依當前 tick 狀態設定標題列的背景色
	titlebar_success.bg_color = SUCCESS_COLOR
	titlebar_failure.bg_color = FAILURE_COLOR
	titlebar_running.bg_color = RUNNING_COLOR
	
			# 依當前 tick 狀態設定標題列的邊框色
	titlebar_success.border_color = SUCCESS_COLOR
	titlebar_failure.border_color = FAILURE_COLOR
	titlebar_running.border_color = RUNNING_COLOR
	
	# 取得普通面板樣式作為基礎，並取得選取狀態面板樣式作為其他狀態的基礎
	panel_normal = plugin.get_editor_interface().get_base_control().get_theme_stylebox(&"panel", &"GraphNode").duplicate()
	panel_success = plugin.get_editor_interface().get_base_control().get_theme_stylebox(&"panel_selected", &"GraphNode").duplicate()
	panel_failure = panel_success.duplicate()
	panel_running = panel_success.duplicate()
	
	# 依當前 tick 状態設定面板的邊框色
	panel_success.border_color = SUCCESS_COLOR
	panel_failure.border_color = FAILURE_COLOR
	panel_running.border_color = RUNNING_COLOR
