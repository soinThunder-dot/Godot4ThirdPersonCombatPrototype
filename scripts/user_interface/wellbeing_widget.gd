# NPC 健康狀態小部件：整合顯示 NPC 的血條與不穩定値條
class_name WellbeingWidget
extends Node2D

@onready var health_bar: NPCHealthBar = $NPCHealthBar
@onready var instability_bar: NPCInstabilityBar = $NPCInstabilityBar
