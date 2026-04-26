extends CanvasLayer

@onready var _weapon_name: Label = $Root/VBox/WeaponNameLabel
@onready var _icon: ColorRect = $Root/VBox/WeaponIcon
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
	if _icon:
		_icon.color = _color_for_weapon(weapon_name)


func _color_for_weapon(name: String) -> Color:
	match name:
		"Wrench":
			return Color(0.65, 0.7, 0.75)
		"Revolver":
			return Color(0.85, 0.55, 0.35)
		"Shotgun":
			return Color(0.55, 0.7, 0.45)
		"Machine Gun":
			return Color(0.75, 0.4, 0.4)
		_:
			return Color(0.7, 0.7, 0.7)
