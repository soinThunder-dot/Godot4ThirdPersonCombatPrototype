# ==========================================================
# 【檔案說明】player_instability_bar.gd
# 這是「玩家失衡條」的腳本（類似《隻狼》玩家的架勢條）。
# 玩家格擋或受到攻擊時失衡值上升，滿了就會破防/硬直。
# 功能：
#   1. 失衡值 > 0 時顯示；歸零後等待 0.5 秒才隱藏。
#   2. 依百分比縮放長度，並從漸層取色。
#   3. 失衡值滿時顯示閃光（Glare）。
#   4. 提供播放「失衡滿」動畫與「重置」動畫的函式。
# ==========================================================

# 註冊為全域類別 PlayerInstabilityBar。
class_name PlayerInstabilityBar
# 繼承 Control（UI 節點）。
extends Control


# color_gradient：顏色漸層（編輯器中設定），依失衡百分比取樣顏色。
@export var color_gradient: Gradient

# _instability：玩家目前失衡值。
var _instability: float
# _max_instability：玩家最大失衡值。
var _max_instability: float

# _default_instability_scale_x：失衡條滿值時的水平縮放（100% 基準）。
var _default_instability_scale_x: float

# _disappear_pause_timer：失衡值歸零後，延遲隱藏失衡條的計時器。
var _disappear_pause_timer: Timer
# _disappear_pause_length：歸零後等待多久才隱藏（秒）。
var _disappear_pause_length: float = 0.5

# ---------- 子節點參考 ----------
# _anim_player：動畫播放器，內含「max_instability」和「RESET」兩個動畫。
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
# _instability_bar：失衡條本體。
@onready var _instability_bar: Node2D = $Instability
# _glare：失衡值滿時的閃光特效。
@onready var _glare: Node2D = $Glare

# _player：從 Globals 取得玩家節點。
@onready var _player: Player = Globals.player


# 初始化。
func _ready():
	# 一開始隱藏失衡條（失衡值為 0）。
	visible = false
	
	# 記錄失衡條原始（滿值）水平縮放。
	_default_instability_scale_x = _instability_bar.scale.x
	# 讀取玩家的最大失衡值。
	_max_instability = _player.instability_component.max_instability
	
	# ---- 建立「延遲隱藏」計時器 ----
	_disappear_pause_timer = Timer.new()
	# 等待 0.5 秒。
	_disappear_pause_timer.wait_time = _disappear_pause_length
	# 不自動開始。
	_disappear_pause_timer.autostart = false
	# 一次性計時器。
	_disappear_pause_timer.one_shot = true
	# 時間到 → 呼叫 hide_bar() 隱藏失衡條。
	_disappear_pause_timer.timeout.connect(
		func(): hide_bar()
	)
	# 加入場景樹，計時器才會運作。
	add_child(_disappear_pause_timer)
	
	# 平時停用動畫播放器（active = false），避免它持續覆蓋屬性值。
	_anim_player.active = false
	# 動畫播放完畢時，再次停用動畫播放器。
	# 匿名函式的參數 _anim_name 是播完的動畫名稱（此處不使用）。
	_anim_player.animation_finished.connect(
		func(_anim_name: String): _anim_player.active = false
	)


# 每個畫面影格執行。
func _process(_delta):
	# 讀取玩家目前失衡值。
	_instability = _player.instability_component.instability
	
	# 失衡值大於 0 → 顯示失衡條。
	if _instability > 0:
		visible = true
	# 失衡值為 0、延遲計時器沒在跑、且失衡條目前還顯示中
	# → 啟動 0.5 秒延遲計時器，時間到後才隱藏。
	elif _disappear_pause_timer.is_stopped() and visible:
		_disappear_pause_timer.start()
	
	# 計算失衡百分比（0.0 ~ 1.0）。
	var instability_percentage = _instability / _max_instability
	
	# 依百分比設定失衡條長度：0% → 長度 0，100% → 原始長度。
	_instability_bar.scale.x = lerp(
		0.0, 
		_default_instability_scale_x,
		instability_percentage
	)
	
	# 依百分比從漸層取樣顏色並套用。
	_instability_bar.self_modulate = color_gradient.sample(
		instability_percentage
	)
	
	# 失衡值滿（近似 100%）時顯示閃光，否則隱藏。
	_glare.visible = is_equal_approx(instability_percentage, 1.0)


# play_max_instability()：失衡值滿時由外部呼叫，播放「失衡滿」動畫。
func play_max_instability() -> void:
	# 先啟用動畫播放器。
	_anim_player.active = true
	# 播放名為 max_instability 的動畫（&"..." 是 StringName，比一般字串比較更有效率）。
	_anim_player.play(&"max_instability")


# reset()：重置失衡條外觀，播放 RESET 動畫（把屬性恢復成預設值）。
func reset() -> void:
	_anim_player.active = true
	_anim_player.play(&"RESET")


# hide_bar()：隱藏失衡條（由延遲計時器時間到時呼叫）。
func hide_bar() -> void:
	visible = false
