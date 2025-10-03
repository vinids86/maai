class_name DeathState
extends State

var current_profile: DeathProfile

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")
	if not current_profile:
		push_warning("DeathState: Não recebeu um DeathProfile.")
	
	_emit_phase_signal()
	
	if owner_node.has_method("hide_status_ui"):
		owner_node.hide_status_ui()
	
	owner_node.set_collision_layer_value(1, false)
	owner_node.set_collision_mask_value(1, false)

	for child in owner_node.get_children():
		if child is CollisionShape2D:
			child.disabled = true
		if child is Area2D:
			child.monitoring = false
			child.monitorable = false
			
	owner_node.velocity = Vector2.ZERO

func process_physics(_delta: float, _walk_direction: float, _is_running: bool):
	pass

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(_context: ContactContext) -> ContactResult:
	return null

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "DIED",
		"profile": current_profile,
	}
	if current_profile:
		phase_data["animation_to_play"] = current_profile.animation_name
		phase_data["sfx_to_play"] = current_profile.sfx
	
	state_machine.emit_phase_change(phase_data)
