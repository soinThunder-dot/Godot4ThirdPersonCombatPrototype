# ==========================================================
# 【檔案說明】small_projectile.gd
# 這是敵人使用的小型直射投射物效果腳本，繼承非近戰動作效果的共用介面。
# 效果啟動時，它會從敵人的鎖定掛點產生一枚 Projectile，朝目標方向發射，
# 並把投射物被格擋（parried）時的事件連到敵人的失衡元件。
# ==========================================================

# 繼承 NonMeleeActionEffect，讓此腳本可作為敵人非近戰動作的一種具體效果。
extends NonMeleeActionEffect


# 要實例化的投射物場景；可在 Inspector 指定，場景中的節點需可作為 Projectile 使用。
@export var projectile_scene: PackedScene


# effect() 在此非近戰效果開始執行時呼叫，建立並設定一枚投射物。
func effect() -> void:
	# 從指定的 PackedScene 建立投射物節點實例。
	var projectile: Projectile = projectile_scene.instantiate()
	# 設定投射物所屬的實體，供傷害來源等共用系統識別。
	projectile.entity = entity
	# 將投射物加入此效果節點之下，使其進入場景樹並開始運作。
	add_child(projectile)
	
	# 當投射物發出 parried 訊號時，呼叫失衡元件的 got_parried；bind 將 35 與 false 預先附加為呼叫參數。
	projectile.parried.connect(
		entity.instability_component.got_parried.bind(35, false)
	)
	
	# 設定投射物速度為每秒 20 個座標單位。
	projectile.speed = 20
	
	# 從敵人的鎖定掛點讀取投射物的起始世界座標。
	projectile.global_position = entity\
		.lock_on_component\
		.attachment_point\
		.global_position
	
	# 宣告目標世界座標；依目標是否為玩家，使用對應的瞄準位置。
	var target_pos: Vector3
	# 若目標是 Player，瞄準玩家專用的鎖定掛點；否則使用目標物件的 global_positio 成員，照原始程式保留。
	if entity.target is Player:
		target_pos = entity.target.lock_on_attachment_point.global_position
	else:
		target_pos = entity.target.global_positio
	
	# 由敵人鎖定掛點朝目標座標計算單位方向，並指定為投射物的移動方向。
	projectile.direction = entity.lock_on_component.attachment_point.global_position.direction_to(target_pos)
	# 讓投射物節點朝向目標的世界座標，供其外觀方向與瞄準方向一致。
	projectile.look_at(entity.target.global_position)


# end() 在此效果結束時呼叫；目前沒有額外清理或停止處理。
func end() -> void:
	# pass 表示此函式刻意留空，保留共用效果介面的結束掛鉤。
	pass
