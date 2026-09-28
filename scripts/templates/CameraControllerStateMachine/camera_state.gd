# meta-name: Camera Controller State
# meta-default: true
# meta-space-indent: 4

# ==========================================================
# 【檔案說明】camera_state.gd（腳本範本 / Script Template）
# 這不是遊戲執行時會用到的腳本，而是 Godot 的「腳本範本」。
# 在 Godot 編輯器中「新增腳本」時，可以選擇這個範本，
# 自動產生一個「相機控制器狀態」的空白骨架，省去重複打字。
# 最上面三行 meta-* 是範本設定，必須放在檔案最開頭：
#   meta-name：範本在選單中顯示的名稱
#   meta-default：是否作為該類型的預設範本
#   meta-space-indent：產生腳本時用 4 個空格作為縮排
# 相機使用「狀態機（State Machine）」設計：每個狀態（例如自由視角、鎖定視角）
# 各自一個腳本，狀態機依情況切換目前狀態，並呼叫下列函式。
# ==========================================================

# 類別名稱（用範本建立新腳本時，通常會改成自己的名稱）。
class_name CameraControllersState
# 繼承相機控制器狀態機的基底類別。
extends CameraControllerStateMachine


# 初始化：呼叫父類別的 _ready()，確保父類別的初始化邏輯也會執行。
func _ready():
	super._ready()


# enter()：進入此狀態時呼叫一次（例如設定初始值）。
func enter() -> void:
	pass


# process_camera()：處於此狀態時，每影格由狀態機呼叫，處理相機的移動/旋轉邏輯。
func process_camera() -> void:
	pass


# process_unhandled_input(_event)：處於此狀態時，處理未被其他節點處理的輸入事件。
func process_unhandled_input(_event: InputEvent) -> void:
	pass


# exit()：離開此狀態時呼叫一次（例如清理或重設）。
# pass：代表「什麼都不做」，只是佔位用，實際使用時再填入程式碼。
func exit() -> void:
	pass
