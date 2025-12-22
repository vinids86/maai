class_name Spikes extends Node2D

@export var attack_profile: AttackProfile
@onready var hitbox: Hitbox = $Hitbox

func _ready() -> void:
	# Injeta o perfil na Hitbox assim que o jogo começa
	if hitbox and attack_profile:
		hitbox.attack_profile = attack_profile
