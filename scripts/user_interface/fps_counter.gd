# ==========================================================
# 【檔案說明】fps_counter.gd
# 這是「FPS（每秒影格數）計數器」的腳本。
# 它掛在一個 Label（文字標籤）上，持續顯示目前遊戲的 FPS，
# 方便開發時觀察效能。
# 注意：這個腳本沒有 class_name，所以不是全域類別，只是單純掛在節點上。
# ==========================================================

# 繼承 Label：用來顯示文字的 UI 節點。
extends Label


# 每個物理影格更新一次文字內容。
func _physics_process(_delta: float) -> void:
	# Performance.get_monitor(Performance.TIME_FPS)：取得引擎目前的 FPS 數值。
	# str(...)：把數字轉成字串，再與 "FPS: " 串接，
	# 最後指定給 Label 的 text 屬性，畫面上就會顯示例如「FPS: 60」。
	text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
