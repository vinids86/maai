class_name CounterExecutorComponent
extends Node

var _owner_node: Node
var _attack_executor: AttackExecutor
var _state_machine: StateMachine

func initialize(owner: Node, sm: StateMachine):
	_owner_node = owner
	_state_machine = sm
	_attack_executor = _owner_node.find_child("AttackExecutor")


func execute_counter(profile: CounterExecutionProfile, target: Node):
	if not _attack_executor:
		push_error("CounterExecutorComponent: AttackExecutor não inicializado.")
		return

	if profile is MikiriCounterProfile:
		_execute_mikiri(profile, target)
	elif profile is PushCounterProfile:
		_execute_push(profile, target)


func _execute_mikiri(profile: MikiriCounterProfile, target: Node):
	if not profile or not profile.executor_attack_profile or not target:
		return
	
	var phase_data = {
		"state_name": "ExecuteMikiriCounter",
		"phase_name": "EXECUTE",
		"profile": profile,
		"animation_to_play": profile.executor_animation,
		"sfx_to_play": profile.mikiri_sfx
	}
	_state_machine.emit_phase_change(phase_data)
	
	_attack_executor.execute(profile.executor_attack_profile)


func _execute_push(profile: PushCounterProfile, target: Node):
	if not profile or not profile.executor_attack_profile or not target:
		return

	if profile.switch_sides:
		var facing_component = _owner_node.find_child("FacingComponent")
		if facing_component:
			facing_component.facing_sign *= -1

	var phase_data = {
		"state_name": "ExecutePushCounter",
		"phase_name": "EXECUTE",
		"profile": profile,
		"animation_to_play": profile.executor_animation_name,
		"sfx_to_play": profile.sfx_executing
	}
	_state_machine.emit_phase_change(phase_data)
	
	_attack_executor.execute(profile.executor_attack_profile)
