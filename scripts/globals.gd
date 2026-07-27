# 全域單例 (Autoload/Singleton) — Globals
# 用途：集中存放整個遊戲共用的重要節點參照，讓其他場景可以透過 Globals.xxx 直接存取，
# 無需逐層 get_node() 查找，方便跨場景共享資料。
extends Node

# 玩家角色節點本身的參照，方便其他系統（如鍵盤、UI、敌人 AI）直接存取玩家狀態
var player : Player
# 鏡頭控制器，負責第三人稱鏡頭跟隨、旋轉與碰撞迴避等邏輯
var camera_controller: CameraController
# 鎖定系統（Lock-On），負責鎖定目標敌人並讓鏡頭/攻擊對準目標
var lock_on_system: LockOnSystem
# 背刺系統，判斷玩家是否從敌人背後發動額外傷害的背刺攻擊
var backstab_system: BackstabSystem
# 暈進系統，處理角色被擊昇後進入省人事/無法行動的狀態與計時
var dizzy_system: DizzySystem
# 存點（檢查點）系統，負責紀錄玩家目前的存點位置以及復活邏輯
var checkpoint_system: CheckpointSystem
# 音樂系統，負責背景音樂的播放、切換與淡入淡出控制
var music_system: MusicSystem
# 跳空/死亡系統，當玩家掉落地圖外或掉入深淵時觸發重新定位或扣血邏輯
var void_death_system: VoidDeathSystem

# 使用者介面（HUD/菜單）的根節點參照，方便其他系統更新血條、指標等 UI 元素
var user_interface: UserInterface
# 除錯用的文字標籤，可在畫面上顯示自定義的除錯資訊
var debug_label: Label

# 全域資源字典，用來存放需要跨場景保留的任意資料（例如共用的 Resource 或自定義變數）
var resources: Dictionary
