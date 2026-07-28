# ===================================================================
# 暄眩終結相機狀態機（Dizzy Finisher Camera State）
#
# 這個檔案是一個「小型狀態機（sub state machine）」，
# 專門負責當敌人被打暄眩（dizzy）並遭到玩家發動終結技（finisher）時，
# 決定相機應該播放哪一種進入動畫/角度：
#   1. 如果敌人是因為「招架（parry）」而達到滿暄眩值 -> 播放 from_parry 那套相機動畫
#   2. 否則（例如累積傷害造成滿暄眩）-> 播放 from_damage 那套相機動畫
#
# 繼承自 CameraControllerStateMachine，所以它自己也是一個可以被切換進去的「狀態」，
# 同時它內部又管理著兩個更小的子狀態（from_parry / from_damage）
# ===================================================================
class_name CameraControllerDizzyFinisherState
extends CameraControllerStateMachine

# 當敵人是被「招架成功（parry）」造成暄眩時，要播放的相機子狀態
# 需要在 Godot 編輯器裡拖入對應的節點
@export var from_parry: CameraControllerDizzyFinisherFromParryState

# 當敵人是被「傷害累積（damage）」造成暄眩時，要播放的相機子狀態
@export var from_damage: CameraControllerDizzyFinisherFromDamageState

# 從全局物件 Globals 取得目前的暄眩系統（DizzySystem），
# 裡面會記錄誰是目前被暄眩的目標（dizzy_victim）
@onready var dizzy_system: DizzySystem = Globals.dizzy_system


func _ready():
	# 先執行父類（CameraControllerStateMachine）自己的初始化邏輯
	# 一般來說要實作自己的 _ready() 時，若有父類邏輯需要保留，都應先呼叫 super._ready()
	super._ready()


# enter() 會在這個狀態機被切換進來的那一刻被呼叫，用來決定接下來要進入哪個子狀態
func enter() -> void:
	# 先宣告一個變數，用來暫存「接下來要切換進去的目標狀態」
	var state: CameraControllerStateMachine
	
	# 判斷這次暄眩是不是因為招架（parry）而達到滿暄眩值
	# instability_component 是敵人身上計算暄眩值的元件
	if dizzy_system.dizzy_victim.instability_component.full_instability_from_parry:
		# 是由招架達成的 -> 使用招架專用的相機動畫
		state = from_parry
	else:
		# 不是招架（例如是普通攻擊累積造成的）-> 使用傷害累積專用的相機動畫
		state = from_damage
	
	# 只有當目標狀態跟現在不一樣時才切換，避免重複進入同一個狀態而重新播放動畫
	if current_state != state:
		change_state(state)


# 每幀更新相機用的函式，但這個父級狀態本身不需要做任何事，
# 實際的相機邏輯都寫在 from_parry / from_damage 這兩個子狀態裡面
func process_camera() -> void:
	pass


# 處理玩家輸入事件用的函式，同樣不需要在這裡做任何事
func process_unhandled_input(_event: InputEvent) -> void:
	pass


# 離開這個狀態時會執行的函式，目前不需要做任何清理
func exit() -> void:
	pass
