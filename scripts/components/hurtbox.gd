class_name Hurtbox
extends Area2D

var owner_actor: Node

func _ready():
	owner_actor = get_parent()
	assert(owner_actor != null, "Hurtbox deve ser filha de um nó de ator.")
	
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):	
	if not area is Hitbox:
		print("LOG [Hurtbox]: O objeto que colidiu NÃO é uma Hitbox. A ignorar.")
		return
	
	ImpactResolver.resolve_contact(area, self)
