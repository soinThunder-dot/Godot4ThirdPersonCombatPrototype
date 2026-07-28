# 玩家回血蔽子充電數顯示：顯示目前可使用的回血次數，並依照剩餘次數改變顏色
class_name PlayerHealthCharges
extends Control

@export var flask_color: Color = Color("8aff15")
@export var no_charges_color: Color = Color("556744")

@onready var label: Label = $Label
@onready var flask: Sprite2D = $Flask
@onready var player: Player = Globals.player


func _process(_delta):
	# 取得目前剩餘回血次數並更新文字顯示
	var charges_num: int = player.health_charge_component.current_charges
	label.text = String.num_int64(
		charges_num
	)
	
	# 次數用盡時顯示灰暗顏色，否則顯示正常蔽子顏色
	if charges_num == 0:
		flask.self_modulate = no_charges_color
	else:
		flask.self_modulate = flask_color
