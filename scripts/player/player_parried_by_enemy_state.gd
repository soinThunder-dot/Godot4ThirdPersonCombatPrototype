# ==========================================================
# 【檔案說明】player_parried_by_enemy_state.gd
# 這是玩家「武器被敵人彈開」時使用的短暫狀態。
# 它監聽玩家武器的 parried 訊號；收到訊號後，透過父狀態機切換到本狀態。
# 進入狀態時會中斷正在進行的近戰攻擊，並啟動短計時器；計時期間若玩家按下攻擊，
# 就在計時結束後接續進入攻擊狀態，否則回到父狀態機的預設狀態。
# ==========================================================

# 註冊為可在 Godot 中識別的 PlayerParriedByEnemyState 類別。
class_name PlayerParriedByEnemyState
# 繼承玩家狀態機基底，使用其父狀態與狀態切換功能。
extends PlayerStateMachine

# 在 Inspector 指定計時結束後可接續進入的玩家攻擊狀態。
@export var attack_state: PlayerAttackState

# 儲存此狀態使用的一次性計時器。
var _timer: Timer
# 武器被彈開後等待的秒數；預設 0.4 秒。
var _timer_length: float = 0.4

# 記錄玩家是否在等待期間按過攻擊；用來在短暫硬直後接續攻擊。
var _pressed_attack: bool = false


# _ready：節點加入場景樹並準備完成時由 Godot 呼叫；在此連接訊號並建立計時器。
func _ready():
	# 呼叫父類別的初始化，讓共用的狀態機設定先完成。
	super._ready()
	
	# （回呼內容）武器發出 parried 時，通知父狀態機切換至本狀態。
	player.weapon.parried.connect(
		func():
			parent_state.change_state(self)
	)
	
	# 建立 Timer 節點，供本狀態計算短暫等待時間。
	_timer = Timer.new()
	# 設定計時秒數。
	_timer.wait_time = _timer_length
	# 不在建立時自動開始，改由 enter() 控制。
	_timer.autostart = false
	# 計時到期只觸發一次，避免重複回呼。
	_timer.one_shot = true
	# （回呼內容）等待時間結束後，若期間按過攻擊就轉入攻擊狀態，否則回到預設狀態。
	_timer.timeout.connect(
		func():
			if _pressed_attack:
				parent_state.change_state(attack_state)
			else:
				parent_state.transition_to_default_state()
	)
	# 將計時器加入場景樹，讓它能正常計時並發出 timeout 訊號。
	add_child(_timer)


# enter：狀態機進入本狀態時呼叫，開始計時、打斷攻擊並清除上次的輸入紀錄。
func enter() -> void:
	# 開始短暫等待；倒數結束時會由 timeout 回呼決定下一個狀態。
	_timer.start()
	# 停止當前近戰攻擊，避免被彈開後原攻擊繼續執行。
	player.melee_component.interrupt_attack()
	# 每次進入狀態都重新等待新一輪的攻擊輸入。
	_pressed_attack = false


# process_player：狀態活動期間由狀態機逐次處理玩家輸入。
func process_player() -> void:
	# 如果玩家此刻剛按下攻擊，先記錄輸入，等計時結束再接續攻擊。
	if Input.is_action_just_pressed("attack"):
		_pressed_attack = true


# exit：離開本狀態時呼叫；停止計時器，避免舊的 timeout 回呼干擾後續狀態。
func exit() -> void:
	_timer.stop()
