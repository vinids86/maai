class_name AttackState
extends State

# --- REFERÊNCIAS ---
var hitbox: Area2D
var hitbox_shape: CollisionShape2D

var current_profile: AttackProfile

enum Phases { STARTUP, ACTIVE, RECOVERY }
var current_phase: Phases
var time_left_in_phase: float = 0.0

# A função _ready() foi REMOVIDA para evitar a "race condition".

func enter(args: Dictionary = {}):
	# --- INICIALIZAÇÃO SEGURA DAS REFERÊNCIAS (LAZY LOADING) ---
	# Fazemos isto apenas na primeira vez que entramos no estado.
	if not hitbox:
		hitbox = owner_node.find_child("AttackHitbox")
		if hitbox:
			hitbox_shape = hitbox.find_child("CollisionShape2D")
		
		assert(hitbox != null, "AttackState: Nó 'AttackHitbox' não encontrado como filho do ator.")
		assert(hitbox_shape != null, "AttackState: Nó 'CollisionShape2D' não encontrado como filho da AttackHitbox.")

	# --- LÓGICA NORMAL DE ENTRADA ---
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("AttackState: Não recebeu um AttackProfile para executar. A abortar.")
		state_machine.on_current_state_finished()
		return
	
	owner_node.facing_locked = true
	owner_node.velocity = Vector2.ZERO
	_change_phase(Phases.STARTUP)


func exit():
	# Garantimos que a hitbox é desativada se o estado for interrompido.
	if hitbox_shape:
		hitbox_shape.disabled = true
	owner_node.facing_locked = false


func process_physics(delta: float, is_running: bool = false):
	time_left_in_phase -= delta
	
	if time_left_in_phase <= 0:
		var time_exceeded = -time_left_in_phase
		
		match current_phase:
			Phases.STARTUP:
				_change_phase(Phases.ACTIVE)
				time_left_in_phase -= time_exceeded
			Phases.ACTIVE:
				_change_phase(Phases.RECOVERY)
				time_left_in_phase -= time_exceeded
			Phases.RECOVERY:
				state_machine.on_current_state_finished()
				return

func allow_dodge() -> bool:
	return false

func allow_attack() -> bool:
	return current_phase == Phases.RECOVERY

func _change_phase(new_phase: Phases):
	current_phase = new_phase
	
	var sfx_to_play: AudioStream
	match current_phase:
		Phases.STARTUP:
			time_left_in_phase = current_profile.startup_duration
			sfx_to_play = current_profile.startup_sfx
		Phases.ACTIVE:
			time_left_in_phase = current_profile.active_duration
			sfx_to_play = current_profile.active_sfx
			# Ativamos e configuramos a hitbox
			_update_and_enable_hitbox()
		Phases.RECOVERY:
			time_left_in_phase = current_profile.recovery_duration
			sfx_to_play = current_profile.recovery_sfx
			# Desativamos a hitbox
			hitbox_shape.disabled = true
			# E removemos a sua forma para uma depuração visual mais limpa.
			hitbox_shape.shape = null
			
	var phase_data = {
		"state_name": self.name,
		"phase_name": Phases.keys()[current_phase],
		"profile": current_profile,
		"sfx_to_play": sfx_to_play
	}
	
	if current_phase == Phases.STARTUP:
		phase_data["animation_to_play"] = current_profile.animation_name
	
	state_machine.emit_phase_change(phase_data)


func _update_and_enable_hitbox():
	# Criamos uma nova forma retangular para a hitbox.
	var shape = RectangleShape2D.new()
	shape.size = current_profile.hitbox_size
	
	# Atribuímos a nova forma e definimos a sua posição.
	hitbox_shape.shape = shape
	hitbox.position = current_profile.hitbox_position
	
	# A posição deve respeitar a direção para a qual o personagem está virado.
	hitbox.position.x *= owner_node.facing_sign
	
	# Ativamos a hitbox para que ela possa detetar colisões.
	hitbox_shape.disabled = false
