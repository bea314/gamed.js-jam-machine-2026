@tool
extends Control

## PASOS: 1) Colocá los cuatro marcos en `WeaponHud.tscn` (`WeaponSlotsRoot`). 2) Abrí esta escena y esperá a que el cyan iguale el slot grande.
## 3) Afiná cada `WeaponIcon` en `WeaponsRow/*/SlotHost/HudWeaponSlot1`. 4) Guardá. El juego **solo** usa estas poses (vía `WeaponHud.weapon_pose_authoring_scene`).
##
## El script sincroniza el tamaño del `SlotHost` con el rect visual de `HudWeaponSlot1` del HUD; no toca offsets ni rotación del icono.

@export var weapon_hud_scene: PackedScene

@onready var _status: Label = %StatusLine
@onready var _weapons_row: HBoxContainer = %WeaponsRow


func _ready() -> void:
	_apply_slot_sizes_from_weapon_hud.call_deferred()


## Tamaño del slot grande del HUD real; no toca offsets / rotación del `WeaponIcon` (eso lo editás en la escena).
func _apply_slot_sizes_from_weapon_hud() -> void:
	if _weapons_row == null:
		return
	var source_scene := weapon_hud_scene
	if source_scene == null:
		source_scene = load("res://Ecenes/Player/Weapons/WeaponHud.tscn") as PackedScene
	if source_scene == null:
		return

	var hud: Node = source_scene.instantiate()
	add_child(hud)
	if hud is CanvasLayer:
		(hud as CanvasLayer).visible = false
	elif hud is Control:
		(hud as Control).visible = false

	var slot1 := _req_slot(hud, "HudWeaponSlot1")
	if slot1 == null:
		hud.queue_free()
		return

	var sz_big := _slot_visual_size(slot1)
	var slot_name := "HudWeaponSlot1"

	for cell in _weapons_row.get_children():
		var host := cell.get_node_or_null("SlotHost") as Control
		if host != null:
			host.custom_minimum_size = sz_big
			host.clip_contents = false
		var dims := cell.get_node_or_null("SlotDims") as Label
		if dims != null:
			dims.text = "%d×%d px" % [int(roundf(sz_big.x)), int(roundf(sz_big.y))]

	if _status:
		var w := int(roundf(sz_big.x))
		var h := int(roundf(sz_big.y))
		_status.text = "Cuadro cyan = límite %d×%d px (%s). En el árbol: WeaponsRow → … → WeaponIcon — ahí movés, rotás y escalás cada asset; el HUD lee estas poses." % [w, h, slot_name]

	hud.queue_free()


func _req_slot(hud: Node, slot_name: String) -> Control:
	return hud.get_node_or_null("Root/WeaponSlotsRoot/%s" % slot_name) as Control


func _slot_visual_size(control: Control) -> Vector2:
	return Vector2(absf(control.size.x * control.scale.x), absf(control.size.y * control.scale.y))
