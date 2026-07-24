class_name BaseAnimations
extends Node

## 動畫基礎類別，作為所有動畫子類別的基礎，提供共用工具方法

# anim_tree：角色的動畫樹圖（AnimationTree）引用
@export var anim_tree: AnimationTree
# debug：是否啟用除錯輸出
@export var debug: bool = false


## should_return_blend：判斷混合値是否已達目標狀態（防止不必要的重複更新）
static func should_return_blend(flag: bool, blend: float) -> bool:
	return (flag and is_equal_approx(blend, 1.0)) or \
		(not flag and is_equal_approx(blend, 0.0))
