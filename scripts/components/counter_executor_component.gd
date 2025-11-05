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
		
	if not is_instance_valid(_owner_node) or not is_instance_valid(target):
		return

	if profile.switch_sides:
		var p_mask = _owner_node.collision_mask
		var t_mask = target.collision_mask
		
		_owner_node.collision_mask = p_mask & ~target.collision_layer
		target.collision_mask = t_mask & ~_owner_node.collision_layer
		
		var timer = get_tree().create_timer(profile.execution_duration)
		timer.timeout.connect(
			_restore_collisions.bind(_owner_node, target, p_mask, t_mask, profile.switch_sides)
		)

	var phase_data = {
		"state_name": "ExecutePushCounter",
		"phase_name": "EXECUTE",
		"profile": profile,
		"animation_to_play": profile.executor_animation_name,
		"sfx_to_play": profile.sfx_executing
	}
	_state_machine.emit_phase_change(phase_data)
	
	_attack_executor.execute(profile.executor_attack_profile)


func _restore_collisions(owner: Node, target: Node, owner_mask: int, target_mask: int, switch_sides: bool):
	if is_instance_valid(owner):
		owner.collision_mask = owner_mask
		if switch_sides:
			owner.facing_sign *= -1
			
	if is_instance_valid(target):
		if target.has_node("StateMachine"):
			var target_state_machine = target.get_node("StateMachine")
			if target_state_machine and target_state_machine.current_state and "DeathState" in target_state_machine.current_state.name:
				return
		
		target.collision_mask = target_mask
