shader_type canvas_item;
render_mode unshaded;

/// Relleno radial real: sector circular en espacio corregido por aspect ratio del rectángulo.
uniform float progress : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform vec2 center_uv = vec2(0.5, 0.5);
/// Ángulo de inicio (grados): convención igual que TextureProgressBar Godot — horario desde el eje +X.
uniform float start_angle_deg = 205.0;
/// Arco total recorrido al 100% (grados), en sentido horario.
uniform float sweep_deg = 155.0;
/// `size.x / size.y` del TextureRect para que el ángulo sea circular en píxeles.
uniform float aspect_ratio = 1.0;
/// Suavizado del borde del sector (grados).
uniform float edge_soft_deg : hint_range(0.0, 6.0) = 1.25;
/// +1.0 = mismo sentido que TextureProgressBar (clockwise); -1.0 invierte el barrido.
uniform float angle_direction : hint_range(-1.0, 1.0) = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (progress <= 0.001) {
		COLOR = vec4(tex_color.rgb, 0.0);
		return;
	}

	vec2 d = UV - center_uv;
	d.x *= aspect_ratio;
	float af = atan(d.y, d.x);

	float start = radians(start_angle_deg);
	float max_angle = radians(sweep_deg * progress);

	// Distancia angular según `angle_direction` (por defecto: horario desde `start`).
	float delta_a = angle_direction * (start - af);
	float cw = mod(delta_a + 6.28318530718, 6.28318530718);

	float edge = radians(edge_soft_deg);
	float in_wedge = 1.0 - smoothstep(max_angle - edge * 0.5, max_angle + edge, cw);

	COLOR = tex_color;
	COLOR.a *= in_wedge;
}
