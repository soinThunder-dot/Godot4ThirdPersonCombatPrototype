# 巡邏移動速度節點：依據距離巡邏目標點的遠近，動態調整移動與動畫播放速度
class_name PatrolMoveSpeed
extends ActionLeaf

# 移動最低/最高速度
@export var move_min_speed: float = 0
@export var move_max_speed: float = 3
# 動畫最低/最高播放速度
@export var anim_min_speed: float = 0.2
@export var anim_max_speed: float = 1.0
# 距離映射範圍（最小/最大）
@export var min_dist: float = 0.3
@export var max_dist: float = 2


func tick(_actor: Node, blackboard: Blackboard) -> int:
	# 若黑板中沒有巡邏距離資訊，直接返回成功
	if blackboard.get_value("patrol_dist") == null: return SUCCESS
	
	var patrol_dist: float = blackboard.get_value("patrol_dist")
	
	# 依距離將動畫速度映射到指定範圍並限制在上下限內
	var patrol_anim_speed: float = clamp(
		remap(
			patrol_dist,
			min_dist,
			max_dist,
			anim_min_speed,
			anim_max_speed
		),
		anim_min_speed,
		anim_max_speed
	)
	
	# 依距離將移動速度映射到指定範圍並限制在上下限內
	var patrol_move_speed: float = clamp(
		remap(
			patrol_dist,
			min_dist,
			max_dist,
			move_min_speed,
			move_max_speed
		),
		move_min_speed,
		move_max_speed
	)
	
	# 將計算結果寫入黑板供動畫與移動系統使用
	blackboard.set_value("anim_move_speed", patrol_anim_speed)
	blackboard.set_value("move_speed", patrol_move_speed)
	
	return SUCCESS
