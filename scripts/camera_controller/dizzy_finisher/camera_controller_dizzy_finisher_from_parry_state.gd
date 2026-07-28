# ==============================================================
# 暈眩終結相機狀態機 - 被【招架(Parry)】觸發的分支 (From Parry)
#
# 這個檔案負責當敵人是「因為玩家成功招架(parry)」而進入暗暈(dizzy)狀態時，
# 播放的專屬相機演出。與 from_damage 檔案是兄弟關係，
# 兩者都由 camera_controller_dizzy_finisher_state.gd 依情況擇一切換進入。
#
# 大致流程：
# 1. enter()：剛進入這個狀態時，先判斷玩家跟敵人的朝向差，
#    決定攝影機要往左邊繞還是往右邊繞比較好看 (_cam_right_or_left)。
# 2. process_camera()：每一影格執行，負責：
#    - 若還有暈眩目標(dizzy_victim)，把鏡頭拉近、環繞注視敵人，做特寫演出，
#      並記錄下目標(_saved_dizzy_victim)，供目標死亡後仍能繼續看向該位置。
#    - 若目標消失（可能被打死或暈眩結束），視情況延遲收尾，
#      再把鏡頭慢慢移回玩家背後的一般視角(_recently_had_dizzy_victim)。
#    - 若完全沒有暈眩行為在進行中，直接切回一般相機狀態(normal_state)。
# ==============================================================
class_name CameraControllerDizzyFinisherFromParryState
extends CameraControllerStateMachine

# 一般狀態的相機節點，結束演出後要切換回去這個狀態
@export var normal_state: CameraControllerNormalState

# 用來保存暈眩目標，因為目標被打死後 dizzy_victim 會馬上變成 null，
# 但這裡仍需要目標的位置資訊來繼續播放收尾鏡頭
var _saved_dizzy_victim: DizzyComponent

# 是否要播放「拉近鏡頭做特寫偏移」的暈眩演出行為
var _dizzy_behaviour: bool = false

# 標記「最近曾經有過暈眩目標」，用於目標消失後，判斷是否要播放收尾轉場
var _recently_had_dizzy_victim: bool = false

# 標記「暈眩目標最近被打死了」，用於觸發收尾計時器
var _recently_killed_dizzy_victim: bool = false

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

	# 如果目前沒有暈眩目標，且也沒有「剛保存的目標」或「最近曾有目標」的殘留狀態，
	# 代表整個暈眩演出已經徹底結束，直接切回一般相機狀態
	if not dizzy_victim and (
		not _saved_dizzy_victim or \
		not _recently_had_dizzy_victim
	):
		parent_state.parent_state.change_state(
			normal_state
		)

	if dizzy_victim:
		# --- 情況一：目前仍有暈眩目標，記錄狀態並開啟特寫演出 ---
		_dizzy_behaviour = true
		_saved_dizzy_victim = dizzy_victim
		_recently_had_dizzy_victim = true
		_recently_killed_dizzy_victim = true
	elif not dizzy_system.victim_being_killed:
		# --- 情況二：目標已經不在了，且並非「正在被擊殺」的過程，
		#     代表暈眩已經自然結束（例如玩家沒有補刀），直接關閉特寫演出 ---
		_dizzy_behaviour = false
	elif _recently_killed_dizzy_victim:
		# --- 情況三：目標剛剛被擊殺，觸發一次收尾計時器 ---
		# 這個旗標只需要觸發一次，觸發後立刻關閉，避免重複建立計時器
		_recently_killed_dizzy_victim = false
		# 等待 0.5 秒，讓玩家先看清楚擊殺瞬間，之後才關閉特寫演出並清除保存的目標
		var dizzy_timer: SceneTreeTimer = get_tree().create_timer(0.5)
		dizzy_timer.timeout.connect(
			func():
				_dizzy_behaviour = false
				_saved_dizzy_victim = null
		)

	if _dizzy_behaviour:
		# --- 播放「拉近鏡頭環繞特寫」的暈眩演出 ---

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

		# 讓鏡頭直接看向保存下來的暈眩目標位置（即使目標已死也能繼續看向該處）
		camera.look_at(_saved_dizzy_victim.global_position)
		# 再依照剛剛算好的左右偏移，額外多轉一點角度，做出「側面環繞」的構圖
		camera.global_rotation_degrees.y += _cam_right_or_left * 20
		# 額外把鏡頭往下壓一點角度，讓畫面更有壓迫感（招架版本比傷害版本多這一行）
		camera.global_rotation_degrees.x -= 10

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
			.direction_to(_saved_dizzy_victim.global_position)
		_looking_direction = -_looking_direction

		# 用 atan2 把方向向量換算成 Y 軸旋轉角度(弧度)
						var _target_look: float = atan2(
						_looking_direction.x,
						_looking_direction.z
		)

		# 再加上左右偏移(90度)，讓攝影機不要正对敵人，而是站在斜側面拍攝
		# (招架版本的偏移角度比傷害版本大，拍出來的構圖会更側面)
		_target_look += _cam_right_or_left * deg_to_rad(90)

		# 將攝影機目前的 Y 軸角度，平滑地插值轉向目標角度 _target_look
		var desired_rotation_y: float = lerp_angle(
			camera_controller.rotation.y,
			_target_look,
			0.1
		)

		camera_controller.rotation.y = desired_rotation_y

	elif _recently_had_dizzy_victim:
		# --- 情況四：暈眩演出已經關閉，但仍在「轉場回一般相機」的過渡階段 ---

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
		# 當角度差已經非常小，視為轉場完成，清除「最近曾有目標」的旗標
		if abs(
			camera_controller.rotation.y \
			- player.rotation.y
		) < 0.05:
			_recently_had_dizzy_victim = false

		
