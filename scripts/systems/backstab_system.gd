# ==========================================================
# 【檔案說明】backstab_system.gd
# 這是「背刺系統」的腳本。
# 它負責決定「目前哪一個敵人可以被玩家背刺」（背刺目標 / victim）。
# 運作方式：
#   - 每個敵人身上有 BackstabComponent（背刺元件），當玩家走到敵人背後的
#     範圍內時，元件會呼叫 set_backstab_victim() 來「報名」成為背刺目標。
#   - 本系統依一連串條件篩選（鎖定目標、距離、是否正在攻擊、敵人是否存活、
#     敵人是否已發現玩家…），最後只保留「一個」背刺目標。
#   - 目標改變時發出 current_victim 訊號，讓其他系統（如 UI、玩家狀態）知道。
# ==========================================================

# 註冊為全域類別 BackstabSystem。
class_name BackstabSystem
# 繼承 Node3D（3D 節點）。
extends Node3D


# current_victim：背刺目標改變時發出，參數是新的目標（沒有目標時為 null）。
signal current_victim(victim: BackstabComponent)

# backstab_victim：目前的背刺目標（敵人身上的背刺元件），null 代表沒有。
var backstab_victim: BackstabComponent

# _current_dist_to_player：目前背刺目標與玩家的距離。
# 預設 10（一個夠大的值），用來和新候選目標比較「誰比較近」。
var _current_dist_to_player: float = 10
# _can_switch_victim：目前是否允許切換背刺目標。
# 背刺目標死亡後會暫時鎖住 1 秒，避免立刻跳到下一個敵人。
var _can_switch_victim: bool = true

# _player_melee_component：玩家的近戰元件，用來判斷玩家是否正在攻擊中。
@onready var _player_melee_component: MeleeComponent = Globals.player.melee_component

# （以下是 Godot 預設產生的英文註解：每個影格都會呼叫，delta 是距上一影格的秒數。）
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	
	# 如果有背刺目標，但它已經死亡：
	if backstab_victim and not backstab_victim.health_component.is_alive():
		# 清除目標。
		backstab_victim = null
		# 暫時禁止切換目標。
		_can_switch_victim = false
		# 建立 1 秒計時器，時間到後才重新允許切換目標。
		var timer: SceneTreeTimer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): _can_switch_victim = true)
	
	# 沒有背刺目標時：
	if not backstab_victim:
		# 通知外部「目前沒有目標」。
		current_victim.emit(null)
		# 距離重設為預設的大數值。
		_current_dist_to_player = 10
		# 直接結束，下面的距離計算不需要做。
		return
	
	# 有目標時：每影格更新目標（entity = 敵人本體）與玩家之間的距離。
	# 反斜線「\」是換行接續符號，讓一行長程式碼可以分成多行寫。
	_current_dist_to_player = backstab_victim\
		.entity\
		.global_position\
		.distance_to(Globals.player.global_position)


# set_backstab_victim(victim, dist)：由敵人的背刺元件呼叫，嘗試成為背刺目標。
# victim：想成為目標的背刺元件；dist：它與玩家的距離。
# 函式中有很多「return」，代表不符合條件就直接放棄，不改變目前目標。
func set_backstab_victim(victim: BackstabComponent, dist: float) -> void:
	# （下一行是作者留下的除錯輸出，已被註解停用。）
#	if backstab_victim: prints(victim.get_parent().name, backstab_victim.get_parent().name, dist, _current_dist_to_player)
	
	# 取得鎖定系統目前鎖定的目標。
	var lock_on_system_target: LockOnComponent = Globals.lock_on_system.target
	# 條件 1：如果玩家有鎖定某個敵人，而且鎖定的「不是」這個候選敵人：
	if lock_on_system_target and \
	lock_on_system_target.component_owner != victim.entity:
		
		# 若目前的背刺目標也不是被鎖定的那個敵人，就清掉它
		# （有鎖定時，只允許背刺被鎖定的那個敵人）。
		if backstab_victim and \
		backstab_victim.entity != lock_on_system_target.component_owner:
			backstab_victim = null
		
		# 這個候選敵人不符合，放棄。
		return
	
	# 條件 2：沒有鎖定時，候選敵人必須比目前目標「更近」才會取代
	# （減 0.02 是一點容差，避免兩個距離差不多的敵人來回跳動）。
	if not lock_on_system_target and dist > _current_dist_to_player - 0.02:
		return
	
	# 條件 3：目前沒有背刺目標、而玩家正在攻擊中 → 不設定新目標
	# （避免攻擊動作途中突然變成背刺）。
	if not backstab_victim and _player_melee_component.attacking:
		return
	
	# 條件 4：候選敵人已經死亡 → 放棄。
	if not victim.health_component.is_alive():
		return
		
	# 條件 5：候選敵人已處於「仇恨（Aggro）」狀態，也就是已經發現玩家 → 不能背刺。
	if victim.notice_component.current_state is NoticeComponentAggroState:
		return
	
	# 條件 6：候選敵人本來就是目前的目標 → 不需重複設定。
	if victim == backstab_victim:
		return
	
	# 條件 7：目前處於禁止切換的冷卻時間 → 放棄。
	if not _can_switch_victim:
		return
	
	# 全部條件都通過：設定新的背刺目標並記錄距離。
	backstab_victim = victim
	_current_dist_to_player = dist
	
	# 通知外部背刺目標已改變。
	current_victim.emit(victim)


# clear_backstab_victim(victim)：由敵人的背刺元件呼叫（例如玩家離開其背後範圍）。
func clear_backstab_victim(victim: BackstabComponent) -> void:
	# 只有當它正是目前的目標時才清除，避免誤清掉別的敵人。
	if victim == backstab_victim:
		backstab_victim = null
