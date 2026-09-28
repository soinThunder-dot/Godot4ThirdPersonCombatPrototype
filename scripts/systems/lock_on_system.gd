# ==========================================================
# 【檔案說明】lock_on_system.gd
# 這是「鎖定系統」的腳本（類似魂系遊戲按右類比鍵鎖定敵人）。
# 主要功能：
#   1. 用一個偵測球體（EnemyDetectionSphere）找出玩家附近可鎖定的目標。
#   2. 按下 "lock_on" 鍵：沒鎖定時選擇「最靠近畫面中央」的目標；已鎖定時取消。
#   3. 鎖定中移動滑鼠或右搖桿，可以向左/右切換到其他目標。
#   4. 目標太遠（超過 retain_distance）會自動取消鎖定。
#   5. 目標被消滅時自動切換到新目標（背刺/處決時會延遲 1 秒）。
# 每次鎖定目標改變都會發出 lock_on 訊號（HUD 會用它顯示鎖定標記）。
# ==========================================================

# 註冊為全域類別 LockOnSystem。
class_name LockOnSystem
# 繼承 Node3D（3D 節點）。
extends Node3D


# lock_on：鎖定目標改變時發出，參數是新目標（取消鎖定時為 null）。
signal lock_on(target: LockOnComponent)


# enabled：是否啟用鎖定系統。
@export var enabled: bool = true
# target_detection_range：偵測可鎖定目標的範圍半徑（公尺）。
@export var target_detection_range: float = 20.0
# retain_distance：保持鎖定的最大距離，超過就自動取消鎖定。
@export var retain_distance: float = 25.0

# @export_category：在編輯器屬性面板中建立一個名為「Changing Target」的分類標題。
@export_category("Changing Target")
# change_target_mouse_threshold：滑鼠單次移動量超過此值才會切換目標（像素）。
@export var change_target_mouse_threshold: float = 60.0
# change_target_controller_threshold：右搖桿水平推動量超過此值才會切換目標（0~1）。
@export var change_target_controller_threshold: float = 0.2
# change_target_wait_time：切換目標後的冷卻時間（秒），避免連續快速切換。
@export var change_target_wait_time: float = 0.5
# can_change_target：目前是否可以切換目標（冷卻中為 false）。
@export var can_change_target = true

# target：目前鎖定的目標（LockOnComponent），null 表示沒有鎖定。
var target: LockOnComponent = null

# _targets_nearby：目前在偵測範圍內的所有可鎖定目標。
var _targets_nearby: Array[LockOnComponent]

# _change_target_timer：切換目標冷卻用的計時器節點。
@onready var _change_target_timer: Timer = $ChangeTargetTimer
# _enemy_detection_sphere：偵測範圍的碰撞形狀（球體）。
@onready var _enemy_detection_sphere: CollisionShape3D = $EnemyDetectionSphere

# 從 Globals 取得的系統參考。
# _player：玩家。
@onready var _player: Player = Globals.player
# _dizzy_system：暈眩（處決）系統。
@onready var _dizzy_system: DizzySystem = Globals.dizzy_system
# _backstab_system：背刺系統。
@onready var _backstab_system: BackstabSystem = Globals.backstab_system


# 初始化。
func _ready() -> void:
	# 把冷卻計時器的等待時間設為編輯器中設定的值。
	_change_target_timer.wait_time = change_target_wait_time
	# 把偵測球體的半徑設為偵測範圍。
	# 「as SphereShape3D」是型別轉換，告訴 Godot 這個 shape 是球體，才能設定 radius。
	(_enemy_detection_sphere.shape as SphereShape3D).radius = target_detection_range


# 每個物理影格執行。
func _physics_process(_delta: float) -> void:
	
	# 系統停用時不做任何事。
	if not enabled:
		return
	
	# 讓整個鎖定系統（含偵測球體）跟著玩家移動。
	position = _player.position
	
	# 有鎖定目標時，檢查距離是否太遠：
	if target:
		var distance: float = _player.global_position.distance_to(target.global_position)
		# 超過保持距離 → 取消鎖定並通知外部。
		if distance > retain_distance:
			target = null
			lock_on.emit(target)
	
	# 按下鎖定鍵（剛按下的那一影格）：
	if Input.is_action_just_pressed("lock_on"):
		# 已鎖定 → 取消鎖定。
		if target:
			target = null
		# 未鎖定 → 選擇一個目標。
		else:
			_choose_lock_on_target()
		# 通知外部鎖定狀態改變。
		lock_on.emit(target)

	# （作者註解：用手把切換目標）
	# change target with controller
	# 讀取手把 0 號的右搖桿水平軸數值（-1 最左 ~ 1 最右）。
	var controller_r_joystick_x: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	# 可以切換、搖桿推動量超過門檻（取絕對值，左右都算）、且目前有鎖定目標：
	if can_change_target and abs(controller_r_joystick_x) > change_target_controller_threshold and target:

		# 往右推 → 切到右邊的目標；往左推 → 切到左邊的目標。
		if controller_r_joystick_x > 0:
			_change_target_right()
		else:
			_change_target_left()

		# 通知外部目標改變。
		lock_on.emit(target)
		# 進入冷卻，並啟動冷卻計時器。
		can_change_target = false
		_change_target_timer.start()


# _input(event)：處理輸入事件（這裡用來處理滑鼠切換目標）。
func _input(event: InputEvent) -> void:
	
	# 系統停用時不處理。
	if not enabled:
		return
	
	# （作者註解：用滑鼠切換目標）
	# change target with mouse
	# 只在「滑鼠移動」且有鎖定目標時處理。
	if event is InputEventMouseMotion and target:
		# 轉型為滑鼠移動事件。
		event = event as InputEventMouseMotion
		# relative：這次滑鼠移動的相對位移量（不是游標位置）。
		var current_mouse_pos: Vector2 = event.relative
		# 位移量的長度超過門檻、且不在冷卻中 → 才切換（避免輕微晃動就切換）。
		if Vector2.ZERO.distance_to(current_mouse_pos) > change_target_mouse_threshold and can_change_target:
			# 滑鼠往右甩 → 切到右邊目標；往左甩 → 切到左邊目標。
			if current_mouse_pos.x > 0:
				_change_target_right()
			else:
				_change_target_left()

			# 通知外部並進入冷卻。
			lock_on.emit(target)
			can_change_target = false
			_change_target_timer.start()


# reset_target()：外部呼叫以強制取消鎖定（例如玩家死亡重生時）。
func reset_target() -> void:
	target = null
	lock_on.emit(target)


# _on_area_entered(area)：有 Area 進入偵測球體時呼叫
# （這個函式應該是在編輯器中連接到 Area3D 的 area_entered 訊號）。
func _on_area_entered(area: LockOnComponent) -> void:
	# 若尚未記錄、且該鎖定元件是啟用狀態：
	if area not in _targets_nearby and area.enabled:
		# 加入附近目標清單。
		_targets_nearby.append(area)
		# 連接它的 destroyed（被消滅）訊號，消滅時呼叫 _target_destroyed。
		area.destroyed.connect(_target_destroyed)


# _on_area_exited(area)：有 Area 離開偵測球體時呼叫。
func _on_area_exited(area: LockOnComponent) -> void:
	# 從附近目標清單中移除。
	_targets_nearby.erase(area)
	# 若之前有連接 destroyed 訊號，就中斷連接（避免重複連接或殘留）。
	if area.destroyed.is_connected(_target_destroyed):
		area.destroyed.disconnect(_target_destroyed)


# _on_change_target_timer_timeout()：冷卻計時器時間到時呼叫（在編輯器中連接）。
func _on_change_target_timer_timeout() -> void:
	# 冷卻結束，可以再次切換目標。
	can_change_target = true


# _target_destroyed(t)：某個目標被消滅（例如敵人死亡）時呼叫。
func _target_destroyed(t: LockOnComponent) -> void:
	# 從附近目標清單中移除它。
	_targets_nearby.erase(t)
	
	# 記錄被消滅的目標。
	var prev_target: LockOnComponent = t
	
	# 目前沒有鎖定任何目標 → 不需要選新目標。
	if not target:
		return
	
	# 判斷目前鎖定的目標是否正在被「處決」或「背刺」：
	#   情況 A：它是暈眩目標，而且失衡滿是彈反造成的（處決演出中）；
	#   情況 B：它是背刺目標（背刺演出中）。
	# 這種情況下不要立刻切換目標，而是等 1 秒（讓處決/背刺動畫播完）再切換。
	if  (
		_dizzy_system.dizzy_victim and \
		_dizzy_system.dizzy_victim.entity == target.component_owner and \
		_dizzy_system.dizzy_victim.instability_component.full_instability_from_parry
	) or \
	(
		_backstab_system.backstab_victim and \
		_backstab_system.backstab_victim.entity == target.component_owner
	):
		
		# 建立 1 秒計時器。
		# 時間到時，如果鎖定目標仍是剛被消滅的那個，才選擇新目標。
		var timer: SceneTreeTimer = get_tree().create_timer(1.0)
		timer.timeout.connect(
			func():
				if target == prev_target:
					_choose_new_target()
		)
		
		return
	
	# 一般情況：立刻選擇新目標。
	_choose_new_target()


# _choose_new_target()：選擇新的鎖定目標並通知外部。
func _choose_new_target():
	_choose_lock_on_target()
	lock_on.emit(target)


# _can_see_target(t)：判斷相機是否「看得到」目標（中間沒有被牆壁等東西擋住）。
# 做法：從相機位置往目標位置發射一條射線（raycast）。
func _can_see_target(t: LockOnComponent) -> bool:
	# 預設看得到。
	var can_see: bool = true
	# 取得目前使用中的 3D 相機。
	var cam: Camera3D = get_viewport().get_camera_3d()

	# 取得 3D 物理空間的狀態，用來做射線查詢。
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	# 建立射線查詢參數：起點 = 相機位置，終點 = 目標位置，
	# 最後的 1 是碰撞遮罩（只偵測第 1 層碰撞層）。
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		cam.global_position,
		t.global_position,
		1
	)
	# 執行射線查詢，結果是字典（Dictionary）；沒撞到任何東西時為空字典。
	var result: Dictionary = space_state.intersect_ray(query)
	
	# 射線有撞到東西，而且撞到的「不是」目標本身 → 代表被擋住，看不到。
	if result.size() != 0 and result["collider"] != t.component_owner:
		can_see = false

	return can_see


# _get_targets_in_front()：取得所有「在相機前方」且「看得到」的附近目標。
func _get_targets_in_front() -> Array[LockOnComponent]:
	var targets: Array[LockOnComponent] = []
	var cam: Camera3D = get_viewport().get_camera_3d()

	for t in _targets_nearby:
		# is_position_behind：位置是否在相機後方；不在後方且看得到才加入。
		if not cam.is_position_behind(t.global_position) and _can_see_target(t):
			targets.append(t)

	return targets


# _get_targets_in_frustum()：取得所有「在相機視錐內（畫面上看得到的範圍）」、
# 「看得到」且「不是目前目標」的附近目標。
func _get_targets_in_frustum() -> Array[LockOnComponent]:
	var targets: Array[LockOnComponent] = []
	var cam: Camera3D = get_viewport().get_camera_3d()

	for t in _targets_nearby:
		# is_position_in_frustum：位置是否在相機的視錐（可視範圍）內。
		if t != target and cam.is_position_in_frustum(t.global_position) and _can_see_target(t):
			targets.append(t)

	return targets


# _choose_lock_on_target()：從畫面中可見的目標裡，選出「最靠近畫面中央」的那一個。
func _choose_lock_on_target() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	# 畫面中心點座標（視窗尺寸 ÷ 2）。
	var viewport_center: Vector2 = Vector2(get_viewport().size / 2)
	# 取得畫面內的候選目標。
	var targets_in_frustum: Array[LockOnComponent] = _get_targets_in_frustum()

	# closest_dist：目前找到的最近距離；closest_target：目前找到的最近目標。
	var closest_dist: float
	var closest_target: LockOnComponent = null

	# 沒有任何候選目標 → 不鎖定。
	if targets_in_frustum.size() == 0:
		target = null
		return

	# 逐一比較每個候選目標：
	for t in targets_in_frustum:
		# unproject_position：把 3D 世界座標轉換成螢幕上的 2D 座標，
		# 再計算它與畫面中心的距離。
		var dist: float = viewport_center.distance_to(cam.unproject_position(t.global_position))
		# 第一個目標、或比目前最近的還近 → 更新為最近目標。
		if closest_target == null or dist < closest_dist:
			closest_dist = dist
			closest_target = t

	# 鎖定最靠近畫面中央的目標。
	target = closest_target


# _change_target_right()：切換到目前目標「右邊」的目標。
# 規則：
#   1. 優先選擇螢幕上位於目前目標右邊、且距離最近的目標。
#   2. 如果右邊沒有目標，就「繞回去」選擇左邊距離最遠的目標（循環切換）。
#   3. 都找不到就維持原目標。
func _change_target_right() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	# 取得相機前方看得到的目標（變數名稱雖叫 frustum，實際用的是 in_front）。
	var targets_in_frustum: Array[LockOnComponent] = _get_targets_in_front()

	# 沒有任何目標 → 取消鎖定。
	if targets_in_frustum.size() == 0:
		target = null
		return
	# 把目前目標從候選中移除（不能切換到自己）。
	targets_in_frustum.erase(target)

	# closest_dist：最近距離；target_target：找到的新目標（「目標的目標」）。
	var closest_dist: float
	var target_target: LockOnComponent = null
	# 目前目標在螢幕上的 2D 位置。
	var current_target_pos: Vector2 = cam.unproject_position(target.global_position)

	# 第一輪：找右邊（x 較大）且最近的目標。
	for t in targets_in_frustum:
		var pos: Vector2 = cam.unproject_position(t.global_position)
		var dist: float = current_target_pos.distance_to(pos)

		if pos.x > current_target_pos.x and (target_target == null or dist <= closest_dist):
			closest_dist = dist
			target_target = t

	# 第二輪（右邊找不到時）：找左邊（x 較小）且最遠的目標，達成循環效果。
	if not target_target:
		var furthest_dst: float
		for t in targets_in_frustum:
			var pos: Vector2 = cam.unproject_position(t.global_position)
			var dist: float = current_target_pos.distance_to(pos)

			if pos.x < current_target_pos.x and (target_target == null or dist >= furthest_dst):
				furthest_dst = dist
				target_target = t

	# 有找到新目標就切換，沒找到就維持原本的目標。
	target = target_target if target_target else target


# _change_target_left()：切換到目前目標「左邊」的目標。
# 邏輯與 _change_target_right() 完全對稱，只是左右相反：
#   1. 優先選左邊最近的目標；2. 左邊沒有就選右邊最遠的（循環）；3. 都沒有就維持。
func _change_target_left() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	# 取得相機前方看得到的目標。
	var targets_in_frustum: Array[LockOnComponent] = _get_targets_in_front()

	# 沒有任何目標 → 取消鎖定。
	if targets_in_frustum.size() == 0:
		target = null
		return
	# 移除目前目標。
	targets_in_frustum.erase(target)

	var closest_dist: float
	var target_target: LockOnComponent = null
	# 目前目標在螢幕上的 2D 位置。
	var current_target_pos: Vector2 = cam.unproject_position(target.global_position)

	# 第一輪：找左邊（x 較小）且最近的目標。
	for t in targets_in_frustum:
		var pos: Vector2 = cam.unproject_position(t.global_position)
		var dist: float = current_target_pos.distance_to(pos)

		if pos.x < current_target_pos.x and (target_target == null or dist <= closest_dist):
			closest_dist = dist
			target_target = t

	# 第二輪（左邊找不到時）：找右邊（x 較大）且最遠的目標。
	if not target_target:
		var furthest_dst: float
		for t in targets_in_frustum:
			var pos: Vector2 = cam.unproject_position(t.global_position)
			var dist: float = current_target_pos.distance_to(pos)

			if pos.x > current_target_pos.x and (target_target == null or dist >= furthest_dst):
				furthest_dst = dist
				target_target = t

	# 有找到就切換，沒找到就維持原目標。
	target = target_target if target_target else target
