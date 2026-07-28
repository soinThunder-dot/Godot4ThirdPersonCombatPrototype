# 鏢外提示三角形：當目標位於鏢外時，顯示方向性三角形指向其位置
class_name OffCameraNoticeTriangle
extends Node2D

var debug: bool = false

# 保存每個子節點初始縮放值，供縮放運算使用
var _original_scales: Array[Vector2] = []

@onready var triangle_arc_base: Sprite2D = $TriangleArcBase
@onready var inner_mask: Sprite2D = $InsideTriangleMask
@onready var inner_triangle: Sprite2D = $InsideTriangleMask/InsideTriangle
@onready var background_mask: Sprite2D = $BackgroundTriangleMask
@onready var background_triangle: Sprite2D = $BackgroundTriangleMask/BackgroundTriangle

@onready var player: Player = Globals.player
@onready var camera_controller: CameraController = Globals.camera_controller


func _ready():
	# 記錄除最後一個以外所有子節點的初始縮放
	for index in get_child_count() - 1:
		_original_scales.append(get_child(index).scale)


# 設定內外遮罩位移，控制鏢外提示圖形顯示範圍
func process_mask_offsets(value: float) -> void:
	inner_mask.offset.y = get_off_cam_inside_offset(value)
	background_mask.offset.y = get_off_cam_background_offset(value)


# 根據相機方向與玩家到目標的方向，計算三角形應旋轉的角度
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
	
	var desired_rotation: float = -r + 180
	rotation_degrees = desired_rotation


# 依據擴張比例，將每個子節點縮放回從原始值調整
func process_scale(expand_scale: float) -> void:
	for index in get_child_count() - 1:
		get_child(index).scale = _original_scales[index] * Vector2(expand_scale, expand_scale)


# 平滑過渡三角形弧形基座與內部三角形的顏色
func process_colour(colour: Color) -> void:
	triangle_arc_base.self_modulate = lerp(
		triangle_arc_base.self_modulate,
		colour,
		0.2
	)
	
	inner_triangle.self_modulate = lerp(
		inner_triangle.self_modulate,
		colour,
		0.2
	)


# 平滑過渡整體透明度
func process_alpha(alpha: float) -> void:
	modulate.a = lerp(
		modulate.a,
		alpha,
		0.1
	)


# 根據目標於鏢外的程度計算內部遮罩的位移量
func get_off_cam_inside_offset(value: float) -> float:
	return 65.0 * value - 76.0


# 根據目標於鏢外的程度計算背景遮罩的位移量
func get_off_cam_background_offset(value: float) -> float:
	return 67.0 * value + 23.0
