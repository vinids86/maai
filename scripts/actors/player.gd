class_name Player
extends CharacterBody2D

# --- REFERÊNCIAS ---
@onready var state_machine: StateMachine = $StateMachine
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer
@onready var buffer_controller: BufferController = $BufferController

# --- DADOS DE COMBATE ---
@export var attack_set: AttackSet

# --- ESTADO INTERNO ---
var is_running: bool = false
var facing_sign: int = 1
var facing_locked: bool = false
var combo_index: int = 0

# --- CICLO DE VIDA DO GODOT ---

func _ready():
	hold_input_timer.timeout.connect(_on_hold_input_timer_timeout)
	run_cancel_timer.timeout.connect(_on_run_cancel_timer_timeout)

func _physics_process(delta: float):
	state_machine.process_physics(delta, is_running)
	move_and_slide()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("dodge_run"):
		if not run_cancel_timer.is_stopped():
			run_cancel_timer.stop()
			var direction = _get_dodge_direction_from_input()
			state_machine.on_dodge_pressed(direction)
		else:
			hold_input_timer.start()
		
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released("dodge_run"):
		if not is_running:
			if not hold_input_timer.is_stopped():
				hold_input_timer.stop()
				var direction = _get_dodge_direction_from_input()
				state_machine.on_dodge_pressed(direction)
		else:
			run_cancel_timer.start()

		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("attack"):
		# A lógica foi simplificada. O Player apenas notifica a StateMachine da intenção.
		# A StateMachine irá então perguntar ao estado atual como deve proceder.
		state_machine.on_attack_pressed()
		
		get_viewport().set_input_as_handled()
		return

	state_machine.process_input(event)


# --- HANDLERS DOS TIMERS ---

func _on_hold_input_timer_timeout():
	if Input.is_action_pressed("dodge_run"):
		is_running = true

func _on_run_cancel_timer_timeout():
	is_running = false

# --- LÓGICA DE COMBO ---

func get_next_attack_in_combo() -> AttackProfile:
	if not attack_set or attack_set.attacks.is_empty():
		return null

	if combo_index >= attack_set.attacks.size():
		return null
	
	var profile = attack_set.attacks[combo_index]
	combo_index += 1
	return profile

func reset_combo_chain():
	combo_index = 0

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
