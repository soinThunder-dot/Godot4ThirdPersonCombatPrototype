# ==========================================================
# 【檔案說明】heads_up_display.gd
# 這是 HUD（抬頭顯示器，Heads-Up Display）的主腳本。
# HUD 是遊戲進行中畫面上常駐的介面，包含：
#   - 敵人頭上的「察覺三角形」（NoticeTriangles）
#   - 畫面外敵人的察覺指示（OffCameraNoticeTriangles）
#   - 敵人的血條/失衡條小工具（WellbeingWidgets）
#   - 互動提示（InteractionHints）
#   - 玩家的失衡條（PlayerInstabilityBar）
#   - 鎖定目標的標記圖示（LockOn）
# 此腳本負責：鎖定標記的位置更新、HUD 整體淡入淡出、清除敵人相關 HUD。
# ==========================================================

# 註冊為全域類別 HeadsUpDisplay。
class_name HeadsUpDisplay
# 繼承 Control（UI 節點）。
extends Control


# enabled：HUD 是否啟用（可在編輯器調整）。
# true 時 HUD 淡入顯示，false 時 HUD 淡出隱藏（例如過場動畫時）。
@export var enabled: bool = true

# _lock_on_target：目前鎖定的目標（LockOnComponent 元件），null 代表沒有鎖定。
var _lock_on_target: LockOnComponent = null

# ---------- 子節點參考 ----------
# notice_triangles：存放所有「敵人察覺三角形」的容器（Node2D）。
@onready var notice_triangles: Node2D = $NoticeTriangles
# off_camera_notice_triangles：存放「畫面外敵人察覺指示」的容器。
@onready var off_camera_notice_triangles: Control = $OffCameraNoticeTriangles
# wellbeing_widgets：存放所有敵人「狀態小工具」（血條 + 失衡條）的容器。
@onready var wellbeing_widgets: Node2D = $WellbeingWidgets
# interaction_hints：互動提示節點（例如「按 E 休息」）。
@onready var interaction_hints: InteractionHints = $InteractionHints
# instability_bar：玩家的失衡條。
@onready var instability_bar: PlayerInstabilityBar = $PlayerInstabilityBar

# _lock_on_texture：鎖定目標時顯示在目標身上的標記圖片。
@onready var _lock_on_texture: TextureRect = $LockOn

# ---------- 全域系統參考（來自 Globals 單例）----------
# lock_on_system：鎖定系統，鎖定/取消鎖定目標時會發出 lock_on 訊號。
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system
# backstab_system：背刺系統（本腳本目前只取得參考，尚未使用）。
@onready var backstab_system: BackstabSystem = Globals.backstab_system
# dizzy_system：暈眩系統（本腳本目前只取得參考，尚未使用）。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# 初始化。
func _ready() -> void:
	# 一開始沒有鎖定任何目標，隱藏鎖定標記。
	_lock_on_texture.visible = false
	
	# 連接鎖定系統的 lock_on 訊號：
	# 每當玩家鎖定（或取消鎖定）目標時，呼叫 _on_lock_on_system_lock_on。
	lock_on_system.lock_on.connect(
		_on_lock_on_system_lock_on
	)


# 每個物理影格執行。
func _physics_process(_delta: float) -> void:
	
	# 更新鎖定標記在螢幕上的位置。
	_process_lock_on()
	
	# 有鎖定目標（不是 null）就顯示鎖定標記，否則隱藏。
	_lock_on_texture.visible = _lock_on_target != null
	
	# HUD 整體淡入淡出：
	# modulate 會影響此節點「和所有子節點」，所以整個 HUD 會一起變化。
	if enabled:
		# 啟用時逐漸變為不透明。
		modulate.a = lerp(
			modulate.a,
			1.0,
			0.1
		)
	else:
		# 停用時逐漸變為透明。
		modulate.a = lerp(
			modulate.a,
			0.0,
			0.1
		)


# 鎖定系統發出 lock_on 訊號時的處理函式。
# target：新的鎖定目標；取消鎖定時通常會傳入 null。
func _on_lock_on_system_lock_on(target: LockOnComponent) -> void:
	# 記錄目前的鎖定目標。
	_lock_on_target = target


# _process_lock_on()：把鎖定標記移到目標在螢幕上的位置。
func _process_lock_on() -> void:
	# 如果沒有鎖定目標，直接結束（寫在同一行的簡寫 if）。
	if not _lock_on_target: return
	
	# 請相機控制器計算：鎖定目標在 3D 世界中的位置，投影到螢幕上的 2D 座標。
	var pos: Vector2 = Globals.camera_controller.get_lock_on_position(
		_lock_on_target
	)
	# Control 的 position 是「左上角」的位置，
	# 所以要減去貼圖寬高的一半，讓標記的「中心」對準目標。
	var lock_on_pos: Vector2 = Vector2(
		pos.x - _lock_on_texture.size.x / 2,
		pos.y - _lock_on_texture.size.y / 2
	)
	
	# 套用計算好的位置。
	_lock_on_texture.position = lock_on_pos


# clear_enemy_hud_elements()：清除所有與敵人相關的 HUD 元素。
# 通常在玩家死亡重生或在檢查點恢復（敵人重生）時呼叫，避免殘留舊的介面。
func clear_enemy_hud_elements() -> void:
	# 刪除所有察覺三角形。
	# queue_free()：在目前影格結束後安全地刪除節點。
	for child in notice_triangles.get_children():
		child.queue_free()
	
	# 刪除所有敵人的狀態小工具（血條/失衡條）。
	for child in wellbeing_widgets.get_children():
		child.queue_free()
	
	# 刪除所有畫面外察覺指示。
	for child in off_camera_notice_triangles.get_children():
		child.queue_free()
