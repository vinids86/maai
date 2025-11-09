class_name FinisherReadyState
extends State

var current_profile: FinisherProfile
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	# 1. Limpa o buffer de input ("atropelamento")
	# Isso força o jogador a pressionar o botão de ataque NOVAMENTE.
	if state_machine and state_machine.buffer_component:
		state_machine.buffer_component.clear()

	# 2. Atribui o profile (Corrigindo o crash 'Nil')
	self.current_profile = args.get("profile")

	# 3. Checagem de segurança do profile
	if not current_profile:
		state_machine.on_current_state_finished()
		return

	# 4. Lógica de virar (Corrigindo o 'has_meta' anterior)
	var target = args.get("target")
	
	# Apenas checamos se o alvo é válido.
	if is_instance_valid(target): 
		var direction_x = target.global_position.x - owner_node.global_position.x
		
		if direction_x != 0:
			# Ao definir 'facing_sign', o 'setter' em player.gd
			# será chamado automaticamente, que por sua vez
			# chama _update_facing_direction().
			owner_node.facing_sign = sign(direction_x) 

	# 5. Define o tempo da janela de oportunidade
	time_left_in_phase = current_profile.ready_duration
	_emit_phase_signal()

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not current_profile:
		return physics_component.apply_gravity(Vector2.ZERO, delta)

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()
		return physics_component.apply_gravity(Vector2.ZERO, delta)
		
	return physics_component.apply_gravity(Vector2.ZERO, delta)

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	var finisher_attack_profile = owner_node.get_finisher_attack_profile()

	if finisher_attack_profile:
		var context = { "override_profile": finisher_attack_profile }
		return InputHandlerResult.new(InputHandlerResult.Status.ACCEPTED, context)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	if not current_profile:
		return 0.0
	return current_profile.poise_shield_contribution

func get_poise_impact_contribution() -> float:
	return 0.0

func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "FINISHER_READY",
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
