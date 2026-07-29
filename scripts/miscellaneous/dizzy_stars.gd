# ==============================================================
# 暈晖星星特效 (DizzyStars)
#
# 當角色被擊暈時，在頭頂顯示旋轉的星星特效。
# 可透過 enabled 切換顯示與遠位圖狀態。
# ==============================================================
class_name DizzyStars
extends Node3D

# 是否啟用暈晖星星特效（切換時會同步設定可見性與拖尾特效）
@export var enabled: bool = false:
	set(value):
		if value == enabled: return
		visible = value
		_set_stars_trail_enabled(value)
		enabled = value

# 星星旋轉速度（每秒度數）
@export var speed: float = 360

# 星星節點的參考
@onready var stars: Node3D = $Stars

# 初始化：依據 enabled 狀態設定可見性與拖尾特效
func _ready() -> void:
	visible = enabled
	_set_stars_trail_enabled(enabled)

# 每幀更新：讓星星繞 Y 軸旋轉，並讓每顆星星上下浮動形成波浪效果
func _process(delta: float) -> void:
	var r: float = stars.rotation_degrees.y
	stars.rotation_degrees.y = wrapf(
		r + speed * delta,
		0.0,
		360
	)
	
	var count: int = stars.get_child_count()
	for i in count:
		stars.get_child(i).position.y = 0.1 * sin(
			2 * deg_to_rad(r + (i * (360 / float(count))))
		)
