Resumo Técnico do Projeto "Maai"

1. Visão Geral

Tecnologia: Godot Engine (versão 4+) utilizando GDScript.

Estilo de Jogo: Plataforma de Ação e Combate 2D com ênfase em combate técnico, preciso e reativo.

As mecânicas centrais incluem combos, parry, esquivas e a gestão de recursos como Stamina e Poise.

2. Pilares da Arquitetura

O projeto é construído sobre três pilares fundamentais que ditam a organização do código e a implementação de funcionalidades, garantindo manutenibilidade e escalabilidade.

2.1 Máquina de Estados (State Machine) Centralizada

O comportamento de todos os atores (Jogador, Inimigos) é orquestrado por uma StateMachine dedicada.

Esta entidade atua como o cérebro do ator, gerenciando as transições entre os diversos estados comportamentais (LocomotionState, AttackState, AirborneState, etc.) e servindo como a única autoridade para mudança de estado.

2.2 Composição de Componentes

Em vez de herança massiva, os atores são construídos pela agregação de múltiplos nós-filhos, cada um com uma responsabilidade única e encapsulada

(ex: HealthComponent, PoiseComponent, ComboComponent).

O script principal do ator (player.gd, enemy.gd) funciona como um orquestrador, que inicializa e injeta as dependências entre os componentes, mas a lógica específica de cada sistema reside no seu próprio componente.

2.3 Design Orientado a Dados (Data-Driven)

Nenhum valor de gameplay (dano, velocidade, custo de stamina, duração de animações, etc.) é “hardcoded” no código-fonte.

Todos esses parâmetros são externalizados para ficheiros de Recurso (.tres), como AttackProfile, DodgeProfile, entre outros.

Esta abordagem permite que o balanceamento e o ajuste fino das mecânicas sejam realizados sem a necessidade de alterar a lógica do jogo.

3. Regras Arquitetónicas Invioláveis

Estas são as diretrizes fundamentais que garantem a estabilidade e o baixo acoplamento do sistema.

A violação destas regras compromete a integridade da arquitetura.

3.1 A StateMachine é a Única Autoridade de Transição

Um State (estado) nunca decide para qual estado deve transicionar a seguir; ele não tem conhecimento de outros estados.

Ao concluir sua tarefa (ex: um ataque termina), um State deve apenas notificar a StateMachine através de um método padronizado, como:

state_machine.on_current_state_finished()


É responsabilidade exclusiva da StateMachine analisar o contexto atual do ator (input do jogador, estado dos componentes) e determinar qual será o próximo estado.

3.2 Atores Expressam "Intenção", Não Controlam o Estado

O script do ator (ex: player.gd) é responsável por capturar inputs e traduzi-los em intenções (ex: “o botão de ataque foi pressionado”).

O ator delega essa intenção à StateMachine, por exemplo:

state_machine.on_attack_pressed(profile)


sem verificar em qual estado se encontra.

É o State atualmente ativo que recebe a intenção da StateMachine e decide se a ação é válida no seu contexto.

3.3 O Fluxo de Comunicação é Unidirecional

O fluxo de informação segue um caminho estrito para evitar dependências circulares e garantir a previsibilidade do sistema.

Fluxo Padrão: ```
Input → Ator → StateMachine → Estado Atual → Componentes → Estado Atual notifica o fim → StateMachine decide a próxima transição


Qualquer quebra neste fluxo (um estado chamando outro diretamente, ou um componente alterando o estado da máquina) é considerada uma **violação grave da arquitetura**.

---

## 4. Tipos de Inimigos e Variações de Sistema

O projeto suporta diferentes níveis de complexidade para os atores, permitindo a existência de inimigos com combate profundo e inimigos de comportamento simples no mesmo ecossistema.

### 4.1 Inimigo Padrão (Complexo)
O inimigo padrão (`Enemy.gd`) utiliza a arquitetura completa de combate.
- **Recursos:** Possui Health, Stamina e Poise.
- **Defesa:** Capaz de bloquear, aparar (parry) e sofrer quebra de postura.
- **State Machine:** Completa, gerenciando interrupções, buffer de inputs e custos de ação.

### 4.2 Inimigo Simples (SimpleEnemy)
Uma implementação otimizada (`SimpleEnemy.gd`) para inimigos que atuam como obstáculos móveis ou patrulheiros básicos, sem a complexidade de duelo.

#### Principais Diferenças:
1.  **SimpleStateMachine:**
    - Uma versão leve da máquina de estados que remove sistemas de **Input Buffer**, **Action Cost** e **Stamina Management**.
    - Mantém a interface pública compatível (`transition_to`, sinais de fase) para se integrar transparentemente com componentes globais como `AnimationComponent`.

2.  **SimpleState e Resolução de Impacto:**
    - Os estados herdam de `SimpleState`, que implementa uma versão simplificada de `resolve_contact()`.
    - **Dano Direto:** Ao ser atacado, o `SimpleState` ignora cálculos de Poise/Stamina e aplica o dano diretamente ao `HealthComponent`.
    - **Combate Passivo:** Utiliza `Hitbox` sempre ativa para causar dano por contato, sem depender de janelas de animação de ataque.

3.  **Integração Híbrida:**
    - O sistema central `ImpactResolver` e `ContactContext` foram adaptados para suportar tanto a `StateMachine` complexa quanto a `SimpleStateMachine`, permitindo que o Player combata ambos os tipos de inimigos usando as mesmas mecânicas de ataque.
