class_name PlayerAnimations
extends CharacterAnimations

## 玩家角色動畫集合類別，集中声明並暴露玩家所需的各項動畫子系統

# idle_animations：静止動畫子系統
@export var idle_animations: IdleAnimations
# movement_animations：移動動畫子系統
@export var movement_animations: MovementAnimations
# jump_animations：跳躍動畫子系統
@export var jump_animations: JumpAnimations
# melee_animations：近戰攻擊動畫子系統
@export var melee_animations: MeleeAnimations
# block_animations：防御/格擋動畫子系統
@export var block_animations: BlockAnimations
# parry_animations：格挡動畫子系統
@export var parry_animations: ParryAnimations
# hit_and_death_animations：受擊/死亡動畫子系統
@export var hit_and_death_animations: HitAndDeathAnimations
# dizzy_victim_animations：晴晐受害者動畫子系統
@export var dizzy_victim_animations: DizzyVictimAnimations
# dizzy_finisher_animations：晴晐終結技動畫子系統
@export var dizzy_finisher_animations: DizzyFinisherAnimations
# drink_animations：飲酒動畫子系統
@export var drink_animations: DrinkAnimations
# sit_animations：坐下動畫子系統
@export var sit_animations: SitAnimations
