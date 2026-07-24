class_name MeleeAnimations
extends BaseAnimations
## 近戰攻擊動畫控制類別
## 負責管理近戰武器攻擊時的動畫播放、連段(連續攻擊)邏輯、
## 傷害判定的開關、旋轉限制以及攻擊結束後的狀態重置。
## 此類別會與 AnimationTree 的 "Melee" 混合空間互動，控制攻擊與非攻擊狀態間的混合值(blend_amount)。

# 當攻擊發生「額外位移」(例如衝刺攻擊)時發出，攜帶目前攻擊資料供外部處理位移邏輯
signal secondary_movement(attack: MeleeAttack)
# 當需要套用傷害屬性(例如攻擊力、擊退量等)時發出，通知外部更新傷害資料
signal damage_attributes(attributes: DamageAttributes)
# 用來開關「是否可以造成傷害」的訊號，flag為true代表可造成傷害，weapon_names代表哪些武器節點生效
signal can_damage(flag: bool, weapon_names: Array[StringName])
# 用來控制角色是否可以旋轉(通常攻擊過程中會鎖定角色朝向)
signal can_rotate(flag: bool)
# 是否可以進行下一次連段攻擊的訊號
signal can_attack_again(flag: bool)
# 通知外部目前可以播放攻擊動畫了
signal can_play_animation
# 攻擊動作全部結束時發出的訊號
signal attacking_finished

# 儲存所有子節點(每個子節點都是一種MeleeAttack攻擊招式)的陣列
var attacks: Array[MeleeAttack]

# this means if an attacking animation is currently occurring
# 代表目前是否正在進行攻擊動畫(true=攻擊中)
var attacking: bool = false

# which attack to do, meant to control animations
# for successive attacks
# 目前要執行的攻擊等級(索引)，用於控制連段攻擊要撥放attacks陣列中的哪一招
var _level: int = 1

# this means that there is an intent to attack
# 代表玩家/AI有「想要攻擊」的意圖，尚未真正播放動畫
var _intent_to_attack: bool = false

# this means that the attack animation can play
# meant to control when the next attack plays
# when doing successive attacks
# 代表目前是否「允許播放」攻擊動畫，用來控制連續攻擊時下一招何時能觸發
var _can_play_animation: bool = true

# will be checked to decide whether to stop
# the attacking animatino
# 用來判斷是否該停止攻擊動畫(是否不再連段下去)
var _intend_to_stop_attacking: bool = true

# 暫存目前混合值(blend_amount)的插值計算結果
var _blend: float


func _ready() -> void:
	# 初始化時，將 AnimationTree 中「近戰」混合空間的混合量設為0(代表尚未進入近戰動畫)
	anim_tree.set(&"parameters/Melee/blend_amount", 0.0)

	# 將所有子節點(各種攻擊招式腳本)加入attacks陣列，方便之後依索引呼叫
	for child in get_children():
		attacks.append(child)


func _physics_process(_delta: float) -> void:
	if debug:
		pass

	# 如果目前允許播放攻擊動畫，且有攻擊意圖，就觸發攻擊
	if _can_play_animation and _intent_to_attack:
		_can_play_animation = false
		_intent_to_attack = false
		# 呼叫對應等級的攻擊招式來播放動畫
		attacks[_level].play_attack()
		# 廣播該攻擊的傷害屬性給外部(例如武器碰撞偵測腳本)
		damage_attributes.emit(attacks[_level].damage_attributes)

	# 判斷是否需要提早返回，不進行混合值更新(節省效能，避免不必要的計算)
	if BaseAnimations.should_return_blend(attacking, _blend): return

	# 取得目前AnimationTree的混合值參數
	var blend = anim_tree.get(&"parameters/Melee/blend_amount")
	if blend == null: return

	# 依照是否正在攻擊，將混合值以插值(lerp)的方式平滑過渡到1.0(攻擊中)或0.0(非攻擊)
	_blend = lerp(
		float(blend),
		1.0 if attacking else 0.0,
		0.15
	)

	# 將計算後的混合值寫回AnimationTree，讓動畫平滑地混合過渡
	anim_tree.set(
		&"parameters/Melee/blend_amount",
		_blend
	)


## 對外呼叫的攻擊函式，傳入要執行的攻擊等級(第幾段連段攻擊)
## override_can_play: 是否強制允許立刻播放動畫(略過原本的播放限制檢查)
func attack(level: int, override_can_play: bool = false) -> void:
	attacking = true
	_intent_to_attack = true
	_intend_to_stop_attacking = false
	if override_can_play:
		_can_play_animation = true
	_level = level


## 停止攻擊狀態，恢復角色可旋轉，並將攻擊動畫允許播放旗標重置
func stop_attacking() -> void:
	_can_play_animation = true
	can_rotate.emit(true)
	attacking = false


## 動畫事件回呼：接收到「禁止旋轉」的動畫通知時觸發
func receive_prevent_rotation() -> void:
	can_rotate.emit(false)


## 動畫事件回呼：攻擊動畫需要額外位移(例如向前撲擊)時觸發，轉發目前攻擊資料
func receive_secondary_movement() -> void:
	secondary_movement.emit(attacks[_level])


## 動畫事件回呼：播放攻擊對應的下半身(腳步)動畫
func receive_play_legs() -> void:
	attacks[_level].play_legs()


## 動畫事件回呼：停止腳步動畫的過渡，將該攻擊招式的腳步動畫轉場結束
## which_attack: 觸發此事件的動畫所屬的攻擊名稱
func receive_stop_legs(which_attack: StringName) -> void:
	# having a check for the level originating from the animation
	# against the current attack _level to see whether
	# to actually transition out of the current animation's legs
	# 檢查此動畫事件來源的攻擊名稱是否等於目前攻擊等級對應的招式名稱，
	# 避免因動畫混合觸發到錯誤招式的腳步結束邏輯
	if which_attack != attacks[_level].attack_name: return
	attacks[_level].end_legs_transition()


## 動畫事件回呼：允許造成傷害，並帶入可造成傷害的武器節點名稱清單
func receive_can_damage(weapon_names: Array = []) -> void:
	var typed_weapon_names: Array[StringName] = []
	typed_weapon_names.assign(weapon_names)
	can_damage.emit(true, typed_weapon_names)


## 動畫事件回呼：禁止造成傷害(例如攻擊硬直/收招階段)
func receive_cannot_damage(weapon_names: Array = []) -> void:
	var typed_weapon_names: Array[StringName] = []
	typed_weapon_names.assign(weapon_names)
	can_damage.emit(false, typed_weapon_names)


## 動畫事件回呼：通知外部可以進行下一次連段攻擊，並標記「意圖停止攻擊」為true(代表若無下一步輸入則會停止)
func receive_can_attack_again() -> void:
	can_attack_again.emit(true)
	_intend_to_stop_attacking = true


## 動畫事件回呼：通知外部目前不可進行連段攻擊(攻擊視窗已過)
func receive_cannot_attack_again() -> void:
	can_attack_again.emit(false)


## 動畫事件回呼：通知外部目前可以播放攻擊動畫，並將允許播放旗標設為true
func receive_can_play_animation() -> void:
	can_play_animation.emit()
	_can_play_animation = true


## 動畫事件回呼：攻擊動畫完全播放結束時觸發
## 將攻擊等級重置為0，並依照「是否打算停止攻擊」決定是否真正結束攻擊狀態
func receive_attack_finished() -> void:
	_level = 0
	if _intend_to_stop_attacking and attacking:
		attacking_finished.emit()
		stop_attacking()
