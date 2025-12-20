shader_type canvas_item;

// --- Grupo do Flash (Dano - Controlado pelo AnimationComponent) ---
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

// --- Grupo do Tint (Identidade do Inimigo - Controlado pelo Enemy Script) ---
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float tint_intensity : hint_range(0.0, 1.0) = 0.0; 

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    
    // 1. LÓGICA DO TINT (Identificação visual)
    // Calculamos a luminância para preservar sombras e detalhes
    float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 colored_version = tint_color.rgb * luminance * 2.0; 
    
    // Mistura a cor original com a cor de identidade
    vec3 base_rgb = mix(original_color.rgb, colored_version, tint_intensity);
    
    // 2. LÓGICA DO FLASH (Dano - aplica branco por cima de tudo)
    vec3 final_rgb = mix(base_rgb, flash_color.rgb, flash_modifier);
    
    COLOR = vec4(final_rgb, original_color.a);
}