class_name StateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: State, to_state: State)

@export var initial_state_key: String = "LocomotionState"

var states: Dictionary = {}
var current_state: State
var owner_node: Node
var physics_component: Node
var path_follower_component: Node
var buffer_component: BufferComponent
var action_cost_validator: ActionCostValidator
var surface_contact_component: SurfaceContactComponent
var wall_detector: WallDetectorComponent
var counter_executor_component: Node

func setup(p_owner_node: Node, p_physics_comp: Node, p_path_follower_comp: Node, p_buffer_comp: BufferComponent, p_action_cost_validator: ActionCostValidator, p_surface_contact_comp: SurfaceContactComponent, p_wall_detector: WallDetectorComponent, p_counter_executor_comp: Node):
	owner_node = p_owner_node
	physics_component = p_physics_comp
	path_follower_component = p_path_follower_comp
	buffer_component = p_buffer_comp
	action_cost_validator = p_action_cost_validator
	surface_contact_component = p_surface_contact_comp
	wall_detector = p_wall_detector
	counter_executor_component = p_counter_executor_comp
	assert(owner_node != null, "StateMachine: owner_node não pode ser nulo.")
	assert(physics_component != null, "StateMachine: physics_component não pode ser nulo.")
	assert(path_follower_component != null, "StateMachine: path_follower_component não pode ser nulo.")
	assert(buffer_component != null, "StateMachine: buffer_component não pode ser nulo.")
	assert(action_cost_validator != null, "StateMachine: action_cost_validator não pode ser nulo.")
	assert(surface_contact_component != null, "StateMachine: surface_contact_component não pode ser nulo.")
	assert(wall_detector != null, "StateMachine: wall_detector não pode ser nulo.")
	assert(counter_executor_component != null, "StateMachine: counter_executor_component não pode ser nulo.")
	counter_executor_component.initialize(owner_node, self)
	var health_component = owner_node.find_child("HealthComponent")
	if health_component:
		health_component.died.connect(_on_owner_died)

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.initialize(self, owner_node, physics_component, path_follower_component, surface_contact_component, wall_detector, counter_executor_component)
	
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
	if not current_state: return Vector2.ZERO
	return current_state.process_physics(delta, walk_direction, is_running)

func process_input(event: InputEvent):
	if current_state: current_state.process_input(event)

func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)
	
func get_current_state() -> State:
	return current_state

func query_buffered_action() -> Dictionary:
	if buffer_component: return buffer_component.consume()
	return {}

# --- INPUT HANDLERS ---

func on_jump_pressed(profile: JumpProfile):
	var result: InputHandlerResult = current_state.handle_jump_input(profile)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				var transition_args = {"profile": profile, "apply_jump_impulse": true}
				if result.context.get("is_wall_jump", false):
					transition_args["is_wall_jump"] = true
				transition_to("AirborneState", transition_args)
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.JUMP, {"profile": profile})
		InputHandlerResult.Status.CONSUMED:
			pass

func on_jump_released() -> void:
	if current_state and current_state.has_method("on_jump_released"):
		current_state.on_jump_released()

func on_dodge_pressed(direction: Vector2, profile: DodgeProfile):
	var result: InputHandlerResult = current_state.handle_dodge_input(direction, profile)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("DodgeState", {"direction": direction, "profile": profile})
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.DODGE, {"direction": direction, "profile": profile})
		InputHandlerResult.Status.CONSUMED:
			pass

func on_dash_pressed(profile: DashProfile):
	var result: InputHandlerResult = current_state.handle_dash_input(profile)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				transition_to("DashState", {"profile": profile})
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.DASH, {"profile": profile})
		InputHandlerResult.Status.CONSUMED:
			pass

func on_attack_pressed(profile: AttackProfile):
	var result: InputHandlerResult = current_state.handle_attack_input(profile)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:			
			var profile_to_use: AttackProfile = result.context.get("override_profile", profile)
			if action_cost_validator.try_pay_costs(profile_to_use):
				buffer_component.clear()
				if current_state.name == "AirborneState" or current_state.name == "AirAttackState":
					transition_to("AirAttackState", {"profile": profile_to_use})
				else:
					transition_to("AttackState", {"profile": profile_to_use})
		InputHandlerResult.Status.REJECTED:			
			var profile_to_buffer = result.context.get("override_profile", profile)
			buffer_component.capture(BufferComponent.BufferedAction.ATTACK, {"profile": profile_to_buffer})
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
			buffer_component.capture(BufferComponent.BufferedAction.PARRY, {"profile": profile})
		
func on_sequence_skill_pressed(skill_attack_set: AttackSet):
	var result: InputHandlerResult = current_state.handle_sequence_skill_input(skill_attack_set)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if skill_attack_set and not skill_attack_set.attacks.is_empty():
				buffer_component.clear()
				var sequence = ActionSequence.new(skill_attack_set.attacks)
				transition_to("SequenceState", {"sequence_context": sequence})
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.SEQUENCE_SKILL, {"skill_set": skill_attack_set})
		InputHandlerResult.Status.CONSUMED:
			pass

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		if current_state: current_state.handle_attack_outcome(result)

		match result.attacker_outcome:
			ContactResult.AttackerOutcome.PARRIED:
				if current_state.handle_attacker_parried(result):
					transition_to("ParriedState", {"profile": owner_node.get_parried_profile(), "knockback_vector": result.knockback_vector})
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				transition_to("FinisherReadyState", {"profile": owner_node.get_finisher_profile(), "target": result.defender_node})
			ContactResult.AttackerOutcome.TRADE_LOST:
				transition_to("StaggerState", {"profile": owner_node.get_stagger_profile()})
			ContactResult.AttackerOutcome.DODGE_COUNTERED_VULNERABLE:
				transition_to("CounteredVulnerableState", {"result": result})

# --- TRANSITIONS & LOGIC ---

func on_current_state_finished(reason: Dictionary = {}):
	var outcome = reason.get("outcome")
	if outcome:
		match outcome:
			"FELL_OFF":
				owner_node.reset_air_actions()
				transition_to("AirborneState", { "allow_coyote": true })
				return
			"WALL_CONTACT":
				owner_node.reset_air_actions()
				transition_to("WallSlideState", {"profile": owner_node.get_wall_slide_profile()})
				return
			"DODGE_COUNTER_READY":
				transition_to("CounterReadyState", {"result": reason.get("result")})
				return
			"BLOCKED":
				transition_to("BlockStunState", {"profile": owner_node.get_block_stun_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return
			"GUARD_BROKEN":
				transition_to("GuardBrokenState", {"profile": owner_node.get_guard_broken_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return
			"FINISHER_HIT":
				reason["profile"] = owner_node.get_stagger_profile()
				transition_to("StaggerState", reason)
				return
			"HIT", "POISE_BROKEN":
				transition_to("StaggerState", {"profile": owner_node.get_stagger_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return

	if owner_node.is_on_floor():
		owner_node.reset_air_actions()

	var buffered_data = buffer_component.consume()
	if buffered_data:
		match buffered_data.action:
			BufferComponent.BufferedAction.JUMP:
				var j_profile: JumpProfile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(j_profile):
					transition_to("AirborneState", {"profile": j_profile, "apply_jump_impulse": true})
					return
			BufferComponent.BufferedAction.DASH:
				var d_profile: DashProfile = buffered_data.context.get("profile")
				if owner_node is CharacterBody2D and not owner_node.is_on_floor():
					transition_to("AirborneState")
				on_dash_pressed(d_profile)
				return
			BufferComponent.BufferedAction.ATTACK:
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					if current_state.name == "AirborneState" or current_state.name == "AirAttackState":
						transition_to("AirAttackState", {"profile": profile})
					else:
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

	if owner_node.is_on_floor():
		var profile = owner_node.get_locomotion_profile()
		transition_to(initial_state_key, {"profile": profile})
	else:
		transition_to("AirborneState")

func transition_to(new_state_key: String, args: Dictionary = {}):
	if current_state is DeathState: return
	if not states.has(new_state_key): return

	var new_state = states[new_state_key]
	if new_state == current_state and not new_state.allow_reentry(): return

	var previous_state = current_state
	if previous_state: previous_state.exit()

	current_state = new_state
	current_state.enter(args)
	emit_signal("transitioned", previous_state, current_state)
