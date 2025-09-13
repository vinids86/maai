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
func process_physics(delta: float, is_running: bool = false): pass
func process_input(event: InputEvent): pass

# --- FUNÇÕES DE PERMISSÃO ---
func allow_dodge() -> bool: return false
func can_initiate_attack() -> bool: return false
func can_buffer_attack() -> bool: return false
func allow_parry() -> bool: return false
func allow_reentry() -> bool: return false
