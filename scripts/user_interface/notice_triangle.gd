# 通知三角形：用於顯示方向性提示圖示（如場外提示），可依狀態改變顏色與縮放
class_name NoticeTriangle
extends Sprite2D

# 記錄初始縮放比例，供後續縮放運算使用
var original_scale: Vector2

@onready var background_triangle: Sprite2D = $BackgroundTriangle
@onready var triangle_mask: Sprite2D = $TriangleMask
@onready var inner_triangle: Sprite2D = $TriangleMask/InsideTriangle


func _ready():
	# 保存節點初始縮放值
	original_scale = scale


# 設定遮罩位移，用來控制三角形內部圖形顯示範圍
func process_mask_offset(value: float) -> void:
	triangle_mask.offset.y = get_mask_offset(value)


# 依據傳入的擴張比例調整整體縮放
func process_scale(expand_scale: float) -> void:
	scale = original_scale * Vector2(expand_scale, expand_scale)


# 平滑過渡三角形本體與內部三角形的顏色
func process_colour(colour: Color) -> void:
	self_modulate = lerp(
		self_modulate,
		colour,
		0.2
	)
	
	inner_triangle.self_modulate = lerp(
		inner_triangle.self_modulate,
		colour,
		0.2
	)
