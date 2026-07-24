## 刷尺斬(Thrust)近戰攻擊招式
## 向前刷出的種攻擊，不改变下半身行走動畫

class_name ThrustMeleeAttack
extends MeleeAttack


# 設定該攻擊的識別名稱，供其他系統对照
func _ready():
	attack_name = "thrust"


## 播放刷尺斬攻擊動畫，直接以較快速度從頭播放
func play_attack():
	anim_tree.set(&"parameters/Attack Forward Thrust/Forward Thrust Trim/seek_request", 0.0)
	anim_tree.set(&"parameters/Attack Forward Thrust/Forward Thrust Speed/scale", 1.5)
	anim_tree.set(&"parameters/Melee Attack/transition_request", &"thrust")


## 播放腳步(下半身)行走動畫(此攻擊未使用，留空)
func play_legs() -> void:
	pass


## 執行腳步轉場(此攻擊未使用，留空)
func perform_legs_transition():
	pass


## 結束腳步轉場(此攻擊未使用，留空)
func end_legs_transition():
	pass
