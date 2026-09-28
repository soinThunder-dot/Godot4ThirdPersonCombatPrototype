# ==========================================================
# 【檔案說明】player_block_state.gd
# 這是玩家的「格擋狀態」腳本，負責啟用盾牌格擋、處理承受攻擊時的反應，
# 並控制格擋期間的移動動畫與狀態切換。受到攻擊後會短暫等待，再允許不穩定度
# 恢復；玩家也可在格擋中轉為招架、閃避或攻擊。
# 它是 PlayerStateMachine 的子狀態，透過 parent_state 交由上層狀態機管理切換。
# ==========================================================

# 註冊為可供其他腳本引用的 PlayerBlockState 類別。
class_name PlayerBlockState
# 繼承 PlayerStateMachine，沿用玩家狀態機的生命週期與狀態轉換功能。
extends PlayerStateMachine


# parry_state：從格擋轉為招架時要進入的玩家狀態。
@export var parry_state: PlayerParryState
# dodge_state：從格擋開始閃避時要進入的玩家狀態。
@export var dodge_state: PlayerDodgeState
# attack_state：從格擋開始攻擊時要進入的玩家狀態。
@export var attack_state: PlayerAttackState
# movement_animations：格擋時用來調整行走動畫速度的動畫資源參照。
@export var movement_animations: MovementAnimations

# blocking_sfx：進入格擋時播放的音效播放器。
@export var blocking_sfx: AudioStreamPlayer
# block_sfx：成功格擋受到攻擊時播放的 3D 音效播放器。
@export var block_sfx: AudioStreamPlayer3D

# 不穩定度在恢復期間採用的降低速率。
var _reduction_rate: float = 0.2
# 延遲恢復不穩定度的計時器；玩家受擊或進入格擋時會重新啟動。
var _pause_before_reducing_instability_timer: Timer
# 受擊或格擋開始後，等待多久才重新允許不穩定度降低（秒）。
var _pause_before_reducing_instability_length: float = 3.0

# 儲存進入格擋前的動畫速度，離開狀態時用來還原。
var _prev_anim_walk_speed: float


# _ready() 在節點準備完成時由 Godot 呼叫；此處建立計時器並連接受擊訊號。
func _ready():
	# 先執行父狀態機的初始化。
	super._ready()
	
	# 建立一個由本狀態管理的計時器節點。
	_pause_before_reducing_instability_timer = Timer.new()
	# 設定計時器等待時間為上方定義的延遲秒數。
	_pause_before_reducing_instability_timer.wait_time = \
		_pause_before_reducing_instability_length
	# 不進入場景樹時自動啟動，必須由程式明確呼叫 start()。
	_pause_before_reducing_instability_timer.autostart = false
	# 計時一次後停止，避免重複觸發 timeout。
	_pause_before_reducing_instability_timer.one_shot = true
	# （回呼內容）等待時間結束後，重新允許降低不穩定度並套用指定的降低速率。
	_pause_before_reducing_instability_timer.timeout.connect(
		func():
			player.instability_component.reduce_instability = true
			player.instability_component.reduction_rate = _reduction_rate
	)
	# 必須把新建立的 Timer 加入場景樹，計時器才會由 Godot 執行。
	add_child(_pause_before_reducing_instability_timer)
	
	# （回呼內容）玩家碰撞箱收到傷害來源時，只有本格擋狀態仍為目前狀態才處理；接著依攻擊來源施加擊退、重新等待不穩定度恢復、通知盾牌已格擋、更新不穩定度並播放受擊格擋音效。
	player.hitbox_component.damage_source_hit.connect(
		func(incoming_damage_source: DamageSource):
			if parent_state.current_state != self: return
			
			player.locomotion_component.knockback(
				incoming_damage_source.damage_attributes.knockback,
				incoming_damage_source.entity.global_position
			)
			
			_pause_before_reducing_instability_timer.start()
			
			player.shield_component.blocked()
			player.instability_component.reset_reduction_rate()
			player.instability_component.increment_instability(
				incoming_damage_source.damage_attributes.block_instability
			)
			print(incoming_damage_source.damage_attributes.block_instability)
			
			block_sfx.play()
	)


# enter() 在格擋狀態開始時呼叫；啟用盾牌、停止攻擊並啟動恢復延遲計時。
func enter() -> void:
	# 告知盾牌元件玩家正在格擋。
	player.shield_component.blocking = true
	# 格擋開始時中斷尚未完成的近戰攻擊。
	player.melee_component.interrupt_attack()
	# 啟動一次性計時器，等待指定時間後再允許不穩定度降低。
	_pause_before_reducing_instability_timer.start()
	
	# 保存目前行走動畫速度，離開格擋狀態時才能還原。
	_prev_anim_walk_speed = movement_animations.speed
	
	# 播放持續格擋狀態的音效。
	blocking_sfx.play()


# process_player() 逐次檢查輸入；依招架、放開格擋、閃避、攻擊的條件切換狀態。
func process_player() -> void:
	# 剛按下格擋鍵時，將格擋動作轉成招架。
	if Input.is_action_just_pressed("block"):
		parent_state.change_state(parry_state)
		return
	
	# 若已放開格擋鍵且招架元件沒有判定為連續觸發，就回到預設狀態。
	if not Input.is_action_pressed("block") and \
	not player.parry_component.is_spamming():
		parent_state.transition_to_default_state()
		return
	
	# 剛按下跑步鍵時，改進閃避狀態。
	if Input.is_action_just_pressed("run"):
		parent_state.change_state(dodge_state)
		return
	
	# 剛按下攻擊鍵時，改進攻擊狀態。
	if Input.is_action_just_pressed("attack"):
		parent_state.change_state(attack_state)
		return
	
	# 格擋期間持續讓玩家朝鎖定目標設定面向與旋轉方向。
	player.set_rotation_target_to_lock_on_target()
	player.set_rotate_towards_target_if_lock_on_target()


# process_movement_animations() 更新格擋期間的行走動畫方向、狀態與播放速度。
func process_movement_animations() -> void:
	# 鎖定目標存在時，啟用閒置動畫系統的鎖定模式。
	var locked_on: bool = player.lock_on_target != null
	player.character.idle_animations.active = locked_on
	# 取得玩家目前的輸入移動方向，供動畫使用。
	var dir: Vector3 = player.input_direction
	# 沒有鎖定目標且有明顯移動輸入時，讓動畫方向改為固定的前方。
	if not locked_on and dir.length() > 0.05:
		dir = Vector3.FORWARD
	# 設定角色移動動畫方向並播放 walk 動作。
	player.character.movement_animations.dir = dir
	player.character.movement_animations.set_state("walk")
	# 格擋時將行走動畫速度設為一般速度的一半。
	movement_animations.speed = 0.5


# exit() 在離開格擋狀態時呼叫；停止計時與持續音效、清除格擋並還原設定。
func exit() -> void:
	# 離開時停止尚未完成的恢復延遲計時。
	_pause_before_reducing_instability_timer.stop()
	# 將不穩定度恢復速率交回元件的預設設定。
	player.instability_component.reset_reduction_rate()
	# 通知盾牌元件玩家已不再格擋。
	player.shield_component.blocking = false
	# 停止格擋期間的持續音效。
	blocking_sfx.stop()
	# 還原進入格擋前的動畫速度。
	movement_animations.speed = _prev_anim_walk_speed
