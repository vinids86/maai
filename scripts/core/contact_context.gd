class_name ContactContext
extends Resource

## Este objeto é um contêiner de dados temporário ("dossiê").
## Ele é criado pelo ImpactResolver para agrupar todas as informações
## relevantes de um impacto e passá-las para o State do defensor tomar uma decisão.

# --- Referências aos Atores ---
var attacker_node: Node
var defender_node: Node

# --- Referências aos Perfis de Ataque ---
var attack_profile: AttackProfile
var defender_attack_profile: AttackProfile = null

# --- Referências aos Componentes do Defensor ---
var defender_health_comp: HealthComponent
var defender_stamina_comp: StaminaComponent
var defender_poise_comp: PoiseComponent
var defender_state_machine: StateMachine

# --- Dados Calculados pelo ImpactResolver ---
var attacker_offensive_poise: float = 0.0
