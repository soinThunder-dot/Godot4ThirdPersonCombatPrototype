# 使用者介面根節點：整合管理 HUD、檢查點介面與死亡畫面等子介面元件
class_name UserInterface
extends Control

@onready var hud: HeadsUpDisplay = $HUD
@onready var checkpoint_interface: CheckpointInterface = $CheckpointInterface
@onready var death_screen: DeathScreen = $DeathScreen
