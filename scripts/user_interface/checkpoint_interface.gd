# ==========================================================
# 【檔案說明】checkpoint_interface.gd
# 這是「存檔點（檢查點）介面」的腳本。
# 玩家走到檢查點（類似魂系遊戲的篝火）並互動時，會顯示這個選單。
# 選單上有兩個按鈕：
#   1. Recover（恢復）：恢復玩家狀態，並伴隨畫面淡出淡入的演出
#   2. Return（返回）：離開檢查點選單，回到遊戲
# 此腳本也負責控制選單的淡入淡出，以及全螢幕黑幕（Fade）的淡入淡出。
# ==========================================================

# class_name：將此腳本註冊為全域類別「CheckpointInterface」，
# 其他腳本可以直接用這個名稱當作型別（例如 user_interface.gd 中的變數型別）。
class_name CheckpointInterface
# extends Control：此腳本繼承自 Control（Godot 的 UI 節點基底類別）。
extends Control


# ---------- 訊號（Signal）----------
# 訊號是 Godot 的「事件通知」機制：這個節點發出（emit）訊號後，
# 所有連接（connect）到此訊號的函式都會被呼叫。
# perform_recovery：當恢復流程進行到「畫面全黑」時發出，
# 讓外部系統（例如檢查點系統）在玩家看不到的時候執行真正的恢復動作
# （例如補滿血量、重生敵人等）。
signal perform_recovery
# exit_checkpoint：玩家選擇離開檢查點選單時發出。
signal exit_checkpoint


# ---------- 變數 ----------
# fade_out：是否要讓黑幕淡入（變黑）。
# true = 畫面逐漸變黑；false = 黑幕逐漸變透明。
# 這是公開變數（沒有底線開頭），外部腳本也可以修改它。
var fade_out: bool = false

# _show_menu：是否顯示選單（底線開頭代表「私有」，慣例上只在本腳本內使用）。
# 在 _physics_process 中會依此值讓選單透明度漸變到 1 或 0。
var _show_menu: bool = false
# _prev_mouse_mode：記錄「上一次」的滑鼠模式（可見/隱藏/鎖定等），
# 用來判斷滑鼠是否剛剛才從隱藏變成可見。
var _prev_mouse_mode: int

# ---------- @onready 節點參考 ----------
# @onready 代表：等到節點進入場景樹、_ready() 執行前才取得這些值，
# 確保子節點已經存在。$路徑 是 get_node("路徑") 的簡寫。
# menu：整個選單的容器節點。
@onready var menu: Control = $Menu
# recover_button：「恢復」按鈕。
@onready var recover_button: Button = $Menu/Buttons/Recover
# return_button：「返回」按鈕。
@onready var return_button: Button = $Menu/Buttons/Return
# fade_texture：覆蓋整個畫面的黑色貼圖，用來做淡出（變黑）效果。
@onready var fade_texture: TextureRect = $Fade

# music_system：從全域單例 Globals 取得音樂系統，
# 用於恢復時把戰鬥音樂淡出回到閒置音樂。
@onready var music_system: MusicSystem = Globals.music_system


# _ready()：節點與其子節點都準備好後，Godot 自動呼叫一次（初始化用）。
func _ready():
	# 一開始整個介面隱藏（玩家還沒碰到檢查點）。
	visible = false
	# 選單的透明度（modulate.a）設為 0，也就是完全透明，之後再慢慢淡入。
	menu.modulate.a = 0
	
	# 將「恢復」按鈕被按下的訊號（pressed）連接到本腳本的 _recover 函式。
	recover_button.pressed.connect(_recover)
	# 將「返回」按鈕被按下的訊號連接到一個匿名函式（lambda）。
	# 匿名函式內只做一件事：發出 exit_checkpoint 訊號，通知外部玩家要離開選單。
	# （回呼內容）發出「離開檢查點」訊號。
	return_button.pressed.connect(
		func():
			exit_checkpoint.emit()
	)


# _physics_process(delta)：每個物理影格（預設每秒 60 次）呼叫一次。
# _delta 是距離上一個物理影格的秒數；前面加底線表示此參數未被使用。
func _physics_process(_delta):
	
	# ---------- 選單淡入 / 淡出 ----------
	# lerp(a, b, t)：線性插值，回傳 a 往 b 移動 t 比例後的值。
	# 每一影格都往目標移動 10%（0.1），會形成「先快後慢」的平滑淡入淡出效果。
	if _show_menu:
		# 要顯示選單：透明度逐漸趨近 1.0（完全不透明）。
		menu.modulate.a = lerp(
			menu.modulate.a,
			1.0,
			0.1
		)
	else:
		# 不顯示選單：透明度逐漸趨近 0.0（完全透明）。
		menu.modulate.a = lerp(
			menu.modulate.a,
			0.0,
			0.1
		)
	
	# ---------- 黑幕淡入 / 淡出 ----------
	# 這裡改的是 self_modulate（只影響節點自己，不影響子節點），
	# 係數 0.03 比選單的 0.1 小，所以黑幕變化比較慢、比較有戲劇感。
	if fade_out:
		# 畫面逐漸變黑。
		fade_texture.self_modulate.a = lerp(
			fade_texture.self_modulate.a,
			1.0,
			0.03
		)
	else:
		# 黑幕逐漸消失，畫面恢復可見。
		fade_texture.self_modulate.a = lerp(
			fade_texture.self_modulate.a,
			0.0,
			0.03
		)
	
	# 若玩家按下「ui_cancel」（預設為 Esc 鍵 / 手把 B 鍵），
	# 且選單正在顯示中，就發出離開檢查點的訊號。
	# is_action_just_pressed 只在「剛按下的那一影格」回傳 true，避免重複觸發。
	if Input.is_action_just_pressed("ui_cancel") and _show_menu:
		exit_checkpoint.emit()


# _input(event)：每當有輸入事件（鍵盤、滑鼠、手把）時被呼叫。
func _input(event: InputEvent):
	# 只處理「滑鼠移動」事件，且只在選單顯示時處理。
	# 目的：玩家原本可能用手把操作（滑鼠隱藏），一動滑鼠就讓游標出現。
	if event is InputEventMouseMotion and _show_menu:
		# 先記錄目前的滑鼠模式。
		_prev_mouse_mode = Input.mouse_mode
		# 把滑鼠設為可見，讓玩家可以用滑鼠點按鈕。
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# 如果滑鼠「原本不是可見的」（代表是剛剛才顯示出來），
		# 就把游標瞬移到「恢復」按鈕的正中央，方便玩家直接點擊。
		if _prev_mouse_mode != Input.MOUSE_MODE_VISIBLE:
			# warp_mouse：將滑鼠游標移動到指定位置（相對於此 Control）。
			# 按鈕的全域位置 + 按鈕尺寸的一半 = 按鈕中心點。
			warp_mouse(
				recover_button.global_position + (recover_button.size / 2)
			)


# show_menu()：外部呼叫以顯示檢查點選單（例如玩家與檢查點互動時）。
func show_menu() -> void:
	# 讓整個介面可見。
	visible = true
	# 設旗標，讓 _physics_process 開始把選單淡入。
	_show_menu = true
	# 讓「恢復」按鈕取得焦點，這樣玩家用鍵盤或手把可以直接選取/確認。
	recover_button.grab_focus()


# hide_menu()：外部呼叫以隱藏選單（只是淡出，visible 仍維持 true）。
func hide_menu() -> void:
	_show_menu = false


# _recover()：按下「恢復」按鈕時執行的完整恢復演出流程。
# 流程時間軸（大約）：
#   0 秒：選單淡出，播放恢復粒子特效
#   1 秒：畫面開始變黑，若音樂在播放則淡出回閒置音樂
#   3 秒：發出 perform_recovery 訊號（在全黑時真正執行恢復）
#   4 秒：黑幕開始消失
#   5 秒：選單重新淡入
func _recover() -> void:
	# 先隱藏選單。
	_show_menu = false
	
	# 透過全域的檢查點系統，讓「目前的檢查點」播放恢復粒子特效。
	Globals.checkpoint_system.current_checkpoint.play_recovery_particles()
	
	# 宣告一個 SceneTreeTimer（場景樹計時器，一次性、不需加入場景樹）。
	var timer: SceneTreeTimer
	# 建立 1 秒的計時器。
	timer = get_tree().create_timer(1)
	# 計時器時間到時執行以下匿名函式：
	# （回呼內容）開始讓畫面變黑。
	# （回呼內容）如果目前有歌曲正在播放（例如戰鬥音樂），強制淡出回到閒置音樂。
	timer.timeout.connect(
		func():
			fade_out = true
			if music_system.active_song.playing:
				music_system.force_fade_to_idle()
	)
	
	# await：暫停這個函式，直到計時器發出 timeout 訊號後才繼續往下執行
	# （不會卡住整個遊戲，只是這個函式「等待」）。
	await timer.timeout
	# 再建立 2 秒的計時器（此時畫面正在變黑）。
	timer = get_tree().create_timer(2)
	# （回呼內容）畫面已經全黑，發出訊號讓外部執行真正的恢復邏輯。
	timer.timeout.connect(
		func():
			perform_recovery.emit()
	)
	
	# 等待上面 2 秒結束。
	await timer.timeout
	# 再等 1 秒。
	timer = get_tree().create_timer(1)
	# （回呼內容）讓黑幕開始消失，畫面恢復。
	timer.timeout.connect(
		func():
			fade_out = false
	)

	# 等待上面 1 秒結束。
	await timer.timeout
	# 最後再等 1 秒。
	timer = get_tree().create_timer(1)
	# （回呼內容）重新顯示選單，玩家可以再次選擇恢復或返回。
	timer.timeout.connect(
		func():
			_show_menu = true
	)
