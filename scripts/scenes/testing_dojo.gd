extends Node2D

# --- REFERÊNCIAS ---
# Vamos associar o Player e a HUD através do editor.
@export var player: Player
@export var hud: HUDController

func _ready():
	# Verificações de segurança
	assert(player != null, "A referência ao Player não foi atribuída no Inspetor.")
	assert(hud != null, "A referência à HUD não foi atribuída no Inspetor.")
	
	# Procuramos pelos componentes de recursos no Player.
	var health_component = player.find_child("HealthComponent")
	var stamina_component = player.find_child("StaminaComponent")
	
	assert(health_component != null, "O Player não tem um HealthComponent.")
	assert(stamina_component != null, "O Player não tem um StaminaComponent.")
	
	# --- CONEXÃO DOS SINAIS ---
	# Ligamos o sinal "health_changed" do componente de saúde à função "update_health" da HUD.
	health_component.health_changed.connect(hud.update_health)
	# Fazemos o mesmo para a stamina.
	stamina_component.stamina_changed.connect(hud.update_stamina)
	
	# --- INICIALIZAÇÃO DOS VALORES ---
	# Garantimos que a HUD mostra os valores corretos assim que o jogo começa.
	hud.update_health(health_component.current_health, health_component.max_health)
	hud.update_stamina(stamina_component.current_stamina, stamina_component.max_stamina)
