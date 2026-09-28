# ==========================================================
# 【檔案說明】player_parried_enemy_hit_state.gd
# 這是玩家成功格擋／彈開敵人攻擊後的反應狀態，負責呈現格擋特效、音效、動畫與擊退。
# ParryComponent 收到成功彈開攻擊的訊號時，會保存該次傷害來源並視暈眩狀況進入本狀態。
# 狀態期間可優先接續暈眩終結技，也可依攻擊、格擋或奔跑輸入切換到對應狀態；
# 若沒有提早切換，短計時器到期後會回到父狀態機的預設狀態。
# ==========================================================

# 註冊為可在 Godot 中識別的 PlayerParriedEnemyHitState 類別。
class_name PlayerParriedEnemyHitState
# 繼承玩家狀態機基底，以便透過父狀態機切換玩家狀態。
extends PlayerStateMachine


# 在 Inspector 指定玩家移動元件；本狀態會調整其移動速度並設定擊退。
@export var locomotion_component: LocomotionComponent

# 在 Inspector 指定玩家可接續進入的攻擊、格擋、反擊、閃避與暈眩終結技狀態。
@export var attack_state: PlayerAttackState
@export var block_state: PlayerBlockState
@export var parry_state: PlayerParryState
@export var dodge_state: PlayerDodgeState
@export var dizzy_finisher_state: PlayerDizzyFinisherState

# 在 Inspector 指定目標暈眩時採用的預設擊退設定。
@export var default_knockback: SecondaryMovement
# 在 Inspector 指定成功彈開攻擊時播放的 3D 音效播放器。
@export var sfx: AudioStreamPlayer3D

# 保存觸發本狀態的敵方傷害來源，稍後用來讀取反擊數值與施加擊退。
var _incoming_damage_source: DamageSource

# 儲存離開本狀態前的等待計時器。
var _timer: Timer
# 本狀態預設持續 0.5 秒；玩家也可在時間內輸入動作提早轉換。
var _timer_length: float = 0.5

# 從全域 Globals 取得暈眩系統，供狀態判斷暈眩目標與終結技是否已準備完成。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# _ready：節點準備完成時由 Godot 呼叫；連接格擋相關訊號並建立一次性計時器。
func _ready():
	# 先執行父類別初始化，建立狀態機共用設定。
	super._ready()
	
	# （回呼內容）成功彈開敵方攻擊時保存傷害來源；若目前沒有暈眩目標，就進入本狀態。
	player.parry_component.parried_incoming_hit.connect(
		func(incoming_damage_source: DamageSource):
			_incoming_damage_source = incoming_damage_source
			if Globals.dizzy_system.dizzy_victim == null:
				parent_state.change_state(self)
	)
	
	# （回呼內容）本狀態仍是目前狀態且玩家受擊時，播放格擋音效並更新盾牌格擋狀態。
	player.hitbox_component.damage_source_hit.connect(
		func(_damage_source: DamageSource):
			if parent_state.current_state != self: return
			block_state.block_sfx.play()
			player.shield_component.blocking = true
			player.shield_component.blocked()
	)
	
	# 建立專屬計時器；時間到時回到此父狀態機的預設子狀態。
	_timer = Timer.new()
	# 設定等待長度。
	_timer.wait_time = _timer_length
	# 不自動開始，由 enter() 在真正進入狀態時啟動。
	_timer.autostart = false
	# 只計時一次，避免計時到期後重複切換狀態。
	_timer.one_shot = true
	# （回呼內容）本狀態沒有被其他輸入提早切走時，計時結束後返回預設狀態。
	_timer.timeout.connect(
		func(): parent_state.transition_to_default_state()
	)
	# 將 Timer 加入場景樹以啟用計時。
	add_child(_timer)


# enter：進入成功彈開攻擊的狀態時，套用移動、反擊、動畫、擊退、音效並開始計時。
func enter() -> void:
	# 降低移動速度，呈現格擋反應期間的移動限制。
	locomotion_component.speed = 3
	# 進入後將盾牌設為格擋中。
	player.shield_component.blocking = true
	
	# 將敵方攻擊屬性中的 parry_instability 數值套用到玩家的失衡處理。
	player.instability_component.process_parry(
		_incoming_damage_source.damage_attributes.parry_instability
	)
	
	# 重設玩家反擊冷卻，並播放反擊粒子效果。
	player.parry_component.reset_parry_cooldown()
	player.parry_component.play_parry_particles()
	
	# 播放角色專用的反擊動畫。
	player.character.parry_animations.parry()
	
	# 啟用盾牌透明度動畫並播放名為「parried」的盾牌動畫。
	player.shield_component.animating_opacity = true
	player.shield_component.play_animation("parried")
	
	# 通知傷害來源已被成功彈開，讓來源端執行其對應處理。
	_incoming_damage_source.get_parried()
	# 若目前存在暈眩目標，先重設次級移動，再使用此狀態設定的預設擊退。
	if dizzy_system.dizzy_victim:
		locomotion_component.reset_secondary_movement()
		player.locomotion_component.knockback(
			default_knockback,
			_incoming_damage_source.entity.global_position
		)
	# 若沒有暈眩目標，則改用這次敵方攻擊自身的擊退屬性。
	else:
		player.locomotion_component.knockback(
			_incoming_damage_source.damage_attributes.knockback,
			_incoming_damage_source.entity.global_position
		)
	
	# 播放成功彈開攻擊的音效。
	sfx.play()
	
	# 啟動計時，若期間沒有其他狀態切換，時間到會返回預設狀態。
	_timer.start()


# process_player：狀態活動期間檢查玩家輸入；依優先順序切換到終結技、攻擊、反擊或閃避。
func process_player() -> void:
	# 暈眩目標存在且終結技已準備好時，優先開始終結技並結束本次輸入處理。
	if dizzy_system.dizzy_victim and dizzy_system.readied_finisher:
		parent_state.change_state(dizzy_finisher_state)
		return
	
	# 玩家按下攻擊時切換至攻擊狀態；return 避免同一影格又處理其他按鍵。
	if Input.is_action_just_pressed("attack"):
		parent_state.change_state(attack_state)
		return
		
	# 玩家按下格擋時切換到反擊狀態（此處使用指定的 parry_state）。
	if Input.is_action_just_pressed("block"):
		parent_state.change_state(parry_state)
		return
	
	# 玩家按下奔跑時先清除次級移動，再切換到閃避狀態。
	if Input.is_action_just_pressed("run"):
		player.locomotion_component.reset_secondary_movement()
		parent_state.change_state(dodge_state)
		return


# exit：離開狀態時關閉盾牌透明度動畫與格擋旗標，並停止計時器。
func exit() -> void:
	# 關閉盾牌透明度動畫，避免離開後仍沿用本狀態的動畫設定。
	player.shield_component.animating_opacity = false
	# 清除格擋旗標，讓後續狀態不會誤以為玩家仍在格擋。
	player.shield_component.blocking = false
	# 中止計時，避免離開狀態後 timeout 再次要求切換。
	_timer.stop()
