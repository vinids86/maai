class_name Hitbox
extends Area2D

## Referência ao ator "dono" do ataque (quem ganha Mana, XP, etc).
## Pode ser injetado externamente (ex: por um Projétil) ou inferido do pai.
var owner_actor: Node

## A origem física do ataque (usada para calcular direção do knockback).
## Se for um projétil, será o próprio nó do projétil.
## Se for um ataque melee, geralmente é o mesmo que o owner_actor.
var source_node: Node

var attack_profile: AttackProfile

func _ready() -> void:
	# Se owner_actor não foi injetado externamente, tenta pegar o pai.
	if owner_actor == null:
		owner_actor = get_parent()
	
	assert(owner_actor != null, "Hitbox deve ser filha de um nó de ator ou ter owner injetado.")
	
	# Se source_node não foi definido externamente (ex: por setup() de um Projétil), 
	# assume que a fonte física é o próprio dono (comportamento Melee padrão).
	if source_node == null:
		source_node = owner_actor

	area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Handler mantido para não alterar o fluxo; sem logs.
	pass
