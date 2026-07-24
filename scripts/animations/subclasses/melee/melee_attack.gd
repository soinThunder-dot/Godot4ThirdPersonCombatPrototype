class_name MeleeAttack
extends BaseAnimations
## 近戰攻擊招式基底類別(抽象基礎類)
## 每一種具體的近戰攻擊招式(如內旋斩、外旋斩、快速斩擊、匯刺等)都會繼承此類別，
## 並實作各自的動畫播放邏輯。此類別定義了共通的傷害屬性、額外位移資源，
## 以及待子類實作的虛擬函式介面(play_attack, play_legs, perform_legs_transition, end_legs_transition)。

# 傷害屬性資源(包含攻擊力、擊退等參數)，預設載入預設的DefaultDamageAttributes資源檔
@export var damage_attributes: DamageAttributes = \
	preload("res://resources/DefaultDamageAttributes.tres")
# 額外位移資源(例如攻擊時需要向前衝刺的位移量/曲線)，預設載入預設的DefaultMeleeAttackSecondaryMovement資源檔
@export var secondary_movement: SecondaryMovement = \
	preload("res://resources/DefaultMeleeAttackSecondaryMovement.tres")

# 該攻擊招式的名稱，用於 AnimationTree 參數路徑對應與對照目前播放的是哪一招
var attack_name: StringName

# A flag that signifies whether to play
# the attack 1 animation or the copy
# of the attack 1 animation. This is done
# to rectify the issue of instant
# transitions when the transition node
# in the blend tree is requested to play
# the animation that is currently playing.
# 用來標記該播放原始動畫還是其複製版本(Copy)的旗標。
# 由於AnimationTree的轉接節點(transition node)在要求播放「目前正在播放中」的同一個動畫時，
# 會無法正確觸發轉接(因為狀態未變化)，所以使用一個原本動畫的複製節點來交替播放，
# 確保每次都能觸發完整的轉接效果。
var _play_copy: bool = false


## 播放該攻擊的主要動畫(上半身/武器動作)
## 基底類中為空實作，實際邏輯由各子類(如InwardMeleeAttack、OutwardMeleeAttack等)覆寫
## 通常會依據 _play_copy 旗標判斷要播放原版還是複製版動畫節點，並切換_play_copy供下次使用
func play_attack() -> void:
	if _play_copy:
		pass
	else:
		pass


## 播放該攻擊對應的下半身(腳步移動)動畫
## 由各子類實作，這裡為空白實作
func play_legs() -> void:
	pass


## 執行腳步動畫的轉場過渡邏輯
## 由各子類實作，這裡為空白實作
func perform_legs_transition() -> void:
	pass


## 結束腳步動畫的轉場，恢復正常行走動畫速度
## 由各子類實作，這裡為空白實作
func end_legs_transition() -> void:
	pass
