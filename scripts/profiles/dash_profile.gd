class_name DashProfile
extends Resource

@export_group("Phases")
@export var active_duration: float = 0.2
@export var recovery_duration: float = 0.1

@export_group("Movement")
## Distância total aproximada que o dash percorrerá durante a fase ativa.
@export var dash_distance: float = 250.0 

## Curva que define como a velocidade varia durante o dash. 
## Eixo X = Tempo (0 a 1), Eixo Y = Multiplicador de Velocidade (geralmente de 0 a 2). 
## Se vazio, o movimento será linear constante.
@export var speed_curve: Curve

## Quão rápido o personagem desacelera na fase de recuperação (pixels/s^2).
@export var recovery_friction: float = 1000.0

@export_group("Presentation")
@export var animation_name: StringName

@export_group("Audio")
@export var active_sfx: AudioStream
@export var recovery_sfx: AudioStream

@export_group("Mechanics")
@export var stamina_cost: float = 10.0
