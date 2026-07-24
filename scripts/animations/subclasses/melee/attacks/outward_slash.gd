class_name OutwardMeleeAttack
extends MeleeAttack
## 外旋斩(從內向外揮)近戰攻擊招式
## 使用 AnimationTree 中「Attack Outward Slash」與其複製節點「Attack Outward Slash Copy」
## 交替播放，以確保每次攻擊都能從頭觸發動畫轉接。


# 動畫修剔(trim)進度，控制動畫播放的起始位置比例
@export var trim: float = 0.75
@export var speed: float = 1.8


# 設定該攻擊的識別名稱，供其他系統對照
func _ready():
	attack_name = "outward_slash"


## 播放外旋斩攻擊動畫
## 依據 _play_copy 旗標交替使用原版或複製版的 AnimationTree 節點
func play_attack():
	if _play_copy:
		# 播放複製版節點：將攻擊與行走混合量設為1.0(混合行走動作)
		anim_tree.set(&"parameters/Attack Outward Slash Copy/Outward Slash and Walk Blend/blend_amount", 1.0)
		anim_tree.set(&"parameters/Attack Outward Slash Copy/Outward Slash Trim/seek_request", trim)
		anim_tree.set(&"parameters/Attack Outward Slash Copy/Outward Slash Speed/scale", speed)
		anim_tree.set(&"parameters/Attack Outward Slash Copy/Walk Forwards Trim/seek_request", 0.9)
		anim_tree.set(&"parameters/Attack Outward Slash Copy/Walk Forwards Speed/scale", 0.0)
		anim_tree.set(&"parameters/Melee Attack/transition_request", &"outward_slash_copy")
		_play_copy = false
	else:
		# 播放原版節點，邏輯相同，作用於非複製版的 AnimationTree 節點
		anim_tree.set(&"parameters/Attack Outward Slash/Outward Slash and Walk Blend/blend_amount", 1.0)
		anim_tree.set(&"parameters/Attack Outward Slash/Outward Slash Trim/seek_request", trim)
		anim_tree.set(&"parameters/Attack Outward Slash/Outward Slash Speed/scale", speed)
		anim_tree.set(&"parameters/Attack Outward Slash/Walk Forwards Trim/seek_request", 0.9)
		anim_tree.set(&"parameters/Attack Outward Slash/Walk Forwards Speed/scale", 0.0)
		anim_tree.set(&"parameters/Melee Attack/transition_request", &"outward_slash")
		_play_copy = true


## 播放與此攻擊搭配的腳步(下半身)行走動畫
func play_legs() -> void:
	anim_tree.set(&"parameters/Attack Outward Slash/Walk Forwards Speed/scale", 0.8)
	anim_tree.set(&"parameters/Attack Outward Slash Copy/Walk Forwards Speed/scale", 0.8)
	
	var params: Array[String] = [
		"parameters/Attack Outward Slash/Outward Slash and Walk Blend/blend_amount",
		"parameters/Attack Outward Slash Copy/Outward Slash and Walk Blend/blend_amount"
	]
	
	for param in params:
		create_tween().tween_property(
			anim_tree,
			param,
			1.0,
			0.3
		)


## 執行腳步轉場(此攻擊未使用，留空)
func perform_legs_transition():
	pass


## 結束腳步轉場，將行走相關參數還原並以動畫(tween)过渡
func end_legs_transition():
	
	var scale = anim_tree.get(&"parameters/Attack Outward Slash/Walk Forwards Speed/scale")
	if scale == null: return
	
	var params: Array[String] = [
		"parameters/Attack Outward Slash/Walk Forwards Speed/scale",
		"parameters/Attack Outward Slash Copy/Walk Forwards Speed/scale"
	]
	
	for param in params:
		create_tween().tween_property(
			anim_tree,
			param,
			0.05,
			0.2
		)
