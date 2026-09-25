# ==========================================================
# 【檔案說明】interaction_hints.gd
# 這是「互動提示」的腳本（例如靠近檢查點時顯示「按某鍵休息」）。
# 使用「計數器（counter）」機制：
#   - 玩家進入某個可互動區域時，counter + 1
#   - 離開時，counter - 1
#   - 只要 counter > 0（至少在一個互動區域內）就顯示提示，否則隱藏
# 這樣即使多個互動區域重疊，也不會因為離開其中一個就錯誤地隱藏提示。
# ==========================================================

# 註冊為全域類別 InteractionHints。
class_name InteractionHints
# 繼承 Control（UI 節點）。
extends Control


# counter：目前玩家所在的互動區域數量。
# 這裡使用了 Godot 4 的屬性 setter 語法：
# 每次對 counter 賦值時，都會執行下面的 set(value) 區塊。
var counter: int:
	set(value):
		# max(0, value)：確保 counter 永遠不會小於 0，
		# 避免因為多扣了一次而變成負數，導致提示永遠不顯示。
		counter = max(0, value)

# checkpoint_hint：檢查點的提示節點（例如顯示「休息」按鍵圖示的子節點）。
@onready var checkpoint_hint = $CheckpointHint


# 每個物理影格執行：依照 counter 決定提示淡入或淡出。
func _physics_process(_delta):
	# 玩家至少在一個互動區域內 → 提示淡入。
	# 係數 0.25 比較大，所以變化很快（每影格靠近目標 25%）。
	if counter > 0:
		modulate.a = lerp(
			modulate.a,
			1.0,
			0.25
		)
	# 玩家不在任何互動區域 → 提示淡出。
	else:
		modulate.a = lerp(
			modulate.a,
			0.0,
			0.25
		)
