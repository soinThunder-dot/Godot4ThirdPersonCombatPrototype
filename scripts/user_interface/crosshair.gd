# 準星節點：根據多個回呼函式的結果，決定是否顯示準星（例如瞄準敵人時顯示）
class_name Crosshair
extends Sprite3D

# 是否啟用準星邏輯
@export var enabled: bool = true
# 除錯模式開關，啟用後會印出準星相關狀態
@export var debug: bool = false
# 目前是否應顯示準星（由回呼結果決定）
@export var show_crosshair: bool = false

# 用於判斷是否顯示準星的回呼函式清單，只要有一個回傳 true 就顯示
var callbacks: Array[Callable]


func _ready() -> void:
	# 初始時準星完全透明（不顯示）
	modulate.a = 0.0


func _physics_process(_delta: float) -> void:
	# 若整體功能未啟用，直接跳過本幀處理
	if not enabled:
		return

	show_crosshair = false

	# 依序呼叫所有註冊的回呼函式，只要有一個回傳 true，就顯示準星
	for callback in callbacks:
		if bool(callback.call()) == true:
			show_crosshair = true
			break

	#if debug:
		#prints(
			#show_crosshair,
			#modulate.a,
			#visible
		#)

	# 若應顯示準星且尚未完全不透明，逐漸淡入
	if show_crosshair and modulate.a < 1.0:
		modulate.a = move_toward(
			modulate.a,
			1.0,
			0.05
		)
	# 否則若不應顯示且尚未完全透明，逐漸淡出
	elif not show_crosshair and modulate.a > 0.0:
		modulate.a = move_toward(
			modulate.a,
			0.0,
			0.05
		)


# 註冊一個新的回呼函式，用來判斷是否應顯示準星
func register_callback(callback: Callable) -> void:
	callbacks.append(callback)
