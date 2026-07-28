# 死亡畫面：玩家角色死亡後顯示的 UI，包含死亡訊息、畫面變黑、死亡後重生等流程
class_name DeathScreen
extends Control

# 當玩家重生時發出
signal respawn
# 當玩家死亡後站起時發出
signal stand_up

# 是否顯示死亡訊息文字
var _show_message: bool = false
# 是否正在進行畫面變黑淡入
var _fade_to_black: bool = false

# 是否正在重生中（用於控制畫面淡出後是否隱藏整個畫面）
var _respawning: bool = false

# UI 節點參照：死亡訊息、黑屏遮罩貼圖
@onready var _death_message: Control = $DeathMessage
@onready var _fade: TextureRect = $Fade

# 檢查點系統及音樂系統參照，用於播放死亡音效、恢復、重置音樂
@onready var _checkpoint_system: CheckpointSystem = Globals.checkpoint_system
@onready var _music_system: MusicSystem = Globals.music_system


func _ready():
	# 預設不顯示死亡畫面
	visible = false


func _physics_process(_delta):
	# 控制死亡訊息文字的淡入淡出
	if _show_message:
		_death_message.modulate.a = lerp(
			_death_message.modulate.a,
			1.0,
			0.1
		)
	else:
		_death_message.modulate.a = lerp(
			_death_message.modulate.a,
			0.0,
			0.1
		)

	# 控制畫面黑屏遮罩的淡入淡出
	if _fade_to_black:
		_fade.self_modulate.a = move_toward(
			_fade.self_modulate.a,
			1.0,
			0.02
		)
	else:
		_fade.self_modulate.a = move_toward(
			_fade.self_modulate.a,
			0.0,
			0.02
		)

	# 若黑屏遮罩已完全淡出且正在重生中，則隱藏整個畫面並結束重生狀態
	if is_zero_approx(_fade.self_modulate.a) and _respawning:
		visible = false
		_respawning = false


# 播放完整的死亡畫面流程：顯示訊息 -> 黑屏 -> 重生 -> 淡出 -> 站起
func play_death_screen() -> void:
	var timer: SceneTreeTimer

	visible = true

	# 先延遲 2 秒後，顯示死亡訊息並播放死亡音效
	timer = get_tree().create_timer(2)
	timer.timeout.connect(
		func():
			_show_message = true
			_checkpoint_system.play_death_sfx()
	)

	# 先等待上一個計時器結束，接著延遲 3 秒後隱藏死亡訊息
	await timer.timeout
	timer = get_tree().create_timer(3)
	timer.timeout.connect(
		func():
			_show_message = false
	)

	# 先等待上一個計時器結束，接著延遲 1 秒後開始黑屏
	await timer.timeout
	timer = get_tree().create_timer(1)
	timer.timeout.connect(
		func():
			_fade_to_black = true
	)

	# 先等待上一個計時器結束，接著延遲 2 秒後發出重生信號並執行死亡後恢復
	await timer.timeout
	timer = get_tree().create_timer(2)
	timer.timeout.connect(
		func():
			respawn.emit()
			_checkpoint_system.recover_after_death()
	)

	# 先等待上一個計時器結束，接著延遲 1 秒後停止黑屏並重置音樂系統
	await timer.timeout
	timer = get_tree().create_timer(1)
	timer.timeout.connect(
		func():
			_fade_to_black = false
			_respawning = true
			_music_system.reset()
	)

	# 先等待上一個計時器結束，接著延遲 0.5 秒後發出站起信號並播放閒置音樂
	await timer.timeout
	timer = get_tree().create_timer(0.5)
	timer.timeout.connect(
		func():
			stand_up.emit()
			_music_system.idle_song.play()
	)
