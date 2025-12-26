class_name State
extends Node

# --- AUTO-WIRING ---
# O Estado busca seu pai. Assume-se que o Estado é filho direto da StateMachine.
@onready var state_machine: StateMachine = _get_state_machine()

# O Owner (Actor) é acessado dinamicamente através da máquina.
# Isso funciona porque o Actor roda initialize() na máquina antes do primeiro enter() do estado.
var owner_node: Actor:
	get: return state_machine.owner_node

# --- ACESSO A COMPONENTES (Via Actor) ---
var physics_component: PhysicsComponent:
	get: return owner_node.physics_component

var path_follower_component: PathFollowerComponent:
	get: return owner_node.path_follower_component

var surface_contact_component: SurfaceContactComponent:
	get: return owner_node.surface_contact_component

var wall_detector: WallDetectorComponent:
	get: return owner_node.wall_detector

var counter_executor_component: CounterExecutorComponent:
	get: return owner_node.counter_executor_component

# --- LÓGICA DE SETUP ---

func _get_state_machine() -> StateMachine:
	var parent = get_parent()
	if not parent is StateMachine:
		push_error("Erro: O Estado '%s' deve ser filho de um nó StateMachine!" % name)
		return null
	return parent as StateMachine

# Removemos a função 'initialize' antiga completamente.
# Se precisar de setup customizado, use _ready()

# --- MÉTODOS VIRTUAIS (Mantidos iguais) ---

func enter(_args: Dictionary = {}):
	pass

func exit():
	pass
	
func check_contextual_transitions(_walk_direction: float) -> Dictionary:
	return {}

func process_input(_event: InputEvent):
	pass

func process_physics(_delta: float, _walk_direction: float, _is_running: bool) -> Vector2:
	return Vector2.ZERO

# --- INPUT HANDLERS (Igual ao anterior) ---
func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_dash_input(_profile: DashProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)
	
func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_jump_input(_profile: JumpProfile) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	return InputHandlerResult.new(InputHandlerResult.Status.REJECTED)

# --- COMBAT LOGIC (Mantida igual, apenas usando as variáveis herdadas) ---
func handle_attack_outcome(_result: ContactResult):
	pass

func resolve_contact(context: ContactContext) -> ContactResult:
	return _resolve_default_contact(context)

func get_poise_shield_contribution() -> float:
	return 0.0

func get_poise_impact_contribution() -> float:
	return 0.0
	
func allow_reentry() -> bool:
	return false

func handle_attacker_parried(_result: ContactResult) -> bool:
	return true

func _resolve_default_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	if _is_simple_enemy(context.attacker_node):
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		var reason = { "outcome": "HIT", "knockback_vector": context.attack_profile.knockback_vector }
		state_machine.on_current_state_finished(reason)
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.HIT
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.SIMPLE_ENEMY_HIT
		return result_for_attacker

	if context.attack_profile.parry_interaction == AttackProfile.ParryInteractionType.UNPARRYABLE:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		var reason = { "outcome": "POISE_BROKEN", "knockback_vector": context.attack_profile.knockback_vector * 1.5 }
		state_machine.on_current_state_finished(reason)
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.POISE_BROKEN
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE
		return result_for_attacker

	if context.defender_stamina_comp.take_stamina_damage(context.attack_profile.stamina_damage):
		var block_recoil_fraction: float = 1.0
		var base_knockback: Vector2 = context.attack_profile.knockback_vector
		var recoil_velocity: Vector2 = base_knockback * block_recoil_fraction
		var reason = { "outcome": "BLOCKED", "knockback_vector": recoil_velocity }
		state_machine.on_current_state_finished(reason)
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.BLOCKED
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.ATTACK_BLOCKED
	else:
		var reason = { "outcome": "GUARD_BROKEN", "knockback_vector": context.attack_profile.knockback_vector }
		state_machine.on_current_state_finished(reason)
		result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.GUARD_BROKEN
		result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS
	
	return result_for_attacker

func _is_simple_enemy(node) -> bool:
	return node.get_class() == "SimpleEnemy" or (node.get_script() and "class_name SimpleEnemy" in node.get_script().source_code)
