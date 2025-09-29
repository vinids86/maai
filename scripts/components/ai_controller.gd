class_name AIController
extends Node

@export_group("Behavioral Strategy")
@export var parry_chance: float = 0.30
# A 'riposte_action_name' foi removida para dar lugar a um sistema de decisão mais flexível.

var _rng: RandomNumberGenerator
var _owner_actor: Node
@onready var _state_machine: StateMachine = get_parent().find_child("StateMachine")

func _ready():
	_owner_actor = get_parent()
	assert(_owner_actor != null, "AIController deve ser filho de um nó de ator.")

	parry_chance = clampf(parry_chance, 0.0, 1.0)

	_rng = RandomNumberGenerator.new()
	_rng.randomize()

	if _state_machine:
		_state_machine.phase_changed.connect(_on_phase_changed)

func get_walk_direction() -> float:
	return 0.0

func is_running() -> bool:
	return false

func on_incoming_attack(_attacker: CharacterBody2D, _hitbox: Hitbox):
	var roll: float = _rng.randf()
	var do_parry: bool = roll < parry_chance

	if do_parry and _state_machine != null:
		var profile = _owner_actor.get_parry_profile()
		if profile:
			_state_machine.on_parry_pressed(profile)

func _on_phase_changed(phase_data: Dictionary):
	# Este é um "gatilho" para a IA tomar uma decisão.
	# Atualmente, só acontece após um parry bem-sucedido.
	# No futuro, outros eventos poderiam chamar a mesma função de decisão.
	if phase_data.get("state_name") == "ParryState" and phase_data.get("phase_name") == "SUCCESS":
		await get_tree().process_frame
		_decide_and_execute_action()

# --- NOVA FUNÇÃO CENTRAL DE DECISÃO ---
# O "cérebro" da IA. Ele analisa as opções e escolhe uma.
func _decide_and_execute_action():
	# 1. Monta uma lista de todas as ações possíveis que a IA pode tomar.
	var possible_actions: Array[String] = ["normal_attack"]
	
	# Adiciona todas as skills que estão de fato equipadas no "Corpo" (_owner_actor)
	# Acessamos o dicionário interno que criamos no enemy.gd
	if _owner_actor.has_method("_build_skill_dictionary"): # Garante que a função existe
		for skill_action in _owner_actor._equipped_skills.keys():
			possible_actions.append(skill_action)
	
	# 2. Se não houver nenhuma ação possível, não faz nada.
	if possible_actions.is_empty():
		return

	# 3. Escolhe aleatoriamente uma ação da lista.
	# (Esta é a parte que pode se tornar muito mais inteligente no futuro, com pesos e condições)
	var chosen_action = possible_actions.pick_random()

	# 4. Executa a ação escolhida.
	match chosen_action:
		"normal_attack":
			_execute_normal_attack()
		"skill_x", "skill_y", "skill_a", "skill_b":
			_execute_skill(chosen_action)
		_:
			# Fallback para o caso de uma ação desconhecida.
			_execute_normal_attack()

func _execute_skill(action_name: String):
	var skill_to_use: BaseSkill = _owner_actor.get_skill(action_name)
	
	if not skill_to_use:
		# Se a skill não for encontrada por algum motivo, executa um ataque normal.
		_execute_normal_attack()
		return
	
	# Delega a execução para a própria skill, que sabe como se comportar.
	# Isso funciona para SequenceSkill, BuffSkill, ou qualquer outro tipo.
	skill_to_use.execute(_owner_actor, _state_machine)


func _execute_normal_attack():
	var combo_component = _owner_actor.find_child("ComboComponent")
	if combo_component:
		var profile = combo_component.get_next_attack_profile()
		if profile:
			_state_machine.on_attack_pressed(profile)
