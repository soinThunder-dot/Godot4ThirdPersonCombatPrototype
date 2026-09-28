# ==========================================================
# 【檔案說明】energy_beam.gd
# 這是持續發射投射物的非近戰效果腳本，可用 delay 設定每次發射間隔。
# 效果啟動後，每影格累計時間並在間隔到期時建立一枚 Projectile；
# 效果結束時停止後續發射，並將格擋事件連到敵人的失衡元件。
# ==========================================================

# 繼承 NonMeleeActionEffect，使用敵人非近戰效果共用介面中的 entity、effect() 與 end()。
extends NonMeleeActionEffect


# 要實例化的投射物場景資源，可於 Inspector 指定。
@export var projectile_scene: PackedScene
# 連續發射之間等待的秒數；較小的值會讓發射頻率提高。
@export var delay: float = 0.05


# _enabled 控制效果目前是否允許在每影格流程中繼續發射投射物。
var _enabled: bool = false

# 目前倒數到下一次發射的時間；節點初始化時以 delay 作為初始值。
@onready var _current_delay_val: float = delay


# _process(delta) 每影格呼叫；delta 是經過的秒數，用來倒數發射間隔。
func _process(delta: float):
	# 效果未啟用時立即結束本影格處理，不建立投射物。
	if not _enabled: return
	
	# 倒數尚未歸零時，扣除本影格經過的時間。
	if _current_delay_val > 0:
		_current_delay_val -= delta
	# 倒數已到期時發射一枚投射物，並把計時值重設為完整間隔。
	else:
		shoot()
		_current_delay_val = delay 


# effect() 在效果開始時呼叫，開啟每影格的發射流程。
func effect() -> void:
	_enabled = true


# end() 在效果結束時呼叫，關閉每影格的發射流程。
func end() -> void:
	_enabled = false


# shoot() 建立一枚投射物，放到敵人鎖定掛點並朝目標方向發射。
func shoot() -> void:
	# 從指定場景資源建立投射物節點。
	var projectile: Projectile = projectile_scene.instantiate()
	# 指定此投射物所屬的敵人實體。
	projectile.entity = entity
	# 把投射物加入效果節點之下，讓它進入場景樹。
	add_child(projectile)
	
	# 被格擋時透過 parried 訊號呼叫敵人的失衡元件，並預先傳入 10 與 false。
	projectile.parried.connect(
		entity.instability_component.got_parried.bind(10, false)
	)
	
	# 設定此效果所發射投射物的速度為每秒 15 個座標單位。
	projectile.speed = 15
	
	# 將投射物起點設為敵人的鎖定掛點世界座標。
	projectile.global_position = entity\
		.lock_on_component\
		.attachment_point\
		.global_position
	
	# 宣告目標世界座標；玩家使用鎖定掛點，其他目標使用原始程式中的 global_positio 成員。
	var target_pos: Vector3
	# 判斷目標類型並挑選瞄準座標：玩家瞄準鎖定掛點，否則讀取目標的 global_positio。
	if entity.target is Player:
		target_pos = entity.target.lock_on_attachment_point.global_position
	else:
		target_pos = entity.target.global_positio
	
	# 從敵人鎖定掛點朝目標座標計算方向向量，作為投射物的移動方向。
	projectile.direction = entity\
		.lock_on_component\
		.attachment_point\
		.global_position\
		.direction_to(target_pos)
	# 讓投射物朝向目標的全域位置，設定節點的朝向。
	projectile.look_at(entity.target.global_position)
