class_name Player
extends CharacterBody2D

@onready var state_machine: StateMachine = $StateMachine
@onready var hold_input_timer: Timer = $HoldInputTimer
@onready var run_cancel_timer: Timer = $RunCancelTimer

var is_running: bool = false
var facing_sign: int = 1
var facing_locked: bool = false

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

	state_machine.process_input(event)

func _on_hold_input_timer_timeout():
	if Input.is_action_pressed("dodge_run"):
		is_running = true

func _on_run_cancel_timer_timeout():
	is_running = false

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
