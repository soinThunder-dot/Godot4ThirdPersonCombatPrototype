class_name BeehaveDebuggerMessages

## 偵錯器訊息傳送工具類：負責透過 EngineDebugger 將行為樹的運行資料傳送到編輯器偵錯面板。

static func can_send_message() -> bool:
			# 只有在非編輯器實例且具備 editor 功能時，才允許傳送訊息
	return not Engine.is_editor_hint() and OS.has_feature("editor")


static func register_tree(beehave_tree: Dictionary) -> void:
	# 通知編輯器有新的行為樹已註冊
	if can_send_message():
		EngineDebugger.send_message("beehave:register_tree", [beehave_tree])


static func unregister_tree(instance_id: int) -> void:
	# 通知編輯器指定行為樹已被移除
	if can_send_message():
		EngineDebugger.send_message("beehave:unregister_tree", [instance_id])


static func process_tick(instance_id: int, status: int) -> void:
	# 通知編輯器該行為樹本次 tick 的執行結果状態
	if can_send_message():
		EngineDebugger.send_message("beehave:process_tick", [instance_id, status])


static func process_begin(instance_id: int) -> void:
			# 通知編輯器該行為樹開始執行 tick
	if can_send_message():
		EngineDebugger.send_message("beehave:process_begin", [instance_id])


static func process_end(instance_id: int) -> void:
	# 通知編輯器該行為樹已完成本次 tick 執行
	if can_send_message():
		EngineDebugger.send_message("beehave:process_end", [instance_id])
