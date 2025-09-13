class_name EnemyStatusUI
extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar

func _ready():
	health_bar.value = health_bar.max_value
	stamina_bar.value = stamina_bar.max_value

func update_health(current_health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = current_health

func update_stamina(current_stamina: float, max_stamina: float):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina
