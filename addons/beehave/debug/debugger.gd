@tool
extends EditorDebuggerPlugin

const DebuggerTab := preload("debugger_tab.gd")
const BeehaveUtils := preload("res://addons/beehave/utils/utils.gd")

var debugger_tab := DebuggerTab.new()
var floating_window: Window
var session: EditorDebuggerSession


func _has_capture(prefix: String) -> bool:
	# 只攔截前綴為 "beehave" 的訊息，代表這是行為樹除錯資料
	return prefix == "beehave"


func _capture(message: String, data: Array, session_id: int) -> bool:
	# 若行為樹設定有誤，debugger_tab 可能為 null，此時直接放棄處理
	if debugger_tab == null:
		return false
	
	# 依照收到的訊息類型，將資料轉交給對應的處理函式
	if message == "beehave:register_tree":
		debugger_tab.register_tree(data[0])
		return true
	if message == "beehave:unregister_tree":
		debugger_tab.unregister_tree(data[0])
		return true
	if message == "beehave:process_tick":
		# 每次行為樹刻度執行時，更新圖形節點狀態
		debugger_tab.graph.process_tick(data[0], data[1])
		return true
	if message == "beehave:process_begin":
		# 行為樹開始執行時，標記起始狀態
		debugger_tab.graph.process_begin(data[0])
		return true
	if message == "beehave:process_end":
		# 行為樹執行結束時，標記結束狀態
		debugger_tab.graph.process_end(data[0])
		return true
	return false
