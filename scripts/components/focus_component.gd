class_name FocusComponent
extends Node

signal focus_changed(current_focus, max_focus)
signal segment_completed(completed_segments)

@export var max_focus: int = 300
@export var segments: int = 3
@export var decay_delay: float = 3.0

@export_group("Focus Gain")
@export var focus_gain_on_parry: int = 10

var current_focus: int = 0

@onready var decay_timer: Timer = $DecayTimer

func _ready() -> void:
	decay_timer.wait_time = decay_delay
	decay_timer.one_shot = true
	
	ImpactResolver.impact_resolved.connect(_on_impact_resolved)
	decay_timer.timeout.connect(_on_DecayTimer_timeout)
	
	emit_signal("focus_changed", current_focus, max_focus)
	emit_signal("segment_completed", 0)

func _on_impact_resolved(result: ContactResult) -> void:
	if result.attacker_node != owner:
		return
	
	if result.attack_profile and result.attack_profile.focus_cost > 0:
		return
		
	if result.attack_profile and "focus_gain_on_hit" in result.attack_profile:
		gain_focus(result.attack_profile.focus_gain_on_hit)

func gain_focus(amount: int) -> void:
	var old_focus = current_focus
	current_focus = min(current_focus + amount, max_focus)
	
	if current_focus > old_focus:
		decay_timer.start()
		_check_segment_completion()
		emit_signal("focus_changed", current_focus, max_focus)

func consume_focus(cost: int) -> void:
	current_focus -= cost
	decay_timer.start()
	emit_signal("focus_changed", current_focus, max_focus)
	_check_segment_completion()

func has_enough_focus(cost: int) -> bool:
	return current_focus >= cost

func get_focus_per_segment() -> int:
	if segments <= 0:
		return max_focus
	return max_focus / segments

func _check_segment_completion() -> void:
	var focus_per_segment = get_focus_per_segment()
	if focus_per_segment == 0: return
	
	var current_segments = floor(current_focus / float(focus_per_segment))
	emit_signal("segment_completed", current_segments)

func _on_DecayTimer_timeout() -> void:
	var focus_per_segment = get_focus_per_segment()
	if focus_per_segment == 0: return

	var focus_in_current_segment = current_focus % focus_per_segment
	
	if focus_in_current_segment == 0 and current_focus > 0 and current_focus == max_focus:
		return
	
	var new_focus = current_focus - focus_in_current_segment
	if new_focus != current_focus:
		current_focus = new_focus
		emit_signal("focus_changed", current_focus, max_focus)
