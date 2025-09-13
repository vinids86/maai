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
	movement_component = owner_node.find_child("MovementComponent")
	buffer_controller = owner_node.find_child("BufferController")
	stamina_component = owner_node.find_child("StaminaComponent")
	
	assert(owner_node != null, "StateMachine deve ser filha de um nó de ator (Player/Enemy).")
	assert(movement_component != null, "Não foi encontrado um nó 'MovementComponent' como irmão da StateMachine.")
	assert(buffer_controller != null, "Não foi encontrado um nó 'BufferController' como irmão da StateMachine.")
	assert(stamina_component != null, "Não foi encontrado um nó 'StaminaComponent' como irmão da StateMachine.")

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

func on_dodge_pressed(direction: Vector2, profile: DodgeProfile):
	if not current_state.allow_dodge():
		return
	
	if not profile or not stamina_component.try_consume(profile.stamina_cost):
		# TODO: Tocar um som de "falta de stamina" aqui.
		return
		
	transition_to("DodgeState", {"direction": direction, "profile": profile})

func on_attack_pressed():
	if current_state.can_initiate_attack():
		owner_node.reset_combo_chain()
		var profile = owner_node.get_next_attack_in_combo()
		if profile and stamina_component.try_consume(profile.stamina_cost):
			transition_to("AttackState", {"profile": profile})
	elif current_state.can_buffer_attack():
		buffer_controller.capture_attack()

func on_current_state_finished():
	if buffer_controller.consume_attack():
		var next_profile = owner_node.get_next_attack_in_combo()
		if next_profile and stamina_component.try_consume(next_profile.stamina_cost):
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
