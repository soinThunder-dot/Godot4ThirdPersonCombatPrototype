# meta-name: Player State
# meta-default: true
# meta-space-indent: 4

# ==========================================================
# 【檔案說明】player_state.gd（腳本範本 / Script Template）
# 這是 Godot 的「腳本範本」，用來快速建立新的「玩家狀態」腳本。
# 在編輯器新增腳本時選擇此範本，就會產生下列空白骨架。
# 最上面三行 meta-* 是範本設定，必須放在檔案最開頭：
#   meta-name：範本名稱（Player State = 玩家狀態）
#   meta-default：是否為預設範本
#   meta-space-indent：使用 4 個空格縮排
# 玩家使用「狀態機（State Machine）」設計：每個狀態（例如待機、移動、
# 攻擊、格擋、翻滾）各自一個腳本，狀態機依情況切換並呼叫下列函式。
# ==========================================================

# 類別名稱（用範本建立新狀態時，通常會改成自己的名稱）。
class_name PlayerState
# 繼承玩家狀態機的基底類別。
extends PlayerStateMachine


# 初始化：呼叫父類別的 _ready()，確保父類別的初始化也會執行。
func _ready():
	super._ready()


# enter()：進入此狀態時呼叫一次。
func enter() -> void:
	pass


# process_player()：處於此狀態時，每影格由狀態機呼叫，處理玩家的邏輯。
func process_player() -> void:
	pass


# 以下是作者保留、已被註解停用的範例函式：
# 處理移動動畫——有鎖定目標時啟用待機動畫，並把輸入方向傳給移動動畫。
#func process_movement_animations() -> void:
	#player.character.idle_animations.active = player.lock_on_target != null
	#player.character.movement_animations.dir =player.input_direction


# exit()：離開此狀態時呼叫一次。
# pass：代表「什麼都不做」，只是佔位，實際使用時再填入程式碼。
func exit() -> void:
	pass
