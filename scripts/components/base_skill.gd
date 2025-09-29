class_name BaseSkill
extends Resource

# @export var special_cost: float = 10.0
# @export var stamina_cost: float = 0.0

# --- Metadados ---
@export var skill_name: String
@export var skill_icon: Texture2D

func execute(owner: Node, state_machine: StateMachine):
	# TODO: Implementar a verificação de custo aqui no futuro.
	# Por exemplo:
	# var special_comp = owner.find_child("SpecialComponent")
	# if special_comp and special_comp.has_enough_energy(special_cost):
	#     special_comp.consume_energy(special_cost)
	#     _do_execute(owner, state_machine)
	# else:
	#     # Tocar som de falha, etc.
	
	# Por enquanto, vamos chamar a execução diretamente.
	_do_execute(owner, state_machine)

func _do_execute(owner: Node, state_machine: StateMachine):
	push_error("_do_execute() deve ser implementado pela skill filha!")
