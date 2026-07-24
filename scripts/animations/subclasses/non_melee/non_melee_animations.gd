## 非近戰動畫控制器：管理所有非近戰類型動作(NonMeleeAction)的播放流程、狀態與與 anim_tree 的混合(blend)側量

class_name NonMeleeAnimations
extends BaseAnimations


# 以下信號用於與主角控制器、特效系統等其他節點互相通知（可旋轉、次要移動、動作特效、能否再次執行、能否播放動畫、動畫完成等)
signal can_rotate(flag: bool)
signal secondary_movement(action: NonMeleeAction)
signal action_effect(index: int)
signal end_effect(index: int)
signal can_perform_again(flag: bool)
signal can_play_animation
signal animation_finished

# 存放所有子節點中的 NonMeleeAction 動作，陣列索引對應 _level
var actions: Array[NonMeleeAction]

# this means if an active animation is currently occurring（中文：表示目前是否有一個正在進行中的動畫）
var active: bool = false

# which action to do, meant to control animations
# for successive actions（中文：目前要執行哪個動作，用於控制連續動作的切換）
var _level: int = 1

# this means that there is an intent to perform an action（中文：表示目前有執行動作的意圖）
var _intent_to_perform: bool = false

# this means that the action animation can play.
# meant to control when the next perform anim plays
# when doing successive actions
# 中文：表示目前可以播放動作動畫，控制連續動作中下一段執行動畫何時播放
var _can_play_animation: bool = true

# will be checked to decide whether to stop
# the active animation（中文：判斷是否需要停止目前進行中的動畫）
var _intend_to_stop_performing: bool = true

var _blend: float = 0.0


# 節點準備完成時初始化：設定 blend_amount 為 0，並將所有子節點(NonMeleeAction)加入 actions 陣列
func _ready() -> void:
	anim_tree.set(&"parameters/Non Melee/blend_amount", 0.0)
	for child in get_children():
		actions.append(child)


# 每幀物理更新：若有執行意圖且可播放則播放對應動作，並持續更新 blend_amount 使動畫混合順滑
func _physics_process(_delta: float) -> void:
	if debug:
		pass
	
	if _can_play_animation and _intent_to_perform:
		_can_play_animation = false
		_intent_to_perform = false
		actions[_level].play_animation()
	
	# 若目前未在執行且混合值已接近零，代表動畫已完全混回，不需再更新，直接結束本次更新
if BaseAnimations.should_return_blend(active, _blend): return
	
	var blend = anim_tree.get(&"parameters/Non Melee/blend_amount")
	if blend == null: return
	
	# 依 active 狀態將 blend 值向 1(播放中)或 0(未播放)逐步插值，並寫回 anim_tree 以驅動混合動畫
	_blend = lerp(
		float(blend), 
		1.0 if active else 0.0,
		0.15
	)
	
	anim_tree.set(
		&"parameters/Non Melee/blend_amount",
		_blend
	)


# 外部呼叫以啟動指定等級(level)的動作：設為執行中、標記有執行意圖，並依需決定是否可立即播放動畫
func start_action(level: int, override_can_play: bool = false) -> void:
	print(level)
	active = true
	_intent_to_perform = true
	_intend_to_stop_performing = false
	if override_can_play:
		_can_play_animation = true
	_level = level


# 停止目前動作：恢復可播放狀態、重新允許旋轉，並將執行中狀態設為 false
func stop_action() -> void:
	_can_play_animation = true
	can_rotate.emit(true)
	active = false


# 接收來自子動作的通知：進行中需禁止旋轉時，發出 can_rotate(false) 信號
func receive_prevent_rotation() -> void:
	can_rotate.emit(false)


# 接收次要移動通知：若該動作支援次要移動，將該動作資訊向外發出 secondary_movement 信號
func receive_secondary_movement() -> void:
	if not actions[_level].secondary_movement:
		return
	secondary_movement.emit(actions[_level])


# 接收動作特效通知：將目前等級(_level)的特效訊號向外發出
func receive_action_effect() -> void:
	action_effect.emit(_level)


# 接收特效結束通知：將目前等級(_level)的特效結束訊號向外發出
func receive_end_effect() -> void:
	end_effect.emit(_level)


# 接收可再次執行通知：向外發出 can_perform_again(true)，並標記目前有停止執行的意圖
func receive_can_perform_again() -> void:
	can_perform_again.emit(true)
	_intend_to_stop_performing = true


# 接收不可再次執行通知：向外發出 can_perform_again(false)
func receive_cannot_perform_again() -> void:
	can_perform_again.emit(false)


# 接收可播放下一段動作動畫的通知：向外發出 can_play_animation 信號，並允許播放下一段動畫
func receive_can_play_animation() -> void:
	can_play_animation.emit()
	_can_play_animation = true


# 接收動作完全結束通知：重置等級，若有停止意圖且仍在執行中，則發出動畫完成信號並停止動作
func receive_finished() -> void:
	_level = 0
	if _intend_to_stop_performing and active:
		animation_finished.emit()
		stop_action()
