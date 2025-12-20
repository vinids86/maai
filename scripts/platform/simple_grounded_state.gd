class_name SimpleGroundedState
extends SimpleState

## Estado que substitui o Groggy para inimigos voadores.
## Comportamento: O inimigo cai com gravidade até o chão e fica vulnerável.

@export_group("Physics Settings")
## Gravidade aplicada enquanto cai (geralmente maior que a do player para cair rápido).
@export var fall_gravity: float = 1200.0
## Fricção aplicada ao tocar no chão para parar o deslizamento.
@export var ground_friction: float = 800.0
## Pequeno impulso vertical ao tocar o chão (efeito de quique).
@export var bounce_velocity: float = -200.0

@export_group("Animations")
## Animação tocada enquanto está caindo.
@export var animation_falling: StringName = ""
## Animação tocada quando está atordoado no chão.
@export var animation_on_ground: StringName = ""

var _has_touched_ground: bool = false

func enter(_args: Dictionary = {}):
	_has_touched_ground = false
	
	# Reduz velocidade horizontal inicial para cair mais "reto" ou mantém leve inércia
	if owner_node:
		owner_node.velocity.x *= 0.5
	
	state_machine.emit_phase_change({
		"state": "SimpleGroundedState",
		"phase": "fall",
		"animation_to_play": animation_falling
	})

func process_physics(delta: float) -> Vector2:
	var velocity = owner_node.velocity
	
	if not owner_node.is_on_floor():
		# --- FASE DE QUEDA ---
		velocity.y += fall_gravity * delta
		# Arasto no ar para evitar que voe longe demais enquanto cai
		velocity.x = move_toward(velocity.x, 0, 100.0 * delta)
	else:
		# --- FASE DE CHÃO ---
		if not _has_touched_ground:
			_has_touched_ground = true
			
			# Aplica o quique
			velocity.y = bounce_velocity 
			
			# Notifica mudança para animação de chão
			state_machine.emit_phase_change({
				"state": "SimpleGroundedState",
				"phase": "grounded",
				"animation_to_play": animation_on_ground
			})
		else:
			# Fricção forte para parar completamente no chão
			velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
			velocity.y = 0 # Garante que fique "colado" no chão
	
	return velocity

# Nota: A saída deste estado (exit) é gerenciada pelo BaseSimpleStateMachine
# quando o _groggy_timer expira.
