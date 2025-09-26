class_name ContactResult
extends Resource

enum DefenderOutcome { HIT, POISE_BROKEN, PARRY_SUCCESS, BLOCKED, GUARD_BROKEN, DODGED, FINISHER_HIT, COUNTER_SUCCESS }
enum AttackerOutcome { NONE, PARRIED, DEFLECTED, GUARD_BREAK_SUCCESS, TRADE_LOST, FINISHER_SUCCESS, COUNTERED }

var attacker_node: Node
var defender_node: Node
var attack_profile: AttackProfile
var knockback_vector: Vector2

var defender_outcome: DefenderOutcome
var attacker_outcome: AttackerOutcome = AttackerOutcome.NONE
