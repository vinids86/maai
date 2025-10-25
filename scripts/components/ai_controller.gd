class_name AIController
extends Node

var behavior_sequences: Dictionary = {
	"phase_1": [
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "block" },
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_x" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "parry", "riposte": "skill_a" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_b" },
		{ "defense": "block" },
	],
	"phase_2": [
		{ "defense": "parry" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_x" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_b" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "skill_y" },
		{ "defense": "parry", "riposte": "skill_a" },
		{ "defense": "block" },
		{ "defense": "parry", "riposte": "normal_attack" },
	]
}

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")
@onready var _detection_area: Area2D = get_parent().find_child("DetectionArea")
@onready var _facing_component: FacingComponent = get_parent().find_child("FacingComponent")
var _health_component: HealthComponent
var _current_behavior_sequence: Array = []
var _current_phase: String = ""
var _behavior_sequence_counter: int = 0
var _pending_riposte_action: String = ""
var _is_in_attack_loop: bool = false
var _player_last_health: float = -1.0


func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController must be a child of an actor node.")
	assert(_state_machine != null, "AIController: StateMachine not found in Enemy.")
	assert(_detection_area != null, "AIController: Node 'DetectionArea' not found in Enemy.")
	assert(_facing_component != null, "AIController: Node 'FacingComponent' not found in Enemy.")

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	_state_machine.phase_changed.connect(_on_phase_changed)
	_detection_area.body_entered.connect(_on_player_entered_detection_area)
	_detection_area.body_exited.connect(_on_player_exited_detection_area)

	_health_component = _owner_actor.find_child("HealthComponent")
	assert(_health_component != null, "AIController: HealthComponent not found in Enemy.")
	_health_component.health_changed.connect(_on_owner_health_changed)
	_on_owner_health_changed(_health_component.current_health, _health_component.max_health)

	await get_tree().process_frame

	if is_instance_valid(GameManager.player_node):
		var player_health_comp = GameManager.player_node.find_child("HealthComponent")
		if player_health_comp:
			player_health_comp.health_changed.connect(_on_player_health_changed)
			_player_last_health = player_health_comp.current_health
		else:
			push_warning("AIController: Player lacks HealthComponent. AI reset logic might fail.")

		var player_state_machine = GameManager.player_node.find_child("StateMachine")
		if player_state_machine:
			player_state_machine.transitioned.connect(func(f, t): _debug_log_player_state(f, t))
			player_state_machine.phase_changed.connect(_on_player_phase_changed)
		else:
			push_warning("AIController: Player lacks StateMachine. Finisher logic might fail.")
	else:
		push_warning("AIController: GameManager.player_node is not valid.")

	_state_machine.transitioned.connect(func(f, t): _debug_log_ai_state(f, t))


func _debug_log_player_state(f: State, t: State):
	print("DEBUG: Player State: ", f.name if f else "None", " -> ", t.name if t else "None")

func _debug_log_ai_state(f: State, t: State):
	print("DEBUG: AI State: ", f.name if f else "None", " -> ", t.name if t else "None")


func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	if _current_behavior_sequence.is_empty(): return
	if _is_in_attack_loop: return # Let states handle interruptions during loop

	_pending_riposte_action = ""
	var current_step = _current_behavior_sequence[_behavior_sequence_counter]
	var defense_action = current_step.get("defense", "block")

	print("DEBUG: IA incoming attack. Defense step: ", defense_action)

	if defense_action == "parry":
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_pending_riposte_action = current_step.get("riposte", "normal_attack")
			print("DEBUG: IA attempting Parry. Riposte: ", _pending_riposte_action)
			_state_machine.on_parry_pressed(profile)
	else:
		print("DEBUG: IA Defensive Step is Block. Advancing sequence.")
		_advance_sequence() # Advance defense sequence if blocking


func _on_phase_changed(phase_data: Dictionary):
	var state_name = phase_data.get("state_name")
	var phase_name = phase_data.get("phase_name")

	print("DEBUG: AI Phase Changed - State: ", state_name, ", Phase: ", phase_name, ", In Loop: ", _is_in_attack_loop)

	# --- Reset / Break Conditions ---
	if state_name == "GuardBrokenState":
		print("DEBUG: IA Guard Broken. Resetting.")
		reset_behavior_sequence()
		return

	# Break loop COMPLETELY if IA is interrupted by player (parried/staggered)
	if (state_name in ["StaggerState", "BlockStunState", "ParriedState"]) and _is_in_attack_loop:
		print("DEBUG: IA Interrupted during loop (", state_name, "). Breaking loop and advancing sequence.")
		_advance_sequence() # Define _is_in_attack_loop = false
		return

	# --- Start Loop Condition ---
	if state_name == "ParryState" and phase_name == "SUCCESS":
		if not _pending_riposte_action.is_empty():
			print("DEBUG: IA Parry SUCCESS. Pending Riposte: ", _pending_riposte_action)
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
					combo_comp.reset_combo() # Reset combo BEFORE starting loop/skill
			_is_in_attack_loop = (_pending_riposte_action == "normal_attack")
			if _is_in_attack_loop:
				print("DEBUG: Setting _is_in_attack_loop = true")

			_execute_riposte_action(_pending_riposte_action) # Executes P1 or Skill
			_pending_riposte_action = ""

			if not _is_in_attack_loop:
				print("DEBUG: Riposte was not normal_attack. Advancing sequence.")
				_advance_sequence()
		elif _pending_riposte_action.is_empty():
			print("DEBUG: IA Parry SUCCESS but no riposte defined. Advancing sequence.")
			_advance_sequence()
		return # Crucial: Prevent fall-through

	# --- Continue Loop Condition ---
	# Buffer P(n+1) during ACTIVE phase of P(n).
	if state_name == "AttackState" and phase_name == "ACTIVE" and _is_in_attack_loop:
		print("DEBUG: AttackState ACTIVE in loop. Attempting to buffer next attack.")
		_execute_normal_attack() # Tries to buffer P(n+1)
		return # Prevent fall-through

	# --- <<< CORREÇÃO GUARD BROKEN >>> ---
	# Force continuation if FinisherReadyState interrupts the loop
	# Buffer immediately to ensure transition FinisherReadyState -> AttackState
	if state_name == "FinisherReadyState" and _is_in_attack_loop:
		print("DEBUG: Entered FinisherReadyState during loop. Buffering next attack to continue.")
		_execute_normal_attack() # Tries to buffer P(n+1)
		# DO NOT return here. Let FinisherReadyState finish. Buffer will trigger next state.

	# --- REMOVED --- Resume loop from Locomotion logic removed.


func _on_player_phase_changed(phase_data: Dictionary):
	var player_state_name = phase_data.get("state_name")
	print("DEBUG: Player Phase Changed - State: ", player_state_name)

	# Punish only if IA is free. Does not interfere with the ongoing loop.
	if player_state_name == "GuardBrokenState":
		# If IA is already in attack loop, DO NOTHING.
		# The buffer logic triggered by FinisherReadyState should handle continuation.
		if _is_in_attack_loop:
			print("DEBUG: Player entered GuardBrokenState, IA in attack loop. Loop continuation handled by buffer.")
			return
		# If IA is free (Locomotion), execute a single punish attack.
		elif _state_machine.current_state is LocomotionState:
			print("DEBUG: Player entered GuardBrokenState. IA attempting single punish attack.")
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
				combo_comp.reset_combo()
			_execute_normal_attack() # Executes ONE attack
		else:
			print("DEBUG: Player entered GuardBrokenState, but IA is busy (State: %s). Cannot punish now." % _state_machine.current_state.name)


func _on_owner_health_changed(current_health: float, max_health: float):
	var health_percentage: float = current_health / max_health
	var new_phase = "phase_1" if health_percentage > 0.5 else "phase_2"
	if new_phase != _current_phase:
		print("DEBUG: AI changing behavior phase to ", new_phase)
		_set_behavior_phase(new_phase)

func _on_player_health_changed(current_health: float, _max_health: float):
	if _is_in_attack_loop:
		_player_last_health = current_health
		return
	if current_health < _player_last_health:
		print("DEBUG: Player took damage while IA not in loop. Resetting sequence.")
		reset_behavior_sequence()
	_player_last_health = current_health

func _set_behavior_phase(phase_name: String):
	if not behavior_sequences.has(phase_name):
		push_error("AIController: Unknown behavior phase: %s" % phase_name)
		return
	_current_phase = phase_name
	_current_behavior_sequence = behavior_sequences.get(phase_name)
	reset_behavior_sequence()

func reset_behavior_sequence():
	print("DEBUG: reset_behavior_sequence called.")
	_behavior_sequence_counter = 0
	_pending_riposte_action = ""
	_is_in_attack_loop = false
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _advance_sequence():
	print("DEBUG: _advance_sequence called.")
	_is_in_attack_loop = false
	if _current_behavior_sequence and not _current_behavior_sequence.is_empty():
		_behavior_sequence_counter = (_behavior_sequence_counter + 1) % _current_behavior_sequence.size()
		print("DEBUG: New sequence index: ", _behavior_sequence_counter)
	else:
		_behavior_sequence_counter = 0
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _execute_riposte_action(action_to_execute: String):
	print("DEBUG: Executing Riposte: ", action_to_execute)
	if action_to_execute == "normal_attack":
		# Combo reset is handled in _on_phase_changed when setting loop flag
		_execute_normal_attack() # Starts P1
	else:
		# Ensure flag is false if skill
		_is_in_attack_loop = false
		_execute_skill(action_to_execute)

func _execute_skill(action_name: String):
	print("DEBUG: Executing Skill: ", action_name)
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	if not skill_to_use:
		push_warning("AI: Skill '%s' not found, using normal attack as fallback." % action_name)
		_is_in_attack_loop = false
		_execute_normal_attack()
		return
	_is_in_attack_loop = false
	skill_to_use.execute(_owner_actor, _state_machine)


func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		print("DEBUG: Attempting to get next attack profile. Current Loop State: ", _is_in_attack_loop)
		# Reset combo only for single punish attacks (handled in _on_player_phase_changed)

		var profile = combo_component.get_next_attack_profile()
		if profile:
			print("DEBUG: Got profile: ", profile.resource_name if profile else "None", ". Calling on_attack_pressed.")
			_state_machine.on_attack_pressed(profile)
		else:
			print("DEBUG: get_next_attack_profile returned null (end of combo?). Ending loop/sequence.")
			if _is_in_attack_loop:
				_advance_sequence()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("debug_reset_ai"):
		print("DEBUG: Manual AI Reset requested.")
		reset_behavior_sequence()

func _on_player_entered_detection_area(body: Node2D):
	if body == GameManager.player_node:
		print("DEBUG: Player entered detection area.")
		_facing_component.enable(body)

func _on_player_exited_detection_area(body: Node2D):
	if body == GameManager.player_node:
		print("DEBUG: Player exited detection area.")
		_facing_component.disable()
		reset_behavior_sequence() # Reseta ao sair

func get_walk_direction() -> float: return 0.0
func is_running() -> bool: return false
