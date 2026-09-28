# ==========================================================
# 【檔案說明】player_state_machine.gd
# 這是玩家狀態機的基底腳本，負責管理狀態的進入、退出與每影格處理。
# 狀態可以包含子狀態；狀態機會先處理自己，再沿著目前選取的子狀態往下呼叫，
# 讓較高層的狀態負責共通流程，葉節點狀態則實作實際行為。
# 其他玩家狀態繼承此類別，並覆寫 enter、process_player 等掛勾函式。
# ==========================================================

# 註冊為可供其他腳本與 Godot 型別系統使用的 PlayerStateMachine 類別。
class_name PlayerStateMachine
# 繼承 Node，讓狀態可作為場景樹中的節點並包含子狀態。
extends Node


# 開啟時在狀態切換時輸出目前與新狀態，供除錯使用。
@export var debug: bool = false
# 此狀態所屬的玩家參照；由場景 Inspector 指定。
@export var player: Player

# 目前正在執行的狀態；若此節點有子狀態，會沿此參照向下派送流程。
var current_state: PlayerStateMachine
# 最近一次離開的狀態，可供狀態轉換邏輯判斷先前行為。
var previous_state: PlayerStateMachine
# 此狀態在狀態樹中的父狀態，用來向上層要求切換狀態。
var parent_state: PlayerStateMachine
# 子狀態中的預設狀態；由第一個子節點指定。
var default_state: PlayerStateMachine
# 此節點是否有子狀態；沒有子狀態時，此節點視為狀態樹的葉節點。
var has_sub_states: bool = false


# _ready：節點加入場景樹時執行一次，初始化子狀態與父子關係。
func _ready() -> void:
	# 沒有子節點就不建立子狀態流程，保留為單一狀態。
	if get_child_count() <= 0: return
	# 有子節點代表這個狀態機包含其他狀態。
	has_sub_states = true
	
	# 以第一個子節點作為初始狀態，並設為目前狀態。
	default_state = get_child(0)
	current_state = default_state
	
	# 將每個子狀態的父狀態參照設回此節點，方便子狀態要求父層切換。
	for child in get_children():
		var sub_state: PlayerStateMachine = child
		sub_state.parent_state = self


# change_state：切換到指定子狀態；會先退出舊狀態，再進入新狀態並更新記錄。
# new_state：要切換到的 PlayerStateMachine。
func change_state(new_state: PlayerStateMachine) -> void:
	# 除錯模式下顯示切換前的目前狀態與即將進入的狀態。
	if debug: prints(current_state, new_state)
	
	# 葉節點沒有子狀態可供切換，因此直接結束。
	if not has_sub_states: return
	
	# 依序退出舊狀態、記錄舊狀態，再進入新狀態並設為目前狀態。
	current_state.exit_state_machine()
	previous_state = current_state
	new_state.enter_state_machine()
	current_state = new_state


# transition_to_default_state：存在預設子狀態時，切換回該狀態。
func transition_to_default_state() -> void:
	# 尚未設定預設狀態時不執行切換。
	if not default_state: return
	change_state(default_state)


# transition_to_previous_state：存在前一個狀態時，切回最近離開的狀態。
func transition_to_previous_state() -> void:
	# 尚未記錄前一個狀態時不執行切換。
	if not previous_state: return
	change_state(previous_state)


# enter_state_machine：進入此狀態及其狀態樹中的目前子狀態。
func enter_state_machine() -> void:
	# 先呼叫此層狀態的進入掛勾，讓具體狀態初始化自身行為。
	enter()
	# 沒有子狀態時已到葉節點，不需再向下呼叫。
	if not has_sub_states: return
	# 遞迴進入目前子狀態，完成整條狀態路徑的初始化。
	current_state.enter_state_machine()


# process_player_state_machine：每次外部要求更新玩家狀態時，處理此層與目前子狀態。
func process_player_state_machine() -> void:
	# 先執行此層狀態的玩家處理邏輯。
	process_player()
	# 葉節點沒有子狀態，處理到此即可。
	if not has_sub_states: return
	# 將處理流程遞迴派送給目前子狀態。
	current_state.process_player_state_machine()


# process_movement_animations_state_machine：沿目前狀態路徑更新移動動畫。
func process_movement_animations_state_machine() -> void:
	# 若有子狀態，就交由目前子狀態繼續往下處理。
	if has_sub_states:
		current_state.process_movement_animations_state_machine()
	# 到達葉節點時，改由此狀態實作的動畫處理函式執行。
	else:
		process_movement_animations()


# exit_state_machine：退出此狀態及其狀態樹中的目前子狀態。
func exit_state_machine() -> void:
	# 先執行此層狀態的退出掛勾，讓具體狀態清理或停止行為。
	exit()
	# 葉節點沒有子狀態，無需繼續往下退出。
	if not has_sub_states: return
	# 遞迴退出目前子狀態，結束整條狀態路徑。
	current_state.exit_state_machine()


# enter：供子類別覆寫的進入掛勾；基底版本不執行動作。
func enter() -> void:
	pass


# process_player：供子類別覆寫的玩家狀態處理掛勾；基底版本不執行動作。
func process_player() -> void:
	pass


# process_movement_animations：供子類別覆寫的移動動畫掛勾；預設採用玩家的一般移動動畫。
func process_movement_animations() -> void:
	player.process_default_movement_animations()


# exit：供子類別覆寫的退出掛勾；基底版本不執行動作。
func exit() -> void:
	pass
