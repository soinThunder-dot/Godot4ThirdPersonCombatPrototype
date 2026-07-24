## 格擋（防禦）動畫控制器：依 shield_component 的格擋狀態驅動盾牌權重的混合動畫
class_name BlockAnimations
extends BaseAnimations


# 盾牌組件參考，用於讀取目前是否正在格擋中(blocking)
@export var shield_component: ShieldComponent

# 目前格擋混合權重，用於平滑過渡格擋動畫混合
var _blend: float = 0.0


# 節點準備完成時初始化格擋動畫參數：設定播放起始位置及速度倍率（初始不播放）
func _ready() -> void:
	anim_tree.set(&"parameters/Block Trim/seek_request", 0.35)
	anim_tree.set(&"parameters/Block Speed/scale", 0.0)


# 每幀物理更新：依目前是否格擋中，逐步插值更新 blend_amount 以實現平滑的盾牌挖起/收起動畫
func _physics_process(_delta: float) -> void:
	var blocking = shield_component.blocking
	
	if BaseAnimations.should_return_blend(blocking, _blend): return
	
	var blend = anim_tree.get(&"parameters/Block/blend_amount")
	if blend == null: return
	
	_blend = lerp(
		float(blend), 
		1.0 if blocking else 0.0, 
		0.2
	)
	
	anim_tree.set(
		&"parameters/Block/blend_amount",
		_blend
	)
