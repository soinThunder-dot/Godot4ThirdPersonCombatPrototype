# ==========================================================
# 【檔案說明】crosshair.gd
# 這是「準心」的腳本，準心是一個 3D 空間中的 Sprite（Sprite3D）。
# 它採用「回呼函式（callback）」機制：
#   其他系統可以註冊一個函式，只要「任何一個」函式回傳 true，就顯示準心。
#   （例如：瞄準時、鎖定時……由其他腳本決定。）
# 準心的出現與消失是用透明度漸變完成的。
# ==========================================================

# 註冊為全域類別 Crosshair。
class_name Crosshair
# 繼承 Sprite3D：在 3D 世界中顯示的 2D 圖片。
extends Sprite3D


# @export：讓變數出現在 Godot 編輯器的屬性面板（Inspector）中，可直接調整。
# enabled：是否啟用準心邏輯。false 時 _physics_process 直接跳過，不做任何更新。
@export var enabled: bool = true
# debug：除錯開關，配合下方被註解掉的 prints 使用。
@export var debug: bool = false
# show_crosshair：目前是否應該顯示準心（每影格會重新計算）。
@export var show_crosshair: bool = false

# callbacks：存放所有已註冊的回呼函式（Callable 陣列）。
# 每個 Callable 被呼叫時應回傳 true/false，代表「是否需要顯示準心」。
var callbacks: Array[Callable]


# 初始化：一開始把準心設為完全透明（看不到）。
func _ready() -> void:
	modulate.a = 0.0


# 每個物理影格執行一次。
func _physics_process(_delta: float) -> void:
	# 若準心功能被停用，直接結束，不做任何處理。
	if not enabled:
		return
	
	# 先預設「不顯示」，再逐一檢查回呼函式。
	show_crosshair = false
	
	# 逐一呼叫所有註冊的回呼函式：
	for callback in callbacks:
		# callback.call() 執行該函式並取得回傳值，用 bool() 轉成布林值。
		# 只要有一個回傳 true，就代表需要顯示準心。
		if bool(callback.call()) == true:
			show_crosshair = true
			# 已經確定要顯示，不需再檢查剩下的函式，跳出迴圈。
			break
	
	# 以下是作者留下的除錯程式碼（已被註解停用），
	# 若開啟可印出：是否顯示準心、目前透明度、是否可見。
	#if debug:
		#prints(
			#show_crosshair,
			#modulate.a,
			#visible
		#)
	
	# move_toward(from, to, delta)：讓 from 往 to 移動固定量 delta，不會超過 to。
	# 與 lerp 不同，這是「等速」變化：每影格固定改變 0.05，
	# 所以從 0 到 1 大約需要 20 個物理影格（約 1/3 秒）。
	# 需要顯示、且目前還沒完全不透明 → 逐漸淡入。
	if show_crosshair and modulate.a < 1.0:
		modulate.a = move_toward(
			modulate.a,
			1.0,
			0.05
		)
	# 不需要顯示、且目前還沒完全透明 → 逐漸淡出。
	elif not show_crosshair and modulate.a > 0.0:
		modulate.a = move_toward(
			modulate.a,
			0.0,
			0.05
		)


# register_callback(callback)：讓外部腳本註冊判斷函式。
# 例如：crosshair.register_callback(func(): return is_aiming)
func register_callback(callback: Callable) -> void:
	# 加入陣列，之後每影格都會被呼叫檢查。
	callbacks.append(callback)
