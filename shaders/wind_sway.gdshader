shader_type canvas_item;

// Globais (Controladas pelo Project Settings ou Script Global)
global uniform float global_wind_speed; 
global uniform float global_wind_strength;

// Locais (Ajustes finos por objeto no Inspector)
uniform float minStrength : hint_range(0.0, 1.0) = 0.05; 
uniform float maxStrength : hint_range(0.0, 1.0) = 0.1; 
uniform float strengthScale = 100.0; 
uniform float interval = 3.5; 
uniform float detail = 1.0; 
uniform float distortion : hint_range(0.0, 1.0) = 0.0; 
uniform float heightOffset : hint_range(0.0, 1.0) = 0.0; 

float get_wind(vec2 vertex, vec2 uv, float time){
    float diff = pow(maxStrength - minStrength, 2.0);
    float strength = clamp(minStrength + diff + sin(time / interval) * diff, minStrength, maxStrength) * strengthScale;
    
    // O cálculo base do vento
    float wind = (sin(time) + cos(time * detail)) * strength * max(0.0, (1.0-uv.y) - heightOffset);
    
    return wind; 
}

void vertex() {
    // 1. Usamos a VELOCIDADE global para acelerar o tempo
    float time = TIME * global_wind_speed + VERTEX.x + VERTEX.y; 
    
    // 2. Calculamos o vento local
    float wind_amount = get_wind(VERTEX.xy, UV, time);
    
    // 3. AQUI entra a FORÇA global. Multiplicamos o resultado final.
    // Se global_wind_strength for 0, o resultado é 0 (sem vento).
    VERTEX.x += wind_amount * global_wind_strength;
}