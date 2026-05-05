@tool
extends Control
## Gizmo copia centro → `ShieldArcProgress.radial_center_offset`.  
## Por defecto NO se pisán los ángulos del `TextureProgressBar` (así editor y partida igualan tu .tscn).

@export var hide_center_gizmo_in_game: bool = true

## Desactivado: radiales lee lo que configures en hijo ShieldArcProgress.  
## Activado: este nodo fuerza radial_initial/fill usando los valores de abajo.
@export var override_radial_params_from_parent: bool = false:
	set(v):
		override_radial_params_from_parent = v
		_apply_optional_radial_overrides_if_ready()
@export var editor_full_texture_preview: bool = false:
	set(v):
		editor_full_texture_preview = v
		if is_inside_tree():
			_sync_editor_shield_display()

## Simula cuánto escudo hay en el editor (solo `Engine.editor_hint`; en juego usa HealthHUD).
@export_range(0.0, 100.0, 0.5) var editor_radial_preview_percent: float = 100.0:
	set(v):
		editor_radial_preview_percent = v
		if is_inside_tree() and Engine.is_editor_hint():
			_apply_editor_radial_preview_value()

@export var show_radial_guides_in_editor: bool = true
@export var editor_draw_progress_image_rect: bool = false:
	set(v):
		editor_draw_progress_image_rect = v
		_redraw_guides()
@export var editor_draw_sector_wedge_outer: bool = true:
	set(v):
		editor_draw_sector_wedge_outer = v
		_redraw_guides()
@export var editor_draw_sector_end_labels: bool = true:
	set(v):
		editor_draw_sector_end_labels = v
		_redraw_guides()
@export_range(48.0, 360.0, 1.0) var guides_sector_outer_radius: float = 155.0
@export_range(16.0, 240.0, 1.0) var guides_ray_length: float = 96.0

## Solo aplican cuando Override Radial Params From Parent está activo.
@export_range(-180.0, 180.0, 0.5) var radial_angle_correction_deg: float = 0.0:
	set(v):
		radial_angle_correction_deg = v
		_apply_optional_radial_overrides_if_ready()
		_redraw_guides()
@export var radial_initial_angle: float = 240.0:
	set(v):
		radial_initial_angle = v
		_apply_optional_radial_overrides_if_ready()
		_redraw_guides()
@export var radial_fill_degrees: float = 155.0:
	set(v):
		radial_fill_degrees = v
		_apply_optional_radial_overrides_if_ready()
		_redraw_guides()

@onready var _bar: TextureProgressBar = $ShieldArcProgress
@onready var _full_preview: TextureRect = $ShieldArcFullPreview


func _ready() -> void:
	_apply_optional_radial_overrides()
	_sync_radial_center_from_gizmo()
	_sync_gizmo_visibility()
	call_deferred(&"_sync_radial_center_from_gizmo")
	if Engine.is_editor_hint():
		_sync_editor_shield_display()
	else:
		if _full_preview:
			_full_preview.visible = false
		if _bar:
			_bar.visible = true
	_redraw_guides()


func _redraw_guides() -> void:
	if Engine.is_editor_hint() and show_radial_guides_in_editor:
		queue_redraw()


func _process(_delta: float) -> void:
	_sync_radial_center_from_gizmo()
	if Engine.is_editor_hint():
		if editor_full_texture_preview:
			_sync_preview_transform_from_bar()
		else:
			_apply_editor_radial_preview_value()
		if show_radial_guides_in_editor:
			queue_redraw()


func _apply_optional_radial_overrides_if_ready() -> void:
	if not is_node_ready():
		return
	_apply_optional_radial_overrides()


func _apply_optional_radial_overrides() -> void:
	if _bar == null:
		return
	if override_radial_params_from_parent:
		_bar.radial_initial_angle = radial_initial_angle + radial_angle_correction_deg
		_bar.radial_fill_degrees = radial_fill_degrees


func _guide_start_deg() -> float:
	if _bar == null:
		return 0.0
	if override_radial_params_from_parent:
		return radial_initial_angle + radial_angle_correction_deg
	return _bar.radial_initial_angle


func _guide_sweep_deg() -> float:
	if _bar == null:
		return 155.0
	if override_radial_params_from_parent:
		return radial_fill_degrees
	return _bar.radial_fill_degrees


func _sync_radial_center_from_gizmo() -> void:
	var gizmo := get_node_or_null("RadialFillCenterGizmo") as Control
	if _bar == null or gizmo == null:
		return
	var gc: Vector2 = gizmo.position + gizmo.size * 0.5
	var bc: Vector2 = _bar.position + _bar.size * 0.5
	_bar.radial_center_offset = gc - bc


func _sync_editor_shield_display() -> void:
	if _full_preview == null or _bar == null:
		return
	if not Engine.is_editor_hint():
		return
	_full_preview.texture = _bar.texture_progress
	if editor_full_texture_preview:
		_full_preview.visible = true
		_bar.visible = false
		_sync_preview_transform_from_bar()
	else:
		_full_preview.visible = false
		_bar.visible = true
		_apply_editor_radial_preview_value()


func _apply_editor_radial_preview_value() -> void:
	if not Engine.is_editor_hint() or _bar == null or editor_full_texture_preview:
		return
	var v: float = clampf(editor_radial_preview_percent / 100.0, 0.0, 1.0) * _bar.max_value
	_bar.value = v


func _sync_preview_transform_from_bar() -> void:
	if not Engine.is_editor_hint() or not editor_full_texture_preview:
		return
	if _full_preview == null or _bar == null:
		return
	_full_preview.position = _bar.position
	_full_preview.size = _bar.size
	_full_preview.scale = _bar.scale
	_full_preview.rotation = _bar.rotation
	if show_radial_guides_in_editor:
		queue_redraw()


func set_shield_fill(ratio: float) -> void:
	if _bar == null:
		return
	var r: float = clampf(ratio, 0.0, 1.0)
	_bar.value = r * _bar.max_value


func _draw() -> void:
	if not show_radial_guides_in_editor or not Engine.is_editor_hint():
		return
	var gizmo := get_node_or_null("RadialFillCenterGizmo") as Control
	if _bar == null or gizmo == null:
		return

	if editor_draw_progress_image_rect:
		_draw_editor_progress_quad()

	var c: Vector2 = gizmo.position + gizmo.size * 0.5
	var eff0 := _guide_start_deg()
	var eff1: float = eff0 + _guide_sweep_deg()
	var rad0 := deg_to_rad(eff0)
	var rad1 := deg_to_rad(eff1)

	var rlen: float = guides_ray_length
	var rout: float = maxf(guides_sector_outer_radius, rlen + 14.0)
	var d0: Vector2 = Vector2.from_angle(rad0)
	var d1: Vector2 = Vector2.from_angle(rad1)

	if editor_draw_sector_wedge_outer:
		var wedge := _build_sector_polygon(c, rad0, rad1, rout, 56)
		if wedge.size() >= 3:
			draw_colored_polygon(wedge, Color(0.25, 0.95, 0.85, 0.09))

	draw_line(c, c + d0 * rlen, Color(0.15, 1.0, 0.5, 0.95), 3.25)
	draw_line(c, c + d1 * rlen, Color(1.0, 0.5, 0.12, 0.95), 3.25)

	var arc_r: float = minf(maxf(guides_ray_length * 0.55, rout * 0.38), guides_sector_outer_radius * 0.72)
	var a0 := rad0
	var a_hi := rad1 if rad1 >= rad0 else rad1 + TAU
	draw_arc(c, arc_r, a0, a_hi, 48, Color(0.92, 0.92, 0.3, 0.55), 2.75, true)
	draw_circle(c, 6.0, Color(0.92, 0.95, 1.0, 0.95))

	if editor_draw_sector_end_labels:
		var font: Font = ThemeDB.fallback_font
		var fs := 13
		var col := Color(0.92, 0.98, 1.0, 1.0)
		draw_string(font, c + d0 * (rlen + 8.0) + Vector2(-36, -10), "[ini 0%%]", HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)
		draw_string(font, c + d1 * (rlen + 8.0) + Vector2(-48, -10), "[fin 100%%]", HORIZONTAL_ALIGNMENT_CENTER, -1, fs, col)


func _draw_editor_progress_quad() -> void:
	if _bar == null:
		return
	var xf: Transform2D = _bar.get_transform()
	var s: Vector2 = _bar.size
	var corners := PackedVector2Array([
		xf * Vector2.ZERO,
		xf * Vector2(s.x, 0.0),
		xf * s,
		xf * Vector2(0.0, s.y),
	])
	corners.append(corners[0])
	draw_polyline(corners, Color(0.95, 0.35, 1.0, 0.9), 2.25, true)


func _build_sector_polygon(origin: Vector2, rad_from: float, radial_to: float, radius: float, segments: int) -> PackedVector2Array:
	var out := PackedVector2Array([origin])
	var rf := rad_from
	var rt := radial_to
	if rt < rf:
		rt += TAU
	var steps := clampi(segments, 8, 256)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		out.append(origin + Vector2.from_angle(lerpf(rf, rt, t)) * radius)
	return out


func _sync_gizmo_visibility() -> void:
	var gizmo := get_node_or_null("RadialFillCenterGizmo") as Control
	if gizmo == null:
		return
	if Engine.is_editor_hint():
		gizmo.visible = true
	else:
		gizmo.visible = not hide_center_gizmo_in_game


func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	if not has_node("ShieldArcProgress"):
		w.append("Falta el hijo 'ShieldArcProgress' (TextureProgressBar radial).")
	elif not get_node("ShieldArcProgress") is TextureProgressBar:
		w.append("ShieldArcProgress debe ser TextureProgressBar (Fill radial).")
	if not has_node("RadialFillCenterGizmo"):
		w.append("Falta RadialFillCenterGizmo para alinear el centro del arco en el editor.")
	return w
