class_name InwardMeleeAttack
extends MeleeAttack
## 內旋斩(從外向內揮)近戰攻擊招式
## 使用 AnimationTree 中「Attack Inward Slash」與其複製節點「Attack Inward Slash Copy」
## 交替播放，以確保每次攻擊都能從頭觸發動畫轉接。

# 動畫修剔(trim)進度，控制動畫播放的起始位置比例
@xport var trim: float = 0.3
@export var speed: float = 1.5


func _ready():
	# 設定該攻擊的識別名稱，供其他系統對照(例如 receive_stop_legs 中比對用)
	attack_name = "inward_slash"


## 播放內旋斩攻擊動畫
## 依據 _play_copy 旗標交替使用原版或複製版的 AnimationTree 節點，避免相同動畫連續播放時無法重新觸發轉接
func play_attack():
	if _play_copy:
							# 播放複製版節點：先將攻擊與行走混合量歸零(完全以攻擊動畫為主)
		anim_tree.set(&"parameters/Attack Inward Slash Copy/Inward Slash and Walk Blend/blend_amount", 0.0)
		# 設定動畫播放起始進度(trim)，可跳過前段直接從中途開始播放
		anim_tree.set(&"parameters/Attack Inward Slash Copy/Inward Slash Trim/seek_request", trim)
		# 設定攻擊動畫播放速度倍率
		anim_tree.set(&"parameters/Attack Inward Slash Copy/Inward Slash Speed/scale", speed)
		# 設定同步行走動畫的起始進度
		anim_tree.set(&"parameters/Attack Inward Slash Copy/Walk Forwards Trim/seek_request", 0.55)
		# 初始將行走動畫速度設為0(尚未進入連段行走階段)
		anim_tree.set(&"parameters/Attack Inward Slash Copy/Walk Forwards Speed/scale", 0.0)
		# 觸發 AnimationTree 轉接到　複製版內旋斩狀態
		anim_tree.set(&"parameters/Melee Attack/transition_request", &"inward_slash_copy")
		_play_copy = false
	else:
		# 播放原版節點，邏輯與上面相同，只是作用於非複製版的 AnimationTree 節點
		anim_tree.set(&"parameters/Attack Inward Slash/Inward Slash and Walk Blend/blend_amount", 0.0)
		anim_tree.set(&"parameters/Attack Inward Slash/Inward Slash Trim/seek_request", trim)
		anim_tree.set(&"parameters/Attack Inward Slash/Inward Slash Speed/scale", speed)
		anim_tree.set(&"parameters/Attack Inward Slash/Walk Forwards Trim/seek_request", 0.55)
		anim_tree.set(&"parameters/Attack Inward Slash/Walk Forwards Speed/scale", 0.0)
		# 觸發 AnimationTree 轉接到原版內旋斩狀態
		anim_tree.set(&"parameters/Melee Attack/transition_request", &"inward_slash")
		_play_copy = true


## 播放與此攻擊搭配的腳步(下半身)行走動畫，使角色能邊攻擊邊往前移動
func play_legs() -> void:
	# 將原版與複製版的行走速度都設為0.8倍，讓角色開始移動
	anim_tree.set(&"parameters/Attack Inward Slash/Walk Forwards Speed/scale", 0.8)
	anim_tree.set(&"parameters/Attack Inward Slash Copy/Walk Forwards Speed/scale", 0.8)

	# 需要同步調整的混合量參數路徑清單(原版與複製版都要變化)
	var params: Array[String] = [
		"parameters/Attack Inward Slash/Inward Slash and Walk Blend/blend_amount",
		"parameters/Attack Inward Slash Copy/Inward Slash and Walk Blend/blend_amount"
	]

	# 利用淹歳動畫(Tween)將混合量從目前值平滑過渡到1.0(完全行走狀態)，花費0.3秒
	for param in params:
		create_tween().tween_property(
			anim_tree,
			param,
			1.0,
			0.3
		)


## 結束腳步動畫的轉場，將行走速度恢復正常低速(回到待機行走狀態)
func end_legs_transition():
	var scale = anim_tree.get(&"parameters/Attack Inward Slash/Walk Forwards Speed/scale")
	if scale == null: return

	var params: Array[String] = [
		"parameters/Attack Inward Slash/Walk Forwards Speed/scale",
		"parameters/Attack Inward Slash Copy/Walk Forwards Speed/scale"
	]

	# 將行走速度緩慢降回很低的值(0.05)，避免突然停頓造成不自然的動畫邏接
	for param in params:
		create_tween().tween_property(
			anim_tree,
			param,
			0.05,
			0.2
		)
