# ==============================================================
# 拖尾特效 (Trail3D)
#
# 用於產生角色或武器移動時的拖尾殘影特效，
# 透過動態產生三角形條帶網格來表現。
# 參考教學：https://www.youtube.com/watch?v=vKrrxKS-lcA
# ==============================================================
class_name Trail3D
extends MeshInstance3D

"""
from https://www.youtube.com/watch?v=vKrrxKS-lcA
"""

# 是否啟用拖尾效果
@export var trail_enabled : bool = true

# 拖尾起始端的寬度
@export var _from_width : float = 0.5
# 拖尾末端的寬度
@export var _to_width : float = 0.0
# 寬度衰減的縮放加速度
@export_range(0.5, 1.5) var _scale_acceleration : float = 1.0

# 新增點的最小移動距離門櫃
@export var _motion_delta : float = 0.01
# 每個點的存活時間
@export var _lifespan : float = 1.0

# 拖尾起始顏色
@export var _start_color : Color = Color(1.0, 1.0, 1.0, 1.0)
# 拖尾結束顏色（這裡預設透明度為 0，表示淡出）
@export var _end_color : Color = Color(1.0, 1.0, 1.0, 0.0)

# 記錄拖尾上每一點的位置
var _points = []
# 記錄每一點對應的寬度資訊
var _widths = []
# 記錄每一點已存活的時間
var _life_points = []

# 上一幀的位置，用於判斷是否移動足夠距離新增點
var _old_pos : Vector3

# 初始化：記錄起始位置並建立動態網格
func _ready() -> void:
	_old_pos = global_transform.origin
	mesh = ImmediateMesh.new()

# 每幀更新：新增拖尾點、移除過期點，並重新繪製拖尾網格
func _process(delta):
	if trail_enabled and \
	(_old_pos - global_transform.origin).length() > _motion_delta:
		_append_point()
		_old_pos = global_transform.origin
	
	var p = 0
	var max_points = _points.size()
	while p < max_points:
		_life_points[p] += delta
		if _life_points[p] > _lifespan:
			_remove_point(p)
			max_points = _points.size()
		else:
			p += 1
	
	mesh.clear_surfaces()
	
	if _points.size() < 2:
		return
	
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(_points.size()):
		var t = float(i) / (_points.size() - 1.0)
		var curr_color = _start_color.lerp(_end_color, 1 - t)
		mesh.surface_set_color(curr_color)
		
		var curr_width = _widths[i][0] \
		- pow(1 - t, _scale_acceleration) \
		* _widths[i][1]
		
		var t0 = i / float(_points.size())
		var t1 = t
		mesh.surface_set_uv(Vector2(t0, 0))
		mesh.surface_add_vertex(to_local(_points[i] + curr_width))
		mesh.surface_set_uv(Vector2(t1, 1))
		mesh.surface_add_vertex(to_local(_points[i] - curr_width))
	mesh.surface_end()

# 新增一個拖尾點，記錄目前位置、寬度及初始存活時間
func _append_point() -> void:
	_points.append(global_transform.origin)
	_widths.append([
		global_transform.basis.x * _from_width,
		global_transform.basis.x * _from_width \
		- global_transform.basis.x * _to_width
	])
	_life_points.append(0.0)

# 移除指定索引的拖尾點（已超過存活時間）
func _remove_point(i: int) -> void:
	_points.remove_at(i)
	_widths.remove_at(i)
	_life_points.remove_at(i)
