extends CanvasLayer

@onready var _weapon_name: Label = $Root/VBox/WeaponNameLabel
@onready var _icon: ColorRect = $Root/VBox/WeaponIcon
@onready var _ammo: Label = $Root/VBox/AmmoLabel
@onready var _reload_label: Label = $Root/VBox/ReloadLabel

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
