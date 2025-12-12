extends GPUParticles2D

# --- CONTROLLER DE IMPACTO VISUAL ---
# Adiciona:
# 1. Partículas de Metal Derretido (Explosão direcional ou radial)
# 2. Flash Central (Bola de energia)
# 3. Flare Horizontal (REMOVIDO: Não agradou visualmente)

# O sinal 'finished' é nativo do GPUParticles2D, não precisamos redeclarar.

var flash: Sprite2D
# var flare: Sprite2D # Flare desativado

func _ready() -> void:
	# --- 1. CONFIGURAR PARTÍCULAS (Base) ---
	emitting = false
	one_shot = true
	explosiveness = 1.0 # Explosão total no frame 0
	fixed_fps = 60
	lifetime = 0.45 # Ajustado para dar tempo do arco se formar
	
	# Material ADD (Brilho intenso)
	var add_mat = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	self.material = add_mat
	
	# Textura: Agulha grossa
	var tex = GradientTexture2D.new()
	tex.width = 4
	tex.height = 12
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 1)
	var tex_grad = Gradient.new()
	tex_grad.set_color(0, Color(1, 1, 1, 1))
	tex_grad.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = tex_grad
	self.texture = tex
	
	# Física Inicial (Será sobrescrita no configure_type)
	var process_mat = ParticleProcessMaterial.new()
	process_mat.particle_flag_align_y = true
	process_mat.particle_flag_disable_z = true
	process_mat.direction = Vector3(0, -1, 0)
	
	# --- FORMA DA EXPLOSÃO ---
	# Para garantir simetria de nascimento (cima/baixo iguais), usamos Spread 180 (Círculo completo).
	# A forma "esticada" e "menor nos lados" será feita usando a escala do nó (scale) no configure_type.
	process_mat.spread = 180.0 
	process_mat.flatness = 0.0
	process_mat.gravity = Vector3(0, 600, 0) # Gravidade pesada (mantida conforme pedido)
	
	self.process_material = process_mat
	
	# --- 2. CONFIGURAR FLASH (Bola de Luz) ---
	flash = Sprite2D.new()
	var flash_tex = GradientTexture2D.new()
	flash_tex.width = 128 
	flash_tex.height = 128
	flash_tex.fill = GradientTexture2D.FILL_RADIAL
	flash_tex.fill_from = Vector2(0.5, 0.5)
	flash_tex.fill_to = Vector2(0.5, 0.0)
	var flash_grad_res = Gradient.new()
	flash_grad_res.set_color(0, Color(1, 1, 1, 1))
	flash_grad_res.set_color(0.3, Color(1, 1, 1, 0.9)) # Centro denso
	flash_grad_res.set_color(1, Color(1, 1, 1, 0))
	flash_tex.gradient = flash_grad_res
	flash.texture = flash_tex
	flash.material = add_mat
	flash.visible = false
	add_child(flash)
	
	# Configuração padrão
	configure_type(true)
	
	# Disparar animação visual imediatamente
	_animate_flash()

# Chamado pelo VFXComponent ou manualmente
func configure_type(is_parry: bool) -> void:
	var process_mat = self.process_material as ParticleProcessMaterial
	if not process_mat: return
	
	var grad = Gradient.new()
	
	if is_parry:
		# --- PARRY (CLASH) ---
		# Gradiente HDR
		grad.add_point(0.0, Color(100, 5, 2, 1)) 
		grad.add_point(0.1, Color(20, 2, 0.5, 1)) 
		grad.add_point(0.4, Color(3, 0.1, 0.0, 1)) 
		grad.add_point(1.0, Color(0, 0, 0, 0))
		
		amount = 120 
		
		# --- FORMA ELÍPTICA (Oval Vertical) ---
		# TRUQUE: Deformamos a escala do nó inteiro. 
		# X=0.6: Lados ficam "espremidos" (menor alcance).
		# Y=1.2: Vertical fica "esticada" (maior alcance).
		scale = Vector2(0.6, 1.2)
		
		# Velocidade e Damping
		process_mat.initial_velocity_min = 200.0 
		process_mat.initial_velocity_max = 600.0
		process_mat.damping_min = 400.0 
		process_mat.damping_max = 800.0
		process_mat.scale_min = 0.5
		process_mat.scale_max = 2.5 
		
		if flash: flash.modulate = Color(8, 2.0, 0.5, 1) 
		
	else:
		# --- BLOCK ---
		grad.add_point(0.0, Color(15, 1, 0.1, 1))
		grad.add_point(0.3, Color(2, 0.1, 0.0, 1))
		grad.add_point(1.0, Color(0, 0, 0, 0))
		
		amount = 30
		scale = Vector2(0.7, 1.0) # Levemente estreito
		
		process_mat.initial_velocity_min = 100.0
		process_mat.initial_velocity_max = 350.0
		process_mat.damping_min = 200.0
		process_mat.damping_max = 400.0
		process_mat.scale_min = 0.5
		process_mat.scale_max = 1.0
		
		if flash: flash.modulate = Color(2, 0.2, 0.0, 0.5) 

	var ramp = GradientTexture1D.new()
	ramp.gradient = grad
	process_mat.color_ramp = ramp
	
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	var curve_tex = CurveTexture.new()
	curve_tex.curve = curve
	process_mat.scale_curve = curve_tex

func _animate_flash() -> void:
	if flash:
		flash.visible = true
		flash.scale = Vector2(0.2, 0.2)
		var tween = create_tween()
		tween.set_parallel(true)
		# O flash herda a escala do pai (que já é oval), então scale uniforme aqui mantém a proporção oval
		tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.05).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(flash, "modulate:a", 0.0, 0.12) 
		tween.chain().tween_callback(func(): flash.visible = false)
