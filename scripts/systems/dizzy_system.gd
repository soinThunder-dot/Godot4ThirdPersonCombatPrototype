# ==========================================================
# 【檔案說明】dizzy_system.gd
# 這是「暈眩（處決）系統」的腳本，類似《隻狼》架勢條滿了之後的「忍殺」。
# 當敵人失衡值滿而進入暈眩狀態時，就成為「暈眩目標（dizzy_victim）」，
# 玩家靠近並按下攻擊即可處決（finisher）。
# 本系統負責記錄：誰是暈眩目標、玩家是否可以處決、處決是否正在進行中。
# 註：檔案中原本就有的英文註解是作者寫的，下方的中文註解會一併解釋。
# ==========================================================

# 註冊為全域類別 DizzySystem。
class_name DizzySystem
# 繼承 Node3D（3D 節點）。
extends Node3D


# @warning_ignore("unused_signal")：告訴 Godot 忽略「此訊號在本腳本中沒被使用」的警告
# （這個訊號是由其他腳本發出的）。
# dizzy_victim_killed：暈眩目標被處決時發出的訊號。
@warning_ignore("unused_signal")
signal dizzy_victim_killed


# （作者註解：目前可以被處決的目標）
# the current victim that can be finished
# dizzy_victim：目前的暈眩目標，使用 setter 在賦值時做額外處理。
var dizzy_victim: DizzyComponent:
	set(value):
		# 如果新值與舊值相同，什麼都不做。
		if dizzy_victim == value: return
		# 先把「舊的目標」存到 saved_victim，再換成新值。
		saved_victim = dizzy_victim
		dizzy_victim = value

# （作者註解翻譯：save 的定義 = 保存起來供之後使用。
#   暈眩目標被處決後，dizzy_victim 會立刻被設為 null，
#   但有些行為仍需要知道「剛剛被處決的是哪個敵人」，所以用 saved_victim 保存。）
# save def: keep and store up for future use.
# when the dizzy victim is killed, dizzy_victim will
# instantly be set to null afterwards. but some
# behaviour still needs to check which entity
# was the victim.
var saved_victim: DizzyComponent

# （作者註解翻譯：玩家是否應該進入「像電影鏡頭般、準備處決目標」的狀態，
#   還是正常進行遊戲。）
# whether the player should be in that cinematic like
# state ready to finish the victim, or whether they
# should live life normally
var readied_finisher: bool = false

# （作者註解翻譯：此時按下攻擊是否真的會執行處決。
#   準心與玩家的暈眩處決狀態會使用這個值。）
# whether pressing attack at this stage should actually
# go about finishing the victim. used by crosshair and
# player dizzy finisher states
var can_kill_victim: bool = false

# （作者註解翻譯：有暈眩目標、且玩家已按下攻擊進行處決時為 true；
#   處決攻擊動畫結束後會變回 false。）
# this is true when there is a victim and the player
# has pressed the attack button to execute them.
# it will be false once the attack animation concludes.
var victim_being_killed: bool = false

# finisher_distance：可以處決的最大距離（公尺）。
var finisher_distance: float = 1.5

# player：從 Globals 取得玩家節點。
@onready var player: Player = Globals.player


# 每個畫面影格執行：更新「是否可以處決」。
func _process(_delta):
	# （作者留下的除錯輸出，已停用。）
	#prints(victim_being_killed, saved_victim, dizzy_victim, readied_finisher)
	
	# 處決動作進行中 → 不更新任何狀態，直接結束。
	if victim_being_killed:
		return
		
	# （作者註解翻譯：攻擊結束後，就不再需要 saved_victim 了。）
	# after the attack concludes, saved victim is no longer needed
	# 沒有暈眩目標時，清掉保存的舊目標並結束。
	if not dizzy_victim:
		saved_victim = null
		return
	
	# 如果目標的失衡滿是「因為被玩家彈反（parry）造成的」：
	# 只要玩家已進入準備處決狀態，或在處決距離內，就可以處決。
	if dizzy_victim.instability_component.full_instability_from_parry:
		can_kill_victim = readied_finisher or _player_within_finisher_distance()
	# 其他原因造成的失衡滿：玩家必須在處決距離內才可以處決。
	else:
		can_kill_victim = _player_within_finisher_distance()


# _player_within_finisher_distance()：判斷玩家與暈眩目標的距離是否在處決距離內。
func _player_within_finisher_distance() -> bool:
	# 目標本體位置到玩家位置的距離 <= 1.5 就回傳 true。
	return dizzy_victim\
		.entity\
		.global_position\
		.distance_to(player.global_position) <= finisher_distance
