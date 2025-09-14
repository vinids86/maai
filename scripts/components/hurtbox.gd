class_name Hurtbox
extends Area2D

var owner_actor: Node

func _ready() -> void:
	owner_actor = get_parent()
	assert(owner_actor != null, "Hurtbox deve ser filha de um nó de ator.")

	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not (area is Hitbox):
		return

	var hb: Hitbox = area as Hitbox
	ImpactResolver.resolve_contact(hb, self)
