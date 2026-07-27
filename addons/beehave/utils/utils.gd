@tool

## 工具函式集合：提供取得 Beehave 插件實例、編輯器縮放比例及動畫幀資源的共用存取方法。

static func get_plugin() -> EditorPlugin:
	# 從場景樹的根節點中尋找名為 "BeehavePlugin" 的節點，以取得插件實例
	var tree: SceneTree = Engine.get_main_loop()
	return tree.get_root().get_child(0).get_node_or_null("BeehavePlugin")


static func get_editor_scale() -> float:
	# 若插件存在，回傳編輯器目前的介面縮放比例
	var plugin := get_plugin()
	if plugin:
		return plugin.get_editor_interface().get_editor_scale()
	# 若未取得插件（例如在遊戲運行時），預設回傳 1.0
	return 1.0


static func get_frames() -> RefCounted:
	# 嘗試從插件實例中取得共用的動畫幀資源
	var plugin := get_plugin()
	if plugin:
		return plugin.frames
	# 若找不到插件，輸出錯誤並回傳 null
	push_error("Can't find Beehave Plugin")
	return null
