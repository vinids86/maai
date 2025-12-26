class_name StateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: State, to_state: State)

@export_group("Settings")
@export var initial_state_key: String = "LocomotionState"

@export_group("Logic Components")
@export var buffer_component: BufferComponent
@export var action_cost_validator: ActionCostValidator
@export var health_component: HealthComponent 

# --- ESTADOS (Referências para Validação e Dicionário) ---
@export_group("Movement States")
@export var locomotion_state: State
@export var airborne_state: State
@export var dash_state: State
@export var dodge_state: State
@export var wall_slide_state: State

@export_group("Combat States")
@export var attack_state: State
@export var air_attack_state: State
@export var sequence_state: State
@export var finisher_ready_state: State
@export var counter_ready_state: State

@export_group("Reaction/Defense States")
@export var parry_state: State
@export var parried_state: State
@export var block_stun_state: State
@export var guard_broken_state: State
@export var stagger_state: State
@export var countered_vulnerable_state: State
@export var death_state: State

var states: Dictionary = {}
var current_state: State
var owner_node: Actor 

func initialize(p_owner_node: Actor):
	owner_node = p_owner_node
	
	_validate_dependencies()
	
	if owner_node.counter_executor_component:
		owner_node.counter_executor_component.initialize(owner_node, self)
	
	if health_component:
		health_component.died.connect(_on_owner_died)
	
	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	# --- REGISTRO MÍNIMO ---
	# Apenas populamos o dicionário 'states' usando os exports.
	# NÃO chamamos inicialização nos estados. Eles já se autoconfiguraram no _ready().
	
	var all_exported_states = [
		locomotion_state, airborne_state, dash_state, dodge_state, wall_slide_state,
		attack_state, air_attack_state, sequence_state, finisher_ready_state, counter_ready_state,
		parry_state, parried_state, block_stun_state, guard_broken_state, stagger_state, countered_vulnerable_state, death_state
	]

	for state in all_exported_states:
		if state:
			states[state.name] = state

	# Opcional: Se quiser suportar estados que não estão no export mas são filhos
	for child in get_children():
		if child is State and not states.has(child.name):
			states[child.name] = child
	
	# Start
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		var profile = null
		if owner_node.has_method("get_locomotion_profile"):
			profile = owner_node.get_locomotion_profile()
		current_state.enter({"profile": profile})
	else:
		push_error("StateMachine Error: Estado inicial '%s' não encontrado." % initial_state_key)

func _validate_dependencies():
	assert(owner_node != null, "StateMachine: initialize() não chamado.")
	assert(buffer_component, "StateMachine: Faltando BufferComponent")
	# ... adicione seus asserts de estados aqui ...

# ... (Mantenha Input Handlers e _transition_to iguais) ...
# Não há necessidade de alterá-los se eles usam 'current_state' e 'owner_node'
# que já estão configurados.

func on_jump_pressed(profile: JumpProfile):
	var result: InputHandlerResult = current_state.handle_jump_input(profile)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if action_cost_validator.try_pay_costs(profile):
				buffer_component.clear()
				var transition_args = {"profile": profile, "apply_jump_impulse": true}
				if result.context.get("is_wall_jump", false):
					transition_args["is_wall_jump"] = true
				_transition_to("AirborneState", transition_args)
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
				_transition_to("DodgeState", {"direction": direction, "profile": profile})
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
				_transition_to("DashState", {"profile": profile})
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
					_transition_to("AirAttackState", {"profile": profile_to_use})
				else:
					_transition_to("AttackState", {"profile": profile_to_use})
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
				_transition_to("ParryState", {"profile": profile})
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.PARRY, {"profile": profile})
		
func on_sequence_skill_pressed(skill_attack_set: AttackSet):
	var result: InputHandlerResult = current_state.handle_sequence_skill_input(skill_attack_set)
	match result.status:
		InputHandlerResult.Status.ACCEPTED:
			if skill_attack_set and not skill_attack_set.attacks.is_empty():
				buffer_component.clear()
				var sequence = ActionSequence.new(skill_attack_set.attacks)
				_transition_to("SequenceState", {"sequence_context": sequence})
		InputHandlerResult.Status.REJECTED:
			buffer_component.capture(BufferComponent.BufferedAction.SEQUENCE_SKILL, {"skill_set": skill_attack_set})
		InputHandlerResult.Status.CONSUMED:
			pass

func on_current_state_finished(reason: Dictionary = {}):
	var outcome = reason.get("outcome")
	if outcome:
		match outcome:
			"FELL_OFF":
				owner_node.reset_air_actions()
				_transition_to("AirborneState", { "allow_coyote": true })
				return
			"WALL_CONTACT":
				owner_node.reset_air_actions()
				_transition_to("WallSlideState", {"profile": owner_node.get_wall_slide_profile()})
				return
			"DODGE_COUNTER_READY":
				_transition_to("CounterReadyState", {"result": reason.get("result")})
				return
			"BLOCKED":
				_transition_to("BlockStunState", {"profile": owner_node.get_block_stun_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return
			"GUARD_BROKEN":
				_transition_to("GuardBrokenState", {"profile": owner_node.get_guard_broken_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return
			"FINISHER_HIT":
				reason["profile"] = owner_node.get_stagger_profile()
				_transition_to("StaggerState", reason)
				return
			"HIT", "POISE_BROKEN":
				_transition_to("StaggerState", {"profile": owner_node.get_stagger_profile(), "knockback_vector": reason.get("knockback_vector", Vector2.ZERO)})
				return

	if owner_node.is_on_floor():
		owner_node.reset_air_actions()

	var buffered_data = buffer_component.consume()
	if buffered_data:
		match buffered_data.action:
			BufferComponent.BufferedAction.JUMP:
				var j_profile: JumpProfile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(j_profile):
					_transition_to("AirborneState", {"profile": j_profile, "apply_jump_impulse": true})
					return
			BufferComponent.BufferedAction.DASH:
				var d_profile: DashProfile = buffered_data.context.get("profile")
				if owner_node is CharacterBody2D and not owner_node.is_on_floor():
					_transition_to("AirborneState")
				on_dash_pressed(d_profile)
				return
			BufferComponent.BufferedAction.ATTACK:
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					if current_state.name == "AirborneState" or current_state.name == "AirAttackState":
						_transition_to("AirAttackState", {"profile": profile})
					else:
						_transition_to("AttackState", {"profile": profile})
					return
			BufferComponent.BufferedAction.DODGE:
				var direction = buffered_data.context.get("direction")
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					_transition_to("DodgeState", {"direction": direction, "profile": profile})
					return
			BufferComponent.BufferedAction.PARRY:
				var profile = buffered_data.context.get("profile")
				if action_cost_validator.try_pay_costs(profile):
					_transition_to("ParryState", {"profile": profile})
					return
			BufferComponent.BufferedAction.SEQUENCE_SKILL:
				var skill_set = buffered_data.context.get("skill_set")
				if skill_set and not skill_set.attacks.is_empty():
					var sequence = ActionSequence.new(skill_set.attacks)
					_transition_to("SequenceState", {"sequence_context": sequence})
					return

	if owner_node.is_on_floor():
		var profile = owner_node.get_locomotion_profile()
		_transition_to(initial_state_key, {"profile": profile})
	else:
		_transition_to("AirborneState")

func _transition_to(new_state_key: String, args: Dictionary = {}):
	if current_state is DeathState: return
	if not states.has(new_state_key): return

	var new_state = states[new_state_key]
	if new_state == current_state and not new_state.allow_reentry(): return

	var previous_state = current_state
	if previous_state: previous_state.exit()

	current_state = new_state
	current_state.enter(args)
	emit_signal("transitioned", previous_state, current_state)

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		if current_state: current_state.handle_attack_outcome(result)

		match result.attacker_outcome:
			ContactResult.AttackerOutcome.PARRIED:
				if current_state.handle_attacker_parried(result):
					_transition_to("ParriedState", {"profile": owner_node.get_parried_profile(), "knockback_vector": result.knockback_vector})
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				_transition_to("FinisherReadyState", {"profile": owner_node.get_finisher_profile(), "target": result.defender_node})
			ContactResult.AttackerOutcome.TRADE_LOST:
				_transition_to("StaggerState", {"profile": owner_node.get_stagger_profile()})
			ContactResult.AttackerOutcome.DODGE_COUNTERED_VULNERABLE:
				_transition_to("CounteredVulnerableState", {"result": result})

func _on_owner_died():
	if current_state is DeathState:
		return
	var profile = null
	if owner_node.has_method("get_death_profile"):
		profile = owner_node.get_death_profile()
	_transition_to("DeathState", {"profile": profile})

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
