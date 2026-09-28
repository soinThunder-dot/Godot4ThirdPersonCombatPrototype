# ==========================================================
# 【檔案說明】player_health_bar.gd
# 這是「玩家血條」的腳本（通常在畫面左上角）。
# 特色：
#   1. 血條的「總長度」會依玩家的最大血量自動延長
#      （最大血量越高，血條越長，類似魂系遊戲升級生命值後血條變長）。
#   2. 有「延遲條」：受傷時主血條立刻縮短，延遲條停頓 0.8 秒後再慢慢追上，
#      讓玩家看清楚損失了多少血。
#   3. 補血時延遲條會直接跳到新的長度（不做延遲動畫）。
# 血條使用 Polygon2D（多邊形）繪製，長度透過 scale.x 控制。
# ==========================================================

# 註冊為全域類別 PlayerHealthBar。
class_name PlayerHealthBar
# 繼承 Control（UI 節點）。
extends Control


# _health：玩家目前血量（每次計算血條時從玩家的血量元件讀取）。
var _health: float
# _default_health：玩家最大血量。
var _default_health: float

# _default_health_scale_x：最大血量 ÷ 100 的比例，用來決定血條要延長多少倍。
# 例如最大血量 150 → 1.5 倍長。
var _default_health_scale_x: float

# ---------- 延遲條相關 ----------
# _health_delay_timer：受傷後等待的計時器。
var _health_delay_timer: Timer
# _health_delay_pause：延遲條開始縮短前的停頓時間（秒）。
var _health_delay_pause: float = 0.8
# _play_delay：延遲條是否正在縮短中。
var _play_delay: bool = false

# _default_background_length：最大血量為 100 時，血條背景的基準長度（像素）。
var _default_background_length: float = 100.0

# ---------- 子節點參考（皆為 Polygon2D 多邊形）----------
# _background：血條背景（外框/底色）。
@onready var _background: Polygon2D = $Background
# _health_bar：主血條（代表目前血量）。
@onready var _health_bar: Polygon2D = $Health
# _delay_bar：延遲條（顯示剛失去的血量）。
@onready var _delay_bar: Polygon2D = $DelayBar

# _player：從 Globals 取得玩家節點。
@onready var _player: Player = Globals.player


# 初始化。
func _ready():
	
	# 讀取玩家的最大血量。
	_default_health = _player.health_component.max_health
	# 計算延長倍率：以 100 血為 1 倍基準。
	_default_health_scale_x = _default_health / 100.0
	
	# 以下調整各多邊形「右側兩個頂點」（索引 2 和 3）的 x 座標，
	# 也就是把多邊形的右邊界往右拉，讓血條依最大血量變長。
	# （推測頂點 0、1 在左側，2、3 在右側。）
	# 主血條與延遲條比背景短 8 像素，是為了在背景內留下邊框空間。
	# this extends the health bar depending the player's max health
	_background.polygon[2].x = _default_background_length * _default_health_scale_x
	_background.polygon[3].x = _default_background_length * _default_health_scale_x
	_health_bar.polygon[2].x = (_default_background_length * _default_health_scale_x) - 8.0
	_health_bar.polygon[3].x = (_default_background_length * _default_health_scale_x) - 8.0
	_delay_bar.polygon[2].x = (_default_background_length * _default_health_scale_x) - 8.0
	_delay_bar.polygon[3].x = (_default_background_length * _default_health_scale_x) - 8.0
	
	# 連接「受到傷害」訊號：
	# 受傷時，若延遲計時器沒有在跑，就啟動它（0.8 秒後延遲條開始縮短）。
	# 只在停止時才啟動，避免連續受傷時不斷重設計時器。
	_player.health_component.took_damage.connect(
		func():
			if _health_delay_timer.is_stopped():
				_health_delay_timer.start()
	)
	# 連接「血量增加」訊號（例如喝藥補血）：
	# 延遲條直接設為新的血條長度，不播放延遲動畫。
	_player.health_component.health_increased.connect(
		func():
			_delay_bar.scale.x = _get_health_bar_scale()
	)
	
	# ---- 建立延遲計時器 ----
	# 註：上面的匿名函式雖然先寫，但要等訊號觸發才會執行，
	# 那時計時器已經在這裡建立好了，所以不會出錯。
	_health_delay_timer = Timer.new()
	# 等待 0.8 秒。
	_health_delay_timer.wait_time = _health_delay_pause
	# 不自動開始。
	_health_delay_timer.autostart = false
	# 一次性計時器。
	_health_delay_timer.one_shot = true
	# 時間到：開始讓延遲條縮短。
	_health_delay_timer.timeout.connect(
		func():
			_play_delay = true
	)
	# 加入場景樹，計時器才會運作。
	add_child(_health_delay_timer)


# 每個畫面影格執行。
func _process(_delta):
	# 依目前血量更新主血條的水平縮放（0 ~ 1）。
	_health_bar.scale.x = _get_health_bar_scale()
	
	# 延遲條縮短中：每影格以固定量 0.005 往主血條長度靠近（等速）。
	if _play_delay:
		_delay_bar.scale.x = move_toward(
			float(_delay_bar.scale.x),
			_health_bar.scale.x,
			0.005
		)
	
	# 延遲條已經追上主血條 → 停止延遲動畫。
	if is_equal_approx(_delay_bar.scale.x, _health_bar.scale.x):
		_play_delay = false

# _get_health_bar_scale()：計算並回傳主血條應有的水平縮放值（0.0 ~ 1.0）。
func _get_health_bar_scale() -> float:
	# 從玩家的血量元件讀取目前血量。
	_health = _player.health_component.health
	# lerp(0, 1, 血量百分比)：結果其實就等於「目前血量 ÷ 最大血量」。
	return lerp(
		0.0, 
		1.0,
		_health / _default_health
	)
