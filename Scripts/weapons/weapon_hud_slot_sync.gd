class_name WeaponHudSlotSync
extends RefCounted

## Espacio ocupado por un hueco HUD (offsets + escala cuando `Control.size` aún es 0 pre-layout).

static func slot_visual_size(control: Control) -> Vector2:
	if control == null:
		return Vector2.ZERO
	var w := control.size.x
	var h := control.size.y
	if w <= 0.001 or h <= 0.001:
		w = absf(control.offset_right - control.offset_left)
		h = absf(control.offset_bottom - control.offset_top)
	return Vector2(absf(w * control.scale.x), absf(h * control.scale.y))
