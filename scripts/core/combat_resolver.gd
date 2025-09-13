extends Node

# O "relatório de incidente" é uma classe interna para evitar conflitos de nome.
class ContactResult extends Resource:
	enum Outcome {
		HIT,
		PARRIED,
		BLOCKED,
		GUARD_BROKEN,
		DODGED
	}
	var outcome: Outcome

func resolve_contact(hitbox: Hitbox, hurtbox: Hurtbox):
	var attacker = hitbox.owner_actor
	var defender = hurtbox.owner_actor
	var attack_profile = hitbox.attack_profile
	
	if not attacker or not defender or not attack_profile:
		push_warning("CombatResolver: Contexto de combate incompleto.")
		return

	# --- LÓGICA DE DANO DIRETO ---
	# Esta é a nossa primeira regra de combate. No futuro, a lógica de parry e block virá antes disto.
	
	# Procuramos por um HealthComponent no defensor.
	var defender_health = defender.find_child("HealthComponent")
	if defender_health is HealthComponent:
		# Se encontrarmos, aplicamos o dano definido no perfil de ataque.
		defender_health.take_damage(attack_profile.damage)

	# Por agora, para dar um feedback visual mínimo, podemos fazer o defensor piscar a vermelho.
	if defender.has_method("flash_red"):
		defender.flash_red()

	print("Impacto resolvido: ", attacker.name, " atingiu ", defender.name, " causando ", attack_profile.damage, " de dano.")
