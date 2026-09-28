# ==========================================================
# 【檔案說明】level.gd
# 這是「關卡」根節點的腳本。
# 它的唯一工作：在關卡一進入場景樹時，把關卡中的各個重要系統
# 註冊到全域單例 Globals 上。
# 之後其他腳本就可以用 Globals.player、Globals.lock_on_system 等方式
# 直接取得這些系統，不用自己去找節點路徑。
# ==========================================================

# 註冊為全域類別 Level。
class_name Level
# 繼承 Node3D（3D 節點）。
extends Node3D


# 以下都是 @export 變數，在 Godot 編輯器中把對應節點拖進來設定。
# player：玩家。
@export var player: Player
# user_interface：使用者介面根節點。
@export var user_interface: UserInterface
# camera_controller：相機控制器。
@export var camera_controller: CameraController
# lock_on_system：鎖定系統。
@export var lock_on_system: LockOnSystem
# backstab_system：背刺系統。
@export var backstab_system: BackstabSystem
# dizzy_system：暈眩（處決）系統。
@export var dizzy_system: DizzySystem
# checkpoint_system：檢查點系統。
@export var checkpoint_system: CheckpointSystem
# music_system：音樂系統。
@export var music_system: MusicSystem
# void_death_system：掉落虛空死亡系統。
@export var void_death_system: VoidDeathSystem


# _enter_tree()：節點「進入場景樹」時呼叫，比 _ready() 更早執行。
# 用 _enter_tree 的原因：其他節點的 @onready 變數（在它們的 _ready 之前取值）
# 會讀取 Globals.xxx，所以必須在所有子節點 _ready 之前就先註冊好。
func _enter_tree():
	# 把各系統逐一存到 Globals 單例中。
	Globals.backstab_system = backstab_system
	Globals.dizzy_system = dizzy_system
	Globals.lock_on_system = lock_on_system
	Globals.camera_controller = camera_controller
	Globals.player = player
	Globals.user_interface = user_interface
	Globals.checkpoint_system = checkpoint_system
	Globals.music_system = music_system
	Globals.void_death_system = void_death_system
