class_name SimpleStaggerState
extends SimpleState

# Aumentei a fricção para um valor físico. 
# 1000.0 significa que ele perde 1000 pixels de velocidade por segundo (bom para deslizar).
@export var stagger_duration: float = 0.8
@export var friction: float = 800.0
@export var audio: AudioStream

var _timer: float = 0.0
# Usamos essa variável para calcular a velocidade desejada
var _current_velocity: Vector2 = Vector2.ZERO
# Flag para garantir que o impulso inicial seja aplicado
var _is_first_frame: bool = false

func enter(args: Dictionary = {}):
	owner_node.set_hitbox_enabled(false)
	
	# Captura o vetor total (X e Y)
	_current_velocity = args.get("knockback_vector", Vector2.ZERO)
	_timer = stagger_duration
	_is_first_frame = true # Marca que acabamos de entrar
	
	state_machine.emit_phase_change({
		"state": "SimpleStaggerState",
		"phase": "hurt",
		"sfx_to_play": audio,
		"animation_to_play": "hit" # Confirme se o nome é "hurt" ou "hit" no seu Spine
	})

func process_physics(delta: float) -> Vector2:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.on_current_state_finished()
		return Vector2.ZERO

	# LÓGICA DE SINCRONIA:
	# Se NÃO for o primeiro frame, atualizamos nossa velocidade interna com a REALIDADE do ator.
	# Isso garante que se ele bater numa parede ou chão, a velocidade zera corretamente.
	if not _is_first_frame:
		_current_velocity = owner_node.velocity
	else:
		# Se É o primeiro frame, não lemos o owner_node, pois ele tem a velocidade antiga (ex: andando).
		# Mantemos o _current_velocity que configuramos no enter().
		_is_first_frame = false

	# 1. Aplica Gravidade no Y
	if not owner_node.is_on_floor():
		_current_velocity.y += 980.0 * delta
	
	# 2. Aplica Fricção no X (deslizar até parar)
	# move_toward é melhor que lerp para atrito físico constante
	_current_velocity.x = move_toward(_current_velocity.x, 0.0, friction * delta)
	
	# Retorna a velocidade calculada para o SimpleEnemy aplicar no move_and_slide()
	return _current_velocity

func exit():
	owner_node.set_hitbox_enabled(true)
