# Maai: Sistema de Progressão e Customização (Compilado)

Este documento detalha os três sistemas centrais que permitem ao jogador (Hana) customizar o seu estilo de combate: **Artes de Combate**, **Árvore de Talentos**, **Aprimoramento da Katana** e **Talismãs**.

---

## 1. Visão Geral e Loop de Recursos

O combate é definido pela gestão de três recursos e um loop de ação central.

### Recursos Base

* **HP (Vida):** A vida real. (Quase) só é danificada por *Finishers*.
* **Stamina-Escudo:** A defesa primária. Todo o dano (exceto *Finishers*) é aplicado aqui primeiro. Regenera-se passivamente fora de ações de ataque ou defesa.
* **Foco (Mana):** O recurso de ação. É gasto para usar *Artes de Combate* (ofensivo) e *Ações Táticas* como a *Esquiva Neutra* (defensivo/utilidade).

### O Loop de Combate Central

> **Ganhar Foco:** O jogador ganha Foco (Mana) ao executar *Parries Perfeitos*.
>
> **Gastar Foco:** O jogador gasta Foco para usar *Artes de Combate* (para quebrar o inimigo) ou *Ações Táticas* (para se defender/reposicionar).
>
> **A Quebra:** O objetivo é esgotar o *Stamina-Escudo* do inimigo.
>
> **A Punição:** Inimigos com *Stamina-Escudo* quebrado ficam abertos a um *Finisher*, que causa dano massivo de HP.

---

## 2. Artes de Combate (O Arsenal de 4 Slots)

Estas são as ações ativas que o jogador equipa nos seus 4 slots de acesso rápido. Todas as *Artes de Combate* custam Foco (Mana).

### A. Artes Físicas (Foco em Dano de Stamina-Escudo)

* **Arte: *Chute da Garça*** (Custo: Baixo)
  *Um chute rápido que quebra a guarda. Causa alto dano de Stamina-Escudo.*

* **Arte: *Ascensão da Carpa*** (Custo: Médio)
  *Um golpe de espada ascendente que lança inimigos leves ao ar.*

* **Arte: *Dança da Lâmina Dupla*** (Custo: Médio)
  *Uma sequência de dois golpes rápidos. Se o primeiro acertar, o segundo é garantido.*

### B. Artes Táticas (Foco em Controle e Mobilidade)

* **Arte: *Sombra Fugaz*** (Custo: Médio)
  *Troca de posição instantaneamente com o alvo (requer mira).*

* **Arte: *Ilusão do Dobro*** (Custo: Baixo)
  *Cria uma ilusão que atrai o aggro de inimigos comuns por um curto período.*

* **Arte: *Onda de Repulsão*** (Custo: Baixo)
  *Um pulso de energia que empurra inimigos próximos, criando distância.*

### C. Artes à Distância (Foco em Manter Pressão)

* **Arte: *Kunai Perfurante*** (Custo: Baixo)
  *Lança uma kunai rápida em linha reta. Causa dano de Stamina-Escudo quase nulo, mas pausa a regeneração do Stamina-Escudo do alvo por 3 segundos.*

* **Arte: *Shuriken de Sombra*** (Custo: Médio)
  *Lança uma shuriken lenta que persegue o alvo e atinge múltiplas vezes. Causa dano de Stamina-Escudo baixo, mas interrompe ações fracas.*

* **Arte: *Corte Espectral*** (Custo: Alto)
  *Canaliza por um momento e desfere um corte horizontal, lançando uma onda de energia espectral que perfura todos os inimigos no caminho.*

### D. Artes Elementais e de Status (Foco em Debuffs de Stamina)

* **Arte: *Lâmina Tóxica*** (Custo: Médio)
  *Aplica o status **Veneno**.*
  **Efeito:** Dano de Stamina-Escudo ao longo do tempo (DoT).

* **Arte: *Fragmento Gélido*** (Custo: Médio)
  *Lança um projétil de gelo que aplica **Geada**.*
  **Efeito:** Reduz em 50% a regeneração de Stamina-Escudo do alvo.

* **Arte: *Selo Explosivo*** (Custo: Médio)
  *Coloca um selo no chão que explode ao contato, aplicando **Queimadura**.*
  **Efeito:** O alvo recebe +20% de dano de Stamina-Escudo de todas as fontes enquanto em chamas.

* **Arte: *Javali Elétrico*** (Custo: Médio)
  *Uma investida rápida coberta de raios que aplica **Choque**.*
  **Efeito:** Causa dano de Stamina-Escudo médio e drena 25% do Foco (Mana) atual do inimigo.

---

## 3. Árvore de Talentos (Progressão Permanente)

Desbloqueada gastando **Pontos de Maestria** (obtidos ao derrotar Bosses e Mini-Bosses). Focada em desbloquear mecânicas e eficiência, não em *grind* de stats.

### Ramo 1: Stats (Poder Bruto / Eficiência)

* **+10% HP Máximo**
* **+10% Stamina-Escudo Máximo**
* **+10% Foco (Mana) Máximo**
* **Recuperação Rápida:** +15% na regeneração passiva do Stamina-Escudo.
* **Concentração de Combate:** +20% de Foco ganho ao executar Parries Perfeitos.
* **Fim de Ramo - Sobrepujar:** Quebrar o Stamina-Escudo de um inimigo concede 3s de regeneração acelerada de Foco.

### Ramo 2: Técnicas (Novas Mecânicas)

* **Contra-Ataque Perfurante:** Habilita o *Mikiri* (Esquiva + Frente) contra investidas.
* **Contra-Ataque em Arco:** Habilita counter (Esquiva + Cima) contra varreduras.
* **Esquiva Tática:** Habilita *Esquiva Neutra* (Esquiva + Neutro, custo em Foco).
* **Lâmina Oportuna:** Parries Perfeitos agora causam dano base de Stamina-Escudo.
* **Upgrade - Impacto Ressonante:** +50% de dano na *Lâmina Oportuna*.
* **Recuperação Aérea:** Permite Esquiva no ar após ser atingido (custo de Foco).
* **Fim de Ramo - Transcendência Momentânea:** Após um Parry Perfeito, a próxima Arte custa -30% de Foco.

### Ramo 3: Versatilidade (Slots e Artes)

* **Desbloqueia o 1º Slot de Talismã**
* **Desbloqueia o 2º Slot de Talismã**
* **Desbloqueia o 3º Slot de Talismã**
* **Fim de Ramo:** Desbloqueia o 4º Slot de Talismã
* **Aprende a Arte:** [Nome da Arte] (vários nós dedicados)

---

## 4. Aprimoramento da Katana: A Lâmina Marcada

A katana de Hana **não recebe upgrades numéricos** (+1, +2, etc.). Em vez disso, ganha uma **infusão permanente**.

> **Como Funciona:** após derrotar um Boss de *mid-game*, o jogador ganha a habilidade de *Marcar a Lâmina*.
>
> **A Escolha:** deve escolher **um Talismã** do inventário.
> **O Ritual:** o Talismã é consumido permanentemente e seu efeito infundido na katana.
> **O Resultado:** a katana passa a ter esse efeito passivo para sempre, como um 5º slot fixo de Talismã.

Essa decisão representa o **estilo principal de combate** do jogador e a maestria alcançada até aquele ponto.

---

## 5. Talismãs (Especialização de Estilo)

Modificadores passivos equipados nos Slots de Talismã. Focados em **trade-offs** (risco/recompensa) para especializar o loop de combate.

> Com a *Lâmina Marcada*, o jogador tem **4 Slots normais + 1 permanente.**

---

### Foco: Recompensa pelo Finisher

* **Talismã Sanguinário:** Executar um Finisher restaura **10% de HP**.
* **Talismã do Fôlego:** Executar um Finisher restaura **40% do Stamina-Escudo**.
* **Talismã do Foco:** Executar um Finisher restaura **30% do Foco**.
* **Talismã da Vantagem:** Executar um Finisher **atordoa inimigos próximos** por curto período.

### Foco: Risco/Recompensa no Parry

* **Talismã do Duelista:** Janela de Parry -20%, mas Parries causam +50% de dano.
* **Talismã da Lâmina Larga:** Janela de Parry +10%, mas Defesa Automática custa +20% de Stamina.
* **Talismã do Surto de Batalha:** Cada Parry aumenta dano de Stamina +10% por 3s (acumula 5x). Recebe +30% de dano de Stamina em parry falho.
* **Talismã da Pressão Incessante:** Artes de Combate causam 25% de dano mesmo se bloqueadas, mas custam +15% de Foco.

### Foco: Tensão do Foco (Artes vs. Esquiva Neutra)

* **Talismã do Estratega:** Esquiva Neutra custa -40% Foco, Artes +20%.
* **Talismã do Executor:** Artes custam -20% Foco, Esquiva Neutra +40%.
* **Talismã do Oportunista:** Após Esquiva Neutra, a próxima Arte causa +30% dano de Stamina-Escudo.

### Foco: Modificadores de Artes e Recursos

* **Talismã do Conjurador:** Artes -15% Foco, ataques básicos -10% dano.
* **Talismã da Fúria Arcana:** Artes +20% dano, Defesa Automática custa +30% de Stamina.
* **Talismã da Reserva de Batalha:** Usar Arte com Foco <25% concede +30% dano, mas Parries regeneram -10% de Foco globalmente.

### Foco: Interação entre Recursos (HP/Stamina/Foco)

* **Talismã do Berserker:** HP <33% concede +25% dano de Stamina-Escudo.
* **Talismã da Calma Interior:** Foco cheio acelera regeneração de Stamina +25%.
* **Talismã do Sacrifício de Sangue:** Permite usar Artes sem Foco, gastando HP (triplo custo).
* **Talismã da Vanguarda:** Stamina cheio reduz custo de Foco das Artes em -15%.

### Foco: Elemental, Status e Distância

* **Talismã da Peçonha Virulenta:** Veneno +50% mais rápido, dura -30%.
* **Talismã do Inverno Eterno:** Geada também reduz velocidade de movimento do alvo.
* **Talismã da Conflagração:** Queimadura dura +5s, mas Artes de Fogo custam +15% Foco.
* **Talismã da Tempestade Sifão:** Choque drena +10% de Foco para si, mas reduz dano base.
* **Talismã do Atirador Oportunista:** Artes à Distância +30% dano, mas regeneração de Stamina -20%.
* **Talismã do Espelho Afiado:** Projéteis refletidos causam dano mínimo de HP (5%).
* **Talismã da Lâmina Distante:** Artes corpo-a-corpo +20% custo, Artes à Distância -30% custo.

### Foco: Combos Elementais

* **Talismã da Combustão Corrosiva:** Fogo em inimigo envenenado causa explosão massiva de dano.
* **Talismã da Geada Estilhaçante:** Golpes físicos em alvo congelado causam dano extra e removem o efeito.
* **Talismã da Supercondução:** Raio em alvo molhado duplica drenagem de Foco.
