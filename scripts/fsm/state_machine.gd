class_name StateMachine
extends Node
## 通用有限状态机（玩家与敌人共用）。
## 子节点中所有 State 会被自动注册，key 为节点名的小写 StringName。

@export var host_path: NodePath        # 指向宿主实体
@export var initial_state: NodePath    # 初始状态节点

var current_state: State
var states: Dictionary = {}            # name(StringName 小写) -> State


func _ready() -> void:
	for child in get_children():
		if child is State:
			var key := StringName(child.name.to_lower())
			states[key] = child
			child.host = get_parent() if host_path.is_empty() else get_node_or_null(host_path)
			child.state_machine = self
	if not initial_state.is_empty():
		var start := get_node_or_null(initial_state) as State
		if start != null:
			# 推迟到首帧末尾切换，确保宿主 @onready 引用已就绪
			change_to.call_deferred(StringName(start.name.to_lower()))


func change_to(state_name: StringName) -> void:
	if not states.has(state_name):
		push_warning("StateMachine: 未注册的状态 '%s'" % state_name)
		return
	var previous := StringName("")
	if current_state != null:
		previous = StringName(current_state.name.to_lower())
		current_state.exit()
	current_state = states[state_name]
	current_state.enter(previous)


func _process(delta: float) -> void:
	if current_state != null:
		current_state.state_process(delta)


func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.state_physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state != null:
		current_state.state_unhandled_input(event)
