class_name State
extends Node

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

func get_current_poise() -> float:
	return 0.0

func allow_dodge() -> bool: return false
func allow_attack() -> bool: return false
func allow_parry() -> bool: return false
func allow_reentry() -> bool: return false
func allow_autoblock() -> bool: return false

func resolve_contact(_context: ContactContext) -> ContactResult:
	push_warning("O estado '%s' não implementou o método 'resolve_contact'. O impacto foi ignorado." % self.name)
	return null
