class_name HealthComponent
extends Node

signal health_changed(current_health, max_health)
signal died

@export var max_health: float = 100.0
var current_health: float
var _is_dead: bool = false

func _ready():
	current_health = max_health

func take_damage(amount: float):
	if _is_dead:
		return

	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		_is_dead = true
		emit_signal("died")

func heal(amount: float):
	if _is_dead:
		return
	
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)

func is_dead() -> bool:
	return _is_dead
