# ==========================================================
# 【檔案說明】secondary_movement.gd
# 這個 Resource 描述一段次級移動效果的參數，適合由其他移動系統用來設定推力或擊退。
# 它保存速度、效果時間、摩擦力與方向；本檔只定義資料和建立資源的方法，
# 實際如何逐影格套用這些數值取決於使用此資源的移動元件。
# ==========================================================

# 本腳本標記為 @tool，讓資源腳本可在編輯器環境中執行其工具端邏輯。
@tool

# 註冊為可在 Godot 中識別的 SecondaryMovement 類別。
class_name SecondaryMovement
# 繼承 Resource，讓這組移動參數能作為資源儲存、指定與重用。
extends Resource


# 次級移動的速度大小；預設值為 3.0。
@export var speed: float = 3.0
# 次級移動持續時間（秒）；設定時會將負值限制為 0，避免時間小於零。
@export var time: float = 5.0:
	# setter 在外部寫入 time 時執行；max 取兩者較大值，因此不會保存負時間。
	set(value): time = max(0.0, value)
# 次級移動的摩擦力參數；實際衰減方式由讀取此資源的移動元件決定。
@export var friction: float = 5.0
# 次級移動方向向量；Vector3.ZERO 代表預設為零向量。
@export var direction: Vector3 = Vector3.ZERO


# create：以參數建立並回傳新的 SecondaryMovement 資源。
# _speed、_time、_friction 分別設定速度、持續時間與摩擦力；_direction 是移動方向向量。
# static 表示此工廠函式可以直接透過類別呼叫。
static func create(
	_speed: float,
	_time: float,
	_friction: float,
	_direction: Vector3
) -> SecondaryMovement:
	# 建立新資源並逐欄位填入呼叫端提供的值。
	var instance = SecondaryMovement.new()
	instance.speed = _speed
	instance.time = _time
	instance.friction = _friction
	instance.direction = _direction
	# 回傳可由移動系統使用的完整設定。
	return instance
