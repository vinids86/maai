class_name BaseSimpleStateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: SimpleState, to_state: SimpleState)

@export_group("State Configuration")
@export var initial_state_key: String = ""
## Nome do nó na cena que representa o estado de Groggy (vulnerável).
@export var groggy_state_name: String = "SimpleGroggyState"
## Nome do nó na cena que representa o estado de Parried (interrupção leve).
@export var parried_state_name: String = "SimpleParriedState"

@export_group("Mechanics")
@export var parries_required_for_groggy: int = 1

var _current_parry_count: int = 0
var states: Dictionary = {}
var current_state: SimpleState
var owner_node: Node
var physics_component: Node
var wall_detector: WallDetectorComponent
var surface_contact_component: SurfaceContactComponent 

var _groggy_timer: float = 0.0

func setup(p_owner_node: Node, p_physics_comp: Node, p_surface_contact_comp: SurfaceContactComponent, p_wall_detector: WallDetectorComponent):
	owner_node = p_owner_node
	physics_component = p_physics_comp
	surface_contact_component = p_surface_contact_comp
	wall_detector = p_wall_detector
	
	assert(owner_node != null, "BaseSimpleStateMachine: owner_node não pode ser nulo.")
	assert(physics_component != null, "BaseSimpleStateMachine: physics_component não pode ser nulo.")

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	for child in get_children():
		if child is SimpleState:
			states[child.name] = child
			child.initialize(self, owner_node, physics_component, surface_contact_component, wall_detector)
	
	_current_parry_count = 0
	_start_initial_state()

func _start_initial_state():
	if not initial_state_key.is_empty() and states.has(initial_state_key):
		current_state = states[initial_state_key]
		current_state.enter({})
	elif not initial_state_key.is_empty():
		push_error("BaseSimpleStateMachine Error: Estado inicial '%s' não encontrado." % initial_state_key)

func process_physics(delta: float) -> Vector2:
	if _groggy_timer > 0:
		_groggy_timer -= delta
		if _groggy_timer <= 0 and current_state.name == groggy_state_name:
			on_current_state_finished({"outcome": "GROGGY_FINISHED"})

	if not current_state:
		return Vector2.ZERO
	return current_state.process_physics(delta)

func trigger_groggy(duration: float):
	_current_parry_count += 1
	if _current_parry_count < parries_required_for_groggy:
		var push_dir = Vector2.ZERO
		if is_instance_valid(GameManager.player_node):
			push_dir = (owner_node.global_position - GameManager.player_node.global_position).normalized()
			push_dir.y = 0
			if states.has(parried_state_name):
				transition_to(parried_state_name, {"direction": push_dir})
		return
	_current_parry_count = 0
	_groggy_timer = duration
	
	if current_state.name != groggy_state_name and states.has(groggy_state_name):
		transition_to(groggy_state_name)

func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)
	
func get_current_state() -> SimpleState:
	return current_state

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		if current_state:
			current_state.handle_attack_outcome(result)

func on_current_state_finished(reason: Dictionary = {}):
	
	if current_state.name == "SimpleDeathState":
		return
		
	var outcome = reason.get("outcome")
	if outcome == "HIT" or outcome == "ATTACK_CONNECTED":
		_decide_next_state(reason)
		return
		
	if _groggy_timer > 0:
		if current_state.name != groggy_state_name:
			if states.has(groggy_state_name):
				transition_to(groggy_state_name)
				return

	_decide_next_state(reason)

# Função abstrata para filhos implementarem
func _decide_next_state(_reason: Dictionary):
	pass

func transition_to(new_state_key: String, args: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("BaseSimpleStateMachine Error: Estado '%s' não existe." % new_state_key)
		return

	var new_state = states[new_state_key]
	var previous_state = current_state
	
	if previous_state:
		previous_state.exit()

	current_state = new_state
	current_state.enter(args)
	emit_signal("transitioned", previous_state, current_state)
