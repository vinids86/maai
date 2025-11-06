class_name ContactResult
extends Resource

enum DefenderOutcome {
	HIT,
	POISE_BROKEN,
	PARRY_SUCCESS,
	BLOCKED,
	GUARD_BROKEN,
	DODGED,
	FINISHER_HIT,
	DODGE_COUNTER_READY
}
enum AttackerOutcome {
	NONE,
	PARRIED,
	DEFLECTED,
	GUARD_BREAK_SUCCESS,
	TRADE_LOST,
	FINISHER_SUCCESS,
	ATTACK_BLOCKED,
	DODGE_COUNTERED_VULNERABLE
}

var attacker_node: Node
var defender_node: Node
var attack_profile: AttackProfile
var knockback_vector: Vector2
var counter_profile: CounterExecutionProfile

var defender_outcome: DefenderOutcome
var attacker_outcome: AttackerOutcome = AttackerOutcome.NONE
