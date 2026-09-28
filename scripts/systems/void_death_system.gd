# ==========================================================
# 【檔案說明】void_death_system.gd
# 這是「掉落虛空死亡系統」的腳本。
# 關卡中會放置一些 Area3D 區域（例如懸崖下方），並加入 "void_area" 群組。
# 任何物體（玩家或敵人）掉進這些區域時，系統會發出 fallen_into_the_void 訊號，
# 讓其他腳本處理死亡（例如玩家直接死亡）。
# ==========================================================

# 註冊為全域類別 VoidDeathSystem。
class_name VoidDeathSystem
# 繼承 Node（最基本的節點）。
extends Node


# fallen_into_the_void：有物體掉入虛空時發出，參數是掉下去的物體。
signal fallen_into_the_void(body: Node3D)


# 初始化：找出所有虛空區域並連接訊號。
func _ready() -> void:
	# 取得場景中所有屬於 "void_area" 群組的節點。
	var void_areas = get_tree().get_nodes_in_group("void_area")
	for node in void_areas:
		# 當作 Area3D 使用（型別宣告）。
		var area: Area3D = node
		# 連接該區域的 body_entered（有物體進入）訊號到匿名函式：
		#   （回呼內容）發出 fallen_into_the_void 訊號，並把掉下去的物體傳出去；
		#   （回呼內容）在主控台印出除錯訊息，顯示是哪個物體掉進虛空。
		area.body_entered.connect(
			func(body: Node3D):
				fallen_into_the_void.emit(body)
				prints("Fallen in to the void:", body)
		)
