@tool
extends EditorPlugin

## Beehave 插件主入口：負責註冊全域自動載入節點及編輯器偵錯器面板。

const BeehaveEditorDebugger := preload("debug/debugger.gd")
var editor_debugger: BeehaveEditorDebugger
var frames: RefCounted


func _init():
	name = "BeehavePlugin"
	# 註冊全域指標與偵錯器自動載入節點，使其在遊戲運行時可被全域存取
	add_autoload_singleton("BeehaveGlobalMetrics", "metrics/beehave_global_metrics.gd")
	add_autoload_singleton("BeehaveGlobalDebugger", "debug/global_debugger.gd")
	print("Beehave initialized!")


func _enter_tree() -> void:
	# 建立編輯器偵錯器實例並載入共用動畫幀資源
	editor_debugger = BeehaveEditorDebugger.new()
	frames = preload("debug/frames.gd").new()
	# 將偵錯器面板加入編輯器的 Debugger 選項卡中
	add_debugger_plugin(editor_debugger)


func _exit_tree() -> void:
			# 插件卸載時，移除已註冊的偵錯器面板，避免資源洩漏
	remove_debugger_plugin(editor_debugger)
