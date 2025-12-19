extends Node
# PlayerFeedbackComponent.gd
# Reage ao sinal ImpactResolver.impact_resolved(ContactResult)
# e aplica trauma na Camera2D de acordo com o outcome.

@onready var camera: Node = get_parent().get_node_or_null("Camera2D")

@export_group("Hit Stop")
@export var hitstop_on_hit: float = 0.06
@export var hitstop_on_parry_or_break: float = 0.10
@export var hitstop_slow_scale: float = 0.01

@export_group("Defaults")
@export var fallback_trauma: float = 0.25

@export_group("Defender Outcomes (quando o Player DEFENDE)")
@export var trauma_def_hit: float = 0.30
@export var trauma_def_poise_broken: float = 0.55
@export var trauma_def_parry_success: float = 0.85
@export var trauma_def_blocked: float = 0.20
@export var trauma_def_guard_broken: float = 0.60
@export var trauma_def_dodged: float = 0.0
@export var trauma_def_finisher_hit: float = 0.70
@export var trauma_def_counter_success: float = 0.60

@export_group("Attacker Outcomes (quando o Player ATACA)")
@export var trauma_att_none: float = 0.20
@export var trauma_att_parried: float = 0.35
@export var trauma_att_deflected: float = 0.30
@export var trauma_att_guard_break_success: float = 0.60
@export var trauma_att_trade_lost: float = 0.25
@export var trauma_att_finisher_success: float = 0.70
@export var trauma_att_countered: float = 0.55

func _ready() -> void:
	if ImpactResolver:
		ImpactResolver.impact_resolved.connect(_on_impact_resolved)

func _on_impact_resolved(contact: ContactResult) -> void:
	if camera == null:
		camera = get_tree().get_first_node_in_group("MainCamera")

	if camera == null or not camera.has_method("add_trauma"):
		return
	if contact == null:
		return

	var me := get_parent()
	var i_am_defender := contact.defender_node == me
	var i_am_attacker := contact.attacker_node == me
	if not (i_am_defender or i_am_attacker):
		return

	var amount := fallback_trauma

	if i_am_defender:
		match contact.defender_outcome:
			ContactResult.DefenderOutcome.HIT:
				amount = trauma_def_hit
			ContactResult.DefenderOutcome.POISE_BROKEN:
				amount = trauma_def_poise_broken
			ContactResult.DefenderOutcome.PARRY_SUCCESS:
				amount = trauma_def_parry_success
			ContactResult.DefenderOutcome.BLOCKED:
				amount = trauma_def_blocked
			ContactResult.DefenderOutcome.GUARD_BROKEN:
				amount = trauma_def_guard_broken
			ContactResult.DefenderOutcome.DODGED:
				amount = trauma_def_dodged
			ContactResult.DefenderOutcome.FINISHER_HIT:
				amount = trauma_def_finisher_hit
			_:
				amount = fallback_trauma
	elif i_am_attacker:
		match contact.attacker_outcome:
			ContactResult.AttackerOutcome.NONE:
				amount = trauma_att_none
			ContactResult.AttackerOutcome.PARRIED:
				amount = trauma_att_parried
			ContactResult.AttackerOutcome.DEFLECTED:
				amount = trauma_att_deflected
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS:
				amount = trauma_att_guard_break_success
			ContactResult.AttackerOutcome.TRADE_LOST:
				amount = trauma_att_trade_lost
			ContactResult.AttackerOutcome.FINISHER_SUCCESS:
				amount = trauma_att_finisher_success
			ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY:
				amount = trauma_att_guard_break_success
			ContactResult.AttackerOutcome.ATTACK_BLOCKED:
				amount = trauma_att_guard_break_success
			_:
				amount = fallback_trauma

	camera.call("add_trauma", amount)
	
	var duration := 0.0
	if i_am_defender:
		match contact.defender_outcome:
			ContactResult.DefenderOutcome.GUARD_BROKEN:
				duration = hitstop_on_parry_or_break
			ContactResult.DefenderOutcome.BLOCKED:
				duration = 0.1
			_:
				duration = hitstop_on_hit
	elif i_am_attacker:
		match contact.attacker_outcome:
			ContactResult.AttackerOutcome.GUARD_BREAK_SUCCESS, \
			ContactResult.AttackerOutcome.FINISHER_SUCCESS:
				duration = hitstop_on_parry_or_break
			ContactResult.AttackerOutcome.ATTACK_BLOCKED:
				duration = 0.04
			ContactResult.AttackerOutcome.HIT_SUCCESS_SIMPLE_ENEMY:
				duration = 0.06
			_:
				duration = hitstop_on_hit

	if duration > 0.0:
		HitStop.apply(duration, hitstop_slow_scale)
