class_name Projectile
extends Node2D

@export var speed: float = 600.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var has_impacted: bool = false

func _ready() -> void:
	# Autodestruição por tempo para evitar vazamento de memória
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

## Configura o projétil antes de lançá-lo.
## Deve ser chamado imediatamente após instanciar a cena.
func setup(real_shooter: Node, profile: AttackProfile, shoot_direction: Vector2) -> void:
	direction = shoot_direction.normalized()
	rotation = direction.angle() # Rotaciona o visual para a direção do tiro
	
	# Localiza e configura o Hitbox filho
	var hitbox = find_child("Hitbox") as Hitbox
	if hitbox:
		# Lógica RPG: Quem ganha a mana/XP é o atirador original
		hitbox.owner_actor = real_shooter
		
		# Lógica Física: O empurrão vem DESTA bala, não do atirador lá longe
		hitbox.source_node = self 
		
		# Injeta os dados do ataque (dano, knockback force, etc)
		hitbox.attack_profile = profile
		
		# Opcional: Conectar sinal para destruir o projétil ao acertar algo
		# hitbox.area_entered.connect(_on_hitbox_contact)
	else:
		push_warning("Projectile: Nenhum nó 'Hitbox' encontrado como filho.")

func _physics_process(delta: float) -> void:
	if not has_impacted:
		global_position += direction * speed * delta

# Função utilitária para ser chamada quando o Hitbox confirma um hit válido
func on_impact_confirmed() -> void:
	has_impacted = true
	queue_free()
