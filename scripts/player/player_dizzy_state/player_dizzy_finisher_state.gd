# ==========================================================
# 【檔案說明】player_dizzy_finisher_state.gd
# 這是玩家執行暈眩終結技時的上層狀態，根據暈眩來源選擇對應的終結技子狀態。
# 進入時會暫時關閉玩家 hitbox、調整移動速度，並檢查暈眩目標是否由招架造成滿值不穩定；
# 若是就走招架終結技，否則走受傷終結技。實際演出與完成後的流程由兩個子狀態處理。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerDizzyFinisherState 類別。
class_name PlayerDizzyFinisherState
# 繼承玩家狀態機節點，管理終結技的兩種子狀態。
extends PlayerStateMachine


# 終結技期間使用的移動元件引用；進入狀態時調整其速度。
@export var locomotion_component: LocomotionComponent

# 暈眩來源為招架時使用的終結技子狀態。
@export var from_parry: PlayerDizzyFinisherFromParryState
# 暈眩來源為受到傷害時使用的終結技子狀態。
@export var from_damage: PlayerDizzyFinisherFromDamageState

# 取得全域暈眩系統，供本狀態判斷受害者的暈眩來源。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# _ready：節點初始化時由 Godot 呼叫；由父類別設定本狀態機的子狀態。
func _ready():
	super._ready()


# enter：進入終結技上層狀態時呼叫；暫停 hitbox、設定速度並選擇演出分支。
func enter() -> void:
	# 終結技演出期間暫時停用玩家 hitbox。
	player.hitbox_component.enabled = false
	# 設定終結技期間使用的移動速度。
	locomotion_component.speed = 3
	
	# 暫存接下來要進入的終結技子狀態。
	var state: PlayerStateMachine
	# 若暈眩系統記錄此受害者是由招架造成滿值不穩定，就使用招架終結技分支。
	if dizzy_system.dizzy_victim.instability_component.full_instability_from_parry:
		state = from_parry
	# 否則使用受到傷害後觸發的終結技分支。
	else:
		state = from_damage
	
	# 只有目標子狀態尚未是目前子狀態時才切換，避免重複進入同一狀態。
	if current_state != state:
		change_state(state)


# process_player：上層狀態本身沒有額外逐影格工作；具體流程交由目前的子狀態。
func process_player() -> void:
	pass


# exit：離開終結技狀態時呼叫，重新啟用玩家 hitbox。
func exit() -> void:
	player.hitbox_component.enabled = true
