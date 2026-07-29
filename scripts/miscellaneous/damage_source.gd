# ==============================================================
# 傷害來源 (DamageSource)
#
# 用來定義一個可以對目標造成傷害的來源節點。
# 可設定傷害屬性、是否啟用傷害，並處理格檔（parry）與命中邏輯。
# ==============================================================
class_name DamageSource
extends Node3D

# 當這個傷害來源被格檔時發出的訊號
signal parried

# 使用這個傷害來源的實體（角色）
@export var entity: CharacterBody3D
# 是否開啟除錯訊息輸出
@export var debug: bool = false

# 是否目前可以造成傷害
@export var can_damage: bool = false
# 此傷害來源使用的傷害屬性資源
@export var damage_attributes: DamageAttributes = \
	preload("res://resources/DefaultDamageAttributes.tres")

# Used to make sure an entity is only hit
# once in a single instance. For example
# this may come in and out of a hitbox
# multiple times but it should only count
# as one hit if its the same instance.
# （用來確保同一個實體在單一情況下只會被打中一次，
# 例如可能會多次進出同一個攻擊判定範圍，
# 但若是同一個實例則只應算作一次命中）
var instance: int = 0

# 每幀處理：若開啟除錯模式則印出目前是否可造成傷害
func _process(_delta):
	if debug: print(can_damage)

## this damage source got parried by an entity
## （此傷害來源被某個實體格檔時呼叫）
func get_parried() -> void:
	parried.emit()

## Logic when this damage source successfully hits an entity
## Returns whether its going to free itsself
## （當此傷害來源成功命中實體時的處理邏輯，回傳是否要釋放自身）
func hit_considered() -> bool:
	# meant to be overridden
	# （此函式預期會被子類別覆寫）
	return false
