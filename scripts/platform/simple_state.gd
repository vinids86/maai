class_name SimpleState
extends Node

var state_machine: SimpleStateMachine
var owner_node: Node
var physics_component: Node
var surface_contact_component: SurfaceContactComponent
var wall_detector: WallDetectorComponent

func initialize(sm: SimpleStateMachine, owner: Node, physics_comp: Node, surface_contact_comp: SurfaceContactComponent, p_wall_detector: WallDetectorComponent):
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

func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	if context.defender_health_comp:
		context.defender_health_comp.take_damage(context.attack_profile.damage)
		
		if not context.defender_health_comp.is_dead():
			var direction = (context.defender_node.global_position - context.attacker_node.global_position).normalized()
			var push_force = 550.0 # Valor base, idealmente viria do AttackProfile mas mantemos simples aqui
			
			# Se o AttackProfile tiver dados de knockback, podemos usar (opcional)
			# if context.attack_profile.knockback_vector != Vector2.ZERO: ...
			
			var knockback = direction * push_force
			knockback.y = -100.0 # Um leve pulinho para tirar do chão
			
			var reason = { "outcome": "HIT", "knockback_vector": knockback }
			state_machine.on_current_state_finished(reason)

	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.HIT
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY

	return result_for_attacker
