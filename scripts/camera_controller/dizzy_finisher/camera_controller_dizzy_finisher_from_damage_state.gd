# ==============================================================
# 暗暈終結相機狀態機 - 被【傷害累積】觸發的分支 (From Damage)
#
# 這個檔案負責當敵人是「被普通攻擊累積傷害」而進入暗暈(dizzy)狀態時，
# 播放的專屬相機演出。與 from_parry 檔案是兄弟關係，
# 兩者都由 camera_controller_dizzy_finisher_state.gd 依情況擇一切換進入。
#
# 大致流程：
#   1. enter()：剛進入這個狀態時，先判斷玩家跟敵人的朝向差，
#      決定攝影機要往左邊繞還是往右邊繞比較好看 (_cam_right_or_left)。
#   2. process_camera()：每一影格執行，負責：
#        - 若還有暈眩目標(dizzy_victim)，把鏡頭拉近、環繞注視敵人，做特寫演出。
#        - 若目標被打死了(沒有 dizzy_victim 了)，先延遲 0.7 秒，
#          再開始把鏡頭『轉場』(_transition_out) 慢慢移回玩家背後的一般視角。
#   3. return_back_to_normal_cam()：轉場完成後呼叫，跳回一般相機狀態。
# ==============================================================
class_name CameraControllerDizzyFinisherFromDamageState
extends CameraControllerStateMachine

# 一般狀態的相機節點，轉場結束後要切換回去這個狀態
@export var normal_state: CameraControllerNormalState

# 標記「暈眩目標剛剛被打死」的旗標，用來觸發之後的轉場計時器
var _recently_killed_dizzy_victim: bool = false

# 是否已經進入「往回轉場到一般相機」的階段
var _transition_out: bool = false

# 攝影機要繞著敵人偏右邊還是偏左邊拍攝比較好看：
# 1 代表往右偏移，-1 代表往左偏移
var _cam_right_or_left: int = 1

# 從全局物件 Globals 取得目前的暈眩系統(DizzySystem)，
# 裡面會記錄誰是目前被暈眩的目標(dizzy_victim)
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


# 進入這個狀態時執行一次，用來決定攝影機要往哪一邊偏移拍攝
func enter() -> void:
	# 計算「攝影機目前朝向」跟「玩家目前朝向」之間差了幾度(0~360之間)
	var diff_in_rotation: float = wrapf(
		camera_controller.rotation_degrees.y - player.rotation_degrees.y,
		0.0,
		360.0
	)
	
	# 依照角度差的區間，判斷鏡頭應該往哪一邊繞比較不會穿模/比較好看
	if 182 < diff_in_rotation and diff_in_rotation < 345:
		_cam_right_or_left = -1
	else:
		_cam_right_or_left = 1


# 每一影格都會呼叫的相機邏輯，是這個狀態真正的核心
func process_camera() -> void:
	# 目前被暈眩鎖定的敵人組件，如果敵人已死或暈眩結束，這裡會是 null
	var dizzy_victim: DizzyComponent = dizzy_system.dizzy_victim
	
	# 如果這一影格發現目標消失了（代表被打死了），標記旗標，準備稍後轉場
	if not dizzy_victim:
		_recently_killed_dizzy_victim = true
	
	if _recently_killed_dizzy_victim:
		# 這個旗標只需要觸發一次，觸發後立刻關閉，避免重複建立計時器
		_recently_killed_dizzy_victim = false
		# 等待 0.7 秒，讓玩家先看清楚擊殺的瞬間，之後才開始把鏡頭轉回一般視角
		var timer: SceneTreeTimer = get_tree().create_timer(0.7)
		timer.timeout.connect(
			func():
				_transition_out = true
		)
		
	# prints(dizzy_victim, _recently_killed_dizzy_victim)
	
	if dizzy_victim:
		# --- 情況一：暈眩目標還存在，播放特寫環繞演出 ---
		
		# 讓視野角度(fov)慢慢縮小到 65，製造「拉近鏡頭」的特寫感
		camera.fov = move_toward(
			camera.fov,
			65,
			2
		)
		
		# 攝影機主體位置平滑移動到玩家身邊（稍微墊高 0.5）
		camera_controller.global_position = camera_controller.global_position.lerp(
			player.global_position + Vector3(0, 0.5, 0), 
			0.05
		)
		
		# 讓鏡頭直接看向暈眩中的敵人
		camera.look_at(dizzy_victim.global_position)
		# 再依照剛剛算好的左右偏移，額外多轉一點角度，做出「側面環繞」的構圖
		camera.global_rotation_degrees.y += _cam_right_or_left * 20
		
		# 攝影機仰角/俯角慢慢調整到 -35 度，讓鏡頭有一點往下俯視的效果
		camera_controller.rotation_degrees.x = lerp_angle(
			camera_controller.rotation_degrees.x,
			-35.0,
			0.05
		)
		
		# 計算「攝影機位置指向敵人位置」的方向向量，並反轉方向
		# (反轉是因為之後要用這個方向去算出『攝影機背對敵人』時該面向的角度)
		var _looking_direction: Vector3 = camera_controller\
			.global_position\
			.direction_to(dizzy_victim.global_position)
		_looking_direction = -_looking_direction
		
		# 用 atan2 把方向向量換算成 Y 軸旋轉角度(弧度)
		var _target_look: float = atan2(
			_looking_direction.x,
			_looking_direction.z
			
		)
		# 再加上左右偏移(80度)，讓攝影機不要正對敵人，而是站在斜側面拍攝
		_target_look += _cam_right_or_left * deg_to_rad(80)
		
		# 將攝影機目前的 Y 軸角度，平滑地插值轉向目標角度 _target_look
		var desired_rotation_y: float = lerp_angle(
			camera_controller.rotation.y, 
			_target_look, 
			0.1
		)
		
		camera_controller.rotation.y = desired_rotation_y
		
	elif _transition_out:
		# --- 情況二：暈眩目標已消失，且已經進入「轉場回一般相機」階段 ---
		
		# 如果玩家已經開始移動，或是已經有新的鎖定目標，
		# 代表玩家想繼續操作了，直接切回一般相機狀態，不用等轉場動畫跑完
		if player.input_direction.length() > 0 or \
			lock_on_system.target != null:
			return_back_to_normal_cam()
			return
		
		# 視野角度(fov)慢慢還原回相機控制器原本設定的一般視野值
		camera.fov = move_toward(
			camera.fov,
			camera_controller.camera_fov,
			2
		)
		# 攝影機位置慢慢移回玩家背後、一般狀態下的相機高度(vertical_offset)
		camera_controller.global_position = camera_controller\
			.global_position\
			.lerp(
				player.global_position + Vector3(
					0,
					camera_controller.vertical_offset,
					0
				),
				0.1
			)
		# 攝影機本身的旋轉慢慢歸零(不再往任何方向偏移看)
		camera.rotation = camera.rotation.lerp(Vector3.ZERO, 0.1)
		# 攝影機控制器的 Y 軸角度慢慢轉回跟玩家目前面向一致
		camera_controller.rotation.y = lerp_angle(
			camera_controller.rotation.y,
			player.rotation.y,
			0.1
		)
		# 當角度差已經非常小，視為轉場完成，正式切回一般相機狀態
		if abs(
			camera_controller.rotation.y \
			- player.rotation.y
		) < 0.05:
			return_back_to_normal_cam()
			return


# 轉場動畫結束後呼叫，正式把相機狀態機切換回一般相機狀態
func return_back_to_normal_cam() -> void:
	print("Return back to normal cam after dizzy finisher from damage camera behaviour")
	parent_state.parent_state.change_state(
		normal_state
	)
