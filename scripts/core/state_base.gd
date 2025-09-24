class_name State
extends Node

enum InputHandlerResult {
	REJECTED,
	ACCEPTED,
	CONSUMED,
}

var state_machine: StateMachine
var owner_node: Node
var movement_component: Node

func initialize(sm: StateMachine, owner: Node, move_comp: Node):
	self.state_machine = sm
	self.owner_node = owner
	self.movement_component = move_comp

func enter(args: Dictionary = {}): pass
func exit(): pass
func process_physics(delta: float, walk_direction: float, is_running: bool): pass
func process_input(event: InputEvent): pass

func get_poise_shield_contribution() -> float:
	return 0.0

func get_poise_impact_contribution() -> float:
	return 0.0

func allow_reentry() -> bool: return false

func handle_dodge_input(_direction: Vector2, _profile: DodgeProfile) -> InputHandlerResult:
	return InputHandlerResult.REJECTED

func handle_attack_input(_profile: AttackProfile) -> InputHandlerResult:
	return InputHandlerResult.REJECTED

func handle_parry_input(_profile: ParryProfile) -> InputHandlerResult:
	return InputHandlerResult.REJECTED

func handle_sequence_skill_input(_skill_attack_set: AttackSet) -> InputHandlerResult:
	return InputHandlerResult.REJECTED

func resolve_contact(_context: ContactContext) -> ContactResult:
	push_warning("O estado '%s' não implementou o método 'resolve_contact'. O impacto foi ignorado." % self.name)
	return null
