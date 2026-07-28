# ===================================================
# 返回原位節點（Return Leaf）
# 用途：當敌人跟丢玩家或讓開戰逗太遠時，讓敌人自動走回他最初的位置（original_position）
# 並在到達後轉回最初的面向（original_rotation）
# 這是一個 Beehave 行為樹的 ActionLeaf，每幀會被 tick() 呼叫一次
# ===================================================
extends ActionLeaf

# 標記目前是否處於「最後轉身對齊方向」的階段
# true  = 尚未進入轉身階段（仍在移動中）
# false = 已到達目標附近，正在執行最後的轉身動作
var _turning_back: bool = true

# 標記整個返回流程是否已經完全結束（包括轉身動作也做完了）
var _done: bool = false


# before_run() 會在這個節點被重新進入執行前自動調用一次
# 目的是檢查現在離原位多遠，如果離得夠遠（> 2.0）就重新啟動一次完整的返回流程
func before_run(_actor: Node, blackboard: Blackboard) -> void:
	if blackboard.get_value("dist_original_position") > 2.0:
		# 離原位夠遠，重置狀態：先走路回去，不要直接跳到轉身
		_turning_back = false
		_done = false


# tick() 是行為樹每幀實際執行的地方，必須回傳 SUCCESS / FAILURE / RUNNING 其中一種狀態碼
func tick(actor: Node, blackboard: Blackboard) -> int:
	# 把 actor 轉型成 Enemy，方便存取敌人專屬的移動元件 locomotion_component
	var entity: Enemy = actor
	# 取得敌人目前距離原始位置有多遠
	var dist_original = blackboard.get_value("dist_original_position")
	
	# 若之前已經完成整個返回流程，直接回報成功，不用重複執行
	if _done: return SUCCESS
	
	# 情況一：還沒開始轉身（_turning_back 為 false），且距離原位還夠遠（> 0.6）
	# => 繼續讓敌人往原始位置走去
	if not _turning_back and dist_original > 0.6:
		# 設定 AI 移動系統的目標點為敌人的原始位置
		blackboard.set_value(
			"agent_target_position",
			blackboard.get_value("original_position")
		)
		# 切換移動策略為 root_motion（由動畫驅動位移，而非手動程式控制）
		entity.locomotion_component.set_active_strategy("root_motion")
		# 讓敌人自動面向目標位置的方向
		blackboard.set_value("rotate_towards_target", true)
		# 動畫播放速度設為正常速度（1.0）
		blackboard.set_value("anim_move_speed", 1.0)
		# 輸入方向設為向前，讓角色開始往前移動
		blackboard.set_value("input_direction", Vector3.FORWARD)
	else:
		# 情況二：已經足夠接近原始位置，進入最後的轉身對齊階段
		_turning_back = true
		# 把目標點設在「原始位置往前方 2 單位」的位置，
		# 這樣啊敌人會面向他原本的方向（original_rotation）並轉回去
		blackboard.set_value(
			"agent_target_position",
			blackboard.get_value("original_position") + \
			Vector3.FORWARD.rotated(
				Vector3.UP,
				blackboard.get_value("original_rotation")
			) * 2
		)
		# 等 0.5 秒（大致夠讓轉身動畫播完）後，停止移動並標記整個流程完成
		get_tree().create_timer(0.5).timeout.connect(
			func():
				# 清除輸入方向，敌人停止移動
				blackboard.set_value("input_direction", Vector3.ZERO)
				# 標記為已完成，下次 tick 會直接回報 SUCCESS
				_done = true
		)
	# 還沒完全完成，回報 RUNNING，讓行為樹下一幀繼續執行這個節點
	return RUNNING
