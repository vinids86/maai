class_name SimpleStateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: SimpleState, to_state: SimpleState)

@export var initial_state_key: String = "SimplePatrolState"

var states: Dictionary = {}
var current_state: SimpleState
var owner_node: Node
var physics_component: Node
var wall_detector: WallDetectorComponent
var surface_contact_component: SurfaceContactComponent 

func setup(p_owner_node: Node, p_physics_comp: Node, p_surface_contact_comp: SurfaceContactComponent, p_wall_detector: WallDetectorComponent):
	owner_node = p_owner_node
	physics_component = p_physics_comp
	surface_contact_component = p_surface_contact_comp
	wall_detector = p_wall_detector
	
	assert(owner_node != null, "SimpleStateMachine: owner_node não pode ser nulo.")
	assert(physics_component != null, "SimpleStateMachine: physics_component não pode ser nulo.")

	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

	for child in get_children():
		if child is SimpleState:
			states[child.name] = child
			child.initialize(self, owner_node, physics_component, surface_contact_component, wall_detector)
	
	if states.has(initial_state_key):
		current_state = states[initial_state_key]
		current_state.enter({})
	else:
		push_error("SimpleStateMachine Error: Estado inicial '%s' não encontrado." % initial_state_key)

func process_physics(delta: float) -> Vector2:
	if not current_state:
		return Vector2.ZERO
	return current_state.process_physics(delta)

func emit_phase_change(data: Dictionary):
	emit_signal("phase_changed", data)
	
func get_current_state() -> SimpleState:
	return current_state

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		if current_state:
			current_state.handle_attack_outcome(result)

func on_current_state_finished(reason: Dictionary = {}):
	var outcome = reason.get("outcome")
	
	if outcome == "ATTACK_CONNECTED":
		transition_to("SimpleRecoilState", reason)
		return
	
	if outcome == "HIT":
		var knockback = reason.get("knockback_vector", Vector2.ZERO)
		transition_to("SimpleStaggerState", {"knockback_vector": knockback})
		return

	if states.has(initial_state_key):
		transition_to(initial_state_key)

func transition_to(new_state_key: String, args: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("SimpleStateMachine Error: Estado '%s' não existe." % new_state_key)
		return

	var new_state = states[new_state_key]
	var previous_state = current_state
	
	if previous_state:
		previous_state.exit()

	current_state = new_state
	current_state.enter(args)
	emit_signal("transitioned", previous_state, current_state)
