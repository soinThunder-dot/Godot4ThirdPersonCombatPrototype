# 玩家主 HUD：整合顯示鎖定框、敌人提示三角形、不適感小工具、互動提示、不穩定條等 UI 元素
class_name HeadsUpDisplay
extends Control

# 是否啟用整個 HUD 顯示
@export var enabled: bool = true

# 目前鎖定中的目標（若無則為 null）
var _lock_on_target: LockOnComponent = null

# UI 子節點參照：提示三角形、鏡頭外提示、不適感小部件、互動提示、不穩定條
@onready var notice_triangles: Node2D = $NoticeTriangles
@onready var off_camera_notice_triangles: Control = $OffCameraNoticeTriangles
@onready var wellbeing_widgets: Node2D = $WellbeingWidgets
@onready var interaction_hints: InteractionHints = $InteractionHints
@onready var instability_bar: PlayerInstabilityBar = $PlayerInstabilityBar

# 鎖定框貼圖節點，用於標示鎖定中的目標位置
@onready var _lock_on_texture: TextureRect = $LockOn

# 相關系統參照：鎖定系統、偷袭系統、暈眩系統
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system
@onready var backstab_system: BackstabSystem = Globals.backstab_system
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


func _ready() -> void:
	# 初始時鎖定框貼圖不顯示
	_lock_on_texture.visible = false

	# 監聽鎖定系統發出的鎖定事件，更新目前鎖定目標
	lock_on_system.lock_on.connect(
		_on_lock_on_system_lock_on
	)


func _physics_process(_delta: float) -> void:
	# 每幀更新鎖定框位置
	_process_lock_on()

	# 根據是否有鎖定目標來決定鎖定框是否顯示
	_lock_on_texture.visible = _lock_on_target != null

	# 根據 HUD 是否啟用，逐漸淡入或淡出整個 HUD 的透明度
	if enabled:
		modulate.a = lerp(
			modulate.a,
			1.0,
			0.1
		)
	else:
		modulate.a = lerp(
			modulate.a,
			0.0,
			0.1
		)


# 當鎖定系統鎖定一個新目標時呼叫，記錄下來供顯示鎖定框使用
func _on_lock_on_system_lock_on(target: LockOnComponent) -> void:
	_lock_on_target = target


# 根據目前鎖定目標的位置，更新鎖定框在畫面上的位置
func _process_lock_on() -> void:
	if not _lock_on_target: return

	# 取得目標在螢幕上的對應位置
	var pos: Vector2 = Globals.camera_controller.get_lock_on_position(
		_lock_on_target
	)

	# 以鎖定框貼圖尺寸的一半作為偏移，使鎖定框能夠居中對準目標
	var lock_on_pos: Vector2 = Vector2(
		pos.x - _lock_on_texture.size.x / 2,
		pos.y - _lock_on_texture.size.y / 2
	)

	_lock_on_texture.position = lock_on_pos


# 清除所有與敌人相關的 HUD 元素（提示三角形、不適感小部件、鏡頭外提示），通常在離開战鬥或切換場景時使用
func clear_enemy_hud_elements() -> void:
	for child in notice_triangles.get_children():
		child.queue_free()

	for child in wellbeing_widgets.get_children():
		child.queue_free()

	for child in off_camera_notice_triangles.get_children():
		child.queue_free()
