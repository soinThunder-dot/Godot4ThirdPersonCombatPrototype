# ==========================================================
# 【檔案說明】projectile.gd
# 這是共用的「飛行投射物」基底腳本，負責讓投射物依指定方向與速度移動。
# 它也會在逾時或碰到指定碰撞層的靜態物件時自行刪除，並提供命中後的清理處理。
# 其他投射物效果可繼承本類別，設定 entity、方向與速度後使用。
# ==========================================================

# 註冊為全域類別 Projectile，讓其他腳本可用類別名稱宣告或取得這種節點。
class_name Projectile
# 繼承 DamageSource，沿用傷害來源系統提供的資料與行為。
extends DamageSource


# 投射物每秒移動的距離；此值可在 Godot Inspector 中由場景設定。
@export var speed: float = 2

# 投射物目前的移動方向；Vector3.FORWARD 是 Godot 3D 座標中的前方預設向量。
var direction: Vector3 = Vector3.FORWARD

# 取得子節點 Area，供此投射物監聽其他物理物件進入偵測區域的事件。
@onready var area: Area3D = $Area 


# _ready() 在節點進入場景樹並完成初始化時呼叫；在此安排逾時清除並接上碰撞事件。
func _ready():
	# 建立 10 秒後逾時的 SceneTreeTimer；timeout 訊號發出時呼叫 queue_free() 安全移除此投射物。
	get_tree().create_timer(10.0).timeout.connect(queue_free)
	# （回呼內容）Area 偵測到物體進入時，先忽略非 StaticBody3D；接著把碰撞層遮罩轉成二進位字串，若末位不是 1 就忽略，符合時便移除此投射物。
	area.body_entered.connect(
		func(body: Node3D):
			if not body is StaticBody3D: return
			var static_body: StaticBody3D = body
			var layers: String = String.num_uint64(
				static_body.collision_layer,
				2
			)
			if not layers.ends_with("1"): return
			queue_free()
	)


# _process(delta) 每影格呼叫；delta 是距離上一影格經過的秒數，乘上它可讓移動不依賴影格率。
func _process(delta: float) -> void:
	# 沿 direction 方向移動 speed × delta 的距離。
	position += direction * speed * delta


# hit_considered() 由傷害來源流程呼叫，用來回應這次命中是否被視為有效命中。
func hit_considered() -> bool:
	# 命中被處理後移除此投射物，避免它繼續留在場景中。
	queue_free()
	# 回傳 true，表示這次命中已被視為處理完成。
	return true
