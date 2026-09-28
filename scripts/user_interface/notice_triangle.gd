# ==========================================================
# 【檔案說明】notice_triangle.gd
# 這是「察覺三角形」的腳本，顯示在敵人頭上（類似潛行遊戲的警覺指示）。
# 三角形內部會隨著敵人「察覺程度」逐漸被填滿：
#   原理是用一個遮罩（TriangleMask）上下移動，露出更多或更少的內部三角形。
# 外部（通常是敵人的察覺元件）會每影格呼叫這裡的 process_xxx 函式來更新：
#   填滿程度、縮放大小、顏色、透明度。
# ==========================================================

# 註冊為全域類別 NoticeTriangle。
class_name NoticeTriangle
# 繼承 Sprite2D：這個節點本身就是三角形的外框圖片。
extends Sprite2D


# original_scale：記錄三角形原本的縮放值，之後縮放都以它為基準相乘。
var original_scale: Vector2

# ---------- 子節點參考 ----------
# background_triangle：三角形的背景（底色）。
@onready var background_triangle: Sprite2D = $BackgroundTriangle
# triangle_mask：遮罩節點，透過調整它的 offset.y 來控制內部三角形露出多少。
@onready var triangle_mask: Sprite2D = $TriangleMask
# inner_triangle：內部被填滿的三角形（位於遮罩底下，是遮罩的子節點）。
@onready var inner_triangle: Sprite2D = $TriangleMask/InsideTriangle


# 初始化：記錄原始縮放。
func _ready():
	original_scale = scale


# process_mask_offset(value)：依察覺程度設定遮罩的垂直偏移。
# value：察覺程度，通常介於 0.0（完全沒察覺）到 1.0（完全察覺）。
func process_mask_offset(value: float) -> void:
	# 把察覺程度換算成遮罩的 y 偏移量並套用。
	triangle_mask.offset.y = get_mask_offset(value)


# process_scale(expand_scale)：設定三角形的縮放倍率。
# 例如察覺滿時讓三角形短暫放大，產生「彈跳」強調效果。
func process_scale(expand_scale: float) -> void:
	# 原始縮放 × 倍率（x、y 同比例縮放）。
	scale = original_scale * Vector2(expand_scale, expand_scale)


# process_colour(colour)：讓三角形外框與內部顏色平滑變換到指定顏色。
# 例如：懷疑時黃色、發現玩家時紅色。
func process_colour(colour: Color) -> void:
	# 外框顏色：每次呼叫往目標顏色靠近 20%。
	self_modulate = lerp(
		self_modulate,
		colour,
		0.2
	)
	
	# 內部三角形顏色：同樣往目標顏色靠近 20%。
	inner_triangle.self_modulate = lerp(
		inner_triangle.self_modulate,
		colour,
		0.2
	)


# process_alpha(alpha)：讓整個三角形（含子節點）的透明度平滑變化到指定值。
func process_alpha(alpha: float) -> void:
	# modulate 會影響自身與所有子節點；每次呼叫靠近目標 10%。
	modulate.a = lerp(
		modulate.a,
		alpha,
		0.1
	)


# get_mask_offset(value)：將察覺程度（0~1）轉換為遮罩偏移量的線性公式。
#   value = 0 時 → 回傳 80.0（遮罩在下方，內部三角形幾乎看不到）
#   value = 1 時 → 回傳 18.0（-62 + 80，遮罩上移，內部三角形完全露出）
# 這些數字是依照三角形貼圖尺寸手動調整出來的。
func get_mask_offset(value: float) -> float:
	return -62.0 * value + 80.0
