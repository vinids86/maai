extends Area2D
class_name Token

## Referência ao Sprite para feedback visual.
@onready var sprite: Sprite2D = $Sprite2D

## Armazena a escala original para animações de tween.
var original_scale: Vector2
var tween: Tween

func _ready() -> void:
	# Adiciona ao grupo para ser encontrado pelo SmartTargetingComponent
	add_to_group("Tokens")
	
	if sprite:
		original_scale = sprite.scale

## Chamado pelo componente de mira do player para destacar este alvo.
func highlight(active: bool) -> void:
	if not sprite: return
	
	# Mata o tween anterior se existir para evitar conflitos
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if active:
		# Efeito visual de destaque (vermelho e maior)
		tween.parallel().tween_property(sprite, "modulate", Color(2.0, 0.5, 0.5), 0.1) # Brilho avermelhado (HDR)
		tween.parallel().tween_property(sprite, "scale", original_scale * 1.3, 0.1)
	else:
		# Volta ao normal
		tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
		tween.parallel().tween_property(sprite, "scale", original_scale, 0.2)
