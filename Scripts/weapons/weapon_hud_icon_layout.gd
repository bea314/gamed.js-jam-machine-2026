class_name WeaponHudIconLayout
extends RefCounted

## Poses por arma: `WeaponHudSlotAuthoring.tscn` → `Margin/Main/WeaponsRow` → columnas A–D →
## `SlotHost/HudWeaponSlot1/WeaponIcon` (offsets, `scale`, `rotation` en espacio del SlotHost/cyan).
##
## `build_pose_table_from_authoring` devuelve también un `ref_px` tomado del **SlotHost.custom_minimum_size**
## de la autoría (cuadro cyan). En runtime, `WeaponHud` **sustituye** ese valor por el span medido en
## `WeaponHud.tscn` → `HudWeaponSlot1` (y en juego lo refresca desde el slot en vivo). Así la escala de
## las poses sigue al marco grande que editás en el HUD.

const FALLBACK_REF_PX := 117.77286

const _WEAPON_BY_COLUMN := {
	"A_Wrench": "Wrench",
	"B_Revolver": "Revolver",
	"C_Shotgun": "Shotgun",
	"D_MachineGun": "Machine Gun",
}


static func build_pose_table_from_authoring(packed: PackedScene) -> Dictionary:
	var poses: Dictionary = {}
	var ref_px: float = 0.0
	if packed == null:
		return {"poses": poses, "ref_px": FALLBACK_REF_PX}

	var root := packed.instantiate()
	# Sin script: si no, `weapon_hud_slot_authoring.gd` haría `_ready` al entrar al árbol e instanciaría otro HUD.
	if root is Node:
		(root as Node).set_script(null)
	var row: Node = root.get_node_or_null("Margin/Main/WeaponsRow")
	if row == null:
		root.free()
		return {"poses": poses, "ref_px": FALLBACK_REF_PX}

	for col in row.get_children():
		var weapon_name: String = String(_WEAPON_BY_COLUMN.get(col.name, ""))
		if weapon_name.is_empty():
			continue

		var host := col.get_node_or_null("SlotHost") as Control
		var icon := col.get_node_or_null("SlotHost/HudWeaponSlot1/WeaponIcon") as TextureRect
		if icon == null:
			continue

		if ref_px <= 0.01 and host != null:
			var minimum_size := host.custom_minimum_size
			if minimum_size.x > 0.01:
				ref_px = minimum_size.x
			elif minimum_size.y > 0.01:
				ref_px = minimum_size.y

		poses[weapon_name] = {
			"offset_left": icon.offset_left,
			"offset_top": icon.offset_top,
			"offset_right": icon.offset_right,
			"offset_bottom": icon.offset_bottom,
			"scale": icon.scale,
			"rotation": icon.rotation,
		}

	root.free()
	if ref_px <= 0.01:
		ref_px = FALLBACK_REF_PX
	return {"poses": poses, "ref_px": ref_px}


static func apply_to_icon(
	icon: TextureRect,
	slot: Control,
	weapon_name: String,
	poses: Dictionary,
	ref_slot_px: float,
) -> void:
	if icon == null or slot == null:
		return

	var pose: Variant = poses.get(weapon_name)
	if typeof(pose) != TYPE_DICTIONARY:
		return

	var ref_px: float = ref_slot_px if ref_slot_px > 0.01 else FALLBACK_REF_PX
	var sx := slot.size.x
	var sy := slot.size.y
	if sx <= 0.001 or sy <= 0.001:
		sx = absf(slot.offset_right - slot.offset_left)
		sy = absf(slot.offset_bottom - slot.offset_top)
	var slot_size := Vector2(sx, sy)
	if slot_size.x <= 0.01 or slot_size.y <= 0.01:
		return

	var ratio_x := slot_size.x / ref_px
	var ratio_y := slot_size.y / ref_px
	icon.offset_left = float(pose["offset_left"]) * ratio_x
	icon.offset_top = float(pose["offset_top"]) * ratio_y
	icon.offset_right = float(pose["offset_right"]) * ratio_x
	icon.offset_bottom = float(pose["offset_bottom"]) * ratio_y
	var pose_scale: Vector2 = pose["scale"]
	# Slot Control.scale maps local→screen; icon.scale stays as authored (do not multiply by ratio).
	icon.scale = pose_scale
	icon.rotation = float(pose["rotation"])
