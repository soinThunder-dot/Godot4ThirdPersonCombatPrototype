# 玩家不穩定値顯示條：顯示玩家目前不穩定値進度，達到滿值時播放特殊動畫及發光效果
class_name PlayerInstabilityBar
extends Control

# 顏色漸變，依不穩定百分比取樣以改變顯示顏色
@export var color_gradient: Gradient

var _instability: float
var _max_instability: float

# 記錄不穩定條圓形初始的 x 軸縮放值，作為滿值基準
var _default_instability_scale_x: float

# 控制不穩定値歸零後延遲多久才隱藏條的計時器
var _disappear_pause_timer: Timer
var _disappear_pause_length: float = 0.5

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _instability_bar: Node2D = $Instability
@onready var _glare: Node2D = $Glare

@onready var _player: Player = Globals.player


func _ready():
	visible = false
	
	_default_instability_scale_x = _instability_bar.scale.x
	_max_instability = _player.instability_component.max_instability
	
	# 初始化隱藏延遲計時器，時間一到就隱藏條圖
	_disappear_pause_timer = Timer.new()
	_disappear_pause_timer.wait_time = _disappear_pause_length
	_disappear_pause_timer.autostart = false
	_disappear_pause_timer.one_shot = true
	_disappear_pause_timer.timeout.connect(
		func(): hide_bar()
	)
	add_child(_disappear_pause_timer)
	
	# 初始不啟用動畫播放器，並在播放完成後自動關閉
	_anim_player.active = false
	_anim_player.animation_finished.connect(
		func(_anim_name: String): _anim_player.active = false
	)


func _process(_delta):
	_instability = _player.instability_component.instability
	
	# 有不穩定値時顯示，歸零且仍顯示中則開始延遲隱藏計時
	if _instability > 0:
		visible = true
	elif _disappear_pause_timer.is_stopped() and visible:
		_disappear_pause_timer.start()
	
	var instability_percentage = _instability / _max_instability
	
	# 依百分比線性插值縮放條圖形
	_instability_bar.scale.x = lerp(
		0.0,
		_default_instability_scale_x,
		instability_percentage
	)
	
	# 依百分比從顏色漸變取得對應顏色
	_instability_bar.self_modulate = color_gradient.sample(
		instability_percentage
	)
	
	# 達到滿值時顯示發光特效
	_glare.visible = is_equal_approx(instability_percentage, 1.0)


# 播放達到最大不穩定値時的特殊動畫
func play_max_instability() -> void:
	_anim_player.active = true
	_anim_player.play(&"max_instability")


# 重置動畫回到初始狀態
func reset() -> void:
	_anim_player.active = true
	_anim_player.play(&"RESET")


# 隱藏不穩定値顯示條
func hide_bar() -> void:
	visible = false
