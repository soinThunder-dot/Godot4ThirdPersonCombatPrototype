# meta-name: Attack Strategy
# meta-default: true
# meta-space-indent: 4

# ==========================================================
# 【檔案說明】melee_attack.gd（腳本範本 / Script Template）
# 這是 Godot 的「腳本範本」，用來快速建立新的「近戰攻擊」腳本。
# 在編輯器新增腳本時選擇此範本，就會產生下列空白骨架。
# 最上面三行 meta-* 是範本設定，必須放在檔案最開頭：
#   meta-name：範本名稱（Attack Strategy = 攻擊策略）
#   meta-default：是否為預設範本
#   meta-space-indent：使用 4 個空格縮排
# 設計上採用「策略模式（Strategy）」：每一種攻擊（例如輕攻擊、重攻擊）
# 各自一個腳本，繼承 MeleeAttack，並實作以下函式。
# ==========================================================

# 類別名稱（用範本建立新攻擊時，通常會改成自己的名稱）。
class_name NewMeleeAttack
# 繼承近戰攻擊的基底類別。
extends MeleeAttack


# 初始化：設定攻擊名稱（範本中為空字串，使用時填入，例如 "light_attack"）。
func _ready():
	attack_name = ""


# play_attack()：播放攻擊動作（上半身/武器的攻擊動畫）。
func play_attack() -> void:
	pass


# receive_movement()：處理攻擊時角色的位移（例如攻擊時往前踏步）。
func receive_movement() -> void:
	pass


# play_legs()：播放腿部（下半身）的攻擊動畫。
func play_legs() -> void:
	pass


# perform_legs_transition()：開始腿部動畫的過渡（例如從移動切換到攻擊姿勢）。
func perform_legs_transition() -> void:
	pass


# end_legs_transition()：結束腿部動畫的過渡。
# pass：代表「什麼都不做」，只是佔位，實際使用時再填入程式碼。
func end_legs_transition() -> void:
	pass
