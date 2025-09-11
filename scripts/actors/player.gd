class_name Player
extends CharacterBody2D

# --- REFERÊNCIAS ---
@onready var state_machine: StateMachine = $StateMachine
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer

# --- ESTADO INTERNO ---
var is_running: bool = false
# ESTA É A NOVA VARIÁVEL
# A direção para a qual o personagem está virado. 1.0 para a direita, -1.0 para a esquerda.
var facing_sign: float = 1.0

# --- CICLO DE VIDA DO GODOT ---

func _ready():
	# Conectamos os sinais de timeout dos nossos timers às suas respetivas funções.
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)

func _physics_process(delta: float):
	# Agora passamos o nosso estado de corrida para a StateMachine a cada frame.
	state_machine.process_physics(delta, is_running)
	move_and_slide()

func _unhandled_input(event: InputEvent):
	# Lidamos com o pressionar e o soltar da nossa nova ação unificada.
	if event.is_action_pressed("dodge_run"):
		# Se a janela para cancelar a corrida estiver ativa, este "press" é uma esquiva.
		if not run_cancel_timer.is_stopped():
			run_cancel_timer.stop()
			var direction = _get_dodge_direction_from_input()
			state_machine.on_dodge_pressed(direction)
		else:
			# Caso contrário, é um "press" normal para iniciar a lógica de toque/segurar.
			hold_input_timer.start()
		
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("dodge_run"):
		# Se não estávamos a correr, foi um "toque" para esquiva.
		if not is_running:
			if not hold_input_timer.is_stopped():
				hold_input_timer.stop()
				var direction = _get_dodge_direction_from_input()
				state_machine.on_dodge_pressed(direction)
		else:
			# Se estávamos a correr, não paramos imediatamente. Iniciamos a janela de cancelamento.
			run_cancel_timer.start()

		get_viewport().set_input_as_handled()
		return

	# Passamos os outros eventos para a StateMachine.
	state_machine.process_input(event)


# --- HANDLERS DOS TIMERS ---

func _on_hold_input_timer_timeout():
	# O tempo para "segurar" terminou. Ativamos a corrida.
	if Input.is_action_pressed("dodge_run"):
		is_running = true

func _on_run_cancel_timer_timeout():
	# A janela de oportunidade para cancelar a corrida terminou. Agora paramos de correr.
	is_running = false

# --- LÓGICA DE INPUT ---

func _get_dodge_direction_from_input() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y = -1
	elif Input.is_action_pressed("move_down"):
		direction.y = 1
	
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	elif Input.is_action_pressed("move_right"):
		direction.x = 1
		
	return direction
