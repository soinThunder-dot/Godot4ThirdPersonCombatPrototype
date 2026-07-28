# NPC 不穩定値顯示器：顯示不穩定値進度，達到滿值時顯示發光效果
class_name NPCInstabilityBar
extends Node2D

# 顏色漸變，依不穩定百分比取樣以改變顯示顏色
@export var color_gradient: Gradient

var current_instability: float
var max_instability: float
var should_be_visible: bool = false

# 記錄不穩定條圓形初始的 x 軸縮放值，作為滿值基準
var _default_instability_sprite_scale_x: float

@onready var instability_bar: Node2D = $Instability
@onready var glare: Node2D = $Glare


func _ready():
	_default_instability_sprite_scale_x = instability_bar.scale.x


func _process(_delta: float) -> void:
	var instability_percentage = current_instability / max_instability
	
	# 不穩定値為零時自動隱藏
	if is_zero_approx(instability_percentage):
		should_be_visible = false
	
	# 依百分比線性插值縮放條圖形
	instability_bar.scale.x = lerp(
		0.0, 
		_default_instability_sprite_scale_x,
		instability_percentage
	)
	
	# 依百分比從顏色漸變取得對應顏色
	instability_bar.self_modulate = color_gradient.sample(instability_percentage)
	
	# 達到滿值時顯示發光特效
	if is_equal_approx(instability_percentage, 1.0):
		glare.visible = true
