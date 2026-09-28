# ==========================================================
# 【檔案說明】player_health_charges.gd
# 這是「玩家補血次數」顯示的腳本（類似魂系遊戲的「原素瓶」/ 隻狼的「傷藥葫蘆」）。
# 畫面上會顯示一個藥瓶圖示和剩餘次數數字：
#   - 還有次數時，藥瓶是亮綠色
#   - 次數為 0 時，藥瓶變成暗灰綠色，提示玩家已經不能補血
# ==========================================================

# 註冊為全域類別 PlayerHealthCharges。
class_name PlayerHealthCharges
# 繼承 Control（UI 節點）。
extends Control


# flask_color：有補血次數時藥瓶的顏色（預設亮綠色 #8aff15），可在編輯器調整。
@export var flask_color: Color = Color("8aff15")
# no_charges_color：沒有補血次數時藥瓶的顏色（預設暗灰綠色 #556744）。
@export var no_charges_color: Color = Color("556744")

# label：顯示剩餘次數的文字標籤。
@onready var label: Label = $Label
# flask：藥瓶圖示。
@onready var flask: Sprite2D = $Flask
# player：從 Globals 取得玩家節點。
@onready var player: Player = Globals.player


# 每個畫面影格執行：更新次數文字與藥瓶顏色。
func _process(_delta):
	# 從玩家的「補血次數元件」讀取目前剩餘次數。
	var charges_num: int = player.health_charge_component.current_charges
	# String.num_int64(整數)：把整數轉成字串，顯示在標籤上。
	label.text = String.num_int64(
		charges_num
	)
	
	# 依剩餘次數切換藥瓶顏色。
	if charges_num == 0:
		# 沒有次數 → 暗色。
		flask.self_modulate = no_charges_color
	else:
		# 還有次數 → 亮綠色。
		flask.self_modulate = flask_color
