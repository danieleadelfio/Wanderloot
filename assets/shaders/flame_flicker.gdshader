shader_type canvas_item;
render_mode unshaded;
// Movimento della fiamma di torce e candele (M12, #86): distorsione UV orizzontale a due frequenze,
// piu' forte verso la punta (UV.y=0) e quasi nulla alla base. Indipendente dal tremolio della luce
// gia' esistente (LightFlicker, energia del PointLight2D): qui si muove lo sprite stesso.

uniform float distort_amount : hint_range(0.0, 0.05) = 0.018;
uniform float speed : hint_range(0.0, 10.0) = 6.0;

void fragment() {
	vec2 uv = UV;
	float tip_weight = 1.0 - uv.y;
	float offset = (sin(uv.y * 14.0 + TIME * speed) * 0.6 + sin(uv.y * 7.0 - TIME * speed * 1.7 + 1.3) * 0.4);
	uv.x += offset * distort_amount * tip_weight;
	COLOR = texture(TEXTURE, uv);
}
