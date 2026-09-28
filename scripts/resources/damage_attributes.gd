# ==========================================================
# 【檔案說明】damage_attributes.gd
# 這個 Resource 保存一次傷害事件相關的數值設定，可在 Inspector 以資源形式編輯或重複使用。
# 它包含命中生命值傷害、不同情況下增加的失衡值，以及被攻擊者要套用的擊退設定。
# static create() 提供程式建立 DamageAttributes 實例的便利入口。
# ==========================================================

# 註冊為可在 Godot 中識別的 DamageAttributes 類別。
class_name DamageAttributes
# 繼承 Resource，代表此類資料可作為資源保存與重用，而不是場景中的節點。
extends Resource


# 【繁體中文說明】受擊實體命中時要承受的生命值傷害。
## Receiving entity damage on health on hit
# 在 Inspector 可調整命中造成的生命值扣除量，預設為 10。
@export var health: float = 10.0

# 【繁體中文說明】受擊實體被命中時增加的失衡值。
## Receiving entity instability on hit
# 命中時套用的失衡數值，預設為 20。
@export var hit_instability: float = 20.0
# 【繁體中文說明】受擊實體成功格擋時增加的失衡值。
## Receiving entity instability on block
# 格擋時套用的失衡數值，預設為 20。
@export var block_instability: float = 20.0
# 【繁體中文說明】受擊實體成功反擊／彈開時增加的失衡值。
## Receiving entity instability on parry
# 反擊時套用的失衡數值，預設為 5。
@export var parry_instability: float = 5.0

# 【繁體中文說明】此實體遭到反擊／彈開時要增加的失衡值。
## This entity got parried
# 此資源作為攻擊來源遭到彈開時使用的失衡數值，預設為 30。
@export var got_parried_instability: float = 30.0

# 指定命中後套用的次級移動／擊退資源；預設載入專案內的 DefaultSecondaryMovement.tres。
@export var knockback: SecondaryMovement = \
	preload("res://resources/DefaultSecondaryMovement.tres")


# create：建立並回傳一份新的 DamageAttributes 資源。
# _health、各種 _*_instability 分別是傷害與失衡數值；_knockback 是要套用的次級移動設定。
# static 表示可直接透過類別呼叫，不必先建立 DamageAttributes 物件。
static func create(
	_health: float,
	_hit_instability: float,
	_block_instability: float,
	_parry_instability: float,
	_knockback: SecondaryMovement
) -> DamageAttributes:
	# 建立新的資源實例，並逐一複製傳入的設定值。
	var instance = DamageAttributes.new()
	instance.health = _health
	instance.hit_instability = _hit_instability
	instance.block_instability = _block_instability
	instance.parry_instability = _parry_instability
	instance.knockback = _knockback
	# 回傳完成設定的資源，供呼叫端作為一組傷害屬性使用。
	return instance
