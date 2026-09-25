shader_type canvas_item;
// Ondeggio degli alberi nella piazza (M12, #86): ancorato alla base (UV.y=1), oscilla di piu' verso
// la cima (UV.y=0). Fase diversa per albero data dalla posizione nel mondo, cosi' non ondeggiano
// tutti insieme; niente uniform per-istanza necessario.

uniform float sway_amount : hint_range(0.0, 20.0) = 5.0;
uniform float sway_speed : hint_range(0.0, 5.0) = 1.0;

void vertex() {
	float top_weight = 1.0 - UV.y;
	float phase = dot(MODEL_MATRIX[3].xy, vec2(0.017, 0.011));
	VERTEX.x += sin(TIME * sway_speed + phase) * sway_amount * top_weight * top_weight;
}
