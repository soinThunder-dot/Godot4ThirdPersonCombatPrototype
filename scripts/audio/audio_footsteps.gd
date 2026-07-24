class_name AudioFootsteps
extends AudioStreamPlayer3D

## 腳步音效播放器，負責根據角色狀態（地面、奔跑、可否播放）播放對應腳步音效


# can_play：是否允許播放腳步音效
var can_play: bool = true
# on_floor：角色是否位於地面
var on_floor: bool = true
# running：角色是否正在奔跑（影響音效音高）
var running: bool = false


## 播放單次腳步音效，根據目前狀態檢查是否可以播放並調整音高
func play_footstep() -> void:
	if not can_play:
		print("AudioFootsteps CANT PLAY")
		return
	
	if not on_floor:
		print("AudioFootsteps NOT ON FLOOR")
		return
	
	#if playing:
		#print("AudioFootsteps ALREADY PLAYING")
		#return
	
# 根據是否奔跑調整音效音高（奔跑時音高較低）
	if running:
		pitch_scale = 0.7
	else:
		pitch_scale = 0.8
	
	play()
