# ==========================================================
# 【檔案說明】sweep_projectile.gd
# 這是敵人扇形掃射效果腳本，依次建立多枚 Projectile，讓它們沿左右不同偏移量發射。
# 投射方向都以鎖定目標為基準，再套用橫向位移形成一排散射彈幕；
# 每枚投射物被格擋時，也會通知敵人的失衡元件。
# ==========================================================

# 繼承 NonMeleeActionEffect，接入敵人非近戰動作效果的共用流程。
extends NonMeleeActionEffect


# 要用來產生每一枚掃射投射物的場景資源，可在 Inspector 中指定。
@export var projectile_scene: PackedScene


# effect() 在掃射效果開始時呼叫，取得發射與目標位置，再依序發射一組帶不同偏移的投射物。
func effect() -> void:
	# 從敵人的鎖定掛點取得世界座標，作為整排投射物的發射基準位置。
	var pos: Vector3 = entity\
		.lock_on_component\
		.attachment_point\
		.global_position
	# 宣告目標世界座標，並依目標類型選擇對應的瞄準點。
	var target_pos: Vector3
	# 玩家使用鎖定掛點作為瞄準位置；其他目標則使用其全域座標。
	if entity.target is Player:
		target_pos = entity.target.lock_on_attachment_point.global_position
	else:
		target_pos = entity.target.global_position
	
	# 以下 13 次呼叫共用發射位置與目標點；offset 的 X 值由右向左遞減，Z 值提供逐漸變化的散射偏移。
	# 中央一枚使用 Vector3.ZERO，其餘投射物分布在中央的兩側，形成橫向掃射彈幕。
	shoot(pos, Vector3(3, 0, 0.6), target_pos)
	shoot(pos, Vector3(2.5, 0, 0.5), target_pos)
	shoot(pos, Vector3(2, 0, 0.4), target_pos)
	shoot(pos, Vector3(1.5, 0, 0.3), target_pos)
	shoot(pos, Vector3(1, 0, 0.2), target_pos)
	shoot(pos, Vector3(0.5, 0, 0.1), target_pos)
	shoot(pos, Vector3.ZERO, target_pos)
	shoot(pos, Vector3(-0.5, 0, 0.1), target_pos)
	shoot(pos, Vector3(-1, 0, 0.2), target_pos)
	shoot(pos, Vector3(-1.5, 0, 0.3), target_pos)
	shoot(pos, Vector3(-2, 0, 0.4), target_pos)
	shoot(pos, Vector3(-2.5, 0, 0.5), target_pos)
	shoot(pos, Vector3(-3, 0, 0.6), target_pos)



# shoot(pos, offset, target_pos) 建立單枚投射物並完成方向、速度與位置設定。
# pos 是基準發射位置，offset 是相對於瞄準方向旋轉後的散射位移，target_pos 是目標世界座標。
func shoot(pos: Vector3, offset: Vector3, target_pos: Vector3) -> void:
	# 從指定場景實例化一枚投射物。
	var projectile: Projectile = projectile_scene.instantiate()
	# 設定投射物所屬的敵人實體。
	projectile.entity = entity
	# 加入場景樹，使投射物開始運作。
	add_child(projectile)
	
	# 投射物被格擋時，透過訊號連線呼叫失衡元件，並預先傳入 20 與 false 兩個參數。
	projectile.parried.connect(
		entity.instability_component.got_parried.bind(20, false)
	)
	
	# 掃射投射物的移動速度設定為每秒 5 個座標單位。
	projectile.speed = 5
	
	# 從敵人的鎖定掛點朝目標位置計算方向向量。
	var dir: Vector3 = entity\
		.lock_on_component\
		.attachment_point\
		.global_position\
		.direction_to(target_pos)
	# 指定移動方向；direction_to() 回傳由起點指向終點的單位方向向量。
	projectile.direction = dir
	
	# 以方向向量計算繞 Y 軸的水平旋轉角度，atan2 用來由 X、Z 分量求角度。
	var r: float = atan2(-dir.x, -dir.z)
	# 將計算所得的水平角度套用到投射物節點。
	projectile.rotation.y = r
	
	# 將投射物放到基準發射位置，再把散射偏移依同一水平角度旋轉後加到本地位置。
	projectile.global_position = pos
	projectile.position += offset.rotated(Vector3.UP, r)
