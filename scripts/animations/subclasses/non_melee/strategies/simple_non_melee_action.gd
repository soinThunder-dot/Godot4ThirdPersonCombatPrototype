## 簡化版非近戰動作：適用於大部分只需播放單一動畫片段的非近戰動作（如閃避、嗁吼等），支援 Trim/Speed 參數調整及圖參分身循環播放(has_copy)
class_name SimpleNonMeleeAction
extends NonMeleeAction


# action_name: 對應 AnimationTree 中的動畫節點名稱；has_copy: 是否啟用分身(Copy)交替播放以達到可立即重新播放的效果
@export var action_name: String
@export var has_copy: bool = false

# trim: 動畫播放起始位置(seek)；animation_speed: 播放速度倍率
@export_category("Animation Settings")
@export var trim: float = 0.0
@export var animation_speed: float = 1.0


# 播放動作動畫：若未啟用分身則直接播放，若已啟用則交替播放本體與分身以支援連續快速重新觸發
func play_animation():
	if not has_copy:
		_play_action()
		return
	
	_play_action(_play_copy)
	_play_copy = not _play_copy


# 實際執行動作播放：依 action_name 及是否為分身(copy)組裝參數前綴，寫入 Trim/Speed 並觸發對應的 transition_request
func _play_action(copy: bool = false):
	var prefix = "parameters/%s%s/%s " % [
		action_name, " Copy" if copy else "", action_name
	]
	anim_tree.set(
		prefix + "Trim/seek_request",
		 trim
	)
	anim_tree.set(
		prefix + "Speed/scale",
		 animation_speed
	)
	anim_tree.set(
		"parameters/Non Melee Action/transition_request",
		 action_name.to_snake_case() + ("_copy" if copy else "")
	)
