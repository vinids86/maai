class_name DodgeState
extends State

# --- PERFIS DE ESQUIVA ---
@export var neutral_dodge_profile: DodgeProfile
@export var forward_dodge_profile: DodgeProfile
@export var back_dodge_profile: DodgeProfile
@export var up_dodge_profile: DodgeProfile
@export var down_dodge_profile: DodgeProfile

enum Phases { ACTIVE, RECOVERY }
var current_phase: Phases
var current_profile: DodgeProfile

# --- FUNÇÕES DO CICLO DE VIDA DO ESTADO ---

func enter(args: Dictionary = {}):
	var direction_vector = args.get("direction", Vector2.ZERO)
	
	current_profile = _select_profile_from_direction(direction_vector)

	if not current_profile:
		push_warning("DodgeState: Nenhum perfil de esquiva encontrado. A abortar.")
		state_machine.on_current_state_finished()
		return
		
	movement_component.apply_dodge_velocity(direction_vector, current_profile)
	_change_phase(Phases.ACTIVE)


func process_physics(delta: float):
	movement_component.apply_gravity(delta)


func exit():
	state_machine.action_timer.stop()


func on_timeout():
	match current_phase:
		Phases.ACTIVE:
			_change_phase(Phases.RECOVERY)
		Phases.RECOVERY:
			state_machine.on_current_state_finished()

# --- FUNÇÕES DE PERMISSÃO ---

func allow_dodge() -> bool:
	return false

# --- LÓGICA INTERNA ---

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	match current_phase:
		Phases.ACTIVE:
			state_machine.action_timer.start(current_profile.active_duration)
		Phases.RECOVERY:
			# A linha que zerava a velocidade foi removida daqui.
			# Agora o personagem manterá o seu momento horizontal.
			state_machine.action_timer.start(current_profile.recovery_duration)


func _select_profile_from_direction(direction: Vector2) -> DodgeProfile:
	if direction.y < 0:
		return up_dodge_profile
	elif direction.y > 0:
		return down_dodge_profile
	elif direction.x != 0:
		# TODO: Implementar lógica para diferenciar forward/back
		return forward_dodge_profile
	else:
		return neutral_dodge_profile
