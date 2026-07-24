class_name ParryAnimations
extends BaseAnimations

## 格挡（Parry）動畫子類別，負責處理格挡動作的混合與播放


# _parrying：是否正在執行格挡動作
var _parrying: bool = false
# _blend：目前格挡動畫混合比例
var _blend: float = 0.0


## _physics_process：每幀更新格挡動畫混合比例，驅動動畫樹圖中的格挡參數
func _physics_process(_delta) -> void:
	if BaseAnimations.should_return_blend(_parrying, _blend): return
	
	var blend = anim_tree.get(&"parameters/Parry/blend_amount")
	if debug: prints(_parrying, blend)
	if blend == null: return
	
	_blend = lerp(
		float(blend),
		1.0 if _parrying else 0.0,
		0.2 if _parrying else 0.15
	)
	
	anim_tree.set(
		&"parameters/Parry/blend_amount",
		_blend
	)


## parry：觸發格挡動作，設定狀態並調整動畫播放進度與速度
func parry() -> void:
	_parrying = true
	anim_tree.set(&"parameters/Parry Trim/seek_request", 0.35)
	anim_tree.set(&"parameters/Parry Speed/scale", 2.0)


## receive_parry_recovery：格挡後恢復，恢復正常動畫播放速度
func receive_parry_recovery() -> void:
	anim_tree.set(&"parameters/Parry Speed/scale", 0.5)


## receive_parry_finished：格挡動作結束，重置格挡狀態旗標
func receive_parry_finished() -> void:
	_parrying = false
