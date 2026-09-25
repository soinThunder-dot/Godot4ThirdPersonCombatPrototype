# ==========================================================
# 【檔案說明】npc_instability_bar.gd
# 這是「NPC（敵人）失衡條」的腳本（類似《隻狼》的架勢條 / 軀幹值）。
# 敵人被攻擊或格擋時失衡值會上升，滿了之後通常可以處決或造成硬直。
# 功能：
#   1. 依失衡百分比縮放條的長度。
#   2. 依百分比從漸層（Gradient）中取色，例如由黃變紅。
#   3. 失衡值滿（100%）時顯示閃光（Glare）特效。
#   4. 失衡值歸零時標記為不需顯示。
# ==========================================================

# 註冊為全域類別 NPCInstabilityBar。
class_name NPCInstabilityBar
# 繼承 Node2D（2D 節點）。
extends Node2D


# color_gradient：顏色漸層（在編輯器中設定），
# 會依失衡百分比（0~1）取樣出對應的顏色。
@export var color_gradient: Gradient

# current_instability：目前失衡值（由外部更新）。
var current_instability: float
# max_instability：最大失衡值（用來計算百分比）。
var max_instability: float
# should_be_visible：失衡條是否應該顯示（實際顯示由外部管理者依此旗標處理）。
var should_be_visible: bool = false

# _default_instability_sprite_scale_x：失衡條滿值時的水平縮放（100% 基準）。
var _default_instability_sprite_scale_x: float

# instability_bar：失衡條本體節點。
@onready var instability_bar: Node2D = $Instability
# glare：失衡值滿時顯示的閃光特效節點。
@onready var glare: Node2D = $Glare


# 初始化：記錄失衡條原始（滿值）的水平縮放。
func _ready():
	_default_instability_sprite_scale_x = instability_bar.scale.x


# 每個畫面影格執行。
func _process(_delta: float) -> void:
	# 計算失衡百分比（0.0 ~ 1.0）。
	var instability_percentage = current_instability / max_instability
	
	# 失衡值歸零（近似 0）→ 不需要再顯示失衡條。
	if is_zero_approx(instability_percentage):
		should_be_visible = false
	
	# 依百分比設定失衡條長度：0% → 長度 0，100% → 原始長度。
	instability_bar.scale.x = lerp(
		0.0, 
		_default_instability_sprite_scale_x,
		instability_percentage
	)
	
	# 依百分比從漸層中取樣顏色，套用到失衡條上。
	instability_bar.self_modulate = color_gradient.sample(instability_percentage)
	
	# 失衡值滿（近似 1.0）→ 顯示閃光；否則隱藏閃光。
	if is_equal_approx(instability_percentage, 1.0):
		glare.visible = true
	else:
		glare.visible = false


# instability_increased(_instability)：敵人失衡值增加時由外部呼叫
# （通常連接到敵人失衡元件的訊號）。
# 參數 _instability 前面有底線，表示本函式沒有使用它，只是為了符合訊號的參數格式。
func instability_increased(_instability: float) -> void:
	# 失衡值增加了，標記失衡條需要顯示。
	should_be_visible = true
