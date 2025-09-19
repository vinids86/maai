class_name ContactContext
extends Resource

## Este objeto é um contêiner de dados temporário ("dossiê").
## Ele é criado pelo ImpactResolver para agrupar todas as informações
## relevantes de um impacto e passá-las para o State do defensor tomar uma decisão.

# --- Referências aos Atores ---
var attacker_node: Node
var defender_node: Node

# --- Referências aos Perfis de Ataque ---
# O perfil do ataque que está sendo desferido.
var attack_profile: AttackProfile
# O perfil do ataque que o defensor pode estar executando (para trocas de golpes).
var defender_attack_profile: AttackProfile = null

# --- Referências aos Componentes do Defensor ---
# Fornece acesso direto aos "órgãos vitais" do defensor para que o
# State possa aplicar as consequências (dano, consumo de stamina, etc.).
var defender_health_comp: HealthComponent
var defender_stamina_comp: StaminaComponent
var defender_poise_comp: PoiseComponent
var defender_state_machine: StateMachine
