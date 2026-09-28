# ==========================================================
# 【檔案說明】npc_health_bar.gd
# 這是「NPC（敵人）血條」的腳本，顯示在敵人頭上。
# 特色：
#   1. 平時隱藏，敵人受傷時才顯示，5 秒沒再受傷就隱藏。
#   2. 有「延遲條（DelayBar）」：受傷時，主血條立刻縮短，
#      延遲條會先停頓 0.8 秒，再慢慢縮到跟主血條一樣長，
#      讓玩家清楚看到「這一下打掉了多少血」（格鬥/魂系遊戲常見效果）。
# 血條長度是透過改變 Sprite 的 scale.x（水平縮放）達成的。
# ==========================================================

# 註冊為全域類別 NPCHealthBar。
class_name NPCHealthBar
# 繼承 Node2D（2D 節點）。
extends Node2D


# current_health：敵人目前血量（由外部，例如敵人的血量元件，更新）。
var current_health: float
# default_health：敵人的最大血量（用來計算血量百分比）。
var default_health: float
# should_be_visible：血條「是否應該顯示」。
# 此腳本只設定這個旗標，實際的顯示/淡入淡出由外部（例如 WellbeingWidget 的管理者）處理。
var should_be_visible: bool = false

# _default_health_sprite_scale_x：血條滿血時的水平縮放值（作為 100% 的基準）。
var _default_health_sprite_scale_x: float

# ---------- 「顯示血條」計時器 ----------
# _show_health_bar_timer：受傷後開始倒數，時間到就隱藏血條。
var _show_health_bar_timer: Timer
# _show_health_bar_interval：血條顯示的持續時間（秒）。
var _show_health_bar_interval: float = 5.0

# ---------- 「延遲條」計時器 ----------
# _health_delay_timer：受傷後等待一段時間才讓延遲條開始縮短。
var _health_delay_timer: Timer
# _health_delay_pause：延遲條開始縮短前的停頓時間（秒）。
var _health_delay_pause: float = 0.8
# _play_delay：延遲條是否正在縮短中。
var _play_delay: bool = false

# ---------- 子節點參考 ----------
# _health_sprite：主血條圖片（代表目前真實血量）。
@onready var _health_sprite: Sprite2D = $Health
# _delay_sprite：延遲條圖片（位於主血條後方，顯示剛失去的血量）。
@onready var _delay_sprite: Sprite2D = $DelayBar


# 初始化。
func _ready():
	# 記錄滿血時的水平縮放值（編輯器中設定的原始值）。
	_default_health_sprite_scale_x = _health_sprite.scale.x
	
	# ---- 建立「顯示血條」計時器 ----
	# 用程式碼動態建立 Timer 節點。
	_show_health_bar_timer = Timer.new()
	# 等待時間設為 5 秒。
	_show_health_bar_timer.wait_time = _show_health_bar_interval
	# 不要自動開始（等受傷時才手動 start）。
	_show_health_bar_timer.autostart = false
	# 一次性：時間到觸發一次就停止，不會循環。
	_show_health_bar_timer.one_shot = true
	# 時間到時：把血條設為不需顯示。
	_show_health_bar_timer.timeout.connect(
		func():
			should_be_visible = false
	)
	# Timer 必須加入場景樹才會運作，所以加成此節點的子節點。
	add_child(_show_health_bar_timer)
	
	# ---- 建立「延遲條」計時器 ----
	_health_delay_timer = Timer.new()
	# 等待時間設為 0.8 秒。
	_health_delay_timer.wait_time = _health_delay_pause
	_health_delay_timer.autostart = false
	_health_delay_timer.one_shot = true
	# 時間到時：開始讓延遲條縮短。
	_health_delay_timer.timeout.connect(
		func():
			_play_delay = true
	)
	add_child(_health_delay_timer)


# _process(delta)：每個「畫面影格」呼叫（與 _physics_process 不同，頻率跟著 FPS）。
func _process(_delta: float) -> void:
	# 依目前血量更新主血條長度。
	_scale_health_bar_sprite()
	
	# 若延遲條正在縮短：
	# 每影格以固定量 0.005 往主血條的長度靠近（等速縮短）。
	if _play_delay:
		_delay_sprite.scale.x = move_toward(
			float(_delay_sprite.scale.x),
			_health_sprite.scale.x,
			0.005
		)
	
	# 當延遲條已經追上主血條（兩者長度近似相等）：
	# is_equal_approx：判斷兩個浮點數是否近似相等（避免浮點誤差）。
	if is_equal_approx(_delay_sprite.scale.x, _health_sprite.scale.x):
		# 停止延遲條動畫。
		_play_delay = false
		# 如果敵人已經沒血（死亡），就隱藏血條。
		if is_zero_approx(current_health):
			should_be_visible = false


# setup()：由外部在設定好 current_health / default_health 後呼叫，
# 讓血條與延遲條一開始就對齊正確的長度（避免出現錯誤的延遲動畫）。
func setup() -> void:
	# 先依血量算出主血條長度。
	_scale_health_bar_sprite()
	# 讓延遲條直接與主血條一樣長。
	_delay_sprite.scale.x = _health_sprite.scale.x


# show_health_bar()：敵人受傷時由外部呼叫。
func show_health_bar() -> void:
	# 標記血條需要顯示。
	should_be_visible = true
	
	# （重新）開始 5 秒倒數；若已在倒數中，start() 會重新從 5 秒開始計時，
	# 所以只要持續攻擊，血條就會一直顯示。
	_show_health_bar_timer.start()
	# 除錯用輸出：印出延遲條與主血條目前的長度（開發時留下的）。
	prints(_delay_sprite.scale.x, _health_sprite.scale.x)
	# 只有在延遲計時器「沒有在跑」的時候才啟動它，
	# 避免連續攻擊時一直重設 0.8 秒，導致延遲條永遠不動。
	if _health_delay_timer.is_stopped():
		_health_delay_timer.start()


# _scale_health_bar_sprite()：依血量百分比計算並設定主血條的長度。
func _scale_health_bar_sprite() -> void:
	# 血量百分比 = current_health / default_health（0.0 ~ 1.0）。
	# lerp(0, 滿血長度, 百分比)：百分比 0 → 長度 0；百分比 1 → 滿血長度。
	_health_sprite.scale.x = lerp(
		0.0, 
		_default_health_sprite_scale_x,
		current_health / default_health
	)
