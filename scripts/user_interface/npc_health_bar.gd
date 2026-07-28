# NPC 血條顯示器：控制血量進度條、隱藏計時器與延遲損血動畫
class_name NPCHealthBar
extends Node2D

var current_health: float
var default_health: float
var should_be_visible: bool = false

# 記錄血條圓形節點初始的 x 軸縮放值，作為滿血基準
var _default_health_sprite_scale_x: float

# 控制血條顯示後多久自動隱藏的計時器
var _show_health_bar_timer: Timer
var _show_health_bar_interval: float = 5.0

# 控制受傷後延遲多久才開始播放損血動畫的計時器
var _health_delay_timer: Timer
var _health_delay_pause: float = 0.8
var _play_delay: bool = false

@onready var _health_sprite: Sprite2D = $Health
@onready var _delay_sprite: Sprite2D = $DelayBar


func _ready():
	_default_health_sprite_scale_x = _health_sprite.scale.x
	
	# 初始化血條顯示計時器，時間一到就隱藏血條
	_show_health_bar_timer = Timer.new()
	_show_health_bar_timer.wait_time = _show_health_bar_interval
	_show_health_bar_timer.autostart = false
	_show_health_bar_timer.one_shot = true
	_show_health_bar_timer.timeout.connect(
		func():
			should_be_visible = false
	)
	add_child(_show_health_bar_timer)
	
	# 初始化損血延遲計時器，時間一到就開始播放延遲動畫
	_health_delay_timer = Timer.new()
	_health_delay_timer.wait_time = _health_delay_pause
	_health_delay_timer.autostart = false
	_health_delay_timer.one_shot = true
	_health_delay_timer.timeout.connect(
		func():
			_play_delay = true
	)
	add_child(_health_delay_timer)


func _process(_delta: float) -> void:
	# 每幀更新血條實際縮放
	_scale_health_bar_sprite()
	
	# 若正在播放延遲損血動畫，則讓延遲條逐漸追上實際血條
	if _play_delay:
		_delay_sprite.scale.x = move_toward(
			float(_delay_sprite.scale.x),
			_health_sprite.scale.x,
			0.005
		)
		
		if is_equal_approx(_delay_sprite.scale.x, _health_sprite.scale.x):
			_play_delay = false
	
	# 血量為零時自動隱藏血條
	if is_zero_approx(current_health):
		should_be_visible = false


# 初始設定：依當前血量設定圖形縮放，並讓延遲條對齊實際血條
func setup() -> void:
	_scale_health_bar_sprite()
	_delay_sprite.scale.x = _health_sprite.scale.x


# 顯示血條並重新計時自動隱藏，同時若尚未開始延遲則啟動延遲計時器
func show_health_bar() -> void:
	should_be_visible = true
	
	_show_health_bar_timer.start()
	
	prints(_delay_sprite.scale.x, _health_sprite.scale.x)
	if _health_delay_timer.is_stopped():
		_health_delay_timer.start()


# 依當前血量與最大血量比例，線性插值算出血條圖形的縮放值
func _scale_health_bar_sprite() -> void:
	_health_sprite.scale.x = lerp(
		0.0,
		_default_health_sprite_scale_x,
		current_health / default_health
	)
