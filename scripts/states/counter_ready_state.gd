class_name CounterReadyState
extends State

var _current_profile: CounterExecutionProfile
var _triggering_result: ContactResult

enum Phases { READY, EXECUTING }
var _current_internal_phase: Phases
var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	var result: ContactResult = args.get("result")
	if not result or not result.counter_profile:
		state_machine.on_current_state_finished()
		return

	_triggering_result = result
	_current_profile = result.counter_profile
	
	_change_phase(Phases.READY)

func process_physics(delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	if not _current_profile:
		return physics_component.apply_gravity(Vector2.ZERO, delta)

	time_left_in_phase -= delta

	if time_left_in_phase <= 0:
		if _current_internal_phase == Phases.READY or _current_internal_phase == Phases.EXECUTING:
			state_machine.on_current_state_finished()
		return physics_component.apply_gravity(Vector2.ZERO, delta)
	
	var final_velocity = physics_component.apply_gravity(Vector2.ZERO, delta)
	return final_velocity

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if _current_internal_phase == Phases.READY and _current_profile and _triggering_result:
		_change_phase(Phases.EXECUTING)
		return InputHandlerResult.new(InputHandlerResult.Status.CONSUMED)

	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func _change_phase(new_phase: Phases):
	_current_internal_phase = new_phase
	
	var sfx_to_play: AudioStream
	var animation_to_play: StringName
	
	match _current_internal_phase:
		Phases.READY:
			time_left_in_phase = _current_profile.ready_duration
			animation_to_play = _current_profile.counter_ready_animation
			
			if _current_profile is PushCounterProfile:
				sfx_to_play = (_current_profile as PushCounterProfile).sfx_ready
			elif _current_profile is SweepCounterProfile:
				sfx_to_play = (_current_profile as SweepCounterProfile).sfx_ready
		
		Phases.EXECUTING:
			counter_executor_component.execute_counter(_current_profile, _triggering_result.attacker_node)
			
			if _current_profile is MikiriCounterProfile:
				var mikiri_profile = _current_profile as MikiriCounterProfile
				time_left_in_phase = mikiri_profile.execution_duration
				animation_to_play = mikiri_profile.executor_animation
			
			elif _current_profile is PushCounterProfile:
				var push_profile = _current_profile as PushCounterProfile
				time_left_in_phase = push_profile.execution_duration
				animation_to_play = push_profile.executor_animation_name
			
			elif _current_profile is SweepCounterProfile:
				var sweep_profile = _current_profile as SweepCounterProfile
				time_left_in_phase = sweep_profile.execution_duration
				animation_to_play = sweep_profile.executor_animation_name

			else:
				push_error("CounterReadyState: Perfil de execução desconhecido: " + _current_profile.get_class())
				state_machine.on_current_state_finished()
				return

	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[_current_internal_phase],
		"profile": _current_profile,
		"sfx_to_play": sfx_to_play,
		"animation_to_play": animation_to_play
	}
	
	state_machine.emit_phase_change(phase_data)
