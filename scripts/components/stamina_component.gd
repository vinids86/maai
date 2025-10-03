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
	
	ImpactResolver.impact_resolved.connect(_on_impact_resolved)

func _physics_process(delta: float):
	if can_regenerate and current_stamina < max_stamina:
		current_stamina = min(max_stamina, current_stamina + regeneration_rate * delta)
		emit_signal("stamina_changed", current_stamina, max_stamina)

func _on_impact_resolved(result: ContactResult):
	if result.defender_node == get_parent():
		if result.defender_outcome == ContactResult.DefenderOutcome.FINISHER_HIT:
			restore_to_full()

func has_enough_stamina(amount: float) -> bool:
	return current_stamina >= amount

func consume_stamina(amount: float) -> void:
	if has_enough_stamina(amount):
		_update_stamina(current_stamina - amount)

func try_consume(amount: float) -> bool:
	if not has_enough_stamina(amount):
		return false
	
	_update_stamina(current_stamina - amount)
	return true

func take_stamina_damage(amount: float) -> bool:
	if is_stamina_broken():
		return false

	var stamina_after_damage = current_stamina - amount
	_update_stamina(stamina_after_damage)
	
	return not is_stamina_broken()

func restore_to_full():
	_update_stamina(max_stamina)
	can_regenerate = true

func is_stamina_broken() -> bool:
	return current_stamina <= 0

func _update_stamina(new_value: float):
	current_stamina = max(0, new_value)
	can_regenerate = false
	delay_timer.start()
	emit_signal("stamina_changed", current_stamina, max_stamina)
