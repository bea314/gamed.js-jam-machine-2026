extends CanvasLayer

## Único HUD de armas del juego: instanciado solo en `Ecenes/Player.tscn` como hijo `WeaponHud`.

@export_group("Weapon icons")
@export var texture_wrench: Texture2D
@export var texture_revolver: Texture2D
@export var texture_shotgun: Texture2D
@export var texture_machine_gun: Texture2D

@onready var _weapon_name: Label = $Root/WeaponNameLabel
@onready var _icon_tex: TextureRect = $Root/VBox/WeaponIconSlot/InsetArea/WeaponIconTexture
@onready var _ammo: Label = $Root/VBox/AmmoLabel
@onready var _reload_label: Label = $Root/VBox/ReloadLabel
@onready var _pickup_feed: Label = $Root/VBox/PickupFeedLabel

var _pickup_tween: Tween
var _ammo_flash_tween: Tween

func setup(manager: Node) -> void:
	if manager == null:
		return
	if not manager.weapon_changed.is_connected(_on_weapon_changed):
		manager.weapon_changed.connect(_on_weapon_changed)


func _ready() -> void:
	if _ammo:
		_ammo.text = "—"
	if _reload_label:
		_reload_label.visible = false
	if _pickup_feed:
		_pickup_feed.visible = false


func show_reserve_ammo_pickup(kind: StringName, amount: int) -> void:
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
	if _ammo == null:
		return
	if _ammo_flash_tween != null:
		_ammo_flash_tween.kill()
	var base := Color.WHITE
	var punch := Color(1.0, 0.92, 0.35, 1.0)
	_ammo_flash_tween = create_tween()
	_ammo_flash_tween.tween_property(_ammo, "modulate", punch, 0.06)
	_ammo_flash_tween.tween_property(_ammo, "modulate", base, 0.35)


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


func _apply_weapon_icon(weapon_name: String) -> void:
	var tex := _texture_for_weapon(weapon_name)
	var has_tex := tex != null
	if _icon_tex:
		_icon_tex.texture = tex
		_icon_tex.visible = has_tex


func _on_weapon_changed(
	weapon_name: String,
	current_ammo: int,
	reserve_ammo: int,
	magazine_size: int,
	is_reloading: bool
) -> void:
	if _weapon_name:
		_weapon_name.text = weapon_name
	if _ammo:
		if magazine_size <= 0:
			_ammo.text = "—"
		else:
			_ammo.text = "%d / %d  (res: %d)" % [current_ammo, magazine_size, reserve_ammo]
	if _reload_label:
		_reload_label.visible = is_reloading and magazine_size > 0
	_apply_weapon_icon(weapon_name)
