shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	vec4 final_color = mix(original_color, flash_color, flash_modifier);
	COLOR = final_color;
}
