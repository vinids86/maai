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
		current_state.enter()
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

func on_attack_pressed() -> void:
	var can_start: bool = false
	if current_state != null:
		can_start = current_state.can_initiate_attack()

	var can_buffer: bool = false
	if current_state != null:
		can_buffer = current_state.can_buffer_attack()

	if can_start:
		owner_node.reset_combo_chain()
		var profile: AttackProfile = owner_node.get_next_attack_in_combo()
		var has_profile: bool = profile != null
		var has_stamina: bool = false
		if has_profile:
			has_stamina = stamina_component.try_consume(profile.stamina_cost)
		if has_profile and has_stamina:
			transition_to("AttackState", {"profile": profile})
	elif can_buffer:
		buffer_controller.capture_attack()

func on_parry_pressed():
	if current_state.allow_parry():
		transition_to("ParryState")

func _on_impact_resolved(result: ImpactResolver.ContactResult) -> void:
	# DEFENSOR: trata desfecho do defensor
	if result.defender_node == owner_node:
		match result.defender_outcome:
			ImpactResolver.ContactResult.DefenderOutcome.PARRY_SUCCESS:
				if current_state is ParryState:
					current_state.on_parry_success()
			ImpactResolver.ContactResult.DefenderOutcome.BLOCKED:
				transition_to("StaggerState")
			ImpactResolver.ContactResult.DefenderOutcome.GUARD_BROKEN:
				transition_to("StaggerState") # Placeholder
			ImpactResolver.ContactResult.DefenderOutcome.HIT:
				transition_to("StaggerState")
			ImpactResolver.ContactResult.DefenderOutcome.POISE_BROKEN:
				transition_to("StaggerState")
			_:
				pass

	# ATACANTE: só nos importa se foi PARRIED
	if result.attacker_node == owner_node:
		if result.attacker_outcome == ImpactResolver.ContactResult.AttackerOutcome.PARRIED:
			transition_to("ParriedState")

func on_current_state_finished() -> void:
	var had_buffer: bool = buffer_controller.consume_attack()

	if had_buffer:
		var next_profile: AttackProfile = owner_node.get_next_attack_in_combo()
		var can_start: bool = false
		if next_profile != null:
			can_start = stamina_component.try_consume(next_profile.stamina_cost)
		if next_profile != null and can_start:
			transition_to("AttackState", {"profile": next_profile})
			return

	owner_node.reset_combo_chain()
	transition_to(initial_state_key)


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
