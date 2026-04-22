extends RefCounted
class_name HitFlashState

## Acumulador del parpadeo (mismo patrón que `player_movement._sync_invuln_flicker`).
var flicker_time: float = 0.0
## Si el `HealthComponent` no tiene i-frames, el daño sigue disparando un flash breve.
var manual_flash_remaining: float = 0.0


func on_damage_taken(health: HealthComponent) -> void:
	flicker_time = 0.0
	var min_len := 0.12
	if health:
		min_len = maxf(health.hit_invulnerability_duration, 0.12)
	manual_flash_remaining = maxf(manual_flash_remaining, min_len)


func process_frame(
	delta: float,
	health: HealthComponent,
	item: CanvasItem,
	base_modulate: Color,
	hit_flash_tint: Color,
	half_period: float
) -> void:
	if item == null:
		return
	manual_flash_remaining = maxf(manual_flash_remaining - delta, 0.0)
	var invuln := health != null and health.is_invulnerable()
	var flicker := invuln or manual_flash_remaining > 0.0
	if not flicker:
		item.modulate = base_modulate
		flicker_time = 0.0
		return
	flicker_time += delta
	var half_p := maxf(half_period, 0.016)
	var phase := int(floor(flicker_time / half_p)) % 2
	item.modulate = hit_flash_tint if phase == 0 else base_modulate
