# ==========================================================
# 【檔案說明】player_dizzy_finisher_from_parry_state.gd
# 這是玩家暈眩終結技中「由招架造成暈眩」的子狀態，先播放準備演出並面向暈眩受害者。
# 後續依玩家攻擊輸入、終結技是否已就緒及受害者狀態，播放正式終結技或接收完成通知；
# 動畫完成後會請上層狀態機返回預設狀態，離開時恢復移動並清除擊殺中標記。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerDizzyFinisherFromParryState 類別。
class_name PlayerDizzyFinisherFromParryState
# 繼承玩家狀態機節點，作為招架來源終結技的子狀態。
extends PlayerStateMachine


# _finished：招架終結技動畫是否已發出完成訊號；用於逐影格判斷是否離開狀態。
var _finished: bool = false

# 取得全域暈眩系統，讀取受害者、終結技就緒狀態並標記擊殺演出。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# _ready：節點初始化時呼叫；連接動畫完成訊號以設定完成旗標。
func _ready():
	super._ready()
	
	# （回呼內容）暈眩終結技動畫系統發出完成訊號時，將 _finished 設為 true，供 process_player 判斷是否結束流程。
	player.character.dizzy_finisher_animations.dizzy_finisher_finished.connect(
		func(): _finished = true
	)


# enter：切入招架來源終結技時呼叫；重設完成狀態、播放準備動畫並面向暈眩受害者。
func enter() -> void:
	# 清除前一次演出的完成旗標。
	_finished = false
	# 播放招架來源終結技的預備動畫。
	player.character.dizzy_finisher_animations.play_from_parry_pre_finisher()
	# 將角色旋轉目標指定為全域暈眩系統中的受害者實體。
	player.rotation_component.target = Globals.dizzy_system.dizzy_victim.entity
	# 允許旋轉元件轉向剛設定的受害者目標。
	player.rotation_component.rotate_towards_target = true
	# 預備與終結技演出期間禁止玩家移動。
	player.locomotion_component.can_move = false
	# 通知招架動畫系統招架接收流程已完成，銜接後續演出。
	player.character.parry_animations.receive_parry_finished()


# process_player：每次玩家狀態更新時檢查終結技觸發條件、受害者回應與動畫完成旗標。
func process_player() -> void:
	# 玩家剛按下攻擊且系統允許擊殺受害者，或終結技目前尚未準備好時，執行正式終結技分支。
	# 括號中的多行條件是一個布林判斷；此說明放在括號之外，避免插入未完成的條件式中。
	if (
		Input.is_action_just_pressed("attack") and \
		dizzy_system.can_kill_victim
	) or not dizzy_system.readied_finisher:
		# 更新武器攻擊實例，並停用攻擊中斷處理以保護演出流程。
		player.melee_component.increment_weapon_instance()
		player.melee_component.disable_attack_interrupted()
		# 播放招架來源的正式終結技動畫。
		player.character.dizzy_finisher_animations.play_from_parry_finisher()
		# 將受害者標記為正在擊殺演出中。
		dizzy_system.victim_being_killed = true
	
	# 若尚未進行擊殺且系統保存了受害者，就通知動畫系統接收終結技完成事件。
	if not dizzy_system.victim_being_killed and \
	dizzy_system.saved_victim != null:
		# 此呼叫以反斜線接續同一個成員存取鏈；註解放在鏈結之前，不打斷它。
		player\
			.character\
			.dizzy_finisher_animations\
			.receive_dizzy_finisher_finished()
	
	# 完成訊號設下旗標後，請終結技上層的上層狀態機回到預設狀態。
	if _finished:
		parent_state.parent_state.transition_to_default_state()
		return


# exit：離開招架來源終結技時呼叫，恢復玩家移動並清除暈眩系統的擊殺中標記。
func exit() -> void:
	# 重新允許玩家移動。
	player.locomotion_component.can_move = true
	# 通知暈眩系統受害者不再處於擊殺演出中。
	dizzy_system.victim_being_killed = false
	
