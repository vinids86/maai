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
@onready var _combo_chain_timer: Timer = find_child("ComboChainTimer") # <-- NOVO: Referência ao Timer
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
	assert(_combo_chain_timer != null, "AIController: Node 'ComboChainTimer' not found.") # <-- NOVO: Verifica Timer

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
	# Conecta o sinal do timer à nova função
	_combo_chain_timer.timeout.connect(_on_ComboChainTimer_timeout) # <-- NOVO


func _debug_log_player_state(f: State, t: State):
	# LOG: Mantido para referência
	print("DEBUG: Player State: ", f.name if f else "None", " -> ", t.name if t else "None")

func _debug_log_ai_state(f: State, t: State):
	# LOG: Mantido para referência
	print("DEBUG: AI State: ", f.name if f else "None", " -> ", t.name if t else "None")


func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	if _current_behavior_sequence.is_empty(): return
	if _is_in_attack_loop: return # Let states handle interruptions during loop

	_pending_riposte_action = ""
	var current_step = _current_behavior_sequence[_behavior_sequence_counter]
	var defense_action = current_step.get("defense", "block")

	# LOG: Ação de defesa sendo tomada
	print_debug("AIController: Incoming attack. Defense step: ", defense_action)

	if defense_action == "parry":
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_pending_riposte_action = current_step.get("riposte", "normal_attack")
			# LOG: Ação de riposte armazenada
			print_debug("AIController: Attempting Parry. Storing pending riposte: '", _pending_riposte_action, "'")
			_state_machine.on_parry_pressed(profile)
	else:
		print_debug("AIController: Defensive Step is Block. Advancing sequence.")
		_advance_sequence() # Advance defense sequence if blocking


func _on_phase_changed(phase_data: Dictionary):
	var state_name = phase_data.get("state_name")
	var phase_name = phase_data.get("phase_name")
	# REMOVIDO: internal_phase não é mais usado para encadear
	# var internal_phase = phase_data.get("internal_phase_name", "")

	# LOG: Mudança de fase da IA
	print_debug("AIController: AI Phase Changed - State: ", state_name, ", Phase: ", phase_name, ", In Loop: ", _is_in_attack_loop)

	# --- Reset / Break Conditions ---
	if state_name == "GuardBrokenState":
		print_debug("AIController: IA Guard Broken. Resetting.")
		_combo_chain_timer.stop() # <-- NOVO: Para o timer
		reset_behavior_sequence()
		return

	# Break loop COMPLETELY if IA is interrupted by player (parried/staggered)
	if (state_name in ["StaggerState", "BlockStunState", "ParriedState"]) and _is_in_attack_loop:
		print_debug("AIController: IA Interrupted during loop (", state_name, "). Breaking loop and advancing sequence.")
		_combo_chain_timer.stop() # <-- NOVO: Para o timer
		_advance_sequence() # Define _is_in_attack_loop = false
		return

	# --- Start Loop Condition ---
	if state_name == "ParryState" and phase_name == "SUCCESS":

		# LOG: Sucesso do Parry
		print_debug("AIController: Parry SUCCESS. Checking pending riposte: '", _pending_riposte_action, "'")

		if not _pending_riposte_action.is_empty():
			# --- CORREÇÃO DE BUG (RACE CONDITION) ---
			var action_to_take: String = _pending_riposte_action
			_pending_riposte_action = ""
			# --- FIM DA CORREÇÃO ---

			print_debug("AIController: Executing stored riposte: '", action_to_take, "'")
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
					combo_comp.reset_combo() # Reset combo BEFORE starting loop/skill
					print_debug("AIController: ComboComponent reset.")

			_is_in_attack_loop = (action_to_take == "normal_attack")

			if _is_in_attack_loop:
				print_debug("AIController: Setting _is_in_attack_loop = true")

			_execute_riposte_action(action_to_take) # Executes P1 or Skill

		elif _pending_riposte_action.is_empty():
			print_debug("AIController: Parry SUCCESS but no riposte was pending. Advancing sequence.")
			_advance_sequence() # Avança a sequência de comportamento se não houver riposte definido

		# Não precisa mais retornar aqui

	# --- REMOVIDA: Lógica de encadeamento da fase LINK ---

	# --- <<< CORREÇÃO GUARD BROKEN >>> ---
	# (Mantém a lógica para forçar ataque P1 no FinisherReadyState)
	if state_name == "FinisherReadyState":
		print_debug("AIController: Entered FinisherReadyState. Forcing single punish attack (Finisher setup).")
		_combo_chain_timer.stop() # <-- NOVO: Para o timer se estava ativo
		_is_in_attack_loop = false # Garante que não está em loop
		var combo_comp = _owner_actor.find_child("ComboComponent")
		if combo_comp and combo_comp.has_method("reset_combo"):
			combo_comp.reset_combo()
			print_debug("AIController: ComboComponent reset for Finisher punish.")
		_execute_normal_attack() # Inicia o ataque P1


func _on_player_phase_changed(phase_data: Dictionary):
	var player_state_name = phase_data.get("state_name")
	# LOG: Mudança de fase do Player
	print_debug("AIController: Player Phase Changed - State: ", player_state_name)

	# Punish only if IA is free. Does not interfere with the ongoing loop.
	if player_state_name == "GuardBrokenState":
		if _is_in_attack_loop:
			print_debug("AIController: Player entered GuardBrokenState, IA in attack loop. Loop should continue naturally via FinisherReadyState logic.")
			# NOTA: A lógica foi movida para _on_phase_changed -> FinisherReadyState
			return
		elif _state_machine.current_state is LocomotionState:
			print_debug("AIController: Player entered GuardBrokenState. IA attempting single punish attack from Locomotion.")
			_combo_chain_timer.stop() # <-- NOVO: Para o timer se estava ativo
			var combo_comp = _owner_actor.find_child("ComboComponent")
			if combo_comp and combo_comp.has_method("reset_combo"):
				combo_comp.reset_combo()
				print_debug("AIController: ComboComponent reset for Locomotion punish.")
			_execute_normal_attack() # Executes ONE attack
		else:
			print_debug("AIController: Player entered GuardBrokenState, but IA is busy (State: %s). Cannot punish now." % _state_machine.current_state.name)


func _on_owner_health_changed(current_health: float, max_health: float):
	var health_percentage: float = current_health / max_health
	var new_phase = "phase_1" if health_percentage > 0.5 else "phase_2"
	if new_phase != _current_phase:
		print_debug("AIController: AI changing behavior phase to ", new_phase)
		_combo_chain_timer.stop() # <-- NOVO: Para o timer
		_set_behavior_phase(new_phase)

func _on_player_health_changed(current_health: float, _max_health: float):
	if _is_in_attack_loop:
		_player_last_health = current_health
		return
	if current_health < _player_last_health:
		print_debug("AIController: Player took damage while IA not in loop. Resetting sequence.")
		_combo_chain_timer.stop() # <-- NOVO: Para o timer
		reset_behavior_sequence()
	_player_last_health = current_health

func _set_behavior_phase(phase_name: String):
	if not behavior_sequences.has(phase_name):
		push_error("AIController: Unknown behavior phase: %s" % phase_name)
		return
	_current_phase = phase_name
	_current_behavior_sequence = behavior_sequences.get(phase_name)
	_combo_chain_timer.stop() # <-- NOVO: Para o timer
	reset_behavior_sequence()

func reset_behavior_sequence():
	print_debug("AIController: reset_behavior_sequence called.")
	_combo_chain_timer.stop() # <-- NOVO: Para o timer
	_behavior_sequence_counter = 0
	_pending_riposte_action = ""
	_is_in_attack_loop = false
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _advance_sequence():
	print_debug("AIController: _advance_sequence called. Ending attack loop and advancing behavior.")
	_combo_chain_timer.stop() # <-- NOVO: Para o timer
	_is_in_attack_loop = false # Garante que o loop termine
	if _current_behavior_sequence and not _current_behavior_sequence.is_empty():
		_behavior_sequence_counter = (_behavior_sequence_counter + 1) % _current_behavior_sequence.size()
		print_debug("AIController: New sequence index: ", _behavior_sequence_counter)
	else:
		_behavior_sequence_counter = 0
	var combo_comp = _owner_actor.find_child("ComboComponent")
	if combo_comp and combo_comp.has_method("reset_combo"):
		combo_comp.reset_combo()


func _execute_riposte_action(action_to_execute: String):
	print_debug("AIController: _execute_riposte_action deciding for: '", action_to_execute, "'")
	if action_to_execute == "normal_attack":
		print_debug("AIController: Riposte is 'normal_attack', calling _execute_normal_attack().")
		_execute_normal_attack() # Starts P1 (que agora também inicia o timer)
	else:
		# Se for skill, garante que o loop não continue e avança a sequência de comportamento
		print_debug("AIController: Riposte is a skill ('%s'), calling _execute_skill() and advancing sequence." % action_to_execute)
		_is_in_attack_loop = false
		_combo_chain_timer.stop() # <-- NOVO: Para o timer
		_execute_skill(action_to_execute)
		# Avança a sequência APÓS executar a skill
		_advance_sequence()


func _execute_skill(action_name: String):
	print_debug("AIController: _execute_skill called for: '", action_name, "'")
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	if not skill_to_use:
		print_debug("AIController: SKILL NOT FOUND: '", action_name, "'. Fallback ignored.")
		# A sequência será avançada em _execute_riposte_action
		return
	# _is_in_attack_loop já é false
	# _combo_chain_timer já foi parado
	print_debug("AIController: Found skill. Executing.")
	skill_to_use.execute(_owner_actor, _state_machine)
	# A sequência é avançada em _execute_riposte_action


func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		print_debug("AIController: _execute_normal_attack called (Loop: %s)" % _is_in_attack_loop)

		var profile: AttackProfile = combo_component.get_next_attack_profile()

		if profile:
			var profile_name = profile.resource_path.get_file() if profile.resource_path else profile.resource_name
			print_debug("AIController: Got profile from ComboComponent: [", profile_name, "]")
			print_debug("AIController: ---> Calling _state_machine.on_attack_pressed for [", profile_name, "]")
			_state_machine.on_attack_pressed(profile) # Envia o comando para iniciar/bufferizar
			print_debug("AIController: ---> Returned from _state_machine.on_attack_pressed for [", profile_name, "]")

			# --- NOVO: Inicia o timer para o próximo ataque do loop ---
			if _is_in_attack_loop:
				# Calcula o tempo para disparar um pouco antes do fim da recuperação
				var time_to_next_input = profile.startup_duration + profile.active_duration + profile.recovery_duration - 0.05
				if time_to_next_input > 0.0:
					print_debug("AIController: Starting ComboChainTimer for ", time_to_next_input, "s")
					_combo_chain_timer.start(time_to_next_input)
				else:
					# Se o tempo for zero ou negativo, tenta encadear imediatamente (pode acontecer com durações muito curtas)
					print_debug("AIController: Attack duration too short, attempting immediate chain.")
					_on_ComboChainTimer_timeout() # Chama manualmente
			# --- FIM NOVO ---
		else:
			print_debug("AIController: ComboComponent returned NULL profile (end of combo?). Ending loop and advancing behavior sequence.")
			_combo_chain_timer.stop() # <-- NOVO: Para o timer
			if _is_in_attack_loop:
				_advance_sequence() # Define _is_in_attack_loop = false e avança _behavior_sequence_counter
	else:
		print_debug("AIController: _execute_normal_attack failed. 'ComboComponent' not found.")

func _on_ComboChainTimer_timeout():
	print("AIController: ComboChainTimer timed out.")
	if _is_in_attack_loop:
		print_debug("AIController: Still in attack loop. Calling _execute_normal_attack() to chain.")
		_execute_normal_attack()
	else:
		print_debug("AIController: No longer in attack loop. Timer ignored.")


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("debug_reset_ai"):
		print_debug("AIController: Manual AI Reset requested.")
		_combo_chain_timer.stop()
		reset_behavior_sequence()

func _on_player_entered_detection_area(body: Node2D):
	if body == GameManager.player_node:
		print_debug("AIController: Player entered detection area.")
		_facing_component.enable(body)

func _on_player_exited_detection_area(body: Node2D):
	if body == GameManager.player_node:
		print_debug("AIController: Player exited detection area.")
		_facing_component.disable()
		_combo_chain_timer.stop()
		reset_behavior_sequence()

func get_walk_direction() -> float: return 0.0
func is_running() -> bool: return false
