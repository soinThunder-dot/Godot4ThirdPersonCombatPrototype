## 待機動畫控制器：根據角色是否活躍切換待機/非待機動畫
class_name IdleAnimations
extends BaseAnimations


var active: bool = false: # 角色是否處於活躍狀態，變更時自動切換待機動畫
	set(value):
		if value == active: return # 值未變更則直接返回，避免重複切換
			active = value
		_set_idle()


# 節點就緒時根據目前狀態設定待機動畫
func _ready() -> void:
	_set_idle()


# 根據 active 狀態設定動畫樹的待機轉換請求
func _set_idle() -> void:
	anim_tree.set(
		&"parameters/Idle/transition_request",
		&"active" if active else &"inactive"
	)
