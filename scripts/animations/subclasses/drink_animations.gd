## 飲用（嗝酒/回血）動畫控制器：管理角色嗝酒回復道具時的動畫播放、中斷及回血信號
class_name DrinkAnimations
extends BaseAnimations


signal gain_health # 當嗝酒成功並取得回復血量時發出
signal finished # 嗝酒動作正常完成時發出
signal interupted # 嗝酒動作被中斷（例如遭受攻擊）時發出


# 嗝酒動作是否已被中斷；_blend_drinking: 是否正在播放嗝酒動畫
var _interupted: bool = false
var _blend_drinking: bool = false
var _blend: float = 0.0


# 每幀物理更新：逐步插值更新嗝酒混合權重，實現平滑進入/退出嗝酒動畫
func _physics_process(_delta):
	if BaseAnimations.should_return_blend(_blend_drinking, _blend): return
	
	var blend = anim_tree.get(&"parameters/Drink/blend_amount")
	if blend == null: return
	
	_blend = lerp(
		float(blend),
		1.0 if _blend_drinking else 0.0,
		0.05
	)
	
	anim_tree.set(
		&"parameters/Drink/blend_amount",
		_blend
	)


# 外部呼叫以開始嗝酒動作：啟用混合、重置中斷狀態，並設定動畫播放起始位置
func drink() -> void:
	_blend_drinking = true
	_interupted = false
	anim_tree.set(&"parameters/Drink Trim/seek_request", 1.5)
	anim_tree.set(&"parameters/Drink Speed/scale", 1.5)


# 外部呼叫以中斷嗝酒動作（例如遭受攻擊時）：停止混合、標記為中斷，並發出中斷信號
func interupt_drink() -> void:
	_blend_drinking = false
	_interupted = true
	interupted.emit()


# 接收動畫信號以觸發回血：若未被中斷則發出取得血量信號
func receive_gain_health() -> void:
	if _interupted: return
	gain_health.emit()


# 接收動畫完成信號：若未被中斷則停止混合並發出完成信號
func receive_finished() -> void:
	if _interupted: return
	_blend_drinking = false
	finished.emit()
