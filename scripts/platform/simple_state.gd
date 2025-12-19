class_name SimpleState
extends Node

var state_machine: BaseSimpleStateMachine
var owner_node: Node
var physics_component: Node
var surface_contact_component: SurfaceContactComponent
var wall_detector: WallDetectorComponent

func initialize(sm: BaseSimpleStateMachine, owner: Node, physics_comp: Node, surface_contact_comp: SurfaceContactComponent, p_wall_detector: WallDetectorComponent):
	self.state_machine = sm
	self.owner_node = owner
	self.physics_component = physics_comp
	self.surface_contact_component = surface_contact_comp
	self.wall_detector = p_wall_detector

func enter(_args: Dictionary = {}):
	pass

func exit():
	pass

func process_physics(_delta: float) -> Vector2:
	return Vector2.ZERO

func handle_attack_outcome(result: ContactResult):
	print("result.attacker_outcome: ", result.attacker_outcome)
	if result.attacker_outcome == ContactResult.AttackerOutcome.SIMPLE_ENEMY_HIT:
		var target_pos = Vector2.ZERO
		if is_instance_valid(result.defender_node):
			target_pos = result.defender_node.global_position
			
		var reason = {
			"outcome": "ATTACK_CONNECTED",
			"target_position": target_pos
		}
		state_machine.on_current_state_finished(reason)

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	if context.defender_health_comp:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		
		if not context.defender_health_comp.is_dead():
			var direction = (context.defender_node.global_position - context.attacker_node.global_position).normalized()
			var push_force = 350.0 # Valor base, idealmente viria do AttackProfile mas mantemos simples aqui
			
			# Se o AttackProfile tiver dados de knockback, podemos usar (opcional)
			# if context.attack_profile.knockback_vector != Vector2.ZERO: ...
			
			var knockback = direction * push_force
			knockback.y = -100.0 # Um leve pulinho para tirar do chão
			
			var reason = { "outcome": "HIT", "knockback_vector": knockback }
			state_machine.on_current_state_finished(reason)

	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.HIT
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY

	return result_for_attacker
