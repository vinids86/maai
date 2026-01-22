shader_type canvas_item;

// --- FUNCIONALIDADES ORIGINAIS (Hit Flash & Tint) ---
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float tint_intensity : hint_range(0.0, 1.0) = 0.0;

// --- VISIBILIDADE (ZOOM OUT) ---
group_uniforms Zoom_Visibility;

// MARQUE ISTO NO EDITOR PARA VER O EFEITO SEM DAR PLAY
uniform bool debug_force_effect = false; 

// Zoom atual (atualizado pelo script). Valores menores (0.5) = Câmera longe.
uniform float current_zoom = 1.0; 

// Começa a aplicar o efeito quando o zoom for menor que isso (Ex: 0.8)
uniform float zoom_threshold : hint_range(0.1, 2.0) = 0.9;

// Configurações do Visual Pop (Valores mais agressivos por padrão)
uniform float pop_saturation : hint_range(1.0, 5.0) = 2.0; // Cores muito mais vivas
uniform float pop_contrast : hint_range(1.0, 3.0) = 1.2;   // Mais contraste
uniform float pop_brightness : hint_range(0.0, 1.0) = 0.1; // Leve brilho extra

// Função simples para ajuste de saturação
vec3 apply_saturation(vec3 rgb, float adjustment) {
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

void fragment() {
    // 1. Cor base da textura
    vec4 tex = texture(TEXTURE, UV);
    
    // 2. Multiplica pela cor do vértice (CRÍTICO PARA SPINE funcionar corretamente)
    tex *= COLOR;
    
    if (tex.a > 0.0) {
        // Lógica de Intensidade
        float intensity = 0.0;
        
        if (debug_force_effect) {
            intensity = 1.0; // Força total no editor se debug estiver ativado
        } else {
            // Calcula suavemente: 0.0 se perto, 1.0 se longe
            intensity = 1.0 - smoothstep(zoom_threshold - 0.4, zoom_threshold, current_zoom);
        }
        
        // Aplica o "Pop" visual se houver intensidade
        if (intensity > 0.0) {
            vec3 rgb = tex.rgb;
            
            // Saturação
            float sat = mix(1.0, pop_saturation, intensity);
            rgb = apply_saturation(rgb, sat);
            
            // Contraste
            float cont = mix(1.0, pop_contrast, intensity);
            rgb = (rgb - 0.5) * cont + 0.5;
            
            // Brilho
            float bright = mix(0.0, pop_brightness, intensity);
            rgb += bright;
            
            // Reaplica na textura, mantendo alpha original
            tex.rgb = rgb;
        }
        
        // 3. Efeitos de Status (Tint)
        tex.rgb = mix(tex.rgb, tint_color.rgb, tint_intensity);
        
        // 4. Hit Flash (Branco puro)
        tex.rgb = mix(tex.rgb, flash_color.rgb, flash_modifier);
    }
    
    COLOR = tex;
}