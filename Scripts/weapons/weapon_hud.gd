extends CanvasLayer

## Único HUD de armas del juego: instanciado solo en `Ecenes/Player.tscn` como hijo `WeaponHud`.
## HUD munición: balas en cargador | capacidad cargador | **reserva** (solo bolsa; sin lo cargado en el arma).
## Slots bajo `Root/WeaponSlotsRoot`: **no van dentro de VBox/HBox** para poder moverlos en el editor con `layout_mode` manual.
## Mueve todo el grupo arrastrando `WeaponSlotsRoot`; mueve cada arma activando un `HudWeaponSlotN` y editando posición/tamaño (hijos con anclas llenan cada slot).

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
var _weapon_manager: WeaponManager


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
	for lbl: Label in _ammo_labels():
		lbl.text = "—"
	if _reload_label:
		_reload_label.visible = false
	if _pickup_feed:
		_pickup_feed.visible = false


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


func _apply_weapon_slot_row() -> void:
	if _weapon_manager == null:
		return
	var list: Array[WeaponBase] = _weapon_manager.weapons
	if list.is_empty():
		return
	var n := list.size()
	var start: int = _weapon_manager.current_index
	for i in _slot_icons.size():
		var tr: TextureRect = _slot_icons[i]
		if tr == null:
			continue
		var w_idx: int = (start + i) % n
		var w: WeaponBase = list[w_idx]
		var tex: Texture2D = null
		if w != null:
			tex = _texture_for_weapon(w.weapon_name)
		tr.texture = tex
		tr.visible = tex != null


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
	_apply_weapon_slot_row()
