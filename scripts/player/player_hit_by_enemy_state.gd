# ==========================================================
# 【檔案說明】player_hit_by_enemy_state.gd
# 這是玩家受到敵人攻擊後的受擊狀態。
# 它作為 PlayerStateMachine 的子狀態，保存造成受擊的傷害來源、套用傷害與擊退，
# 並在受擊硬直快結束時開放格擋／招架輸入，最後依玩家輸入或狀況切換到其他狀態。
# ==========================================================

# 註冊這個狀態的全域類別名稱，供其他腳本辨識與引用。
class_name PlayerHitByEnemyState
# 繼承玩家狀態機，使用共用的狀態切換與生命週期流程。
extends PlayerStateMachine


# 可在 Inspector 指定攻擊狀態，受擊期間按下攻擊後可在計時結束時切入。
@export var attack_state: PlayerAttackState
# 可在 Inspector 指定格擋狀態，受擊期間按住格擋可切入。
@export var block_state: PlayerBlockState
# 可在 Inspector 指定招架狀態，受擊期間剛按下格擋可切入。
@export var parry_state: PlayerParryState
# 可在 Inspector 指定暈眩狀態；不穩定值滿時會切入。
@export var dizzy_state: PlayerDizzyState
# 可在 Inspector 指定死亡狀態；玩家生命值歸零時會切入。
@export var death_state: PlayerDeathState

# 可在 Inspector 指定 3D 音效播放器，進入受擊狀態時播放。
@export var sfx: AudioStreamPlayer3D

# 保存造成這次受擊的傷害來源，供套用傷害與擊退資料使用。
var _incoming_damage_source: DamageSource

# 記錄目前是否已進入可格擋或招架的時間窗口。
var _can_block_or_parry: bool = false

# 保存受擊硬直計時器參照，用來啟動、檢查與停止倒數。
var _timer: Timer
# 受擊硬直計時器的秒數；預設為 0.8 秒。
var _timer_length: float = 0.8

# 記錄受擊期間是否按下攻擊；若有，計時結束後接續攻擊狀態。
var _pressed_attack: bool = false


# _ready：節點初始化時呼叫；連接受擊訊號並建立一次性硬直計時器。
func _ready():
	# 先執行父狀態機初始化，設定本狀態與父狀態的關係。
	super._ready()
	
	# （回呼內容）受擊盒收到傷害來源時，若玩家不在特定格擋、招架或暈眩狀態，就保存來源並切入受擊狀態。
	player.hitbox_component.damage_source_hit.connect(
		func(incoming_damage_source: DamageSource):
			if not parent_state.current_state is PlayerParriedEnemyHitState and \
			not parent_state.current_state is PlayerParryState and \
			not parent_state.current_state is PlayerBlockState and \
			not parent_state.current_state is PlayerDizzyState:
				_incoming_damage_source = incoming_damage_source
				parent_state.change_state(self)
	)
	
	# 建立計時器並設定硬直時間；one_shot 讓計時只倒數一次，不自動重複。
	_timer = Timer.new()
	_timer.wait_time = _timer_length
	_timer.autostart = false
	_timer.one_shot = true
	# （回呼內容）計時結束時若仍在本狀態，依是否曾按攻擊決定接續攻擊或回到預設狀態。
	_timer.timeout.connect(
		func():
			if parent_state.current_state != self: return
			if _pressed_attack:
				parent_state.change_state(attack_state)
			else:
				parent_state.transition_to_default_state()
	)
	# 將計時器加入節點樹，讓它能依 Godot 的計時機制運作。
	add_child(_timer)


# enter：進入受擊狀態時套用傷害、累積不穩定值、擊退角色並啟動硬直計時器。
func enter() -> void:
	# 每次受擊都先關閉格擋／招架窗口，等待硬直快結束時再開放。
	_can_block_or_parry = false
	
	# 依傷害來源套用傷害，並增加此攻擊設定的不穩定值。
	player.health_component.incoming_damage(_incoming_damage_source)
	player.instability_component.increment_instability(
		_incoming_damage_source.damage_attributes.hit_instability
	)
	
	# 暫時禁止移動，並依傷害來源設定擊退幅度與攻擊者位置。
	player.locomotion_component.can_move = false
	player.locomotion_component.knockback(
		_incoming_damage_source.damage_attributes.knockback,
		_incoming_damage_source.entity.global_position
	)
	# 播放受擊動畫並中斷目前近戰攻擊。
	player.character.hit_and_death_animations.hit()
	player.melee_component.interrupt_attack()
	
	# 清除前一次受擊可能留下的排隊攻擊輸入。
	_pressed_attack = false
	
	# 播放受擊音效並開始硬直計時。
	sfx.play()
	
	_timer.start()


# process_player：逐影格檢查死亡、暈眩、反應窗口與戰鬥輸入，並更新鎖定朝向。
func process_player() -> void:
	# 玩家生命值已歸零時優先切換到死亡狀態，並結束本影格後續檢查。
	if not player.health_component.is_alive():
		parent_state.change_state(death_state)
		return
	
	# 不穩定值已滿時切換到暈眩狀態，避免繼續處理受擊輸入。
	if player.instability_component.is_full_instability():
		parent_state.change_state(dizzy_state)
		return
	
	# 計時器剩餘時間不超過 0.25 秒時，開放格擋與招架反應窗口。
	if _timer.time_left <= 0.25:
		_can_block_or_parry = true
	
	# 只有反應窗口開啟後才接受格擋輸入；剛按下代表招架，持續按住代表格擋。
	if _can_block_or_parry:
		if Input.is_action_just_pressed("block"):
			parent_state.change_state(parry_state)
			return
		
		if Input.is_action_pressed("block"):
			parent_state.change_state(block_state)
			return
	
	# 記錄受擊期間剛按下的攻擊，供硬直計時結束時接續攻擊。
	if Input.is_action_just_pressed("attack"):
		_pressed_attack = true
	
	# 更新玩家旋轉目標，使受擊期間仍朝向目前的鎖定目標。
	player.set_rotation_target_to_lock_on_target()


# process_movement_animations：維持鎖定待機動畫狀態並將移動方向歸零，表現受擊硬直。
func process_movement_animations() -> void:
	player.character.idle_animations.active = player.lock_on_target != null
	player.character.movement_animations.dir = Vector3.ZERO


# exit：離開受擊狀態時恢復玩家移動能力並停止硬直計時器。
func exit() -> void:
	player.locomotion_component.can_move = true
	_timer.stop()
