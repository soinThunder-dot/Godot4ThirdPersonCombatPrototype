## 非近戰動作基礎類別
## 供其他非近戰類型的動作(如遠程攻擊、技能等)繼承使用

class_name NonMeleeAction
extends BaseAnimations


# 次要移動設定(例如攻擊時的位移行為)，默認使用近戰攻擊的設定檔
@export var secondary_movement: SecondaryMovement = \
	preload("res://resources/DefaultMeleeAttackSecondaryMovement.tres")


# A flag that signifies whether to play
# the original or copy. This is done
# to rectify the issue of instant
# transitions when the transition node
# in the blend tree is requested to play
# the animation that is currently playing.
# 中文翻譯：此旗標用來決定播放原版還是複製版動畫，目的是避免當 blend tree 要求播放目前正在播放的同一段動畫時，因無法偵測到變化而無法觸發轉接的問題
var _play_copy: bool = false


## 播放動作（實作邏輯由子類實作，此處僅作為交替播放邏輯的框架）
func play_animation() -> void:
	if _play_copy:
		pass
	else:
		pass
