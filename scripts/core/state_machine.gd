class_name StateMachine
extends Node

# --- SINAL ÚNICO ---
# O nosso novo sinal unificado. Ele transporta um dicionário com todo o contexto.
signal phase_changed(phase_data: Dictionary)

# --- CONFIGURAÇÃO ---
@export var initial_state_key: String = "LocomotionState"

# --- COMPONENTES E ESTADOS ---
var states: Dictionary = {}
var current_state: State
var owner_node: Node
var movement_component: Node
var buffer_controller: BufferController

func _ready():
	owner_node = get_parent()
	movement_component = owner_node.find_child("MovementComponent")
	buffer_controller = owner_node.find_child("BufferController")
	
	assert(owner_node != null, "StateMachine deve ser filha de um nó de ator (Player/Enemy).")
	assert(movement_component != null, "Não foi encontrado um nó 'MovementComponent' como irmão da StateMachine.")
	assert(buffer_controller != null, "Não foi encontrado um nó 'BufferController' como irmão da StateMachine.")

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.initialize(self, owner_node, movement_component)
	
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		# A responsabilidade de emitir o primeiro sinal agora é do próprio estado, na sua função enter().
		current_state.enter()
	else:
		push_error("StateMachine Error: Initial state '%s' not found." % initial_state_key)

func process_physics(delta: float, is_running: bool = false):
	if current_state:
		current_state.process_physics(delta, is_running)

func process_input(event: InputEvent):
	if current_state:
		current_state.process_input(event)

# --- FUNÇÃO PÚBLICA PARA EMITIR SINAIS ---
# Os estados irão chamar esta função para anunciar as suas mudanças de fase.
func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)

# --- INTENÇÕES DE INPUT ---
func on_dodge_pressed(direction: Vector2):
	if current_state.allow_dodge():
		transition_to("DodgeState", {"direction": direction})

func on_attack_pressed(profile: AttackProfile):
	if current_state.allow_attack():
		transition_to("AttackState", {"profile": profile})

# --- LÓGICA DE TRANSIÇÃO ---
func on_current_state_finished():
	if buffer_controller.consume_attack():
		var next_profile = owner_node.get_next_attack_in_combo()
		if next_profile:
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
	# A emissão do sinal foi REMOVIDA daqui.
	current_state.enter(args)
