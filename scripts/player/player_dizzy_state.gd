# ==========================================================
# 【檔案說明】player_dizzy_state.gd
# 這是玩家進入暈眩時使用的狀態，負責暫停一般操控、播放暈眩效果並計時。
# 暈眩期間會處理受到攻擊時的擊退、受擊動畫與傷害；若從格擋狀態進入，則略過一次傷害。
# 計時結束後回到父狀態機的預設狀態；離開時恢復轉向與移動策略，並清除暈眩 UI、特效和音效。
# 本腳本以訊號連接接收不穩定值與受擊事件，並透過 Timer 控制暈眩持續時間。
# ==========================================================

# 註冊為可在其他腳本與場景中引用的 PlayerDizzyState 類別。
class_name PlayerDizzyState
# 繼承玩家狀態機節點，讓暈眩狀態參與玩家狀態切換。
extends PlayerStateMachine


# 暈眩狀態的持續秒數；進入時會用這個值設定內部計時器。
@export var dizzy_length: float = 3.0

# 一般攻擊狀態的場景引用；本檔案目前保留此匯出欄位供狀態設定使用。
@export var attack_state: PlayerAttackState
# 格擋狀態的場景引用；本檔案目前保留此匯出欄位供狀態設定使用。
@export var block_state: PlayerBlockState
# 招架狀態的場景引用；本檔案目前保留此匯出欄位供狀態設定使用。
@export var parry_state: PlayerParryState

# 暈眩星星特效節點，進入與離開暈眩時會啟用或關閉。
@export var dizzy_stars: DizzyStars

# 玩家一般受擊時播放的 3D 音效播放器。
@export var hit_sfx: AudioStreamPlayer3D
# 進入暈眩時播放的 3D 音效播放器。
@export var dizzy_hit_sfx: AudioStreamPlayer3D
# 暈眩期間播放並淡出的音效播放器（非 3D 節點）。
@export var dizzy_sfx: AudioStreamPlayer

# _timer：暈眩倒數計時器，在 _ready 建立並於 enter 啟動。
var _timer: Timer

# _dizzy_sfx_tween：控制暈眩音效音量淡出的 Tween；可在重新進入時停止舊動畫。
var _dizzy_sfx_tween: Tween
# _default_dizzy_sfx_volume：保存音效原始音量，重新播放前用來還原。
var _default_dizzy_sfx_volume: float

# _skip_damage：若進入前一個狀態是格擋，暈眩受擊回呼會消耗此旗標並略過一次傷害。
var _skip_damage: bool = false


# _ready：節點初始化時呼叫；連接事件、建立計時器並保存初始效果設定。
func _ready():
	super._ready()
	
	# （回呼內容）當玩家不穩定值達到滿值時，若玩家未死亡且目前尚未暈眩，就切入本暈眩狀態。
	player.instability_component.full_instability.connect(
		func():
			if not parent_state.current_state is PlayerDeathState and \
			parent_state.current_state != self:
				parent_state.change_state(self)
	)
	
	# （回呼內容）僅在暈眩狀態有效時處理受擊：套用擊退、播放受擊動畫與音效；若需略過傷害則清除旗標後結束，否則將傷害交給生命元件。
	player.hitbox_component.damage_source_hit.connect(
		func(incoming_damage_source: DamageSource):
			if parent_state.current_state != self: return
			player.locomotion_component.knockback(
				incoming_damage_source.damage_attributes.knockback,
				incoming_damage_source.entity.global_position
			)
			player.character.hit_and_death_animations.hit()
			hit_sfx.play()
			if _skip_damage:
				_skip_damage = false
				return
			player.health_component.incoming_damage(incoming_damage_source)
	)
	
	# 建立暈眩倒數計時器，先設定時間與觸發模式，再連接逾時事件。
	_timer = Timer.new()
	# 設定暈眩持續時間；Timer 會在 start() 後依此秒數倒數。
	_timer.wait_time = dizzy_length
	# 不讓計時器建立後自行啟動，等待進入暈眩狀態時明確 start()。
	_timer.autostart = false
	# 設為單次計時，逾時後不會自動重複倒數。
	_timer.one_shot = true
	# （回呼內容）計時器逾時時，通知父狀態機回到預設狀態以結束暈眩。
	_timer.timeout.connect(
		func(): parent_state.transition_to_default_state()
	)
	# 將計時器加入場景樹，讓 Godot 開始管理其計時與訊號。
	add_child(_timer)
	
	# 初始化時先關閉頭頂暈眩星星特效。
	dizzy_stars.enabled = false
	# 保存暈眩音效的初始音量，供每次進入時重設。
	_default_dizzy_sfx_volume = dizzy_sfx.volume_db


# enter：切入暈眩狀態時呼叫；停止攻擊、鎖住轉向並啟動視覺、音訊與倒數效果。
func enter() -> void:
	# 中斷玩家目前正在進行的近戰攻擊。
	player.melee_component.interrupt_attack()
	# 暈眩期間禁止旋轉控制。
	player.rotation_component.can_rotate = false
	# 使用 root_motion 移動策略，讓移動依動畫根骨骼運動處理。
	player.locomotion_component.set_active_strategy("root_motion")
	# 播放由招架導致暈眩的受害者動畫。
	player.character.dizzy_victim_animations.dizzy_from_parry()
	
	# 在 HUD 上播放不穩定值達到上限的提示效果。
	Globals.user_interface.hud.instability_bar.play_max_instability()
	
	# 每次進入都先清除略過傷害旗標，避免前一次暈眩的狀態殘留。
	_skip_damage = false
	# 若前一個狀態是格擋，設定旗標讓暈眩期間收到的下一次傷害只播放受擊反應、不扣血。
	if parent_state.previous_state is PlayerBlockState:
		_skip_damage = true
	
	# 顯示暈眩星星特效。
	dizzy_stars.enabled = true
	
	# 播放進入暈眩時的短音效。
	dizzy_hit_sfx.play()
	# 若仍有上次的音量淡出 Tween，先停止它，避免和新一輪音量控制衝突。
	if _dizzy_sfx_tween: _dizzy_sfx_tween.kill()
	# 將持續暈眩音效音量還原至初始值，再開始播放。
	dizzy_sfx.volume_db = _default_dizzy_sfx_volume
	dizzy_sfx.play()
	
	# 啟動暈眩倒數；逾時後由前述 timeout 回呼返回預設狀態。
	_timer.start()


# process_player：暈眩期間更新玩家的旋轉目標，使其仍以鎖定目標作為面向參考。
func process_player() -> void:
	player.set_rotation_target_to_lock_on_target()


# process_movement_animations：暈眩期間停用一般移動方向動畫，並視鎖定狀態設定待機動畫。
func process_movement_animations() -> void:
	# 有鎖定目標時啟用待機動畫控制；沒有鎖定目標則停用。
	player.character.idle_animations.active = player.lock_on_target != null
	# 將移動動畫方向歸零，避免暈眩時仍顯示行走方向。
	player.character.movement_animations.dir = Vector3.ZERO


# exit：離開暈眩狀態時呼叫；恢復移動控制並清理暈眩期間啟用的 UI、特效與計時器。
func exit() -> void:
	# 重新允許旋轉元件控制角色朝向。
	player.rotation_component.can_rotate = true
	# 恢復一般程式控制的移動策略。
	player.locomotion_component.set_active_strategy("programmatic")
	# 關閉暈眩受害者動畫的暈眩混合效果。
	player.character.dizzy_victim_animations.disable_blend_dizzy()
	# 將滿值不穩定狀態重設為 0，作為暈眩結束的恢復處理。
	player.instability_component.come_out_of_full_instability(0)
	
	# 重設 HUD 不穩定值顯示，並隱藏量表。
	Globals.user_interface.hud.instability_bar.reset()
	Globals.user_interface.hud.instability_bar.hide_bar()
	
	# 關閉暈眩星星特效。
	dizzy_stars.enabled = false
	# 建立新的 Tween，將暈眩持續音效在 0.5 秒內淡至近乎無聲的 -80 dB。
	_dizzy_sfx_tween = create_tween()
	_dizzy_sfx_tween.tween_property(
		dizzy_sfx,
		"volume_db",
		-80,
		0.5
	)
	
	# 停止暈眩計時器，避免離開後仍發出逾時訊號。
	_timer.stop()
