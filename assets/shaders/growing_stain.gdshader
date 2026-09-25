shader_type canvas_item;
// Pozzanghera/pozza che cresce nel tempo con bordo che incresp (M12, #86): gocce dal soffitto (Cripta,
// GPUParticles2D separate) o di sangue (Ossario) formano una macchia circolare sul pavimento. Shader
// puro, nessuna texture: colore per istanza (acqua o sangue). "progress" (0..1) e' animato da
// growing_stain.gd invece di leggere TIME direttamente: TIME nello shader parte dall'avvio del motore,
// non da quando l'istanza compare, quindi a ogni nuova run la macchia apparirebbe gia' piena.

uniform vec4 stain_color : source_color = vec4(0.3, 0.42, 0.5, 0.55);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_radius : hint_range(0.0, 0.5) = 0.42;
uniform float ripple_amount : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	float radius = progress * max_radius;
	float ripple = sin(dist * 40.0 - TIME * 2.0) * ripple_amount * progress;
	float edge = smoothstep(radius + 0.035 + ripple, radius - 0.05 + ripple, dist);
	COLOR = vec4(stain_color.rgb, stain_color.a * edge);
}
