class_name StateMachine
extends Node

signal phase_changed(phase_data: Dictionary)

@export var initial_state_key: String = "LocomotionState"

var states: Dictionary = {}
var current_state: State
var owner_node: Node
var movement_component: Node
var buffer_controller: BufferController
var stamina_component: StaminaComponent

func _ready():
	owner_node = get_parent()
	movement_component = owner_node.find_child("MovementComponent") as MovementComponent
	buffer_controller = owner_node.find_child("BufferController") as BufferController
	stamina_component = owner_node.find_child("StaminaComponent") as StaminaComponent
	
	assert(owner_node != null, "StateMachine deve ser filha de um nó de ator (Player/Enemy).")
	assert(movement_component != null, "Não foi encontrado um nó 'MovementComponent' como irmão da StateMachine.")
	assert(buffer_controller != null, "Não foi encontrado um nó 'BufferController' como irmão da StateMachine.")
	assert(stamina_component != null, "Não foi encontrado um nó 'StaminaComponent' como irmão da StateMachine.")

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.initialize(self, owner_node, movement_component)
	
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		var profile = owner_node.get_locomotion_profile()
		current_state.enter({"profile": profile})
	else:
		push_error("StateMachine Error: Initial state '%s' not found." % initial_state_key)


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if current_state:
		current_state.process_physics(delta, walk_direction, is_running)

func process_input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)
	
func get_current_state() -> State:
	return current_state

func on_dodge_pressed(direction: Vector2, profile: DodgeProfile):
	if not current_state.allow_dodge():
		return
	
	if not profile or not stamina_component.try_consume(profile.stamina_cost):
		return
		
	transition_to("DodgeState", {"direction": direction, "profile": profile})

func on_attack_pressed():
	if current_state is FinisherReadyState:
		var profile = owner_node.get_finisher_attack_profile()
		if profile and stamina_component.try_consume(profile.stamina_cost):
			transition_to("AttackState", {"profile": profile})
		return

	if current_state.can_initiate_attack():
		owner_node.reset_combo_chain()
		var profile = owner_node.get_next_attack_in_combo()
		if profile and stamina_component.try_consume(profile.stamina_cost):
			transition_to("AttackState", {"profile": profile})
	elif current_state.can_buffer_attack():
		buffer_controller.capture_attack()

func on_parry_pressed():
	var profile = owner_node.get_parry_profile()
	print("current_state.allow_parry()", current_state)
	if current_state.allow_parry() and profile and stamina_component.try_consume(profile.stamina_cost):
		transition_to("ParryState", {"profile": profile})

func _on_impact_resolved(result: ImpactResolver.ContactResult):
	if result.defender_node == owner_node:
		match result.defender_outcome:
			ImpactResolver.ContactResult.DefenderOutcome.PARRY_SUCCESS:
				if current_state is ParryState:
					current_state.on_parry_success()
			ImpactResolver.ContactResult.DefenderOutcome.BLOCKED:
				var profile = owner_node.get_block_stun_profile()
				transition_to("BlockStunState", {"profile": profile})
			ImpactResolver.ContactResult.DefenderOutcome.GUARD_BROKEN:
				var profile = owner_node.get_guard_broken_profile()
				transition_to("GuardBrokenState", {"profile": profile})
			ImpactResolver.ContactResult.DefenderOutcome.HIT:
				var profile = owner_node.get_stagger_profile()
				transition_to("StaggerState", {"profile": profile, "knockback_vector": result.knockback_vector})
			ImpactResolver.ContactResult.DefenderOutcome.POISE_BROKEN:
				var profile = owner_node.get_stagger_profile()
				transition_to("StaggerState", {"profile": profile, "knockback_vector": result.knockback_vector})
	
	if result.attacker_node == owner_node:
		match result.attacker_outcome:
			ImpactResolver.ContactResult.AttackerOutcome.PARRIED:
				var profile = owner_node.get_parried_profile()
				transition_to("ParriedState", {"profile": profile})
			ImpactResolver.ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				var profile = owner_node.get_finisher_profile()
				transition_to("FinisherReadyState", {"profile": profile})

func on_current_state_finished():
	if buffer_controller.consume_attack():
		var next_profile = owner_node.get_next_attack_in_combo()
		if next_profile and stamina_component.try_consume(next_profile.stamina_cost):
			transition_to("AttackState", {"profile": next_profile})
			return

	owner_node.reset_combo_chain()
	var profile = owner_node.get_locomotion_profile()
	transition_to(initial_state_key, {"profile": profile})

func transition_to(new_state_key: String, args: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("StateMachine Error: Attempted to transition to nonexistent state '%s'." % new_state_key)
		return

	var new_state = states[new_state_key]

	if new_state == current_state:
		if not current_state.allow_reentry():
			return

	var previous_state = current_state
	
	if previous_state:
		previous_state.exit()
	
	current_state = new_state
	current_state.enter(args)
