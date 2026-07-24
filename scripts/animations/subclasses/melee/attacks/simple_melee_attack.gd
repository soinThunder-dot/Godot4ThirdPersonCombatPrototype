## 通用簡易近戰攻擊類別
## 可透過匯出變數設定任意名稱的攻擊，無須為每種攻擊別寫專屬 script
## 若 has_copy 為 true，會交替使用原版與複製版的 AnimationTree 節點

class_name SimpleMeleeAttack
extends MeleeAttack


# _attack_name: 該攻擊對應的 AnimationTree 節點名稱/識別名；has_copy: 是否具有複製版節點供交替播放
@export var _attack_name: String
@export var has_copy: bool = false

@export_category("Animation Settings")
@export var trim: float = 0.0
@export var animation_speed: float = 1.0


# 將識別名稱設定為匯入的攻擊名稱
func _ready():
	attack_name = _attack_name


## 播放攻擊動畫；若有複製版節點則交替使用以確保每次都能從頭觸發轉接
func play_attack():
	if not has_copy:
		_play_attack()
		return
	
	_play_attack(_play_copy)
	_play_copy = not _play_copy


## 實際執行攻擊動畫播放邏輯：copy 為 true 時使用複製版節點前綴，並設定修剪與速度參數後觸發轉接
func _play_attack(copy: bool = false):
	var prefix = "parameters/%s%s/%s " % [
		_attack_name, " Copy" if copy else "", _attack_name
	]
	anim_tree.set(prefix + "Trim/seek_request", trim)
	anim_tree.set(prefix + "Speed/scale", animation_speed)
	anim_tree.set(
		"parameters/Melee Attack/transition_request",
		 _attack_name.to_snake_case() + ("_copy" if copy else "")
	)
