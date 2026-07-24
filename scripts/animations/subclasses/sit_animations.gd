class_name SitAnimations
extends BaseAnimations

## 坐下（Sit）動畫子類別，負責處理角色坐下、起立及相關狀態與信號發射


# sat_down：坐下完成時發射的信號
signal sat_down
# finished：起立完成時發射的信號
signal finished


# sitting_idle：是否正处於坐下静止狀態
var sitting_idle: bool
# _active：是否正在坐下狀態（包含轉換中）

var _active: bool = false
var _transitioning: bool = false # 是否正在坐下/起立的轉換過程中
var _ignore_method_calls: bool = false # 是否忽略 sit_down/stand_up 方法呼叫（防止重複觸發）

var _can_emit_sat_down: bool = false # 是否可發射 sat_down 信號
var _can_emit_finished: bool = false # 是否可發射 finished 信號

var _sitting_blend: float = 0.0 # 目前坐下動畫混合比例
var _sit_or_stand_blend: float = 0.0 # 目前坐/站切換動畫混合比例


## _physics_process：每幀更新坐下與坐/站切換的混合比例，並在適當時機發射坐下/起立完成信號
func _physics_process(_delta):
	if not BaseAnimations.should_return_blend(_active, _sitting_blend):
		var sitting_blend = anim_tree.get(&"parameters/Sit/blend_amount")
		if sitting_blend == null: return
		
		_sitting_blend = lerp(
			float(sitting_blend),
			1.0 if _active else 0.0,
			0.02 if _active else 0.08
		)
		
		anim_tree.set(
			&"parameters/Sit/blend_amount",
			_sitting_blend
		)
	
	if not BaseAnimations.should_return_blend(_transitioning, _sit_or_stand_blend):
		var sit_or_stand_blend = anim_tree.get(&"parameters/Sit or Stand/blend_amount")
		if sit_or_stand_blend == null: return
		
		_sit_or_stand_blend = lerp(
			float(sit_or_stand_blend),
			1.0 if _transitioning else 0.0,
			0.02
		)
		
		anim_tree.set(
			&"parameters/Sit or Stand/blend_amount",
			_sit_or_stand_blend
		)
	
	if float(_sit_or_stand_blend) < 0.1 and _active:
		sitting_idle = true
		if _can_emit_sat_down:
			_can_emit_sat_down = false
			sat_down.emit()
	else:
		sitting_idle = false
	
	if float(_sitting_blend) < 0.1 and _can_emit_finished:
		_can_emit_finished = false
		finished.emit()


## sit_down：觸發坐下動作，設定狀態並控制動畫播放方向與進度，定時後解除方法呼叫忽略
func sit_down() -> void:
	_ignore_method_calls = true
	_can_emit_sat_down = true
	
	anim_tree.set(&"parameters/Sit or Stand/blend_amount", 1.0)
	anim_tree.set(&"parameters/Sit to Stand Speed/scale", -1.5)
	anim_tree.set(&"parameters/Sit to Stand Trim/seek_request", 5.0)
	
	_active = true
	_transitioning = true
	
	var timer: SceneTreeTimer = get_tree().create_timer(1.5)
	timer.timeout.connect(
		func():
			_ignore_method_calls = false
	)


## blend_to_idle：將狀態混合至静止坐下（非轉換中），若方法呼叫被忽略則直接返回
func blend_to_idle() -> void:
	if _ignore_method_calls: return
	_active = true
	_transitioning = false


## stand_up：觸發起立動作，設定狀態並控制動畫播放方向與進度，定時後解除方法呼叫忽略
func stand_up() -> void:
	_ignore_method_calls = true
	_can_emit_finished = true
	
	anim_tree.set(&"parameters/Sit or Stand/blend_amount", 0.0)
	anim_tree.set(&"parameters/Sit to Stand Speed/scale", 2)
	anim_tree.set(&"parameters/Sit to Stand Trim/seek_request", 0.0)
	
	_active = true
	_transitioning = true
	
	var timer: SceneTreeTimer = get_tree().create_timer(1.5)
	timer.timeout.connect(
		func():
			_ignore_method_calls = false
	)


## finish_standing_up：起立動作完成後重置活躍狀態，若方法呼叫被忽略則直接返回
func finish_standing_up() -> void:
	if _ignore_method_calls: return
	_active = false
