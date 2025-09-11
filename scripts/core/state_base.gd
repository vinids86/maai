class_name State
extends Node

# --- REFERÊNCIAS ---
var state_machine: StateMachine
var owner_node: Node
var movement_component: Node

func initialize(sm: StateMachine, owner: Node, move_comp: Node):
	self.state_machine = sm
	self.owner_node = owner
	self.movement_component = move_comp

# --- FUNÇÕES VIRTUAIS DO CICLO DE VIDA DO ESTADO ---

func enter(args: Dictionary = {}):
	pass

func exit():
	pass
	
func process_physics(delta: float):
	pass
	
func process_input(event: InputEvent):
	pass

# ESTA É A NOVA FUNÇÃO
# Chamada pela StateMachine quando o seu ActionTimer termina.
# Os estados que usam o timer (como o DodgeState) irão sobrescrever esta função.
func on_timeout():
	pass

# --- FUNÇÕES DE PERMISSÃO ---

func allow_dodge() -> bool:
	return false

func allow_attack() -> bool:
	return false
	
func allow_parry() -> bool:
	return false

func allow_reentry() -> bool:
	return false
