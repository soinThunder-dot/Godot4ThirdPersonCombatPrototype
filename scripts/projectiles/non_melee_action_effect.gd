# ==========================================================
# 【檔案說明】non_melee_action_effect.gd
# 這是敵人「非近戰動作效果」的共用基底腳本，提供敵人實體欄位與效果生命週期掛鉤。
# 具體效果腳本可繼承此類別，覆寫 effect() 執行效果內容，並覆寫 end() 處理結束時的工作。
# 本基底本身不執行攻擊邏輯，兩個方法目前都是空操作。
# ==========================================================

# 註冊為全域類別 NonMeleeActionEffect，供其他效果腳本以類別名稱繼承。
class_name NonMeleeActionEffect
# 繼承 Node，讓效果可以作為 Godot 場景樹中的節點運作。
extends Node


# 此效果所屬的敵人實體；export 讓場景或 Inspector 能指定 Enemy 參照。
@export var entity: Enemy


# effect() 是效果啟動時使用的共用掛鉤；子類可覆寫以執行具體效果。
func effect() -> void:
	# 基底版本不做任何事，pass 是 GDScript 的空操作敘述。
	pass


# end() 是效果結束時使用的共用掛鉤；子類可覆寫以停止效果或進行清理。
func end() -> void:
	# 基底版本不做任何事，保留一致的效果介面。
	pass
