class_name State
extends Node
## 通用状态基类（玩家与敌人共用）。
## 状态作为 StateMachine 的子节点存在，通过 host 访问所属实体。

var host: Node          # 状态所属实体（玩家/敌人）
var state_machine       # 所属 StateMachine（类型 StateMachine，此处不写类型避免循环依赖）


func enter(_previous_state: StringName) -> void:
	pass


func exit() -> void:
	pass


func state_process(_delta: float) -> void:
	pass


func state_physics_process(_delta: float) -> void:
	pass


func state_unhandled_input(_event: InputEvent) -> void:
	pass
