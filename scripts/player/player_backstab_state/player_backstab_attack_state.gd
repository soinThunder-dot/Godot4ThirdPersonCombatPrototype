# ==========================================================
# 【檔案說明】player_backstab_attack_state.gd
# 這是玩家背刺流程中的攻擊子狀態，進入時面向目標並啟動近戰攻擊。
# 為避免攻擊演出期間受到命中判定或被移動控制打斷，會暫時關閉玩家 hitbox 並禁止移動；
# 離開狀態時再恢復 hitbox 與移動能力。攻擊結束後由背刺上層狀態負責返回一般狀態。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerBackstabAttackState 類別。
class_name PlayerBackstabAttackState
# 繼承玩家狀態機節點，依共用狀態流程執行背刺攻擊。
extends PlayerStateMachine

# _ready：節點初始化時由 Godot 呼叫；委派父類別完成狀態機初始化。
func _ready():
	super._ready()


# enter：切入背刺攻擊時呼叫；設定面向、觸發攻擊並暫停玩家移動與 hitbox。
func enter() -> void:
	# 允許旋轉元件朝目前設定的目標轉向。
	player.rotation_component.rotate_towards_target = true
	# 呼叫近戰元件執行攻擊；參數 2 與 true 的具體意義由近戰元件定義。
	player.melee_component.attack(2, true)
	# 背刺演出期間停用玩家 hitbox。
	player.hitbox_component.enabled = false
	# 背刺演出期間禁止玩家移動。
	player.locomotion_component.can_move = false

# exit：離開背刺攻擊時呼叫，恢復 hitbox 與角色移動能力。
func exit() -> void:
	# 重新啟用玩家 hitbox。
	player.hitbox_component.enabled = true
	# 重新允許玩家移動。
	player.locomotion_component.can_move = true
