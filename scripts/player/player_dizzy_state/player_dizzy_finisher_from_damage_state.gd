# ==========================================================
# 【檔案說明】player_dizzy_finisher_from_damage_state.gd
# 這是玩家暈眩終結技中「由受傷造成暈眩」的子狀態，負責鎖住玩家移動與傷害輸出，
# 並播放相應的終結技動畫。動畫系統發出完成訊號後，本狀態通知上層終結技流程回到一般狀態。
# 透過 dizzy_system.victim_being_killed 標記目前是否正在執行擊殺演出。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerDizzyFinisherFromDamageState 類別。
class_name PlayerDizzyFinisherFromDamageState
# 繼承玩家狀態機節點，作為受傷來源終結技的子狀態。
extends PlayerStateMachine


# _finished：動畫完成訊號是否已抵達；process_player 會依此旗標結束終結技。
var _finished: bool = false

# 取得全域暈眩系統，用來標記受害者擊殺演出的開始與結束。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# _ready：節點初始化時呼叫；連接動畫完成訊號以更新本狀態的完成旗標。
func _ready():
	super._ready()
	
	# （回呼內容）暈眩終結技動畫完成時，若此子狀態仍是父狀態機目前啟用的狀態，就將 _finished 設為 true；否則忽略過期訊號。
	player.character.dizzy_finisher_animations.dizzy_finisher_finished.connect(
		func():
			if parent_state.current_state != self:
				return
			_finished = true
	)


# enter：進入受傷來源終結技時呼叫；重設旗標、限制控制並啟動動畫演出。
func enter() -> void:
	# 清除前一次演出的完成狀態。
	_finished = false
	# 終結技期間禁止玩家移動。
	player.locomotion_component.can_move = false
	# 終結技演出期間禁止玩家武器造成傷害。
	player.weapon.can_damage = false
	# 更新武器實例序號，讓近戰元件建立／辨識新一輪攻擊實例。
	player.melee_component.increment_weapon_instance()
	# 停用攻擊被中斷時的處理，避免終結技演出被一般攻擊中斷機制影響。
	player.melee_component.disable_attack_interrupted()
	# 播放受傷來源的暈眩終結技動畫。
	player.character.dizzy_finisher_animations.play_from_damage_finisher()
	# 告知全域暈眩系統，受害者目前正在被擊殺演出中。
	dizzy_system.victim_being_killed = true


# process_player：每次更新檢查動畫是否完成；完成後請上層狀態機退出整個終結技流程。
func process_player() -> void:
	# 動畫完成訊號設下旗標後，沿父狀態機階層返回終結技流程上一層的預設狀態。
	if _finished:
		parent_state.parent_state.transition_to_default_state()
		return


# exit：離開此終結技子狀態時呼叫，恢復玩家移動並清除擊殺演出標記。
func exit() -> void:
	# 重新允許玩家移動。
	player.locomotion_component.can_move = true
	# 通知暈眩系統擊殺演出已結束。
	dizzy_system.victim_being_killed = false
