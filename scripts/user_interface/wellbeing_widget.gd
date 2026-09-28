# ==========================================================
# 【檔案說明】wellbeing_widget.gd
# 這是「敵人狀態小工具」的腳本（wellbeing = 健康狀態）。
# 每個敵人頭上會有一個這樣的小工具，把兩個條組合在一起：
#   - NPC 血條（NPCHealthBar）
#   - NPC 失衡條（NPCInstabilityBar）
# 這些小工具會被放在 HUD 的 WellbeingWidgets 容器節點底下。
# 本腳本只負責提供兩個子節點的參考，方便外部存取。
# ==========================================================

# 註冊為全域類別 WellbeingWidget。
class_name WellbeingWidget
# 繼承 Node2D（2D 節點）。
extends Node2D


# health_bar：此敵人的血條。
@onready var health_bar: NPCHealthBar = $NPCHealthBar
# instability_bar：此敵人的失衡條。
@onready var instability_bar: NPCInstabilityBar = $NPCInstabilityBar
