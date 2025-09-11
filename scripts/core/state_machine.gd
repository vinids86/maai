class_name StateMachine
extends Node

# --- SINAIS ---
signal state_changed(previous_state: State, new_state: State)

# --- CONFIGURAÇÃO ---
@export var initial_state_key: String = "LocomotionState"

# --- COMPONENTES E ESTADOS ---
var states: Dictionary = {}
var current_state: State
var owner_node: Node
var movement_component: Node
# A referência ao ActionTimer foi REMOVIDA.

func _ready():
	owner_node = get_parent()
	movement_component = owner_node.find_child("MovementComponent")
	
	assert(owner_node != null, "StateMachine deve ser filha de um nó de ator (Player/Enemy).")
	assert(movement_component != null, "Não foi encontrado um nó 'MovementComponent' como irmão da StateMachine.")

	# A conexão do sinal do timer foi REMOVIDA.

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.initialize(self, owner_node, movement_component)
	
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		current_state.enter()
		emit_signal("state_changed", null, current_state)
	else:
		push_error("StateMachine Error: Initial state '%s' not found." % initial_state_key)


func process_physics(delta: float, is_running: bool = false):
	if current_state:
		current_state.process_physics(delta, is_running)

func process_input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

# --- INTENÇÕES DE INPUT ---

func on_dodge_pressed(direction: Vector2):
	if current_state.allow_dodge():
		transition_to("DodgeState", {"direction": direction})

# --- LÓGICA DE TRANSIÇÃO ---

func on_current_state_finished():
	# TODO: Implementar lógica de buffer aqui no futuro.
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
	
	emit_signal("state_changed", previous_state, current_state)
