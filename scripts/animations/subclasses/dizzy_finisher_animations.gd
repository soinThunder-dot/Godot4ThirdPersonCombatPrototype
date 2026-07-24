## 暈眩終結技動畫控制器：當敵人處於暈眩狀態時，播放對其發動終結技的專屬混合動畫
class_name DizzyFinisherAnimations
extends BaseAnimations


# 當閃避終結技播放完成時發出此信號
signal dizzy_finisher_finished


# signifies that the character is in the process
# of performing the finisher on the dizzy victim（中文：表示角色目前正在對閃避中的受害者執行終結技）
var attacking: bool = false

# flag that dictates whether to play the finisher anim（中文：標記是否要播放終結技動畫）
var _blend_dizzy_finisher: bool = false
var _blend: float = 0.0


# 每幀物理更新：依 _blend_dizzy_finisher 旗標逐步接近目標混合值，驅動終結技動畫的混合權重
func _physics_process(_delta):
	if BaseAnimations.should_return_blend(_blend_dizzy_finisher, _blend): return
	
	var blend = anim_tree.get(&"parameters/Dizzy Finisher/blend_amount")
	if blend == null: return
	
	_blend = move_toward(
		float(blend),
		1.0 if _blend_dizzy_finisher else 0.0,
		0.1
	)
	
	anim_tree.set(
		&"parameters/Dizzy Finisher/blend_amount",
		_blend
	)


# 從「強行拆解閃避(parry)前置終結」觸發的終結技播放：啟用混合、切換到對應轉換設定並設定速度/起始位置參數
func play_from_parry_pre_finisher() -> void:
	_blend_dizzy_finisher = true
	anim_tree.set(&"parameters/Dizzy Finisher Which One/transition_request", &"from_parry")
	anim_tree.set(&"parameters/Dizzy Finisher From Parry Speed/scale", 0.0)
	anim_tree.set(&"parameters/Dizzy Finisher From Parry Trim/seek_request", 0.0)


# 真正開始播放閃避終結技動畫（已先由 play_from_parry_pre_finisher 設定好前置），只需調整最終播放速度
func play_from_parry_finisher() -> void:
	anim_tree.set(&"parameters/Dizzy Finisher From Parry Speed/scale", 1.5)


# 當敵人因受到傷害而觸發閃避終結技（非 parry 觸發）時播放：啟用混合、切換到對應轉換、設定起始位置及速度
func play_from_damage_finisher() -> void:
	_blend_dizzy_finisher = true
	anim_tree.set(&"parameters/Dizzy Finisher Which One/transition_request", &"from_damage")
	anim_tree.set(&"parameters/Dizzy Finisher From Damage Trim/seek_request", 1.8)
	anim_tree.set(&"parameters/Dizzy Finisher From Damage Speed/scale", 1.5)


# 設定暈眩終結技的播放方式：如果來自閃避(parry)則依是否正在攻擊來決定速度；否則若之前正在攻擊則切換為受傷型終結技
func set_dizzy_finisher(from_parry: bool) -> void:
	if from_parry:
		_blend_dizzy_finisher = true
		anim_tree.set(&"parameters/Dizzy Finisher Which One/transition_request", &"from_parry")
		if attacking:
			anim_tree.set(&"parameters/Dizzy Finisher From Parry Speed/scale", 1.5)
		else:
			anim_tree.set(&"parameters/Dizzy Finisher From Parry Speed/scale", 0.0)
			anim_tree.set(&"parameters/Dizzy Finisher From Parry Trim/seek_request", 0.0)
	elif attacking:
		attacking = false
		# if victim is dizzy from damage, we still want to be able
		# to walk around and do normal stuff. that's why（中文：若受害者因受傷而暈眩，仍希望他能正常行走及行動）
		# _blend_dizzy_finisher is only set to true only if attacking（中文：因此 _blend_dizzy_finisher 只有在正在攻擊時才會設為 true）
		_blend_dizzy_finisher = true
		anim_tree.set(&"parameters/Dizzy Finisher Which One/transition_request", &"from_damage")
		anim_tree.set(&"parameters/Dizzy Finisher From Damage Trim/seek_request", 1.8)
		anim_tree.set(&"parameters/Dizzy Finisher From Damage Speed/scale", 1.5)


# 接收閃避終結技播放完成的通知：重置攻擊及混合旗標，並將完成信號向外發出
func receive_dizzy_finisher_finished() -> void:
	attacking = false
	_blend_dizzy_finisher = false
	dizzy_finisher_finished.emit()
