class_name StaminaComponent
extends Node

signal stamina_changed(current_stamina, max_stamina)

@export_group("Configuration")
@export var max_stamina: float = 100.0
@export var regeneration_rate: float = 25.0
@export var regeneration_delay: float = 1.0

@onready var delay_timer: Timer = $DelayTimer

var current_stamina: float
var can_regenerate: bool = true

func _ready():
	current_stamina = max_stamina
	delay_timer.wait_time = regeneration_delay
	delay_timer.one_shot = true
	delay_timer.timeout.connect(func(): can_regenerate = true)

func _physics_process(delta: float):
	if can_regenerate and current_stamina < max_stamina:
		current_stamina = min(max_stamina, current_stamina + regeneration_rate * delta)
		emit_signal("stamina_changed", current_stamina, max_stamina)

func try_consume(amount: float) -> bool:
	if amount > current_stamina:
		return false
	
	current_stamina -= amount
	can_regenerate = false
	delay_timer.start()
	emit_signal("stamina_changed", current_stamina, max_stamina)
	return true
