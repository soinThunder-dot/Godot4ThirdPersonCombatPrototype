# ==========================================================
# 【檔案說明】enemy_section.gd
# 這是「敵人區域」的腳本，用來做效能優化（類似「分區載入」）。
# 每個敵人區域是一個 Area3D（3D 觸發範圍）：
#   - 玩家「進入」區域 → 把該區的敵人逐一加回場景樹（開始運作）。
#   - 玩家「離開」區域 → 把敵人逐一從場景樹移除（停止運作、節省效能）。
# 為了避免一次加入/移除太多敵人造成卡頓，每隔 0.2 秒才處理一個敵人。
# 另外也會一起啟用/停用該區的巡邏路線（Patrols）。
# ==========================================================

# 註冊為全域類別 EnemySection。
class_name EnemySection
# 繼承 Area3D：可偵測物體進入/離開的 3D 區域。
extends Area3D


# NodeOperation：列舉（enum），表示目前要進行的操作：
#   ADD = 加入敵人、REMOVE = 移除敵人、NONE = 沒有操作。
enum NodeOperation {ADD, REMOVE, NONE}

# enemies：存放本區敵人的子節點。
@onready var enemies: Node3D = $Enemies
# patrols：巡邏路線節點（可能不存在，所以在 _ready 中用 get_node_or_null 取得）。
@onready var patrols: Node3D

# queued_for_deletion：本區是否已被標記為「即將刪除」（恢復/重生敵人時）。
# 設為 true 後就不再處理進出事件。
var queued_for_deletion: bool = false

# enemy_nodes：暫時不在場景樹中的敵人節點清單（等待被加入）。
var enemy_nodes: Array[Node]
# current_operation：目前正在進行的操作，預設為 NONE。
var current_operation: NodeOperation = NodeOperation.NONE

# _time_gap：每處理一個敵人之間的間隔（秒）。
var _time_gap: float = 0.2
# _timer：倒數計時用的變數。
var _timer: float


# 初始化。
func _ready():
	# 嘗試取得 "Patrols" 子節點；不存在時回傳 null，不會報錯。
	patrols = get_node_or_null("Patrols")
	
	# 取得所有敵人節點並記錄下來。
	enemy_nodes = enemies.get_children()
	# 一開始先把所有敵人從場景樹移除（節點本身還在記憶體中，只是不運作）。
	for child in enemy_nodes:
		enemies.remove_child(child)
	# 一開始停用巡邏路線。
	_set_patrols_enabled(false)
	
	# 有物體進入區域時 → 開始加入敵人（_body 參數未使用）。
	# （推測碰撞層設定只會偵測玩家。）
	body_entered.connect(func(_body: Node3D): _add_enemies())
	# 有物體離開區域時 → 開始移除敵人。
	body_exited.connect(func(_body: Node3D): _remove_enemies())
	
	# 計時器初始值設為間隔時間。
	_timer = _time_gap


# 每個畫面影格執行：依目前操作，每隔 0.2 秒加入或移除一個敵人。
func _process(delta: float) -> void:
	# 沒有操作 → 直接結束。
	if current_operation == NodeOperation.NONE: return
	
	# 倒數計時。
	_timer -= delta
	
	# 時間還沒到 → 等下一影格。
	if _timer > 0: return
	
	# ---- 加入敵人 ----
	if current_operation == NodeOperation.ADD:
		# 還有等待加入的敵人：取出清單第一個（pop_front）並加回場景樹。
		if len(enemy_nodes) > 0:
			enemies.add_child(enemy_nodes.pop_front())
		# 全部加入完畢：
		else:
			# 結束操作。
			current_operation = NodeOperation.NONE
			# 重新設定所有子節點的 owner，確保之後打包/保存時正確。
			Globals.checkpoint_system.set_node_owner_to_enemies(
				enemies, enemies
			)
	# ---- 移除敵人 ----
	elif current_operation == NodeOperation.REMOVE:
		# 還有敵人在場景樹中：移除第一個。
		if enemies.get_child_count() > 0:
			var child = enemies.get_child(0)
			enemies.remove_child(child)
		# 全部移除完畢 → 結束操作。
		else:
			current_operation = NodeOperation.NONE
	
	# 重設計時器，準備處理下一個。
	_timer = _time_gap


# _notification(what)：Godot 的通知回呼，節點生命週期中各種事件都會呼叫這裡。
func _notification(what: int) -> void:
	# 只處理「即將被刪除（PREDELETE）」的通知。
	if what != NOTIFICATION_PREDELETE: return
	# 輸出訊息到主控台（除錯用）。
	prints("Unregistering beehave trees in", self)
	# 對每個敵人，向 Beehave（行為樹外掛）的除錯器取消註冊它的行為樹，
	# 避免敵人被刪除後，除錯器還指向不存在的物件。
	for node in enemies.get_children():
		var enemy: Enemy = node
		BeehaveDebuggerMessages.unregister_tree(
			enemy.beehave_tree.get_instance_id()
		)


# free_enemies()：由檢查點系統在恢復時呼叫，釋放本區管理的敵人。
func free_enemies() -> void:
	# 標記為即將刪除，之後不再處理進出事件。
	queued_for_deletion = true
	# 刪除所有「不在場景樹中」的敵人節點
	# （它們不在樹中，不會跟著父節點一起被刪除，必須手動釋放以免記憶體洩漏）。
	for enemy in enemy_nodes:
		enemy.queue_free()


# _add_enemies()：玩家進入區域時呼叫。
func _add_enemies() -> void:
	# 已標記刪除 → 不處理。
	if queued_for_deletion: return
	# 輸出除錯訊息。
	print("Player entered enemy section: " + name)
	# 設定操作為「加入」。
	current_operation = NodeOperation.ADD
	# 重設計時器。
	_timer = _time_gap
	# 啟用巡邏路線。
	_set_patrols_enabled(true)


# _remove_enemies()：玩家離開區域時呼叫。
func _remove_enemies() -> void:
	# 已標記刪除 → 不處理。
	if queued_for_deletion: return
	# 輸出除錯訊息。
	print("Player left enemy section: " + name)
	# 若目前場景樹中有敵人，就把清單更新為這些敵人（之後再進入時要加回來的就是它們）。
	# get_child_count() 不為 0 時視為 true。
	if enemies.get_child_count(): enemy_nodes = enemies.get_children()
	# 設定操作為「移除」。
	current_operation = NodeOperation.REMOVE
	# 重設計時器。
	_timer = _time_gap
	# 停用巡邏路線。
	_set_patrols_enabled(false)


# _set_patrols_enabled(enabled)：啟用或停用巡邏路線節點。
func _set_patrols_enabled(enabled: bool) -> void:
	# 沒有巡邏節點 → 不處理。
	if not patrols: return
	# 啟用：PROCESS_MODE_INHERIT（跟隨父節點，正常運作）；
	# 停用：PROCESS_MODE_DISABLED（完全不執行 process）。
	# 這是「A if 條件 else B」的三元運算式，用反斜線換行。
	patrols.process_mode = Node.PROCESS_MODE_INHERIT if enabled \
		else Node.PROCESS_MODE_DISABLED
