extends CanvasLayer

## -----------------------------------------------------------------------------
## Weapon HUD — qué editás vos y qué hace el juego
##
## Instancia única: nodo `WeaponHud` en `Ecenes/Player.tscn`.
##
## 1) **Posición / escala / rotación de cada asset (por arma)**  
##    Editás solo en `Ecenes/Player/Weapons/WeaponHudSlotAuthoring.tscn`:  
##    `Margin/Main/WeaponsRow` → columna `A_Wrench` / `B_Revolver` / … →  
##    `SlotHost/HudWeaponSlot1/WeaponIcon`.  
##    El marco cyan usa solo la **escala de referencia** del slot grande; ahí colocás cada asset como prefieras.
##
## 2) **Marcos en pantalla (grande + tres chicos)**  
##    Editás en el Inspector del nodo `WeaponHud`: grupo **«Marcos de arma»** (`offset_left/top/right/bottom`, `scale`, `pivot` por slot).  
##    El **pop** al cambiar de arma está en **«Slot 1 — feedback al cambiar arma»** y anima la escala de `HudWeaponSlot1`.
##
## 3) **En partida**  
##    • **Poses** (offset/escala/rotación por arma): se leen de `WeaponHudSlotAuthoring.tscn` (`WeaponsRow`
##    → `A_Wrench` … `D_MachineGun` → `SlotHost/HudWeaponSlot1/WeaponIcon`).  
##    • **Tamaño de referencia** (`ref_px` para escalar esas poses al rect de cada slot): **no** es un valor
##    arbitrario: se obtiene del **`HudWeaponSlot1` de `WeaponHud.tscn`** (mismo hueco grande del HUD; ruta
##    por defecto `res://Ecenes/Player/Weapons/WeaponHud.tscn`, export `weapon_hud_reference_scene`).
##    Mientras corrés la partida, ese valor se **vuelve a medir** del slot 1 en vivo (`_refresh_live_authoring_ref_px`).  
##    Si no hay tabla de autoría, se usa fallback: poses copiadas de los `WeaponIcon` embebidos en esta escena.
## -----------------------------------------------------------------------------
##
## HUD munición: balas en cargador | capacidad cargador | reserva (bolsa).

@export_group("Marcos de arma (HudWeaponSlot 1–4)")
## Si está activo, al iniciar se aplican los valores de abajo a los nodos `%HudWeaponSlot*`. Desactivá para que mande solo la escena `.tscn`.
@export var apply_weapon_slot_controls_from_exports: bool = true
@export_subgroup("Slot 1 — principal (objetivo del pop)")
## Vector4(offset_left, offset_top, offset_right, offset_bottom)
@export var slot_1_offsets: Vector4 = Vector4(-154.0, -33.0, -98.0, 23.0)
@export var slot_1_scale: Vector2 = Vector2(2.1030867, 2.1030867)
@export var slot_1_pivot_offset: Vector2 = Vector2(28.0, 28.0)
@export_subgroup("Slot 1 — feedback al cambiar arma (pop)")
@export var switch_pop_shrink: float = 0.9
@export var switch_pop_overshoot: float = 1.08
@export var switch_pop_out_time: float = 0.06
@export var switch_pop_in_time: float = 0.09
@export var switch_pop_settle_time: float = 0.06
@export_subgroup("Slot 2")
@export var slot_2_offsets: Vector4 = Vector4(-19.0, 45.0, 37.0, 101.0)
@export var slot_2_scale: Vector2 = Vector2(1.134495, 1.134495)
@export var slot_2_pivot_offset: Vector2 = Vector2(28.0, 28.0)
@export_subgroup("Slot 3")
@export var slot_3_offsets: Vector4 = Vector4(39.0, 45.0, 95.0, 101.0)
@export var slot_3_scale: Vector2 = Vector2(1.134495, 1.134495)
@export var slot_3_pivot_offset: Vector2 = Vector2(28.0, 28.0)
@export_subgroup("Slot 4")
@export var slot_4_offsets: Vector4 = Vector4(109.0, 45.0, 165.0, 101.0)
@export var slot_4_scale: Vector2 = Vector2(1.134495, 1.134495)
@export var slot_4_pivot_offset: Vector2 = Vector2(28.0, 28.0)

@export_group("Iconos slots 2–4 (tras pose de autoría)")
## Multiplica la escala del `WeaponIcon` solo en slots 2–4. (1,1) = sin ajuste extra.
@export var secondary_slots_icon_scale_multiplier: Vector2 = Vector2(1.0, 1.0)

@export_group("Icon poses (authoring)")
## Tabla de poses por arma: `WeaponHudSlotAuthoring.tscn` (columnas + `WeaponIcon`). Si vacío se carga por ruta.
@export var weapon_pose_authoring_scene: PackedScene
## Solo para medir **ref_px**: escena con `Root/WeaponSlotsRoot/HudWeaponSlot1` (el slot grande). Por defecto `WeaponHud.tscn`.
@export var weapon_hud_reference_scene: PackedScene

@export_group("Weapon icons")
@export var texture_wrench: Texture2D
@export var texture_revolver: Texture2D
@export var texture_shotgun: Texture2D
@export var texture_machine_gun: Texture2D

@onready var _weapon_name: Label = $Root/WeaponNameLabel
## Orden HUD: índice 0 = arma **actual** (slot visual 1); siguientes = rotación cíclica 2→4.
@onready var _slot_icons: Array[TextureRect] = [
	%HudWeaponSlot1/WeaponIcon,
	%HudWeaponSlot2/WeaponIcon,
	%HudWeaponSlot3/WeaponIcon,
	%HudWeaponSlot4/WeaponIcon,
]
@onready var _ammo_current: Label = $Root/AmmoCurrentInWeaponLabel
@onready var _ammo_magazine_capacity: Label = $Root/AmmoMagazineCapacityLabel
@onready var _ammo_reserve: Label = $Root/AmmoReserveLabel
@onready var _reload_label: Label = $Root/VBox/ReloadLabel
@onready var _pickup_feed: Label = $Root/VBox/PickupFeedLabel

var _pickup_tween: Tween
var _ammo_flash_tween: Tween
var _weapon_switch_tween: Tween
var _weapon_manager: WeaponManager
var _slot_base_scales: Array[Vector2] = []
## Tabla leída de `WeaponHudSlotAuthoring.tscn` (vacía si se usa fallback).
var _poses_authoring: Dictionary = {}
var _authoring_ref_px: float = 0.0
## Fallback: `weapon_name` → datos de los iconos por defecto en `WeaponHud.tscn`.
var _canonical_weapon_poses: Dictionary = {}
var _last_weapon_name := ""
var _slot_row_layout_attempts: int = 0


func _ammo_labels() -> Array[Label]:
	var out: Array[Label] = []
	if _ammo_current != null:
		out.append(_ammo_current)
	if _ammo_magazine_capacity != null:
		out.append(_ammo_magazine_capacity)
	if _ammo_reserve != null:
		out.append(_ammo_reserve)
	return out


func setup(manager: Node) -> void:
	if manager == null:
		return
	_weapon_manager = manager as WeaponManager
	if not manager.weapon_changed.is_connected(_on_weapon_changed):
		manager.weapon_changed.connect(_on_weapon_changed)
	call_deferred("_refresh_from_manager")


func _ready() -> void:
	_apply_weapon_slots_layout_from_exports()
	_load_weapon_icon_poses()
	_capture_slot_base_scales()
	for lbl: Label in _ammo_labels():
		lbl.text = "—"
	if _reload_label:
		_reload_label.visible = false
	if _pickup_feed:
		_pickup_feed.visible = false


func _capture_slot_base_scales() -> void:
	_slot_base_scales.clear()
	for tr: TextureRect in _slot_icons:
		var slot: Control = null
		if tr != null:
			slot = tr.get_parent() as Control
		_slot_base_scales.append(slot.scale if slot != null else Vector2.ONE)


func _apply_weapon_slots_layout_from_exports() -> void:
	if not apply_weapon_slot_controls_from_exports:
		return
	var rows: Array = [
		[%HudWeaponSlot1, slot_1_offsets, slot_1_scale, slot_1_pivot_offset],
		[%HudWeaponSlot2, slot_2_offsets, slot_2_scale, slot_2_pivot_offset],
		[%HudWeaponSlot3, slot_3_offsets, slot_3_scale, slot_3_pivot_offset],
		[%HudWeaponSlot4, slot_4_offsets, slot_4_scale, slot_4_pivot_offset],
	]
	for row in rows:
		var ctl: Control = row[0] as Control
		if ctl == null:
			continue
		var o: Vector4 = row[1] as Vector4
		ctl.offset_left = o.x
		ctl.offset_top = o.y
		ctl.offset_right = o.z
		ctl.offset_bottom = o.w
		ctl.scale = row[2] as Vector2
		ctl.pivot_offset = row[3] as Vector2


func _resolve_authoring_packed_scene() -> PackedScene:
	if weapon_pose_authoring_scene != null:
		return weapon_pose_authoring_scene
	return load("res://Ecenes/Player/Weapons/WeaponHudSlotAuthoring.tscn") as PackedScene


func _resolve_weapon_hud_reference_packed_scene() -> PackedScene:
	if weapon_hud_reference_scene != null:
		return weapon_hud_reference_scene
	return load("res://Ecenes/Player/Weapons/WeaponHud.tscn") as PackedScene


## Span en px coherente con `_live_slot1_reference_span_px`: promedio del tamaño visual del slot 1.
func _reference_span_from_weapon_hud_scene(packed: PackedScene) -> float:
	if packed == null:
		return 0.0
	var root := packed.instantiate()
	if root == null:
		return 0.0
	var slot1 := root.get_node_or_null("Root/WeaponSlotsRoot/HudWeaponSlot1") as Control
	var span := 0.0
	if slot1 != null:
		var vis := WeaponHudSlotSync.slot_visual_size(slot1)
		if vis.x > 0.009 and vis.y > 0.009:
			span = (vis.x + vis.y) * 0.5
	root.queue_free()
	return span


func _load_weapon_icon_poses() -> void:
	_poses_authoring.clear()
	_authoring_ref_px = 0.0
	_canonical_weapon_poses.clear()
	var packed := _resolve_authoring_packed_scene()
	if packed != null:
		var built: Dictionary = WeaponHudIconLayout.build_pose_table_from_authoring(packed)
		var poses: Dictionary = built.get("poses", {})
		var rp: float = float(built.get("ref_px", 0.0))
		if not poses.is_empty() and rp > 0.01:
			_poses_authoring = poses
			_authoring_ref_px = rp
		# Referencia de escala: mismo criterio que el slot grande en WeaponHud, no solo SlotHost en autoría.
		var ref_from_hud := _reference_span_from_weapon_hud_scene(_resolve_weapon_hud_reference_packed_scene())
		if ref_from_hud > 0.01:
			_authoring_ref_px = ref_from_hud
	if _poses_authoring.is_empty():
		push_warning(
			"WeaponHud: no hay poses desde WeaponHudSlotAuthoring. Asigná weapon_pose_authoring_scene o revisá la escena. Usando iconos embebidos en WeaponHud."
		)
		_capture_canonical_weapon_poses_from_weapon_hud_icons()


func _live_slot1_reference_span_px() -> float:
	var slot1: Control = %HudWeaponSlot1
	if slot1 == null:
		return 0.0
	var vis := WeaponHudSlotSync.slot_visual_size(slot1)
	if vis.x <= 0.009 or vis.y <= 0.009:
		return 0.0
	return (vis.x + vis.y) * 0.5


func _refresh_live_authoring_ref_px() -> void:
	if _poses_authoring.is_empty():
		return
	var live := _live_slot1_reference_span_px()
	if live > 0.01:
		_authoring_ref_px = live


func _slots_have_valid_layout() -> bool:
	for tr: TextureRect in _slot_icons:
		if tr == null:
			continue
		var slot := tr.get_parent() as Control
		if slot == null:
			return false
		var vis := WeaponHudSlotSync.slot_visual_size(slot)
		if vis.x <= 0.01 or vis.y <= 0.01:
			return false
	return true


## Mismo orden que los iconos por defecto en `WeaponHud.tscn` (slot 1…4); solo fallback si no hay autoría.
func _capture_canonical_weapon_poses_from_weapon_hud_icons() -> void:
	_canonical_weapon_poses.clear()
	const DEFAULT_WEAPON_NAMES: Array[String] = [
		"Wrench",
		"Revolver",
		"Shotgun",
		"Machine Gun",
	]
	for i in mini(_slot_icons.size(), DEFAULT_WEAPON_NAMES.size()):
		var icon: TextureRect = _slot_icons[i]
		if icon == null:
			continue
		var slot := icon.get_parent() as Control
		if slot == null:
			continue
		var wname: String = DEFAULT_WEAPON_NAMES[i]
		_canonical_weapon_poses[wname] = {
			"offset_left": icon.offset_left,
			"offset_top": icon.offset_top,
			"offset_right": icon.offset_right,
			"offset_bottom": icon.offset_bottom,
			"icon_scale": icon.scale,
			"rotation": icon.rotation,
			"ref_slot_scale": slot.scale,
		}


func _apply_weapon_pose_for_slot(
	icon: TextureRect,
	slot: Control,
	weapon_name: String,
	slot_row_index: int = -1
) -> void:
	if icon == null or slot == null:
		return
	if _authoring_ref_px > 0.01 and not _poses_authoring.is_empty():
		WeaponHudIconLayout.apply_to_icon(icon, slot, weapon_name, _poses_authoring, _authoring_ref_px)
	else:
		var pose: Variant = _canonical_weapon_poses.get(weapon_name)
		if typeof(pose) == TYPE_DICTIONARY:
			var ref_s: Vector2 = pose["ref_slot_scale"]
			if absf(ref_s.x) >= 0.0001 and absf(ref_s.y) >= 0.0001:
				var cur := slot.scale
				var ratio_x := cur.x / ref_s.x
				var ratio_y := cur.y / ref_s.y
				var uniform := (ratio_x + ratio_y) * 0.5
				icon.offset_left = float(pose["offset_left"])
				icon.offset_top = float(pose["offset_top"])
				icon.offset_right = float(pose["offset_right"])
				icon.offset_bottom = float(pose["offset_bottom"])
				icon.rotation = float(pose["rotation"])
				var base_icon_scale: Vector2 = pose["icon_scale"]
				icon.scale = base_icon_scale * uniform
	if slot_row_index >= 1 and slot_row_index <= 3:
		icon.scale *= secondary_slots_icon_scale_multiplier


func show_reserve_ammo_pickup(kind: StringName, amount: int) -> void:
	_refresh_from_manager()
	if _pickup_feed == null or amount <= 0:
		return
	var weapon_label := _label_for_ammo_kind(kind)
	_pickup_feed.text = "+%d  %s  (reserva)" % [amount, weapon_label]
	_pickup_feed.visible = true
	_pickup_feed.modulate = Color(0.45, 1.0, 0.55, 1.0)
	if _pickup_tween != null:
		_pickup_tween.kill()
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(_pickup_feed, "modulate:a", 1.0, 0.08).from(0.35)
	_pickup_tween.tween_interval(1.35)
	_pickup_tween.tween_property(_pickup_feed, "modulate:a", 0.0, 0.45)
	_pickup_tween.tween_callback(func(): _pickup_feed.visible = false)
	_flash_ammo_line()


func _flash_ammo_line() -> void:
	var labels := _ammo_labels()
	if labels.is_empty():
		return
	if _ammo_flash_tween != null:
		_ammo_flash_tween.kill()
	const GOLD := Color(0.976471, 0.937255, 0.454902, 1.0)
	var punch := Color(1.0, 0.92, 0.35, 1.0)
	for lbl: Label in labels:
		lbl.modulate = GOLD
	_ammo_flash_tween = create_tween()
	_ammo_flash_tween.set_parallel(true)
	for lbl: Label in labels:
		_ammo_flash_tween.tween_property(lbl, "modulate", punch, 0.06)
	_ammo_flash_tween.chain()
	_ammo_flash_tween.set_parallel(true)
	for lbl: Label in labels:
		_ammo_flash_tween.tween_property(lbl, "modulate", GOLD, 0.35)


func _label_for_ammo_kind(kind: StringName) -> String:
	match kind:
		WeaponManager.KIND_REVOLVER:
			return "Revólver"
		WeaponManager.KIND_SHOTGUN:
			return "Escopeta"
		WeaponManager.KIND_MACHINEGUN:
			return "Ametralladora"
		_:
			return str(kind)


func _texture_for_weapon(name: String) -> Texture2D:
	match name:
		"Wrench":
			return texture_wrench
		"Revolver":
			return texture_revolver
		"Shotgun":
			return texture_shotgun
		"Machine Gun":
			return texture_machine_gun
		_:
			return null


func _apply_weapon_slot_row(restart_layout_attempts: bool = false) -> void:
	if _weapon_manager == null:
		return
	if restart_layout_attempts:
		_slot_row_layout_attempts = 0
	if not _slots_have_valid_layout():
		if _slot_row_layout_attempts < 12:
			_slot_row_layout_attempts += 1
			call_deferred("_apply_weapon_slot_row", false)
		return
	_slot_row_layout_attempts = 0
	_refresh_live_authoring_ref_px()
	var list: Array[WeaponBase] = _weapon_manager.weapons
	if list.is_empty():
		return
	var n := list.size()
	var start: int = _weapon_manager.current_index
	var dir: int = _weapon_manager.last_switch_direction
	if dir != 1 and dir != -1:
		dir = 1
	for i in _slot_icons.size():
		var tr: TextureRect = _slot_icons[i]
		if tr == null:
			continue
		var w_idx: int
		if i == 0:
			w_idx = start
		else:
			w_idx = (start + i * dir + n * 10) % n
		var w: WeaponBase = list[w_idx]
		var tex: Texture2D = null
		if w != null:
			tex = _texture_for_weapon(w.weapon_name)
		tr.texture = tex
		tr.visible = tex != null
		if tex != null and w != null:
			var slot := tr.get_parent() as Control
			_apply_weapon_pose_for_slot(tr, slot, w.weapon_name, i)


## Tras pickups u otros cambios, re-sincroniza con el arma actual (reserva = bolsa).

func _refresh_from_manager() -> void:
	if _weapon_manager == null:
		return
	var w := _weapon_manager.current_weapon()
	if w == null:
		return
	_on_weapon_changed(
		w.weapon_name,
		w.current_ammo,
		w.reserve_ammo,
		w.magazine_size,
		w.is_reloading
	)


func _reset_weapon_switch_visuals() -> void:
	for i in _slot_icons.size():
		var tr: TextureRect = _slot_icons[i]
		var slot: Control = null
		if tr != null:
			slot = tr.get_parent() as Control
		if slot == null:
			continue
		var base_scale := _slot_base_scales[i] if i < _slot_base_scales.size() else Vector2.ONE
		slot.scale = base_scale


func _play_weapon_switch_feedback() -> void:
	if _weapon_switch_tween != null:
		_weapon_switch_tween.kill()
	_reset_weapon_switch_visuals()

	var primary_icon: TextureRect = null
	if not _slot_icons.is_empty():
		primary_icon = _slot_icons[0]
	var primary_slot: Control = null
	if primary_icon != null:
		primary_slot = primary_icon.get_parent() as Control
	if primary_slot == null:
		_apply_weapon_slot_row(false)
		return

	var base_scale := _slot_base_scales[0] if not _slot_base_scales.is_empty() else primary_slot.scale
	_weapon_switch_tween = create_tween()
	_weapon_switch_tween.tween_property(
		primary_slot,
		"scale",
		base_scale * switch_pop_shrink,
		switch_pop_out_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(
		primary_slot,
		"scale",
		base_scale * switch_pop_overshoot,
		switch_pop_in_time
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_weapon_switch_tween.tween_property(
		primary_slot,
		"scale",
		base_scale,
		switch_pop_settle_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_weapon_changed(
	weapon_name: String,
	current_ammo: int,
	reserve_ammo: int,
	magazine_size: int,
	is_reloading: bool
) -> void:
	if _weapon_name:
		_weapon_name.text = weapon_name
	if _ammo_current:
		if magazine_size <= 0:
			_ammo_current.text = "—"
		else:
			_ammo_current.text = str(current_ammo)
	if _ammo_magazine_capacity:
		if magazine_size <= 0:
			_ammo_magazine_capacity.text = "—"
		else:
			_ammo_magazine_capacity.text = str(magazine_size)
	if _ammo_reserve:
		if magazine_size <= 0:
			_ammo_reserve.text = "—"
		else:
			_ammo_reserve.text = "(%d)" % reserve_ammo
	if _reload_label:
		_reload_label.visible = is_reloading and magazine_size > 0
	var should_animate_switch := not _last_weapon_name.is_empty() and weapon_name != _last_weapon_name
	var prev_name := _last_weapon_name
	_last_weapon_name = weapon_name
	_apply_weapon_slot_row(prev_name.is_empty() or weapon_name != prev_name)
	if should_animate_switch:
		_play_weapon_switch_feedback()
