class_name StateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: State, to_state: State)

@export var initial_state_key: String = "LocomotionState"

var states: Dictionary = {}
var current_state: State
var owner_node: Node
var movement_component: Node
var path_follower_component: Node
var buffer_component: BufferComponent
var action_cost_validator: ActionCostValidator

func setup(p_owner_node: Node, p_movement_comp: Node, p_path_follower_comp: Node, p_buffer_comp: BufferComponent, p_action_cost_validator: ActionCostValidator):
	owner_node = p_owner_node
	movement_component = p_movement_comp
	path_follower_component = p_path_follower_comp
	buffer_component = p_buffer_comp
	action_cost_validator = p_action_cost_validator
	
	assert(owner_node != null, "StateMachine: owner_node não pode ser nulo.")
	assert(movement_component != null, "StateMachine: movement_component não pode ser nulo.")
	assert(path_follower_component != null, "StateMachine: path_follower_component não pode ser nulo.")
	assert(buffer_component != null, "StateMachine: buffer_component não pode ser nulo.")
	assert(action_cost_validator != null, "StateMachine: action_cost_validator não pode ser nulo.")

	var health_component = owner_node.find_child("HealthComponent")
	if health_component:
		health_component.died.connect(_on_owner_died)

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.initialize(self, owner_node, movement_component, path_follower_component)
	
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		var profile = owner_node.get_locomotion_profile()
		current_state.enter({"profile": profile})
	else:
		push_error("StateMachine Error: Estado inicial '%s' não encontrado." % initial_state_key)

func _on_owner_died():
	if current_state is DeathState:
		return
	
	var profile = owner_node.get_death_profile()
	transition_to("DeathState", {"profile": profile})

func process_physics(delta: float, walk_direction: float, is_running: bool) -> Vector2:
	if current_state:
		return current_state.process_physics(delta, walk_direction, is_running)
	return Vector2.ZERO

func process_input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)
	
func get_current_state() -> State:
	return current_state

func on_jump_pressed(profile: JumpProfile):
	var result: InputHandlerResult = current_state.handle_jump_input(profile)
	
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("AirborneState", {"profile": profile, "apply_jump_impulse": true})

func on_dodge_pressed(direction: Vector2, profile: DodgeProfile):
	var result: InputHandlerResult = current_state.handle_dodge_input(direction, profile)
	
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("DodgeState", {"direction": direction, "profile": profile})
		InputHandlerResult.Status.REJECTED:
			var context = {"direction": direction, "profile": profile}
			buffer_component.capture(BufferComponent.BufferedAction.DODGE, context)
		InputHandlerResult.Status.CONSUMED:
			pass

func on_attack_pressed(profile: AttackProfile):
	var result: InputHandlerResult = current_state.handle_attack_input(profile)
	
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("AttackState", {"profile": profile})
		InputHandlerResult.Status.REJECTED:
			var profile_to_buffer: AttackProfile
			if result.context.has("override_profile"):
				profile_to_buffer = result.context["override_profile"]
			else:
				profile_to_buffer = profile
			
			var context_to_buffer = {"profile": profile_to_buffer}
			buffer_component.capture(BufferComponent.BufferedAction.ATTACK, context_to_buffer)
		InputHandlerResult.Status.CONSUMED:
			pass

func on_parry_pressed(profile: ParryProfile):
	var result: InputHandlerResult = current_state.handle_parry_input(profile)
	
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("ParryState", {"profile": profile})
		InputHandlerResult.Status.REJECTED:
			var context = {"profile": profile}
			buffer_component.capture(BufferComponent.BufferedAction.PARRY, context)
		InputHandlerResult.Status.CONSUMED:
			pass
		
func on_sequence_skill_pressed(skill_attack_set: AttackSet):
	var result: InputHandlerResult = current_state.handle_sequence_skill_input(skill_attack_set)

	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if skill_attack_set and not skill_attack_set.attacks.is_empty():
				buffer_component.clear()
				var sequence = ActionSequence.new(skill_attack_set.attacks)
				transition_to("SequenceState", {"sequence_context": sequence})
		InputHandlerResult.Status.REJECTED:
			var context = {"skill_set": skill_attack_set}
			buffer_component.capture(BufferComponent.BufferedAction.SEQUENCE_SKILL, context)
		InputHandlerResult.Status.CONSUMED:
			pass

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		match result.attacker_outcome:
			ContactResult.AttackerOutcome.PARRIED:
				var profile = owner_node.get_parried_profile()
				var knockback = result.knockback_vector
				transition_to("ParriedState", {"profile": profile, "knockback_vector": knockback})
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				var profile = owner_node.get_finisher_profile()
				transition_to("FinisherReadyState", {"profile": profile})
			ContactResult.AttackerOutcome.TRADE_LOST:
				var profile = owner_node.get_stagger_profile()
				transition_to("StaggerState", {"profile": profile})
			ContactResult.AttackerOutcome.COUNTERED:
				var profile = owner_node.get_countered_profile()
				transition_to("CounteredState", {"profile": profile})

func on_current_state_finished(reason: Dictionary = {}):
	var outcome = reason.get("outcome")
	if outcome:
		match outcome:
			"COUNTER_SUCCESS":
				var context = reason.get("context")
				if context:
					var target = context.attacker_node
					var riposte_profile = owner_node.get_mikiri_riposte_profile()
					var args = {"target": target, "profile": riposte_profile}
					
					var buffered_data = buffer_component.consume()
					if buffered_data and buffered_data.action == BufferComponent.BufferedAction.ATTACK:
						args["execute_immediately"] = true
					
					transition_to("ExecuteCounterState", args)
				return
			"BLOCKED":
				var profile = owner_node.get_block_stun_profile()
				var knockback_value = reason.get("knockback_vector", Vector2.ZERO)
				transition_to("BlockStunState", {"profile": profile, "knockback_vector": knockback_value})
				return
			"GUARD_BROKEN":
				var profile = owner_node.get_guard_broken_profile()
				var knockback_value = reason.get("knockback_vector", Vector2.ZERO)
				transition_to("GuardBrokenState", {"profile": profile, "knockback_vector": knockback_value})
				return
			"FINISHER_HIT":
				var args = reason
				args["profile"] = owner_node.get_stagger_profile()
				transition_to("StaggerState", args)
				return
			"HIT", "POISE_BROKEN":
				var profile = owner_node.get_stagger_profile()
				var knockback_value = reason.get("knockback_vector", Vector2.ZERO)
				transition_to("StaggerState", {"profile": profile, "knockback_vector": knockback_value})
				return

	var buffered_data = buffer_component.consume()

	if buffered_data:
		match buffered_data.action:
			BufferComponent.BufferedAction.ATTACK:
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					transition_to("AttackState", {"profile": profile})
					return
			BufferComponent.BufferedAction.DODGE:
				var direction = buffered_data.context.get("direction")
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					transition_to("DodgeState", {"direction": direction, "profile": profile})
					return
			BufferComponent.BufferedAction.PARRY:
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					transition_to("ParryState", {"profile": profile})
					return
			BufferComponent.BufferedAction.SEQUENCE_SKILL:
				var skill_set = buffered_data.context.get("skill_set")
				if skill_set and not skill_set.attacks.is_empty():
					var sequence = ActionSequence.new(skill_set.attacks)
					transition_to("SequenceState", {"sequence_context": sequence})
					return

	if owner_node is CharacterBody2D and owner_node.is_on_floor():
		var profile = owner_node.get_locomotion_profile()
		transition_to(initial_state_key, {"profile": profile})
	else:
		transition_to("AirborneState")


func transition_to(new_state_key: String, args: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("StateMachine Error: Tentativa de transição para o estado inexistente '%s'." % new_state_key)
		return

	var new_state = states[new_state_key]

	if new_state == current_state and not new_state.allow_reentry():
		return

	var previous_state = current_state
	
	if previous_state:
		previous_state.exit()

	current_state = new_state
	current_state.enter(args)
	
	emit_signal("transitioned", previous_state, current_state)
