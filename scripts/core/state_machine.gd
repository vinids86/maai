class_name StateMachine
extends Node

signal phase_changed(phase_data: Dictionary)
signal transitioned(from_state: State, to_state: State)

@export var initial_state_key: String = "LocomotionState"

var states: Dictionary = {}
var current_state: State
var owner_node: Node
var movement_component: Node
var buffer_component: BufferComponent
var stamina_component: StaminaComponent

func _ready():
	owner_node = get_parent()
	movement_component = owner_node.find_child("MovementComponent")
	buffer_component = owner_node.find_child("BufferComponent")
	stamina_component = owner_node.find_child("StaminaComponent")
	
	assert(owner_node != null, "StateMachine deve ser filha de um nó de ator (Player/Enemy).")
	assert(movement_component != null, "Não foi encontrado um nó 'MovementComponent' como irmão da StateMachine.")
	assert(buffer_component != null, "Não foi encontrado um nó 'BufferComponent' como irmão da StateMachine.")
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
	if current_state.allow_dodge():
		if profile and stamina_component.try_consume(profile.stamina_cost):
			buffer_component.clear()
			transition_to("DodgeState", {"direction": direction, "profile": profile})
	else:
		var context = {"direction": direction, "profile": profile}
		buffer_component.capture(BufferComponent.BufferedAction.DODGE, context)

func on_attack_pressed(profile: AttackProfile):
	if current_state.allow_attack():
		if profile and stamina_component.try_consume(profile.stamina_cost):
			buffer_component.clear()
			transition_to("AttackState", {"profile": profile})
	else:
		var context = {"profile": profile}
		buffer_component.capture(BufferComponent.BufferedAction.ATTACK, context)

func on_parry_pressed(profile: ParryProfile):
	if current_state.allow_parry():
		if profile and stamina_component.try_consume(profile.stamina_cost):
			buffer_component.clear()
			transition_to("ParryState", {"profile": profile})
	else:
		var context = {"profile": profile}
		buffer_component.capture(BufferComponent.BufferedAction.PARRY, context)

func _on_impact_resolved(result: ContactResult):
	if result.attacker_node == owner_node:
		match result.attacker_outcome:
			ContactResult.AttackerOutcome.PARRIED:
				var profile = owner_node.get_parried_profile()
				transition_to("ParriedState", {"profile": profile})
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				var profile = owner_node.get_finisher_profile()
				transition_to("FinisherReadyState", {"profile": profile})
			ContactResult.AttackerOutcome.TRADE_LOST:
				var profile = owner_node.get_stagger_profile()
				transition_to("StaggerState", {"profile": profile})


func on_current_state_finished(reason: Dictionary = {}):
	var outcome = reason.get("outcome")
	if outcome:
		match outcome:
			"BLOCKED":
				var profile = owner_node.get_block_stun_profile()
				transition_to("BlockStunState", {"profile": profile})
				return
			"GUARD_BROKEN":
				var profile = owner_node.get_guard_broken_profile()
				transition_to("GuardBrokenState", {"profile": profile})
				return
			"FINISHER_HIT":
				stamina_component.restore_to_full()
				var profile = owner_node.get_stagger_profile()
				transition_to("StaggerState", {"profile": profile})
				return
			"HIT", "POISE_BROKEN":
				var profile = owner_node.get_stagger_profile()
				var knockback_value = reason.get("knockback_vector", Vector2.ZERO)
				print("StateMachine: Recebeu knockback para Stagger: ", knockback_value)
				transition_to("StaggerState", {"profile": profile, "knockback_vector": knockback_value})
				return

	var buffered_data = buffer_component.consume()
	if buffered_data:
		match buffered_data.action:
			BufferComponent.BufferedAction.ATTACK:
				var profile = buffered_data.context.get("profile")
				if profile and stamina_component.try_consume(profile.stamina_cost):
					transition_to("AttackState", {"profile": profile})
					return
			BufferComponent.BufferedAction.DODGE:
				var direction = buffered_data.context.get("direction")
				var profile = buffered_data.context.get("profile")
				if profile and stamina_component.try_consume(profile.stamina_cost):
					transition_to("DodgeState", {"direction": direction, "profile": profile})
					return
			BufferComponent.BufferedAction.PARRY:
				var profile = buffered_data.context.get("profile")
				if profile and stamina_component.try_consume(profile.stamina_cost):
					transition_to("ParryState", {"profile": profile})
					return

	var profile = owner_node.get_locomotion_profile()
	transition_to(initial_state_key, {"profile": profile})

func transition_to(new_state_key: String, args: Dictionary = {}):
	if not states.has(new_state_key):
		push_error("StateMachine Error: Attempted to transition to nonexistent state '%s'." % new_state_key)
		return

	var new_state = states[new_state_key]

	if new_state == current_state and not current_state.allow_reentry():
		return

	var previous_state = current_state
	
	if previous_state:
		previous_state.exit()
	
	current_state = new_state
	current_state.enter(args)
	
	emit_signal("transitioned", previous_state, current_state)
