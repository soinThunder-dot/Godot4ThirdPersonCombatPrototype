# ==========================================================
# 【檔案說明】wellbeing_stats.gd
# 這個 Resource 保存實體的生命值與失衡值上限、初始值，以及是否允許降低失衡的設定。
# 各項數值可在 Inspector 編輯；setter 會限制無效的負上限，並把初始值夾在有效範圍內。
# 本檔只負責提供可重用的狀態資料，不直接執行生命值或失衡的變化流程。
# ==========================================================

# 本腳本標記為 @tool，供 Godot 編輯器端識別並執行工具腳本。
@tool

# 註冊為可在 Godot 中識別的 WellbeingStats 類別。
class_name WellbeingStats
# 繼承 Resource，使生命與失衡設定可保存為資源並供其他元件引用。
extends Resource


# 生命值上限；若寫入負數，setter 會將上限改回 100。
@export var max_health: float = 100:
	# setter 在 max_health 被指定新值時執行；負值視為無效並重設為預設上限 100。
	set(value):
		# 若指定值小於零，就使用 100 作為安全預設值。
		if value < 0:
			value = 100
		max_health = value
# 初始生命值；setter 將值限制在 0 到目前 max_health 之間。
@export var initial_health: float = 100:
	# clamp 會將輸入限制於上下界，避免初始生命值超過上限或低於零。
	set(value):
		initial_health = clamp(value, 0, max_health)

# 失衡值上限；若寫入負數，setter 會將上限改回 100。
@export var max_instability: float = 100:
	# setter 在 max_instability 被指定新值時執行；負值視為無效並重設為 100。
	set(value):
		# 若指定值小於零，就使用 100 作為安全預設值。
		if value < 0:
			value = 100
		max_instability = value
# 初始失衡值；setter 將值限制在 0 到目前 max_instability 之間。
@export var initial_instability: float = 0:
	# clamp 避免初始失衡小於零或高於設定的最大失衡值。
	set(value):
		initial_instability = clamp(value, 0, max_instability)
# 是否允許其他系統降低失衡值；預設允許。
@export var can_reduce_instability: bool = true
