# ==========================================================
# 【檔案說明】death_screen.gd
# 這是「死亡畫面」的腳本（類似魂系遊戲的「YOU DIED」畫面）。
# 玩家死亡時會依序播放一段演出：
#   顯示死亡訊息 → 訊息消失 → 畫面變黑 → 重生 → 黑幕消失 → 角色站起來
# 此腳本用多個計時器串接整個時間軸。
# ==========================================================

# 註冊為全域類別 DeathScreen。
class_name DeathScreen
# 繼承 Control（UI 節點）。
extends Control


# ---------- 訊號 ----------
# respawn：畫面全黑時發出，通知外部讓玩家重生（例如移回檢查點位置）。
signal respawn
# stand_up：演出最後發出，通知玩家角色播放「站起來」的動作。
signal stand_up


# ---------- 私有狀態變數 ----------
# _show_message：是否顯示死亡訊息（控制訊息的淡入淡出）。
var _show_message: bool = false
# _fade_to_black：是否讓畫面變黑（控制黑幕的淡入淡出）。
var _fade_to_black: bool = false

# _respawning：是否處於「重生中、黑幕正在消失」的階段。
# 等黑幕完全透明後，會把整個死亡畫面隱藏並把此值設回 false。
var _respawning: bool = false

# ---------- 節點參考 ----------
# _death_message：死亡訊息（文字/圖片）的容器節點。
@onready var _death_message: Control = $DeathMessage
# _fade：全螢幕的黑色貼圖，用來做淡出變黑效果。
@onready var _fade: TextureRect = $Fade

# 從全域單例 Globals 取得檢查點系統（用來播放死亡音效、死亡後恢復）。
@onready var _checkpoint_system: CheckpointSystem = Globals.checkpoint_system
# 從全域單例 Globals 取得音樂系統（用來重置音樂、播放閒置音樂）。
@onready var _music_system: MusicSystem = Globals.music_system


# 初始化：一開始死亡畫面是隱藏的。
func _ready():
	visible = false


# 每個物理影格執行：處理死亡訊息與黑幕的透明度變化。
func _physics_process(_delta):
	
	# ---------- 死亡訊息淡入淡出 ----------
	# 使用 lerp，每影格往目標靠近 10%，形成平滑（先快後慢）的效果。
	if _show_message:
		# 訊息逐漸浮現。
		_death_message.modulate.a = lerp(
			_death_message.modulate.a,
			1.0,
			0.1
		)
	else:
		# 訊息逐漸消失。
		_death_message.modulate.a = lerp(
			_death_message.modulate.a,
			0.0,
			0.1
		)
	
	# ---------- 黑幕淡入淡出 ----------
	# 使用 move_toward，每影格固定改變 0.02（等速），
	# 從 0 到 1 需要 50 個物理影格，約 0.83 秒。
	# 使用等速的好處是：透明度一定會「剛好」到達 0 或 1，
	# 這樣下面的 is_zero_approx 判斷才會可靠地成立（lerp 只會無限趨近）。
	if _fade_to_black:
		# 畫面逐漸變黑。
		_fade.self_modulate.a = move_toward(
			_fade.self_modulate.a,
			1.0,
			0.02
		)
	else:
		# 黑幕逐漸變透明。
		_fade.self_modulate.a = move_toward(
			_fade.self_modulate.a,
			0.0,
			0.02
		)
	
	# 如果黑幕已經完全透明（約等於 0），而且目前處於重生階段：
	# 表示整段死亡演出結束，把死亡畫面隱藏，並重設重生旗標。
	# is_zero_approx：判斷浮點數是否「近似於 0」（避免浮點誤差）。
	if is_zero_approx(_fade.self_modulate.a) and _respawning:
		visible = false
		_respawning = false


# play_death_screen()：玩家死亡時由外部呼叫，播放完整的死亡演出。
# 時間軸（從呼叫開始算，約略）：
#   0   秒：死亡畫面變可見
#   2   秒：顯示死亡訊息 + 播放死亡音效
#   5   秒：死亡訊息開始消失
#   6   秒：畫面開始變黑
#   8   秒：發出 respawn 訊號、檢查點系統執行死亡後恢復
#   9   秒：黑幕開始消失、進入重生階段、重置音樂
#   9.5 秒：發出 stand_up 訊號、播放閒置音樂
func play_death_screen() -> void:
	# 宣告計時器變數，後面會重複使用。
	var timer: SceneTreeTimer
	
	# 讓死亡畫面可見（但此時訊息與黑幕仍是透明的）。
	visible = true
	
	# 第一段：等 2 秒（讓玩家先看到角色倒下）。
	timer = get_tree().create_timer(2)
	# （回呼內容）顯示死亡訊息。
	# （回呼內容）播放死亡音效。
	timer.timeout.connect(
		func():
			_show_message = true
			_checkpoint_system.play_death_sfx()
	)
	
	# await：等計時器結束後，才繼續執行下面的程式碼。
	await timer.timeout
	# 第二段：訊息停留 3 秒。
	timer = get_tree().create_timer(3)
	# （回呼內容）讓死亡訊息淡出。
	timer.timeout.connect(
		func():
			_show_message = false
	)
	
	await timer.timeout
	# 第三段：再等 1 秒。
	timer = get_tree().create_timer(1)
	# （回呼內容）開始讓畫面變黑。
	timer.timeout.connect(
		func():
			_fade_to_black = true
	)
	
	await timer.timeout
	# 第四段：等 2 秒（確保畫面已經全黑）。
	timer = get_tree().create_timer(2)
	# （回呼內容）發出重生訊號，讓玩家在全黑時被移動/重設。
	# （回呼內容）檢查點系統執行死亡後的恢復（例如補血、重置敵人等）。
	timer.timeout.connect(
		func():
			respawn.emit()
			_checkpoint_system.recover_after_death()
	)
	
	await timer.timeout
	# 第五段：再等 1 秒。
	timer = get_tree().create_timer(1)
	# （回呼內容）黑幕開始消失。
	# （回呼內容）標記為重生階段，_physics_process 會在黑幕完全消失後隱藏死亡畫面。
	# （回呼內容）重置音樂系統（例如停止戰鬥音樂）。
	timer.timeout.connect(
		func():
			_fade_to_black = false
			_respawning = true
			_music_system.reset()
	)
	
	await timer.timeout
	# 第六段：再等 0.5 秒。
	timer = get_tree().create_timer(0.5)
	# （回呼內容）通知玩家角色站起來。
	# （回呼內容）開始播放閒置（探索）音樂。
	timer.timeout.connect(
		func():
			stand_up.emit()
			_music_system.idle_song.play()
	)
