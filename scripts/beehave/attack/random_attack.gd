# 隨機攻擊行為節點：依照權重隨機選擇攻擊等級並執行攻擊
class_name RandomAttackLeaf
extends ActionLeaf

# 每種攻擊的權重陣列
@export var weights: Array[float]
# 攻擊後是否可以立即再次攻擊
@export var can_attack_afterwards: bool = false

# 累積權重陣列，用於加權隨機選擇
var _cumulative_weights: Array[float]
# 權重總和
var _total_weight: float


func _ready() -> void:
	# 建立累積權重表
	_cumulative_weights.append(weights[0])
	for i in range(1, len(weights)):
		_cumulative_weights.append(_cumulative_weights[i - 1] + weights[i])
	# 計算所有權重的總和
	_total_weight = weights.reduce(func(accum, number): return accum + number)


func tick(_actor: Node, blackboard: Blackboard) -> int:
	# 依權重總和產生隨機數值
	var rng: float = RandomNumberGenerator.new().randf() * _total_weight
	var which_attack: int = 0
	
	# 找出隨機數值落在哪個累積權重區間，決定攻擊等級
	for i in range(len(_cumulative_weights)):
		if rng <= _cumulative_weights[i]:
			which_attack = i
			break
	
	# 設定黑板值，觸發攻擊
	blackboard.set_value("attack_level", which_attack)
	blackboard.set_value("attack", true)
	# 如果允許攻擊後續動作，則設定可再次攻擊的標記
	if can_attack_afterwards:
		blackboard.set_value("can_attack", true)
	
	return SUCCESS
