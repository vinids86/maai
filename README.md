# Resumo Técnico do Projeto "Maai"

## 1. Visão Geral
* **Tecnologia:** Godot Engine 4 (GDScript 2.0 com tipagem estática).
* **Gênero:** Plataforma de Ação e Combate 2D.
* **Foco:** Combate técnico (Parry, Stagger) e responsividade.

---

## 2. Pilares da Arquitetura

### 2.1 Máquina de Estados (State Machine)
O "cérebro" de cada ator. Centraliza a lógica de transição.
* **Implementação:** Os estados herdam de `StateBase` e são nós filhos da StateMachine.
* **Regra de Ouro:** A StateMachine é a única autoridade de transição. O Estado apenas notifica que terminou.

### 2.2 ⚔️ Arquitetura de Inimigos (Enemy Architecture)

O projeto adota uma **Arquitetura de Dois Níveis** para os inimigos, visando estabilidade e escalabilidade:

#### 2.2.1. Inimigos Complexos (Duelistas)
* **Lógica:** Compartilham a mesma `StateMachine` principal e os mesmos scripts de estado (`scripts/states/`) que o Player.
* **Recursos:** Utilizam o sistema completo de *Poise*, *Stamina*, *Hurtboxes* complexas e *SkillSets*.
* **Uso:** Chefes, inimigos humanóides e oponentes que exigem parry/combate tático.

#### 2.2.2. Inimigos Simples (Plataforma/Goomba)
* **Lógica:** Utilizam uma **`SimpleStateMachine`** totalmente isolada, localizada em `scripts/platform/`.
* **Estados:** Possuem estados exclusivos (`SimplePatrolState`, `SimpleStaggerState`) que **não** herdam dos estados do Player.
* **Motivo:** Garantir que alterações em inimigos básicos de plataforma ("bucha de canhão") jamais quebrem a lógica complexa do Player ou dos Chefes.
* **Regra de Ouro:** Não tente forçar o uso da FSM do Player em inimigos simples (e vice-versa) sem uma refatoração consciente.

### 2.3 Composição de Componentes
Atores são entidades vazias funcionalmente que ganham vida via nós filhos.
* `HealthComponent`: Gerencia vida/morte.
* `PoiseComponent`: Gerencia postura e stagger.
* `ImpactResolver`: Sistema estático para resolver colisão (Hitbox vs Hurtbox).

### 2.4 Design Orientado a Dados (Resources)
Balanceamento feito em arquivos `.tres` (AttackProfile, DodgeProfile), nunca hardcoded no script.

---

## 3. Regras Arquiteturais Estritas

1.  **Input → Intenção:** O script do Ator (`player.gd`) captura Input e despacha "intenções" para a StateMachine (ex: `on_attack_pressed`). O Estado decide se aceita.
2.  **Fluxo Unidirecional:** `Input -> Ator -> StateMachine -> Estado -> Componentes`. Componentes nunca controlam a StateMachine diretamente.
3.  **Dependências:** Injeção via `_ready()` com `assert` para garantir integridade.

---

## 4. Estratégia de Entidades (Sistema Dual)

O projeto utiliza duas arquiteturas distintas para Atores, dependendo da complexidade necessária. Ambas interagem via `ImpactResolver` (dano/colisão), mas operam internamente de formas diferentes.

### 4.1 Atores Complexos (Player, Bosses, Elite Enemies)
Compartilham a arquitetura completa de combate técnico.
* **Controlador:** `StateMachine.gd` (Completa).
* **Recursos:** Possuem `Stamina`, `Poise`, `InputBuffer`.
* **Capacidades:** Podem executar Parry, cancelar ataques, ter postura quebrada.
* **Arquivos Base:** Usam `StateBase` e scripts compartilhados em `scripts/states/`.

### 4.2 Atores Simples (SimpleEnemy / Mobs)
Implementação otimizada para inimigos de patrulha ou comportamento básico.
* **Controlador:** `SimpleStateMachine.gd` (Leve).
* **Diferenças:**
	* Não possuem Stamina ou Input Buffer complexo.
	* Estados herdam de `SimpleState` (versão reduzida).
	* **Combate Passivo:** Usam Hitbox ativa por contato ou ataques diretos sem janelas de cancelamento complexas.
	* **Dano:** O dano recebido vai direto para o `HealthComponent`, ignorando cálculos complexos de Poise (salvo exceções).

### 4.3 Interoperabilidade
O `ImpactResolver` é agnóstico. Ele detecta `Hitbox` vs `Hurtbox`.
* Se o alvo for **Complexo**: Calcula redução de dano, poise, checa parry.
* Se o alvo for **Simples**: Aplica dano direto e knockback básico.

---

## 5. Estrutura de Diretórios (File Map)

### Core Systems
* `scripts/core/`:
	* `state_machine.gd` vs `simple_state_machine.gd`
	* `state_base.gd` vs `simple_state.gd`
	* `impact_resolver.gd` (Lógica compartilhada de combate)

### Atores
* `scripts/actors/player/`: Lógica exclusiva do jogador.
* `scripts/actors/enemies/standard/`: Inimigos que usam a StateMachine complexa.
* `scripts/actors/enemies/simple/`: Inimigos que usam a SimpleStateMachine.

### Componentes Globais
* `scripts/components/`: (`health_component.gd`, `hitbox.gd`, etc) - Usados por **ambos** os tipos de inimigos.

---

## 6. Convenções de Código

1.  **Tipagem Estática:** Obrigatória (`: float`, `: Node`, `-> void`).
2.  **Sinais:** Preferir `signal_name.connect(Callable)`.
3.  **Nomes de Classes:** Usar `class_name` para facilitar injeção (ex: `class_name SimpleEnemy`).
