class_name HUDController
extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var stamina_bar: TextureProgressBar = $StaminaBar
@onready var focus_bar: TextureProgressBar = $FocusBar
@onready var focus_segments_container: HBoxContainer = $FocusSegmentsContainer

# Cores para os segmentos de foco (pode ajustá-las no editor)
@export var segment_incomplete_color: Color = Color(0.5, 0.5, 0.5)
@export var segment_complete_color: Color = Color(0.2, 0.8, 1.0)


func initialize_hud(player_node: Node):
	var health_component = player_node.find_child("HealthComponent")
	var stamina_component = player_node.find_child("StaminaComponent")
	var focus_component = player_node.find_child("FocusComponent")
	
	if health_component:
		health_component.health_changed.connect(update_health)
		# Força a atualização inicial
		update_health(health_component.current_health, health_component.max_health)
	
	if stamina_component:
		stamina_component.stamina_changed.connect(update_stamina)
		# Força a atualização inicial
		update_stamina(stamina_component.current_stamina, stamina_component.max_stamina)
	print("initialize_hud")
	if focus_component:
		focus_component.focus_changed.connect(_on_focus_changed)
		focus_component.segment_completed.connect(_on_segment_completed)
		# Força a atualização inicial
		_on_focus_changed(focus_component.current_focus, focus_component.max_focus)
		_on_segment_completed(0) # Começa com 0 segmentos completos


func update_health(current_health: float, max_health: float):
	health_bar.max_value = max_health
	health_bar.value = current_health

func update_stamina(current_stamina: float, max_stamina: float):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = current_stamina

func _on_focus_changed(current_focus: int, max_focus: int):
	print("_on_focus_changed", current_focus)
	focus_bar.max_value = max_focus
	focus_bar.value = current_focus

func _on_segment_completed(completed_segments: int):
	var segments = focus_segments_container.get_children()
	for i in range(segments.size()):
		if i < completed_segments:
			segments[i].color = segment_complete_color
		else:
			segments[i].color = segment_incomplete_color
