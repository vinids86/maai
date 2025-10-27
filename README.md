# \# Resumo Técnico do Projeto "Maai"

# 

# \## 1. Visão Geral

# 

# \*\*Tecnologia:\*\* Godot Engine (versão 4+) utilizando \*\*GDScript\*\*.  

# \*\*Estilo de Jogo:\*\* Plataforma de Ação e Combate 2D com ênfase em combate técnico, preciso e reativo.  

# As mecânicas centrais incluem \*\*combos, parry, esquivas\*\* e a gestão de recursos como \*\*Stamina\*\* e \*\*Poise\*\*.

# 

# ---

# 

# \## 2. Pilares da Arquitetura

# 

# O projeto é construído sobre \*\*três pilares fundamentais\*\* que ditam a organização do código e a implementação de funcionalidades, garantindo manutenibilidade e escalabilidade.

# 

# \### 2.1 Máquina de Estados (State Machine) Centralizada

# O comportamento de todos os atores (\*\*Jogador\*\*, \*\*Inimigos\*\*) é orquestrado por uma \*\*StateMachine\*\* dedicada.  

# Esta entidade atua como o cérebro do ator, gerenciando as transições entre os diversos estados comportamentais (`LocomotionState`, `AttackState`, `AirborneState`, etc.) e servindo como \*\*a única autoridade para mudança de estado\*\*.

# 

# \### 2.2 Composição de Componentes

# Em vez de herança massiva, os atores são construídos pela \*\*agregação de múltiplos nós-filhos\*\*, cada um com uma responsabilidade única e encapsulada  

# (ex: `HealthComponent`, `PoiseComponent`, `ComboComponent`).  

# 

# O script principal do ator (`player.gd`, `enemy.gd`) funciona como um \*\*orquestrador\*\*, que inicializa e injeta as dependências entre os componentes, mas a lógica específica de cada sistema reside no seu próprio componente.

# 

# \### 2.3 Design Orientado a Dados (Data-Driven)

# Nenhum valor de gameplay (dano, velocidade, custo de stamina, duração de animações, etc.) é “hardcoded” no código-fonte.  

# Todos esses parâmetros são externalizados para ficheiros de \*\*Recurso (.tres)\*\*, como `AttackProfile`, `DodgeProfile`, entre outros.  

# 

# Esta abordagem permite que o \*\*balanceamento e o ajuste fino\*\* das mecânicas sejam realizados sem a necessidade de alterar a lógica do jogo.

# 

# ---

# 

# \## 3. Regras Arquitetónicas Invioláveis

# 

# Estas são as \*\*diretrizes fundamentais\*\* que garantem a estabilidade e o baixo acoplamento do sistema.  

# A violação destas regras compromete a integridade da arquitetura.

# 

# \### 3.1 A StateMachine é a Única Autoridade de Transição

# \- Um \*\*State\*\* (estado) nunca decide para qual estado deve transicionar a seguir; ele \*\*não tem conhecimento de outros estados\*\*.  

# \- Ao concluir sua tarefa (ex: um ataque termina), um State deve apenas notificar a StateMachine através de um método padronizado, como:  

# &nbsp; ```gdscript

# &nbsp; state\_machine.on\_current\_state\_finished()

# 

