# ==========================================================
# 【檔案說明】world_environment.gd
# 這是「世界環境」節點的腳本。
# WorldEnvironment 控制整個場景的環境效果（天空、光照、霧氣、後製特效等）。
# 此腳本只做一件事：依照編輯器中的開關，決定是否開啟霧氣效果。
# 注意：這個腳本沒有 class_name，只是單純掛在節點上。
# ==========================================================

# 繼承 WorldEnvironment（世界環境節點）。
extends WorldEnvironment


# enable_fog：是否開啟霧氣（在編輯器中勾選），預設關閉。
@export var enable_fog: bool = false

# 初始化：套用霧氣設定。
func _ready():
	# 一般霧氣（距離霧，越遠越朦朧）。
	environment.fog_enabled = enable_fog
	# 體積霧（有立體感的霧，可與光線互動，較耗效能）。
	environment.volumetric_fog_enabled = enable_fog
