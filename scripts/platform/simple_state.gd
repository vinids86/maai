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

# Método essencial para o ImpactResolver funcionar com este tipo de inimigo.
# Diferente do State original, aqui ignoramos Stamina/Poise e aplicamos dano direto.
func resolve_contact(context: ContactContext) -> ContactResult:
	var result_for_attacker = ContactResult.new()
	result_for_attacker.attacker_node = context.attacker_node
	result_for_attacker.defender_node = context.defender_node
	result_for_attacker.attack_profile = context.attack_profile

	# Aplica dano direto à vida
	if context.defender_health_comp:
		context.defender_health_comp.take_damage(context.attack_profile.damage)

	# Define o resultado como HIT padrão.
	# Isso informa ao atacante (Player) que o golpe conectou com sucesso (gerando hitstop, som, etc.)
	result_for_attacker.defender_outcome = ContactResult.DefenderOutcome.HIT
	
	result_for_attacker.attacker_outcome = ContactResult.AttackerOutcome.NONE

	# Nota: Se desejarmos que este inimigo sofra knockback no futuro,
	# podemos calcular e retornar o vetor aqui, similar ao State original.
	
	return result_for_attacker
