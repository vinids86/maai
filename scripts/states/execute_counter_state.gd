class_name ExecuteCounterState
extends State

var _target_enemy: Node
var _profile: AttackProfile
var _attack_executor: AttackExecutor
var _is_initialized: bool = false

enum Phases { WINDOW, EXECUTING }
var _current_phase: Phases
var _time_left_in_window: float = 0.0

func _initialize_references():
	if _is_initialized:
		return
	_attack_executor = owner_node.find_child("AttackExecutor")
	assert(_attack_executor != null, "ExecuteCounterState: Nó 'AttackExecutor' não encontrado.")
	_is_initialized = true

func enter(args: Dictionary = {}):
	_initialize_references()

	_target_enemy = args.get("target")
	_profile = args.get("profile")
	var opportunity_duration = args.get("duration", 0.5)
	var execute_immediately = args.get("execute_immediately", false)

	if not is_instance_valid(_target_enemy) or not _profile:
		push_warning("ExecuteCounterState: Não recebeu alvo ou profile válidos.")
		state_machine.on_current_state_finished()
		return
	
	_attack_executor.attack_phase_changed.connect(state_machine.emit_phase_change)
	_attack_executor.finished.connect(_on_attack_executor_finished)

	if execute_immediately:
		_execute_counter()
	else:
		_current_phase = Phases.WINDOW
		_time_left_in_window = opportunity_duration

func exit():
	if _attack_executor:
		_attack_executor.stop()
		if _attack_executor.is_connected("attack_phase_changed", Callable(state_machine, "emit_phase_change")):
			_attack_executor.attack_phase_changed.disconnect(state_machine.emit_phase_change)
		if _attack_executor.is_connected("finished", Callable(self, "_on_attack_executor_finished")):
			_attack_executor.finished.disconnect(_on_attack_executor_finished)

func process_physics(delta: float, _walk_direction: float, _is_running: bool):
	if _current_phase == Phases.WINDOW:
		_time_left_in_window -= delta
		if _time_left_in_window <= 0.0:
			state_machine.on_current_state_finished()
			return

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	if _current_phase == Phases.WINDOW:
		_execute_counter()
		return InputHandlerResult.CONSUMED
	
	return InputHandlerResult.REJECTED

func _execute_counter():
	if _current_phase != Phases.WINDOW:
		return
	
	_current_phase = Phases.EXECUTING
	
	var desired_offset = Vector2(_profile.hitbox_position.x * owner_node.facing_sign, 0)
	var end_position = _target_enemy.global_position - desired_offset
	var move_duration = 0.1

	var move_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(owner_node, "global_position", end_position, move_duration)
	move_tween.tween_callback(func(): _attack_executor.execute(_profile))

func _on_attack_executor_finished():
	state_machine.on_current_state_finished()
