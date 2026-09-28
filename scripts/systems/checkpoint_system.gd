# ==========================================================
# 【檔案說明】checkpoint_system.gd
# 這是「檢查點（存檔點）系統」的腳本，類似魂系遊戲的篝火機制。
# 主要負責：
#   1. 記錄玩家目前所在的檢查點，以及「已儲存」的重生檢查點。
#   2. 遊戲開始時把每個關卡的敵人「打包」成 PackedScene（像拍一張快照），
#      之後恢復時可以重新產生一批全新的敵人（敵人重生）。
#   3. 玩家死亡後：把玩家傳送回儲存的檢查點、重設相機與移動狀態，並執行恢復。
#   4. 恢復（_recover）：刪除舊敵人、重新產生敵人、補滿玩家血量等。
#   5. 控制互動提示的顯示、播放死亡音效。
# ==========================================================

# 註冊為全域類別 CheckpointSystem。
class_name CheckpointSystem
# 繼承 Node（最基本的節點）。
extends Node


# levels：所有關卡的根節點陣列（在編輯器設定），每個關卡底下要有 "Enemies" 節點。
@export var levels: Array[Node3D]
# initial_checkpoint：遊戲一開始的預設重生檢查點。
@export var initial_checkpoint: Checkpoint

# current_checkpoint：玩家「目前靠近」的檢查點（離開範圍時為 null）。
var current_checkpoint: Checkpoint
# saved_checkpoint：已儲存的重生點，玩家死亡後會回到這裡。
var saved_checkpoint: Checkpoint

# at_checkpoint：玩家是否正在檢查點「坐著休息」。
var at_checkpoint: bool = false

# _packed_enemies：每個關卡敵人的「快照」（PackedScene），用來重新產生敵人。
var _packed_enemies: Array[PackedScene]
# _enemies：每個關卡目前實際存在的 "Enemies" 節點。
var _enemies: Array[Node3D]

# death_sfx：死亡音效播放器。
@onready var death_sfx: AudioStreamPlayer = $DeathSfx

# 以下從全域單例 Globals 取得各系統參考。
# player：玩家。
@onready var player: Player = Globals.player
# camera_controller：相機控制器。
@onready var camera_controller: CameraController = Globals.camera_controller
# lock_on_system：鎖定系統。
@onready var lock_on_system: LockOnSystem = Globals.lock_on_system
# interaction_hints：HUD 上的互動提示（使用反斜線換行寫法取得深層節點）。
@onready var interaction_hints: InteractionHints = Globals\
	.user_interface\
	.hud\
	.interaction_hints
# checkpoint_interface：檢查點選單介面。
@onready var checkpoint_interface: CheckpointInterface = Globals\
	.user_interface\
	.checkpoint_interface


# 初始化。
func _ready():
	# 對每一個關卡：
	for level in levels:
		# 取得該關卡底下的 "Enemies" 節點（存放所有敵人）。
		var enemies = level.get_node("Enemies")
		# 記錄起來。
		_enemies.append(enemies)
		# 把所有子節點的 owner 設為 enemies，
		# 因為 PackedScene.pack() 只會打包 owner 是根節點的子節點，不設定會漏掉。
		set_node_owner_to_enemies(enemies, enemies)
		# 建立一個新的 PackedScene。
		var packed_enemies = PackedScene.new()
		# 記錄起來。
		_packed_enemies.append(packed_enemies)
		# 把目前的敵人樹狀結構打包（存成快照）。
		packed_enemies.pack(enemies)
	
	# 連接檢查點介面的 perform_recovery 訊號：
	# 玩家在檢查點按「恢復」且畫面全黑時，執行 _recover()。
	checkpoint_interface.perform_recovery.connect(
		_recover
	)
	
	# 一開始的重生點 = 預設檢查點。
	saved_checkpoint = initial_checkpoint


# 每個物理影格執行。
func _physics_process(_delta: float):
	# 靠近某個檢查點時才顯示檢查點提示。
	interaction_hints.checkpoint_hint.visible = current_checkpoint != null
	# 依玩家角色的坐下動畫狀態，判斷是否正在檢查點休息。
	at_checkpoint = player.character.sit_animations.sitting_idle


# set_node_owner_to_enemies(node, enemies)：遞迴地把 node 底下所有子節點的 owner 設為 enemies。
func set_node_owner_to_enemies(node: Node, enemies: Node) -> void:
	for child in node.get_children():
		# 設定 owner，讓打包時會包含這個節點。
		child.owner = enemies
		# 若這個子節點還有子節點、而且它「不是」敵人本體（Enemy），就繼續往下遞迴。
		# 敵人本體通常是獨立的場景實例，內部結構會隨場景一起保存，不需再往下設定。
		if child.get_child_count() > 0 and not child is Enemy:
			set_node_owner_to_enemies(child, enemies)


# disable_hint()：玩家離開檢查點範圍時呼叫，互動提示計數器 -1。
func disable_hint() -> void:
	interaction_hints.counter -= 1


# enable_hint()：玩家進入檢查點範圍時呼叫，互動提示計數器 +1。
func enable_hint() -> void:
	interaction_hints.counter += 1


# save_current_checkpoint()：把目前的檢查點儲存成重生點（例如玩家在此休息時）。
func save_current_checkpoint() -> void:
	saved_checkpoint = current_checkpoint


# play_death_sfx()：播放死亡音效（由死亡畫面呼叫）。
func play_death_sfx() -> void:
	death_sfx.play()


# recover_after_death()：玩家死亡後（畫面全黑時）由死亡畫面呼叫。
func recover_after_death() -> void:
	# 取消鎖定目標。
	lock_on_system.reset_target()
	
	# 把玩家的位置與旋轉設為重生點的位置與旋轉（瞬間傳送）。
	player.global_transform = saved_checkpoint\
		.respawn_point\
		.global_transform
	
	# 重設玩家的次要移動（例如擊退、衝刺等殘留的速度）。
	player.locomotion_component.reset_secondary_movement()
	# 重設玩家的期望速度，避免重生後還在滑動。
	player.locomotion_component.reset_desired_velocity()
	
	# 把相機的水平旋轉（Y 軸）設成與重生點相同，讓相機面向正確方向。
	camera_controller.global_rotation.y = saved_checkpoint\
		.respawn_point\
		.global_rotation\
		.y
	
	# 執行共同的恢復流程（敵人重生、補血等）。
	_recover()


# _recover()：恢復流程（死亡重生或在檢查點休息時共用）。
func _recover() -> void:
	# 重設相機狀態。
	Globals.camera_controller.reset()
	
	# 刪除所有關卡中目前的敵人：
	for enemies in _enemies:
		for child in enemies.get_children():
			# 只處理敵人區域（EnemySection），其他節點跳過。
			if not child is EnemySection: continue
			var section: EnemySection = child
			# 讓該區域釋放它管理的敵人（包含暫時被移出場景樹的敵人）。
			section.free_enemies()
		# 刪除整個 Enemies 節點。
		enemies.queue_free()
	
	# 清除 HUD 上所有與敵人相關的元素（察覺三角形、血條等）。
	Globals.user_interface.hud.clear_enemy_hud_elements()
	
	# 用遊戲開始時打包的快照，為每個關卡重新產生一批敵人。
	for i in range(len(levels)):
		# instantiate()：依快照建立新的節點樹。
		var new_enemies: Node = _packed_enemies[i].instantiate()
		# 加入對應的關卡。
		levels[i].add_child(new_enemies)
		# 更新記錄為新的敵人節點。
		_enemies[i] = new_enemies
	
	# 玩家血量補滿。
	player.health_component.health = player.health_component.max_health
	# 玩家失衡值歸零。
	player.instability_component.instability = 0
	# 補血次數重置（補滿）。
	player.health_charge_component.reset_charges()
