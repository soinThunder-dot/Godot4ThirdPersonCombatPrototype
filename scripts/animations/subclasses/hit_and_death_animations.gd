## 受擊及死亡動畫控制器：管理角色遭受攻擊時的受擊動畫，以及向前/向後兩種死亡動畫的播放與混合
class_name HitAndDeathAnimations
extends BaseAnimations


signal hit_finished # 受擊動畫播放完成時發出

@export_category("Hit Configuration") # 受擊相關參數分類
@export var hit_duration: float = 0.3 # 受擊動畫持續時間
@export var hit_trim: float = 0.0 # 受擊動畫裁剪起始位置
@export var hit_speed: float = 1.0 # 受擊動畫播放速度

@export_category("Death Forwards Configuration") # 向前死亡相關參數分類
@export var death_forwards_trim: float = 0.0 # 向前死亡動畫裁剪起始位置
@export var death_forwards_speed: float = 1.0 # 向前死亡動畫播放速度

@export_category("Death Backwards Configuration") # 向後死亡相關參數分類
@export var death_backwards_trim: float = 0.0 # 向後死亡動畫裁剪起始位置
@export var death_backwards_speed: float = 1.0 # 向後死亡動畫播放速度

var _death: bool = false # 是否已進入死亡狀態
var _blend_death: bool = false # 是否正在混合播放死亡動畫

var _blend: float = 0.0 # 死亡混合權重

var _hit_timer: Timer # 受擊計時器，用於控制受擊混合結束時點

var _can_emit_hit_finished: bool = false # 是否可發出受擊完成信號


func _ready(): # 節點就緒時初始化受擊計時器
	_hit_timer = Timer.new()
	_hit_timer.wait_time = hit_duration
	_hit_timer.one_shot = true
	_hit_timer.autostart = false
	_hit_timer.timeout.connect(
		func():
			_blend_death = false
	)
	add_child(_hit_timer)


# 每幀物理更新：根據死亡狀態逐步混合死亡動畫，並在受擊混合接近零時發出完成信號
func _physics_process(_delta) -> void:
	if _death:
		_blend_death = true
	
	if BaseAnimations.should_return_blend(_blend_death, _blend): return
	
	var blend = anim_tree.get(&"parameters/Death/blend_amount")
	if blend == null: return
	
	_blend = lerp(
		float(blend),
		1.0 if _blend_death else 0.0,
		0.2 if _blend_death else 0.05
	)
	
	anim_tree.set(
		&"parameters/Death/blend_amount",
		_blend
	)
	
	if _can_emit_hit_finished and float(blend) < 0.1:
		_can_emit_hit_finished = false
		hit_finished.emit()


# 外部呼叫以播放受擊動畫（使用 Death 2 軌道作為受擊動畫），若已死亡則不播放
func hit() -> void:
	if _death:
		return
	
	_can_emit_hit_finished = true
	
	anim_tree.set(&"parameters/Death 2 Trim/seek_request", hit_trim)
	anim_tree.set(&"parameters/Death 2 Speed/scale", hit_speed)
	anim_tree.set(&"parameters/Death Which One/transition_request", &"death_2")
	_blend_death = true
	_hit_timer.start()


# 外部呼叫以播放向後（後退）死亡動畫並標記為死亡狀態
func death_1() -> void:
	anim_tree.set(&"parameters/Death 1 Trim/seek_request", death_backwards_trim)
	anim_tree.set(&"parameters/Death 1 Speed/scale", death_backwards_speed)
	anim_tree.set(&"parameters/Death Which One/transition_request", &"death_1")
	_death = true


# 外部呼叫以播放向前（前傾）死亡動畫並標記為死亡狀態
func death_2() -> void:
	anim_tree.set(&"parameters/Death 2 Trim/seek_request", death_forwards_trim)
	anim_tree.set(&"parameters/Death 2 Speed/scale", death_forwards_speed)
	anim_tree.set(&"parameters/Death Which One/transition_request", &"death_2")
	_death = true


# 中斷死亡混合：立即停止混合並重置混合權重為零
func interrupt_blend_death() -> void:
	_blend_death = false
	anim_tree.set(&"parameters/Death/blend_amount", 0.0)


# 重置死亡狀態：將死亡及混合標記均還原為 false，供角色復活時使用
func reset_death() -> void:
	_death = false
	_blend_death = false
