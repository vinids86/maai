class_name Hitbox
extends Area2D

var owner_actor: Node
var attack_profile: AttackProfile

func _ready():
	owner_actor = get_parent()
	assert(owner_actor != null, "Hitbox deve ser filha de um nó de ator.")
