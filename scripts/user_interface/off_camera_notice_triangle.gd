# ==========================================================
# 【檔案說明】off_camera_notice_triangle.gd
# 這是「畫面外察覺指示」的腳本。
# 當敵人不在鏡頭畫面內、但正在察覺玩家時，
# 會在玩家周圍（畫面中央附近）顯示一個弧形/三角形指示，
# 並旋轉指向該敵人所在的方向，讓玩家知道「哪個方向有敵人在注意你」。
# 內部同樣用遮罩（Mask）的偏移來表示察覺程度的填滿效果。
# ==========================================================

# 註冊為全域類別 OffCameraNoticeTriangle。
class_name OffCameraNoticeTriangle
# 繼承 Node2D（2D 節點，可旋轉）。
extends Node2D


# debug：除錯開關（目前腳本中沒有使用）。
var debug: bool = false

# _original_scales：記錄各子節點的原始縮放值，之後縮放都以此為基準。
var _original_scales: Array[Vector2] = []

# ---------- 子節點參考 ----------
# triangle_arc_base：指示的外框（弧形底座）。
@onready var triangle_arc_base: Sprite2D = $TriangleArcBase
# inner_mask：內部三角形的遮罩，調整其偏移量來控制內部填滿程度。
@onready var inner_mask: Sprite2D = $InsideTriangleMask
# inner_triangle：內部被填滿的三角形（遮罩的子節點）。
@onready var inner_triangle: Sprite2D = $InsideTriangleMask/InsideTriangle
# background_mask：背景三角形的遮罩。
@onready var background_mask: Sprite2D = $BackgroundTriangleMask
# background_triangle：背景三角形（背景遮罩的子節點）。
@onready var background_triangle: Sprite2D = $BackgroundTriangleMask/BackgroundTriangle

# player：從 Globals 取得玩家節點（計算方向時需要玩家位置）。
@onready var player: Player = Globals.player
# camera_controller：從 Globals 取得相機控制器（需要相機的水平旋轉角度）。
@onready var camera_controller: CameraController = Globals.camera_controller


# 初始化：記錄子節點的原始縮放。
func _ready():
	# get_child_count() - 1：只處理「前 N-1 個」子節點，
	# 也就是跳過最後一個子節點（推測最後一個子節點不需要縮放）。
	# 在 GDScript 中「for index in 整數」等同於 range(整數)，從 0 開始。
	for index in get_child_count() - 1:
		_original_scales.append(get_child(index).scale)


# process_mask_offsets(value)：依察覺程度（0~1）設定兩個遮罩的偏移量，
# 使內部三角形與背景三角形呈現填滿效果。
func process_mask_offsets(value: float) -> void:
	# 內部三角形遮罩的偏移。
	inner_mask.offset.y = get_off_cam_inside_offset(value)
	# 背景三角形遮罩的偏移。
	background_mask.offset.y = get_off_cam_background_offset(value)


# process_desired_rotation(entity)：讓指示旋轉，指向指定敵人（entity）的方向。
# 計算方式：
#   1. 取得「相機正前方」的方向：把 Vector3.FORWARD（-Z 方向）
#      繞著 Y 軸（Vector3.UP）旋轉相機的水平角度（rotation_degrees.y）。
#   2. 取得「玩家 → 敵人」的方向向量（direction_to）。
#   3. 用 signed_angle_to 計算這兩個方向之間的「有正負號的夾角」（弧度），
#      以 Y 軸為旋轉軸，正負號代表敵人在左邊還是右邊。
#   4. rad_to_deg 轉換成角度 r。
# 註：下方多行運算式中使用反斜線「\」作為換行接續符號。
func process_desired_rotation(entity: Node3D) -> void:
	var r = rad_to_deg(
	Vector3.FORWARD\
		.rotated(
			Vector3.UP,
			deg_to_rad(camera_controller.rotation_degrees.y)
		)\
		.signed_angle_to(
			player\
				.global_position\
				.direction_to(
					entity.global_position
				),
			Vector3.UP
		)
	)
	
	# 把 3D 夾角轉換成 2D 畫面上的旋轉角度：
	# 取負號是因為 3D 的角度方向與 2D 螢幕的旋轉方向相反；
	# 再加 180 度是為了配合指示貼圖本身的朝向（讓它的尖端指向敵人）。
	var desired_rotation: float = -r + 180
	# 套用旋轉角度（單位：度）。
	rotation_degrees = desired_rotation


# process_scale(expand_scale)：依倍率縮放子節點（與 _ready 一樣跳過最後一個子節點）。
func process_scale(expand_scale: float) -> void:
	for index in get_child_count() - 1:
		# 原始縮放 × 倍率。
		get_child(index).scale = _original_scales[index] * Vector2(expand_scale, expand_scale)


# process_colour(colour)：讓外框與內部三角形的顏色平滑變化到指定顏色。
func process_colour(colour: Color) -> void:
	# 外框：每次呼叫往目標顏色靠近 20%。
	triangle_arc_base.self_modulate = lerp(
		triangle_arc_base.self_modulate,
		colour,
		0.2
	)
	
	# 內部三角形：每次呼叫往目標顏色靠近 20%。
	inner_triangle.self_modulate = lerp(
		inner_triangle.self_modulate,
		colour,
		0.2
	)


# process_alpha(alpha)：讓整個指示（含子節點）的透明度平滑變化到指定值。
func process_alpha(alpha: float) -> void:
	modulate.a = lerp(
		modulate.a,
		alpha,
		0.1
	)


# get_off_cam_inside_offset(value)：內部遮罩偏移的線性公式。
#   value = 0 → -76.0；value = 1 → -11.0（65 - 76）。
# 數值是依貼圖尺寸手動調整出來的。
func get_off_cam_inside_offset(value: float) -> float:
	return 65.0 * value - 76.0


# get_off_cam_background_offset(value)：背景遮罩偏移的線性公式。
#   value = 0 → 23.0；value = 1 → 90.0（67 + 23）。
func get_off_cam_background_offset(value: float) -> float:
	return 67.0 * value + 23.0
