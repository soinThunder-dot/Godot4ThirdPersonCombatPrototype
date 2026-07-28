# 互動提示：當玩家靠近可互動物件時顯示提示圖示（例如檢查點提示）
class_name InteractionHints
extends Control


# 控制目前有多少個互動提示需要顯示，均由 setter 確保不會小於 0
var counter: int:
	set(value):
		counter = max(0, value)

# 檢查點互動提示圖示節點參照
@onready var checkpoint_hint = $CheckpointHint


func _physics_process(_delta):
	# 若目前有互動提示需要顯示，逐漸淡入
	if counter > 0:
		modulate.a = lerp(
			modulate.a,
			1.0,
			0.25
		)
	# 否則逐漸淡出
	else:
		modulate.a = lerp(
			modulate.a,
			0.0,
			0.25
		)
