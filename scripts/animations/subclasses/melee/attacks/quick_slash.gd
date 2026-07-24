## 快速斬(Quick Slash)近戰攻擊招式
## 速度較快，動畫較短，用於連段中的快攻

class_name QuickSlashMeleeAttack
extends MeleeAttack


# 設定該攻擊的識別名稱，供其他系統对照
func _ready():
	attack_name = "quick_slash"


## 播放快速斬攻擊動畫，包含上半身攻擊與下半身行走動畫的修剪與速度設定
func play_attack():
	anim_tree.set(&"parameters/Attack Quick Slash/Quick Slash Trim/seek_request", 0.9)
	anim_tree.set(&"parameters/Attack Quick Slash/Walk Forwards Trim/seek_request", 0.8)
	anim_tree.set(&"parameters/Attack Quick Slash/Walk Forwards Speed/scale", 0.8)
	anim_tree.set(&"parameters/Melee Attack/transition_request", &"quick_slash")


## 播放與快速斬搭配的腳步(下半身)行走動畫
func play_legs():
	anim_tree.set(&"parameters/Attack Quick Slash/Walk Forwards Speed/scale", 0.8)


## 執行腳步轉場(此攻擊未使用，留空)
func perform_legs_transition():
	pass


## 結束腳步轉場，將行走速度以線性插值(lerp)逐步恢復至還原值
func end_legs_transition():
	var speed = anim_tree.get(&"parameters/Attack Quick Slash/Walk Forwards Speed/scale")
	if speed == null: return
	anim_tree.set(
		&"parameters/Attack Quick Slash/Walk Forwards Speed/scale",
		lerp(
			float(speed),
			0.05,
			0.3
		)
	)
