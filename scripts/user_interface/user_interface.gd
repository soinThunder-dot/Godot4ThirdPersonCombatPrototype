# ==========================================================
# 【檔案說明】user_interface.gd
# 這是整個「使用者介面（UI）」的根節點腳本。
# 它本身沒有邏輯，只是把三大 UI 區塊集中起來，
# 讓其他腳本可以透過這個節點方便地存取：
#   - HUD（遊戲中常駐的抬頭顯示介面）
#   - 檢查點介面（存檔點選單）
#   - 死亡畫面
# ==========================================================

# 註冊為全域類別 UserInterface。
class_name UserInterface
# 繼承 Control（UI 節點）。
extends Control


# hud：抬頭顯示器（HeadsUpDisplay），包含敵人察覺指示、血條、鎖定標記等。
@onready var hud: HeadsUpDisplay = $HUD
# checkpoint_interface：檢查點（存檔點）選單介面。
@onready var checkpoint_interface: CheckpointInterface = $CheckpointInterface
# death_screen：玩家死亡時的畫面與演出。
@onready var death_screen: DeathScreen = $DeathScreen
