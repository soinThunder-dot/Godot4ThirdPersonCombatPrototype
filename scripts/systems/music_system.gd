# ==========================================================
# 【檔案說明】music_system.gd
# 這是「背景音樂系統」的腳本。
# 遊戲有兩首背景音樂：
#   - 閒置音樂（IdleBackgroundMusic）：探索、沒有戰鬥時播放
#   - 戰鬥音樂（ActiveBackgroundMusic）：被敵人發現、進入戰鬥時播放
# 兩者之間的切換使用 AnimationPlayer 的動畫做「淡入淡出（交叉淡化）」。
# 使用「計數器（_counter）」記錄目前有幾個敵人處於戰鬥狀態：
#   每個敵人進入戰鬥 +1，離開戰鬥 -1，歸零時才切回閒置音樂。
# ==========================================================

# 註冊為全域類別 MusicSystem。
class_name MusicSystem
# 繼承 Node（最基本的節點）。
extends Node


# enabled：是否啟用音樂系統（在編輯器調整；false 時完全不播放/切換音樂）。
@export var enabled: bool = true

# idle_music：目前是否處於「閒置音樂」模式（true = 閒置，false = 戰鬥）。
var idle_music: bool = true

# _counter：目前處於戰鬥狀態的敵人數量。
# setter：每次賦值時檢查，若小於 0 就修正為 0，避免計數錯亂變成負數。
var _counter: int = 0:
	set(value):
		_counter = value
		if _counter < 0:
			_counter = 0

# idle_song：閒置音樂播放器。
@onready var idle_song: AudioStreamPlayer = $IdleBackgroundMusic
# active_song：戰鬥音樂播放器。
@onready var active_song: AudioStreamPlayer = $ActiveBackgroundMusic
# anim：動畫播放器，內含 FadeToActive、FadeToIdle、IdleFadeOut、ActiveFadeOut、RESET 等動畫，
# 這些動畫會調整兩個播放器的音量，達成淡入淡出效果。
@onready var anim: AnimationPlayer = $AnimationPlayer


# 初始化。
func _ready():
	# 啟用時，一開始就播放閒置音樂（寫在同一行的簡寫 if）。
	if enabled: idle_song.play()
	
	# 平時停用動畫播放器，避免它持續覆蓋音量屬性。
	anim.active = false
	# 動畫播完後再次停用動畫播放器（_anim_name 參數未使用）。
	anim.animation_finished.connect(
		func(_anim_name: String): anim.active = false
	)


# play_animation(anim_name)：啟用動畫播放器並播放指定動畫。
func play_animation(anim_name: StringName) -> void:
	anim.active = true
	anim.play(anim_name)


# fade_to_active()：有敵人進入戰鬥狀態時呼叫 → 切換到戰鬥音樂。
func fade_to_active() -> void:
	# 戰鬥中的敵人數 +1（無論是否啟用都要計數，保持數字正確）。
	_counter += 1
	
	# 系統停用 → 不切換。
	if not enabled: return
	# 已經是戰鬥音樂 → 不需要再切換。
	if not idle_music: return
	
	# 標記為戰鬥模式，播放「淡入戰鬥音樂」動畫。
	idle_music = false
	play_animation(&"FadeToActive")


# fade_to_idle()：有敵人離開戰鬥狀態時呼叫 → 可能切回閒置音樂。
func fade_to_idle() -> void:
	# 戰鬥中的敵人數 -1。
	_counter -= 1
	
	# 系統停用 → 不切換。
	if not enabled: return
	# 已經是閒置音樂 → 不需切換。
	if idle_music: return
	# 還有其他敵人在戰鬥 → 繼續播放戰鬥音樂。
	if _counter != 0: return
	
	# 所有敵人都離開戰鬥了 → 切回閒置音樂。
	force_fade_to_idle()


# force_fade_to_idle()：不管計數器，強制切回閒置音樂
# （例如在檢查點恢復時，由檢查點介面呼叫）。
func force_fade_to_idle() -> void:
	if not enabled: return
	idle_music = true
	play_animation(&"FadeToIdle")


# fade_out()：讓目前播放的音樂淡出消失（例如玩家死亡時）。
func fade_out() -> void:
	if not enabled: return
	
	# 依目前模式播放對應的淡出動畫。
	if idle_music:
		play_animation(&"IdleFadeOut")
	else:
		play_animation(&"ActiveFadeOut")
	
	# 淡出後狀態重設為閒置模式，戰鬥計數歸零。
	idle_music = true
	_counter = 0


# reset()：播放 RESET 動畫，把所有音量等屬性恢復為預設值（死亡重生時呼叫）。
func reset() -> void:
	play_animation(&"RESET")
