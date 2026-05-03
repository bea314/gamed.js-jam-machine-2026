extends Control
## Pantalla de transición: arte mientras `ResourceLoader` trabaja en segundo plano.
## Sin espera mínima tras terminar la carga; solo fades de entrada (`ENTRY_FADE_SEC`) y salida (`EXIT_FADE_SEC`).

## Arte en `res://Recursos/Textures/loading/` (atlas ligero).
const ENTRY_FADE_SEC := 0.55
const EXIT_FADE_SEC := 0.9


## Velocidad fija del “idle” visible (ligera; no igual al FPS del GIF).
const LOADING_PREVIEW_FPS := 8.0
## Muestrear 1 cada N fotogramas en el atlas.
const LOADING_ATLAS_FRAME_STRIDE := 3
## Tope de celdas atlas (pocos `AtlasTexture`).
const LOADING_PREVIEW_MAX_FRAMES := 10

const SPIN_FALLBACK_TEXTURE: Texture2D = preload("res://Recursos/Textures/Menus/main-menu_bug.webp")
const SPIN_SPEED_DEG := 72.0

const LOAD_MEM_CYAN_DIR := "res://Recursos/Textures/loading/mem_pag7_cyan"
const LOAD_MEM_WARM_DIR := "res://Recursos/Textures/loading/mem_pag7_warm"

@onready var _fade: ColorRect = $FadeLayer/Fade
@onready var _bg: ColorRect = $Background
@onready var _art: TextureRect = $ContentLayer/CenterHolder/Art

var _target_path: String = ""

var _gif_frames: Array[Texture2D] = []
var _gif_frame_dt: float = 0.125
var _gif_accum: float = 0.0
var _gif_idx: int = 0
var _gif_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_target_path = LoadingTransition.next_scene_path
	if _target_path.is_empty():
		push_error("LoadingScreen: `next_scene_path` vacío; vuelvo al menú.")
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://Ecenes/Menu/Menu.tscn")
		return

	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.resized.connect(_on_art_resized)

	_setup_visual()

	_fade.modulate = Color(1, 1, 1, 1)
	_fade.visible = true

	await get_tree().process_frame

	var reveal := create_tween()
	reveal.set_trans(Tween.TRANS_QUART)
	reveal.set_ease(Tween.EASE_OUT)
	reveal.tween_property(_fade, "modulate:a", 0.0, ENTRY_FADE_SEC)
	await reveal.finished

	ResourceLoader.load_threaded_request(_target_path)

	while true:
		match ResourceLoader.load_threaded_get_status(_target_path):
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("LoadingScreen: falló la carga de %s" % _target_path)
				get_tree().change_scene_to_file("res://Ecenes/Menu/Menu.tscn")
				return
			_:
				await get_tree().process_frame

	var packed := ResourceLoader.load_threaded_get(_target_path)
	if packed is PackedScene:
		LoadingTransition.clear_pending()

		var out := create_tween()
		out.set_trans(Tween.TRANS_QUART)
		out.set_ease(Tween.EASE_IN)
		out.tween_property(_fade, "modulate:a", 1.0, EXIT_FADE_SEC)
		await out.finished
		get_tree().change_scene_to_packed(packed)
		return

	push_error("LoadingScreen: recurso no es PackedScene (%s)." % _target_path)
	get_tree().change_scene_to_file("res://Ecenes/Menu/Menu.tscn")


func _setup_visual() -> void:
	var ok_dirs: Array[String] = []
	for d: String in [LOAD_MEM_CYAN_DIR, LOAD_MEM_WARM_DIR]:
		if DirAccess.open(d) != null:
			ok_dirs.append(d)

	var chosen: String = ""
	if ok_dirs.size() > 0:
		chosen = ok_dirs.pick_random()

	_gif_frames.clear()
	if not chosen.is_empty():
		_gif_frames = _load_sheet_atlas_frames_thinned(chosen)
	if _gif_frames.size() > 0:
		_gif_active = true
		_gif_frame_dt = 1.0 / LOADING_PREVIEW_FPS
		_gif_idx = 0
		_gif_accum = 0.0
		_art.texture = _gif_frames[0]
		_art.pivot_offset = _art.size * 0.5
		return

	_gif_active = false
	_art.texture = SPIN_FALLBACK_TEXTURE
	_art.pivot_offset = _art.size * 0.5


func _preview_sample_indices(total: int) -> PackedInt32Array:
	if total < 1:
		return PackedInt32Array()
	var stride: int = LOADING_ATLAS_FRAME_STRIDE
	var max_f: int = LOADING_PREVIEW_MAX_FRAMES
	if stride < 1:
		stride = 1
	var eff_stride: int = stride
	if total > eff_stride * max_f:
		eff_stride = (total + max_f - 1) / max_f
	var out: PackedInt32Array = PackedInt32Array()
	var i: int = 0
	while i < total and out.size() < max_f:
		out.append(i)
		i += eff_stride
	if out.size() < 2 and total >= 2:
		out.clear()
		out.append(0)
		out.append(total / 2)
	return out


func _load_sheet_atlas_frames_thinned(dir_path: String) -> Array[Texture2D]:
	var sheet_path := dir_path.path_join("sheet.webp")
	var meta_path := dir_path.path_join("meta.json")
	if not ResourceLoader.exists(sheet_path) or not FileAccess.file_exists(meta_path):
		return []
	var txt: String = FileAccess.get_file_as_string(meta_path).strip_edges()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var meta: Dictionary = parsed
	var count: int = maxi(0, int(meta.get("frames", 0)))
	var cols: int = maxi(1, int(meta.get("cols", 1)))
	var fw: int = maxi(0, int(meta.get("fw", 0)))
	var fh: int = maxi(0, int(meta.get("fh", 0)))
	if count < 1 or fw < 1 or fh < 1:
		return []
	var res: Resource = ResourceLoader.load(sheet_path)
	if res == null:
		return []
	if not res is Texture2D:
		return []
	var sheet_tex: Texture2D = res as Texture2D
	var index_list: PackedInt32Array = _preview_sample_indices(count)
	var result: Array[Texture2D] = []
	for frame_i in index_list:
		var col: int = frame_i % cols
		var row: int = frame_i / cols
		var at := AtlasTexture.new()
		at.atlas = sheet_tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		at.filter_clip = true
		result.append(at)
	return result


func _process(delta: float) -> void:
	if _gif_active:
		if _gif_frames.size() <= 1:
			return
		_gif_accum += delta
		while _gif_accum >= _gif_frame_dt:
			_gif_accum -= _gif_frame_dt
			_gif_idx = (_gif_idx + 1) % _gif_frames.size()
			_art.texture = _gif_frames[_gif_idx]
	elif _art != null:
		_art.rotation_degrees += SPIN_SPEED_DEG * delta


func _on_art_resized() -> void:
	if _art != null:
		_art.pivot_offset = _art.size * 0.5
