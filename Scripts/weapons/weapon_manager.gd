extends Node
class_name WeaponManager

## Identificadores estables para mapear pickups u otra lógica externa al arma correcta.
const KIND_REVOLVER: StringName = &"revolver"
const KIND_SHOTGUN: StringName = &"shotgun"
const KIND_MACHINEGUN: StringName = &"machinegun"
const RANGED_KINDS: Array[StringName] = [KIND_REVOLVER, KIND_SHOTGUN, KIND_MACHINEGUN]

## Solo cuando el arma realmente ejecuta un disparo / melee (no click en vacío ni sin munición).
signal weapon_actually_fired()

signal weapon_changed(
	weapon_name: String,
	current_ammo: int,
	reserve_ammo: int,
	magazine_size: int,
	is_reloading: bool
)

@export var wrench_scene: PackedScene
@export var revolver_scene: PackedScene
@export var shotgun_scene: PackedScene
@export var machinegun_scene: PackedScene

@export var revolver_fire_sfx: AudioStream = preload("res://Recursos/Sound/SFXS/UX_STAGE/WEAPONS_SFXS/GUN.ogg")
@export var shotgun_fire_sfx: AudioStream = preload("res://Recursos/Sound/SFXS/UX_STAGE/WEAPONS_SFXS/SHOTGUN.ogg")
@export var machinegun_fire_sfx: AudioStream = preload("res://Recursos/Sound/SFXS/UX_STAGE/WEAPONS_SFXS/MACHINE_GUN.ogg")

var weapons: Array[WeaponBase] = []
var current_index: int = 0
var owner_player: Node2D
var _damage_flat_bonus: int = 0

# referencia animation weapons
@onready var anima_weapons: AnimationPlayer = $"../Guns_meshes/Anima_Weapons"
@onready var _gun_mesh_wrench: Sprite2D = $"../Guns_meshes/llave_inglesa"
@onready var _gun_mesh_revolver: Sprite2D = $"../Guns_meshes/Revolver"
@onready var _gun_mesh_shotgun: Sprite2D = $"../Guns_meshes/Shot_Gun"
@onready var _gun_mesh_machinegun: AnimatedSprite2D = $"../Guns_meshes/Ametralladora"
@onready var _weapon_sfx_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()


func _ready() -> void:
	add_child(_weapon_sfx_player)
	_weapon_sfx_player.max_polyphony = 8


func setup(player: Node2D) -> void:
	owner_player = player

	var wrench := wrench_scene.instantiate() as WeaponBase
	var revolver := revolver_scene.instantiate() as WeaponBase
	var shotgun := shotgun_scene.instantiate() as WeaponBase
	var machinegun := machinegun_scene.instantiate() as WeaponBase

	weapons = [wrench, revolver, shotgun, machinegun]

	for w in weapons:
		add_child(w)
		w.ammo_changed.connect(_on_ammo_changed)
		w.reload_started.connect(_emit_weapon_changed)
		w.reload_finished.connect(_emit_weapon_changed)
		w.weapon_fired.connect(_forward_weapon_fired)
		if w.has_method("set_damage_flat_bonus"):
			w.set_damage_flat_bonus(_damage_flat_bonus)

	_emit_weapon_changed()
	_sync_gun_mesh_visual()


func _forward_weapon_fired() -> void:
	weapon_actually_fired.emit()
	_play_fire_sfx_for_current_weapon()

	# Verificamos si el índice es 0 (Llave Inglesa)
	if current_index == 0:
		var anim = "LLave_inglesa_shot"
		if anima_weapons.has_animation(anim):
			anima_weapons.stop() 
			anima_weapons.play(anim)
	else:
		var anim_generic = _recoil_anim_name(current_index)
		if anima_weapons.has_animation(anim_generic):
			anima_weapons.play(anim_generic)


func _recoil_anim_name(index: int) -> StringName:
	match index:
		0:
			return &"LLave_inglesa_shot"
		1:
			return &"Revolver_Shot"
		2:
			return &"Shot_Gun_Shot"
		3:
			return &"Ametralladora_shot"
		_:
			return StringName()


func _play_fire_sfx_for_current_weapon() -> void:
	var stream: AudioStream = null
	match current_index:
		1:
			stream = revolver_fire_sfx
		2:
			stream = shotgun_fire_sfx
		3:
			stream = machinegun_fire_sfx
		_:
			return

	if stream == null:
		return

	_weapon_sfx_player.stream = stream
	_weapon_sfx_player.play()


func current_weapon() -> WeaponBase:
	return weapons[current_index]


func fire(aim_direction: Vector2, pressed: bool, just_pressed: bool) -> void:
	var weapon := current_weapon()
	if weapon == null:
		return

	if weapon.automatic:
		if pressed:
			weapon.try_fire(owner_player, aim_direction)
	else:
		if just_pressed:
			weapon.try_fire(owner_player, aim_direction)

func reload() -> void:
	current_weapon().try_reload()

  
func next_weapon() -> void:
	if not _can_switch_weapons():
		return
	current_index = (current_index + 1) % weapons.size()
	_emit_weapon_changed()
	_sync_gun_mesh_visual()


func prev_weapon() -> void:
	if not _can_switch_weapons():
		return
	current_index = (current_index - 1 + weapons.size()) % weapons.size()
	_emit_weapon_changed()
	_sync_gun_mesh_visual()


func set_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if not _can_switch_weapons():
		return
	current_index = index
	_emit_weapon_changed()
	_sync_gun_mesh_visual()


func _can_switch_weapons() -> bool:
	var w := current_weapon()
	# Melee (no magazine): always allow. Ranged: block while reloading.
	return w.magazine_size <= 0 or not w.is_reloading


func _on_ammo_changed(_current: int, _reserve: int) -> void:
	_emit_weapon_changed()


func _emit_weapon_changed() -> void:
	var w := current_weapon()
	weapon_changed.emit(
		w.weapon_name,
		w.current_ammo,
		w.reserve_ammo,
		w.magazine_size,
		w.is_reloading
	)


func _sync_gun_mesh_visual() -> void:
	_gun_mesh_wrench.visible = (current_index == 0)
	_gun_mesh_revolver.visible = (current_index == 1)
	_gun_mesh_shotgun.visible = (current_index == 2)
	_gun_mesh_machinegun.visible = (current_index == 3)


func set_damage_multiplier(multiplier: float) -> void:
	for w in weapons:
		if w != null and w.has_method("set_damage_multiplier"):
			w.set_damage_multiplier(multiplier)


func set_damage_flat_bonus(bonus: int) -> void:
	_damage_flat_bonus = bonus
	for w in weapons:
		if w != null and w.has_method("set_damage_flat_bonus"):
			w.set_damage_flat_bonus(_damage_flat_bonus)


func _index_for_kind(kind: StringName) -> int:
	match kind:
		KIND_REVOLVER:
			return 1
		KIND_SHOTGUN:
			return 2
		KIND_MACHINEGUN:
			return 3
		_:
			return -1


func get_weapon_for_kind(kind: StringName) -> WeaponBase:
	var idx := _index_for_kind(kind)
	if idx < 0 or idx >= weapons.size():
		return null
	return weapons[idx]


## Suma munición a la reserva del arma indicada. Devuelve cuánto se añadió (0 si no aplica o reserva llena).
func add_ammo_for_kind(kind: StringName, amount: int) -> int:
	var w := get_weapon_for_kind(kind)
	if w == null:
		return 0
	return w.add_reserve_ammo(amount)


## True cuando la reserva del arma indicada está al tope (si tiene `reserve_ammo_max` > 0).
func is_reserve_full_for_kind(kind: StringName) -> bool:
	var w := get_weapon_for_kind(kind)
	if w == null:
		return true
	return w.is_reserve_full()


func get_magazine_size_for_kind(kind: StringName) -> int:
	var w := get_weapon_for_kind(kind)
	if w == null:
		return 0
	return w.magazine_size
