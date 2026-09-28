# ==========================================================
# 【檔案說明】player_backstab_state.gd
# 這是玩家背刺流程的上層狀態，負責協調「準備背刺」與「執行背刺攻擊」兩個子狀態。
# 進入本狀態時會先切換到準備狀態；準備狀態可依玩家輸入開始攻擊，
# 攻擊結束後則通知父狀態機回到預設狀態，讓玩家恢復一般操作。
# 本腳本繼承 PlayerStateMachine，並透過其子狀態機流程呼叫各狀態的 enter/process/exit。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerBackstabState 類別。
class_name PlayerBackstabState
# 繼承玩家狀態機節點，取得狀態切換與子狀態管理流程。
extends PlayerStateMachine

# 指向背刺流程中的準備子狀態，通常是本狀態進入後的第一個狀態。
@export var prepare_state: PlayerBackstabPrepareState
# 指向背刺攻擊子狀態，供準備狀態在收到攻擊輸入時切換使用。
@export var attack_state: PlayerBackstabAttackState


# _ready：節點初始化時由 Godot 呼叫；呼叫父類別初始化子狀態機結構。
func _ready():
	super._ready()


# enter：狀態機切入背刺流程時呼叫，立即開始背刺準備階段。
func enter() -> void:
	change_state(prepare_state)


# process_player：每次玩家狀態更新時呼叫；檢查背刺攻擊是否已結束。
func process_player() -> void:
	# 若近戰元件已不在攻擊中，而且目前子狀態仍是背刺攻擊，就結束整個背刺流程。
	if not player.melee_component.attacking and current_state == attack_state:
		# 請父狀態機切回自己的預設狀態，讓玩家離開背刺狀態。
		parent_state.transition_to_default_state()
		# 狀態已安排切換，不必再執行本函式後續內容。
		return


# exit：離開背刺上層狀態時呼叫；目前不需要額外清理，因此保留空操作。
func exit() -> void:
	pass
