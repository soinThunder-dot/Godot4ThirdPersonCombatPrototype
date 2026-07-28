# 玩家血條：顯示玩家目前血量，並包含受傷後延遲損血動畫
class_name PlayerHealthBar
extends Control

var _health: float
var _default_health: float

# 依玩家最大血量計算出的寬度縮放比例
var _default_health_scale_x: float

# 控制受傷後延遲多久才開始播放損血動畫的計時器
var _health_delay_timer: Timer
var _health_delay_pause: float = 0.8
var _play_delay: bool = false

# 血條背景預設長度，侜玩家最大血量擴展
var _default_background_length: float = 100.0

@onready var _background: Polygon2D = $Background
@onready var _health_bar: Polygon2D = $Health
@onready var _delay_bar: Polygon2D = $DelayBar

@onready var _player: Player = Globals.player


func _ready():
	_default_health = _player.health_component.max_health
	_default_health_scale_x = _default_health / 100.0
	
	# 依據玩家最大血量擴展血條寬度
	_background.polygon[2].x = _default_background_length * _default_health_scale_x
	_background.polygon[3].x = _default_background_length * _default_health_scale_x
	_health_bar.polygon[2].x = (_default_background_length * _default_health_scale_x) - 8.0
	_health_bar.polygon[3].x = (_default_background_length * _default_health_scale_x) - 8.0
	_delay_bar.polygon[2].x = (_default_background_length * _default_health_scale_x) - 8.0
	_delay_bar.polygon[3].x = (_default_background_length * _default_health_scale_x) - 8.0
	
	# 受傷時若延遲計時器尚未啟動，則開始計時
	_player.health_component.took_damage.connect(
		func():
			if _health_delay_timer.is_stopped():
				_health_delay_timer.start()
	)
	# 回血時立即同步延遲條縮放，避免逆向播放動畫
	_player.health_component.health_increased.connect(
		func():
			_delay_bar.scale.x = _get_health_bar_scale()
	)
	
	_health_delay_timer = Timer.new()
	_health_delay_timer.wait_time = _health_delay_pause
	_health_delay_timer.autostart = false
	_health_delay_timer.one_shot = true
	_health_delay_timer.timeout.connect(
		func():
			_play_delay = true
	)
	add_child(_health_delay_timer)


func _process(_delta):
	# 每幀更新實際血條縮放
	_health_bar.scale.x = _get_health_bar_scale()
	
	# 若正在播放延遲損血動畫，則讓延遲條逐漸追上實際血條
	if _play_delay:
		_delay_bar.scale.x = move_toward(
			float(_delay_bar.scale.x),
			_health_bar.scale.x,
			0.005
		)
		
		if is_equal_approx(_delay_bar.scale.x, _health_bar.scale.x):
			_play_delay = false


# 依玩家目前血量與最大血量比例，線性插值算出血條縮放值
func _get_health_bar_scale() -> float:
	_health = _player.health_component.health
	return lerp(
		0.0,
		1.0,
		_health / _default_health
	)
