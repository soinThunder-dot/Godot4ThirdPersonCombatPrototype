# 檢查點介面 (CheckpointInterface)：當玩家觸碰檢查點時顯示的選單，提供恢復/離開選項
class_name CheckpointInterface
extends Control


# 信號：當玩家選擇恢復時發出（通知外部執行實際復活邏輯）
signal perform_recovery
# 信號：當玩家選擇離開檢查點時發出
signal exit_checkpoint


# 是否正在執行畫面淡出效果（恢復後用來遮蓋畫面進行過渡）
var fade_out: bool = false
# 是否顯示選單中

# 上一次鼠標模式，用來在顯示/隱藏選單時恢復鼠標狀態
var _show_menu: bool = false
var _prev_mouse_mode: int

# UI 節點參照：選單容器、恢復按鈕、返回按鈕、淡入淡出用的透明度貼圖
@onready var menu: Control = $Menu
@onready var recover_button: Button = $Menu/Buttons/Recover
@onready var return_button: Button = $Menu/Buttons/Return
@onready var fade_texture: TextureRect = $Fade

# 音樂系統參照，用於恢復時淡出背景音樂
@onready var music_system: MusicSystem = Globals.music_system


# 初始化：預設隱藏選單，並綁定按鈕事件
func _ready():
	visible = false  # 預設不顯示整個介面	
	menu.modulate.a = 0  # 選單透明度從 0 開始（完全透明）
	
	# 點擊「恢復」按鈕時呼叫 _recover 函式
	recover_button.pressed.connect(_recover)
	# 點擊「返回」按鈕時，直接發出離開檢查點信號（以 lambda 匿名函式實作）
	return_button.pressed.connect(
		func():
			exit_checkpoint.emit()
	)


# 每幀更新：控制選單的淡入淡出動畫以及鼠標模式切換
func _physics_process(_delta):
	
				# 若選單正在顯示中，透明度向 1.0 插值（淡入顯示）
if _show_menu:
		menu.modulate.a = lerp(
			menu.modulate.a,
			1.0,
			0.1
		)
		# 否則透明度向 0.0 插值（淡出隱藏）
	else:
		menu.modulate.a = lerp(
			menu.modulate.a,
			0.0,
			0.1
		)
	
			# 若正在進行畫面逐漸變黑的淡出效果，遮蓋貼圖透明度向 1.0 插值（逐漸遮住畫面）
	if fade_out:
		fade_texture.self_modulate.a = lerp(
			fade_texture.self_modulate.a,
			1.0,
			0.03
		)
		# 否則遮蓋貼圖透明度向 0.0 插值（逐漸顯現畫面）
	else:
		fade_texture.self_modulate.a = lerp(
			fade_texture.self_modulate.a,
			0.0,
			0.03
		)
	
	# 若玩家在選單顯示時按下取消鍵（如 ESC），視同於選擇離開檢查點
	if Input.is_action_just_pressed("ui_cancel") and _show_menu:
		exit_checkpoint.emit()

# 輸入事件處理：當選單顯示時，讓鼠標可以自由移動來選擇選項（避免被遊戲本身的鼠標鎖定影響）

func _input(event: InputEvent):
	# 當選單顯示時，若偵測到鼠標移動，則瞬間切換為可見鼠標模式，方便玩家用鼠標點選
	if event is InputEventMouseMotion and _show_menu:
				_prev_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				# 若之前鼠標本來是隱藏狀態（例如被鎖定在遊戲畫面中），就把鼠標定位到「恢復」按鈕中心，方便玩家立即點擊
		if _prev_mouse_mode != Input.MOUSE_MODE_VISIBLE:
			warp_mouse(
				recover_button.global_position + (recover_button.size / 2)
			)


func show_menu() -> void:
	visible = true
	_show_menu = true
	recover_button.grab_focus()


func hide_menu() -> void:
	_show_menu = false


func _recover() -> void:
	_show_menu = false
	
	# 撥放檢查點恢復的粒子特效
	Globals.checkpoint_system.current_checkpoint.play_recovery_particles()
	
	# 建立一個計時器，用於控制之後的畫面逐漸變黑淡出流程
			var timer: SceneTreeTimer
	timer = get_tree().create_timer(1)
	timer.timeout.connect(
		func():
			fade_out = true
			if music_system.active_song.playing:
				music_system.force_fade_to_idle()
	)
	
	await timer.timeout
	# 先等待上一個計時器結束，接著建立新的計時器來廲遲發出恢復信號
	timer = get_tree().create_timer(2)		
	timer.timeout.connect(
		func():
			perform_recovery.emit()
	)
	
	# 先等待上一個計時器結束，接著建立新的計時器來廲遲停止點黑遠果
	await timer.timeout		
	timer = get_tree().create_timer(1)
	timer.timeout.connect(
		func():
			fade_out = false
	)

	# 先等待上一個計時器結束，接著建立新的計時器來廲遲重新顯示選單
	await timer.timeout		
	timer = get_tree().create_timer(1)
	timer.timeout.connect(
		func():
			_show_menu = true
	)
