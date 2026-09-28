# ==========================================================
# 【檔案說明】player_parry_state.gd
# 這是玩家的「招架狀態」腳本，負責啟動招架動作、維持盾牌格擋旗標，並在
# 受到攻擊時施加擊退。招架窗口結束後，依玩家是否仍按住格擋鍵，轉入一般格擋
# 或回到預設狀態；若招架已備妥暈眩處決，也會切換至對應處決狀態。
# 它是 PlayerStateMachine 的子狀態，透過 parent_state 請上層狀態機執行切換。
# ==========================================================

# 註冊為可供其他腳本引用的 PlayerParryState 類別。
class_name PlayerParryState
# 繼承 PlayerStateMachine，沿用玩家狀態機的生命週期與切換流程。
extends PlayerStateMachine


# block_state：招架窗口結束但玩家仍按住格擋時要進入的一般格擋狀態。
@export var block_state: PlayerBlockState
# dizzy_finisher_state：招架成功且處決已備妥時要切換到的處決狀態。
@export var dizzy_finisher_state: PlayerStateMachine

# 在節點進入場景樹時取得遊戲共用的暈眩系統參照。
@onready var dizzy_system: DizzySystem = Globals.dizzy_system

# _ready() 在節點準備完成時由 Godot 呼叫；初始化父狀態並監聽碰撞箱受擊訊號。
func _ready():
	# 先執行父狀態機的初始化。
	super._ready()
	
	# （回呼內容）碰撞箱收到傷害來源時，只有本招架狀態正是上層狀態機目前的狀態，才依傷害來源的擊退數值與敵人位置對玩家施加擊退。
	player.hitbox_component.damage_source_hit.connect(
		func(incoming_damage_source: DamageSource):
			if parent_state.current_state == self:
				player.locomotion_component.knockback(
					incoming_damage_source.damage_attributes.knockback,
					incoming_damage_source.entity.global_position
				)
	)


# enter() 在進入招架狀態時呼叫；啟動招架判定、設定盾牌格擋並中斷攻擊。
func enter() -> void:
	# 通知招架元件開始執行招架，並由元件管理招架窗口。
	player.parry_component.parry()
	# 招架期間也標記盾牌為格擋中。
	player.shield_component.blocking = true
	# 中斷進入招架前尚未完成的近戰攻擊。
	player.melee_component.interrupt_attack()


# process_player() 逐次處理招架輸入、招架窗口、面向及暈眩處決條件。
func process_player() -> void:
	# 剛按下格擋鍵，且目前沒有攻擊或近戰元件能停止攻擊時，再觸發一次招架。
	if Input.is_action_just_pressed("block") and (
		not player.melee_component.attacking or \
		player.melee_component.stop_attacking()
	):
		# 輸出除錯訊息，並再次呼叫招架元件。
		print("PLEASE PARRY")
		player.parry_component.parry()
		return
	
	# 招架窗口結束後，依格擋鍵是否仍按住來決定後續狀態。
	if not player.parry_component.in_parry_window:
		# 仍按住格擋鍵就接續一般格擋狀態。
		if Input.is_action_pressed("block"):
			parent_state.change_state(block_state)
		else:
			# 已放開格擋鍵就回到上層狀態機的預設狀態。
			parent_state.transition_to_default_state()
		return
	
	# 招架窗口尚未結束時，持續將玩家的旋轉目標設為鎖定目標。
	player.set_rotation_target_to_lock_on_target()
	
	# 若暈眩系統有目標且已準備好處決，切換到指定處決狀態。
	if dizzy_system.dizzy_victim and dizzy_system.readied_finisher:
		parent_state.change_state(dizzy_finisher_state)


# exit() 在離開招架狀態時呼叫，清除盾牌仍在格擋中的旗標。
func exit() -> void:
	# 離開招架後，通知盾牌元件不再處於格擋狀態。
	player.shield_component.blocking = false
