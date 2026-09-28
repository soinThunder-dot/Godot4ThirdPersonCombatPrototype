# ==========================================================
# 【檔案說明】player_death_state.gd
# 這是玩家生命值歸零後使用的死亡狀態。
# 它作為 PlayerStateMachine 的子狀態，負責播放死亡動畫與死亡畫面，
# 暫停戰鬥相關控制，並在離開死亡狀態時恢復必要的玩家與鎖定系統功能。
# ==========================================================

# 註冊這個狀態的全域類別名稱，供其他腳本辨識與引用。
class_name PlayerDeathState
# 繼承玩家狀態機，使用共用的狀態切換與生命週期流程。
extends PlayerStateMachine


# 可在 Inspector 指定暈眩／受擊音效播放器；生命值歸零且不穩定值已滿時播放。
@export var dizzy_hit_sfx: AudioStreamPlayer3D


# _ready：節點初始化時呼叫；先初始化父狀態機，再連接生命值、死亡畫面與動畫訊號。
func _ready():
	# 呼叫父類別初始化，設定狀態機的子狀態資訊。
	super._ready()
	
	# （回呼內容）生命值歸零時，如果已經在死亡狀態就不重複切換；否則切入本狀態。
	player.health_component.zero_health.connect(
		func():
			if parent_state.current_state == self: return
			parent_state.change_state(self)
	)
	
	# （回呼內容）按下死亡畫面的重生操作時，僅在本狀態仍有效時重設死亡動畫，並讓坐下動畫混合回待機。
	Globals.user_interface.death_screen.respawn.connect(
		func():
			if parent_state.current_state != self: return
			player.character.hit_and_death_animations.reset_death()
			player.character.sit_animations.blend_to_idle()
	)
	
	# （回呼內容）死亡畫面要求起身時，僅在本狀態仍有效時播放起身動畫。
	Globals.user_interface.death_screen.stand_up.connect(
		func():
			if parent_state.current_state != self: return
			player.character.sit_animations.stand_up()
	)
	
	# （回呼內容）坐下動畫結束時，若玩家仍在死亡狀態，切回父狀態機的預設狀態。
	player.character.sit_animations.finished.connect(
		func():
			if parent_state.current_state != self: return
			parent_state.transition_to_default_state()
	)


# enter：進入死亡狀態時切換移動策略、停用戰鬥控制並顯示死亡畫面。
func enter() -> void:
	# 使用根運動策略，使死亡動作可由角色動畫控制位移。
	player.locomotion_component.set_active_strategy("root_motion")
	
	# 清除鎖定目標並停用鎖定系統，避免死亡時繼續操作目標。
	Globals.lock_on_system.reset_target()
	Globals.lock_on_system.enabled = false
	
	# 關閉武器傷害、角色旋轉、頭部旋轉與受擊盒。
	player.weapon.can_damage = false
	player.rotation_component.can_rotate = false
	player.head_rotation_component.enabled = false
	player.hitbox_component.enabled = false
	
	# 播放死亡動畫並啟動死亡畫面。
	player.character.hit_and_death_animations.death_1()
	
	Globals.user_interface.death_screen.play_death_screen()
	
	# 設定旋轉目標為鎖定目標後，關閉朝向目標旋轉。
	player.set_rotation_target_to_lock_on_target()
	player.rotation_component.rotate_towards_target = false
	
	# 淡出背景音樂，讓死亡情境的聲音效果更清楚。
	Globals.music_system.fade_out()
	
	# 若不穩定值已滿，播放 HUD 的滿值效果並播放指定音效。
	if player.instability_component.is_full_instability():
		Globals.user_interface.hud.instability_bar.play_max_instability()
		dizzy_hit_sfx.play()


# process_player：死亡狀態不執行額外的逐影格玩家邏輯。
func process_player() -> void:
	pass


# process_movement_animations：更新待機動畫是否啟用，並將移動方向歸零以停止移動動畫。
func process_movement_animations() -> void:
	player.character.idle_animations.active = player.lock_on_target != null
	player.character.movement_animations.dir = Vector3.ZERO


# exit：離開死亡狀態時恢復一般移動、鎖定、旋轉、頭部控制與受擊盒。
func exit() -> void:
	# 恢復程式控制的移動策略。
	player.locomotion_component.set_active_strategy("programmatic")
	
	# 重新啟用鎖定系統與玩家的旋轉、頭部旋轉和受擊盒。
	Globals.lock_on_system.enabled = true
	
	player.rotation_component.can_rotate = true
	player.head_rotation_component.enabled = true
	player.hitbox_component.enabled = true
	
	# 只有存在目前檢查點時才重新顯示其提示。
	if Globals.checkpoint_system.current_checkpoint:
		Globals.checkpoint_system.enable_hint()
