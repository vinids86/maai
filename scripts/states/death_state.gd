class_name DeathState
extends State

var current_profile: DeathProfile

func enter(args: Dictionary = {}):
	current_profile = args.get("profile")
	
	owner_node.collision_layer = 0
	owner_node.collision_mask = 1 
	owner_node.velocity.x = 0 
	
	if "ai_controller" in owner_node and owner_node.ai_controller:
		owner_node.ai_controller.set_physics_process(false)
		owner_node.ai_controller.set_process(false)

	if "detection_area" in owner_node and owner_node.detection_area:
		owner_node.detection_area.set_deferred("monitoring", false)
		owner_node.detection_area.set_deferred("monitorable", false)
	
	var facing_comp = owner_node.find_child("FacingComponent")
	if facing_comp and facing_comp.has_method("disable"):
		facing_comp.disable()
		
	if "_target_detected" in owner_node:
		owner_node._target_detected = null

	if "status_ui" in owner_node and owner_node.status_ui:
		owner_node.status_ui.hide()

	get_tree().call_group("MainCamera", "unregister_enemy_aggro", owner_node)
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	var new_velocity = owner_node.velocity
	
	new_velocity = physics_component.apply_gravity(new_velocity, delta)
	new_velocity.x = move_toward(new_velocity.x, 0, 2000.0 * delta)
	
	return new_velocity

func _emit_phase_signal():
	if not current_profile:
		return
	
	var phase_data = {
		"state_name": self.name,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	
	state_machine.emit_phase_change(phase_data)

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func get_poise_shield_contribution() -> float:
	return 0.0
