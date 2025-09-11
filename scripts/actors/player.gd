class_name Player
extends CharacterBody2D

# --- REFERÊNCIAS ---
@onready var state_machine: StateMachine = $StateMachine

# --- CICLO DE VIDA DO GODOT ---

func _physics_process(delta: float):
	state_machine.process_physics(delta)
	move_and_slide()

func _unhandled_input(event: InputEvent):
	# O Player interpreta os inputs de AÇÃO e comunica a INTENÇÃO à StateMachine.
	# CORREÇÃO: Usamos event.is_action_pressed(), que existe no objeto InputEvent.
	# Dentro de _unhandled_input, isto efetivamente funciona como "just_pressed".
	if event.is_action_pressed("dodge"):
		var direction = _get_dodge_direction_from_input()
		state_machine.on_dodge_pressed(direction)
		# Consumimos o evento para que outros nós não o processem.
		get_viewport().set_input_as_handled()
		return

	# Se não for uma ação que o Player trata, passamos o evento para
	# a StateMachine, caso o estado atual precise dele.
	state_machine.process_input(event)


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
