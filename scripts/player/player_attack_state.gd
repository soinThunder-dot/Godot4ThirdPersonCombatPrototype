# ==========================================================
# 【檔案說明】player_attack_state.gd
# 這是玩家的「攻擊狀態」腳本，負責在近戰攻擊期間控制玩家可進行的操作。
# 進入狀態時會停止玩家移動並啟動攻擊；攻擊中可接續下一段攻擊，或依輸入
# 切換到格擋／招架，也會檢查是否能進入暈眩處決狀態。
# 它是 PlayerStateMachine 的子狀態，透過 parent_state 通知上層狀態機切換狀態。
# ==========================================================

# 註冊為可供其他腳本引用的 PlayerAttackState 類別。
class_name PlayerAttackState
# 繼承 PlayerStateMachine，沿用玩家狀態機的進入、處理與離開流程。
extends PlayerStateMachine


# parry_state：玩家在攻擊中按下招架輸入時要切換到的招架狀態。
@export var parry_state: PlayerParryState
# block_state：玩家在攻擊中持續按住格擋輸入時要切換到的格擋狀態。
@export var block_state: PlayerBlockState
# dizzy_finisher_state：對符合條件的暈眩敵人施展處決時要切換到的狀態。
@export var dizzy_finisher_state: PlayerDizzyFinisherState

# 記錄是否已確認要切換至暈眩處決；由檢查函式設定，再由 process_player() 執行轉換。
var _transition_to_dizzy_finisher: bool = false


# _ready() 是節點準備完成時由 Godot 呼叫的生命週期函式。
# 呼叫父類別的同名函式，讓 PlayerStateMachine 初始化子狀態與父狀態關係。
func _ready() -> void:
	super._ready()


# enter() 在狀態機進入本攻擊狀態時呼叫。
# 重設處決轉換旗標、優先檢查處決條件，否則鎖定移動並開始適當的攻擊。
func enter() -> void:
	# 每次進入攻擊狀態都先清除上一次留下的處決轉換標記。
	_transition_to_dizzy_finisher = false
	# 若目前已可處決，記下轉換要求並結束本次進入流程；稍後由 process_player() 切換。
	if _check_for_dizzy_finisher():
		return
	
	# 攻擊動作期間暫停一般移動。
	player.locomotion_component.can_move = false
	
	# 若前一個子狀態是格擋，採用 attack() 的三個明確參數，避免沿用一般起手方式。
	if parent_state.previous_state is PlayerBlockState:
		player.melee_component.attack(0, false, false)
	else:
		# 其他情況使用近戰元件的預設攻擊設定。
		player.melee_component.attack()


# process_player() 由狀態機逐次處理玩家輸入與狀態條件。
# 依序處理處決、連續攻擊、攻擊結束，以及從攻擊轉入招架或格擋。
func process_player() -> void:
	# 若進入流程已確認可處決，現在請父狀態機切到暈眩處決狀態。
	if _transition_to_dizzy_finisher:
		parent_state.change_state(dizzy_finisher_state)
		return
	
	# just_pressed 只在按鍵剛按下的這一刻成立；按下攻擊可嘗試接續下一擊。
	if Input.is_action_just_pressed("attack"):
		# 連擊輸入到來時先確認是否應優先轉成暈眩處決。
		if _check_for_dizzy_finisher(): return
		# 讀取目前攻擊段數／層級，供下一行決定是否切換攻擊層級。
		var attack_level = player.melee_component.attack_level
		# 以目前層級的反值呼叫 attack()，請近戰元件執行下一個攻擊層級。
		player.melee_component.attack(not attack_level)
		
	# 攻擊動作已結束時，回到上層狀態機設定的預設狀態。
	if not player.melee_component.attacking:
		parent_state.transition_to_default_state()
		return
		
	# 剛按下格擋鍵且近戰元件成功停止目前攻擊時，改進招架狀態。
	if Input.is_action_just_pressed("block") and \
	player.melee_component.stop_attacking():
		parent_state.change_state(parry_state)
		return
		
	# 持續按住格擋鍵且成功停止攻擊時，改進一般格擋狀態。
	if Input.is_action_pressed("block") and \
	player.melee_component.stop_attacking():
		parent_state.change_state(block_state)
		return


# exit() 在狀態機離開本攻擊狀態時呼叫，恢復移動並中斷尚未完成的攻擊。
func exit() -> void:
	# 重新允許玩家移動。
	player.locomotion_component.can_move = true
	# 確保離開狀態時不會繼續執行攻擊。
	player.melee_component.interrupt_attack()


# _check_for_dizzy_finisher() 檢查全域暈眩系統是否提供可處決的目標。
# 回傳 true 表示暈眩目標存在且允許擊殺；false 表示目前不能進行處決。
func _check_for_dizzy_finisher() -> bool:
	# 取得遊戲共用的暈眩系統參照。
	var dizzy_system: DizzySystem = Globals.dizzy_system
	# 只有存在暈眩目標且系統允許擊殺該目標，才標記處決轉換。
	if dizzy_system.dizzy_victim and dizzy_system.can_kill_victim:
		_transition_to_dizzy_finisher = true
	# 回傳目前的旗標，讓呼叫端決定是否繼續原本的攻擊流程。
	return _transition_to_dizzy_finisher
