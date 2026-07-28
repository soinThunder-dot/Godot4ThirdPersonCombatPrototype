# FPS 計數器：即時顯示目前遊戲畫面更新率（每秒幀數）
extends Label


func _physics_process(_delta: float) -> void:
	# 從引擎效能監控器取得目前 FPS 值並顯示在文字上
	text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
