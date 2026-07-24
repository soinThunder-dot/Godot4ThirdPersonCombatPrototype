## 跳躍動畫控制器：管理角色跳躍、垂直移動混合及落下/落地前動畫的切換與混合
class_name JumpAnimations
extends BaseAnimations


signal jumped # 角色執行跳躍時發出
signal vertical_movement_ended # 垂直移動（跳躍/落下）結束時發出

var about_to_land: bool = false # 是否即將落地

var _fade_vertical_movement: bool = false # 是否正在淡入垂直移動混合

var _can_set_falling: bool = true # 是否可設定為落下狀態
var _fade_to_fall: bool = false # 是否正在淡入落下混合

var _do_jump_1: bool = true # 是否執行第一段跳躍動畫
var _can_switch_jump: bool = false # 是否可切換到第二段跳躍

var _can_emit_vertical_movement_ended: bool = false # 是否可發出垂直移動結束信號

var _just_fall_timer: Timer # 刷新落下狀態前的短暫延遲計時器
var _just_fall_timer_pause: float = 0.1 # 延遲計時器的持續時間

var _vertical_blend: float = 0.0 # 垂直移動混合權重
var _fall_blend: float = 0.0 # 落下混合權重


# 節點就緒時初始化落下延遲計時器，並設定初始跳躍動畫為第一段
func _ready():
	_just_fall_timer = Timer.new()
	_just_fall_timer.autostart = false
	_just_fall_timer.one_shot = true
	_just_fall_timer.wait_time = _just_fall_timer_pause
	_just_fall_timer.timeout.connect(
		func():
			_fade_vertical_movement = true
	)
	add_child(_just_fall_timer)
	
	anim_tree.set(&"parameters/Jump Handler/transition_request", &"jump_1")


# 每幀物理更新：混合垂直移動與落下動畫，並在適當時機發出垂直移動結束信號
func _physics_process(_delta):
	
	if not BaseAnimations.should_return_blend(
		_fade_vertical_movement, _vertical_blend
	):
		# This blends between the normal movement stuff（中文：此處用於混合一般移動與所有垂直移動（跳躍、落下）資料）
		# and all this vertical movement stuff (jump and fall)
		var vertical_blend = anim_tree.get(
			&"parameters/Vertical Movement/blend_amount"
		)
		if vertical_blend == null: return
		
		_vertical_blend = lerp(
			float(vertical_blend),
			1.0 if _fade_vertical_movement else 0.0,
			0.05
		)
		
		anim_tree.set(
			&"parameters/Vertical Movement/blend_amount",
			_vertical_blend
		)
	
	# assume we're transitioning to the vertical movement state,
	# allow the ability to emit the signal when we come back down（中文：假設正在轉入垂直移動狀態，允許於轉回地面時發出信號）
	if _vertical_blend > 0.8:
		_can_emit_vertical_movement_ended = true
	
	
	if not BaseAnimations.should_return_blend(_fade_to_fall, _fall_blend):
		# This blends between the jump animation and the falling idle animation（中文：此處用於混合跳躍動畫與落下待機動畫）
		var jump_and_fall_blend = anim_tree.get(
			&"parameters/Jump and Fall Blend/blend_amount"
		)
		if jump_and_fall_blend == null: return
		
		_fall_blend = lerp(
			float(jump_and_fall_blend),
			1.0 if _fade_to_fall else 0.0,
			0.05 if _fade_to_fall else 0.1
		)
		
		anim_tree.set(
			&"parameters/Jump and Fall Blend/blend_amount",
			_fall_blend
		)
	
	# here we assume we've successfully transitioned from the
	# vertical movement state to the normal state（中文：此處假設已成功從垂直移動狀態轉回普通狀態）
	if _can_emit_vertical_movement_ended and _vertical_blend < 0.8:
		_can_emit_vertical_movement_ended = false
		vertical_movement_ended.emit()


## Method to start the jump animation（中文：用於開始播放跳躍動畫的方法）
func start_jump() -> void: # 切換並播放跳躍1或跳躍2動畫，並切換下次要使用的跳躍段數
	
	if _do_jump_1:
		anim_tree.set(&"parameters/Jump 1/Jump Trim/seek_request", 0.65)
		anim_tree.set(&"parameters/Jump 1/Jump Speed/scale", 1.0)
		anim_tree.set(&"parameters/Jump Handler/transition_request", &"jump_1")
	else:
		anim_tree.set(&"parameters/Jump 2/Jump Trim/seek_request", 0.65)
		anim_tree.set(&"parameters/Jump 2/Jump Speed/scale", 1.0)
		anim_tree.set(&"parameters/Jump Handler/transition_request", &"jump_2")
	
	_do_jump_1 = not _do_jump_1
	
	_can_switch_jump = true
	_fade_vertical_movement = true


## When to actually apply the jump force（中文：實際施加跳躍力道的時機）
func jump_force() -> void:
	jumped.emit()
	_can_set_falling = true


## The point in the jump animation where we can
## switch to the falling idle animation
func falling_idle() -> void:
	if _can_set_falling and not about_to_land:
		_can_set_falling = false
		_fade_to_fall = true


## Method to just play the fall animation
## without the jump. Useful if the player
## literally just walks off a platform
func just_fall() -> void:
	if _just_fall_timer.is_stopped():
		_just_fall_timer.start()
	
	_fade_to_fall = true
	
	var blend = anim_tree.get(&"parameters/Vertical Movement/blend_amount")
	if blend != null and blend < 0.05:
		anim_tree.set(&"parameters/Jump and Fall Blend/blend_amount", 1.0)
	
	anim_tree.set(&"parameters/Jump 1/Jump Speed/scale", 0.0)
	anim_tree.set(&"parameters/Jump 2/Jump Speed/scale", 0.0)


## A method to signfiy when to blend from the
## falling idle animation to the rest of the
## jump animation to 'land'
func jump_landing() -> void:
	_fade_to_fall = false


## A method call to transition from jumping
func fade_out() -> void:
	_fade_vertical_movement = false	
	_fade_to_fall = false
