class_name AIActionStep
extends Resource

## Tipo de defesa que o inimigo usará neste turno.
@export_enum("block", "parry") var defense: String = "block"

## Ação de resposta. Deixe "normal_attack" para ataque básico, ou use o nome da skill (ex: "skill_z").
@export var riposte: String = "normal_attack"
