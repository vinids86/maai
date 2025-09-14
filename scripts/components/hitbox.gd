class_name Hitbox
extends Area2D

var owner_actor: Node
var attack_profile: AttackProfile

func _ready() -> void:
	owner_actor = get_parent()
	assert(owner_actor != null, "Hitbox deve ser filha de um nó de ator.")
	area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Handler mantido para não alterar o fluxo; sem logs.
	pass
