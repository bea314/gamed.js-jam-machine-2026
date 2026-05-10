extends Control
## Pantalla de transición: arte mientras `ResourceLoader` trabaja en segundo plano.
## Sin espera mínima tras terminar la carga; solo fades de entrada (`ENTRY_FADE_SEC`) y salida (`EXIT_FADE_SEC`).

## Arte en `res://Recursos/Textures/loading/` (atlas ligero).
const ENTRY_FADE_SEC := 0.55
const EXIT_FADE_SEC := 0.9
const MAX_THREAD_WAIT_MS := 15000
const SCENE_CHANGE_RETRIES := 3


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
	_target_path = LoadingTransition.get_pending_or_last_scene_path()
	if _target_path.is_empty():
		await get_tree().process_frame
		_target_path = LoadingTransition.get_pending_or_last_scene_path()
	if _target_path.is_empty():
		push_error("LoadingScreen: sin destino tras transición (`next_scene_path` vacío); vuelvo al menú.")
		await get_tree().process_frame
		call_deferred("_deferred_commit_scene_path_or_menu", LoadingTransition.MENU_SCENE_PATH)
		return

	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_art.resized.connect(_on_art_resized)

	_setup_visual()

	_fade.modulate = Color(1, 1, 1, 1)
	_fade.visible = true

	# Dos frames: layout estable antes del tween (evita reveal “muerto” tras intro en negro).
	for _i in 2:
		await get_tree().process_frame

	var reveal := create_tween()
	reveal.set_trans(Tween.TRANS_QUART)
	reveal.set_ease(Tween.EASE_OUT)
	reveal.tween_property(_fade, "modulate", Color(1, 1, 1, 0), ENTRY_FADE_SEC)
	await reveal.finished

	var packed_scene: PackedScene = await _load_target_packed_scene()
	if packed_scene == null:
		push_error(
			"LoadingScreen: fase LOAD — no se obtuvo PackedScene para `%s`; intento `change_scene_to_file`."
			% _target_path
		)
		await _fade_out_and_change_to_file(_target_path)
		return
	if not packed_scene.can_instantiate():
		push_error(
			"LoadingScreen: fase VALIDATE — PackedScene no instanciable (`can_instantiate()==false`) para `%s`."
			% _target_path
		)
		_log_scene_load_diagnostic(_target_path)
		await _fade_out_and_change_to_file(_target_path)
		return

	var commit_path := _target_path
	LoadingTransition.clear_pending()

	await _play_exit_fade()

	call_deferred("_deferred_commit_loaded_scene", packed_scene, commit_path)
	return


func _load_target_packed_scene() -> PackedScene:
	# En Web el export suele ir sin hilos; solo carga síncrona (evita caer en `load_threaded_*` tras un fallo).
	if OS.has_feature("web"):
		return _try_load_packed_sync(_target_path)

	var request_err := ResourceLoader.load_threaded_request(_target_path)
	if request_err != OK and request_err != ERR_BUSY:
		push_warning(
			"LoadingScreen: threaded request %s (%s); pruebo carga síncrona."
			% [_target_path, error_string(request_err)]
		)
		return _try_load_packed_sync(_target_path)

	var started_ms: int = Time.get_ticks_msec()
	while true:
		var status := ResourceLoader.load_threaded_get_status(_target_path)
		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				push_warning("LoadingScreen: threaded falló %s; pruebo carga síncrona." % _target_path)
				return _try_load_packed_sync(_target_path)
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_warning("LoadingScreen: threaded inválido %s; pruebo carga síncrona." % _target_path)
				return _try_load_packed_sync(_target_path)
			_:
				if Time.get_ticks_msec() - started_ms >= MAX_THREAD_WAIT_MS:
					push_warning("LoadingScreen: timeout threaded %s; pruebo carga síncrona." % _target_path)
					return _try_load_packed_sync(_target_path)
				await get_tree().process_frame

	var packed_res: Variant = ResourceLoader.load_threaded_get(_target_path)
	if packed_res is PackedScene:
		var ps_thread: PackedScene = packed_res as PackedScene
		if ps_thread.can_instantiate():
			return ps_thread
		push_warning(
			"LoadingScreen: threaded PackedScene no instanciable (`can_instantiate`); pruebo carga síncrona."
		)
		return _try_load_packed_sync(_target_path)
	push_warning("LoadingScreen: resultado threaded no es PackedScene; pruebo carga síncrona.")
	return _try_load_packed_sync(_target_path)


func _try_load_packed_sync(path: String) -> PackedScene:
	if path.is_empty():
		push_error("LoadingScreen: _try_load_packed_sync: path vacío.")
		return null
	if not ResourceLoader.exists(path):
		push_error("LoadingScreen: _try_load_packed_sync: ResourceLoader.exists(%s) == false." % path)
		_log_scene_load_diagnostic(path)
		return null
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		push_error(
			"LoadingScreen: _try_load_packed_sync: ResourceLoader.load(%s) devolvió null (dependencia rota o error de parseo)."
			% path
		)
		_log_scene_load_diagnostic(path)
		return null
	if not res is PackedScene:
		push_error(
			"LoadingScreen: _try_load_packed_sync: recurso no es PackedScene (tipo=%s) para %s."
			% [res.get_class(), path]
		)
		return null
	var ps := res as PackedScene
	if not ps.can_instantiate():
		push_error(
			"LoadingScreen: _try_load_packed_sync: escena cargada pero can_instantiate()==false para %s."
			% path
		)
		_log_scene_load_diagnostic(path)
		return null
	return ps


func _dependency_res_path(token: String) -> String:
	## Godot 4.1+ puede devolver tokens tipo `uid://…::::res://…`; necesitamos la parte cargable.
	var s := token.strip_edges()
	var idx := s.find("res://")
	if idx >= 0:
		return s.substr(idx)
	return s


func _gather_dependencies_recursive(entry_path: String, max_total: int = 400) -> PackedStringArray:
	## En Godot 4.x `ResourceLoader.get_dependencies()` solo admite un argumento; la recursión va aquí.
	var out: Array[String] = []
	var seen: Dictionary = {}
	var queue: Array[String] = [entry_path]
	seen[entry_path] = true
	while queue.size() > 0 and out.size() < max_total:
		var cur: String = queue.pop_front()
		var direct: PackedStringArray = ResourceLoader.get_dependencies(cur)
		for raw in direct:
			var dep_path := _dependency_res_path(str(raw))
			if dep_path.is_empty():
				continue
			if seen.has(dep_path):
				continue
			seen[dep_path] = true
			out.append(dep_path)
			if ResourceLoader.exists(dep_path):
				queue.append(dep_path)
	return PackedStringArray(out)


func _log_scene_load_diagnostic(path: String) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_error("LoadingScreen: diagnóstico: `%s` no existe en el loader." % path)
		return
	var deps := _gather_dependencies_recursive(path)
	var max_lines := mini(28, deps.size())
	var buf := "LoadingScreen: dependencias recursivas de `%s` (%d total), primeras %d:\n" % [path, deps.size(), max_lines]
	for i in max_lines:
		buf += "  - %s\n" % deps[i]
	push_error(buf.strip_edges())


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


func _play_exit_fade() -> void:
	var out := create_tween()
	out.set_trans(Tween.TRANS_QUART)
	out.set_ease(Tween.EASE_IN)
	out.tween_property(_fade, "modulate:a", 1.0, EXIT_FADE_SEC)
	await out.finished


func _fade_out_and_change_to_file(path: String) -> void:
	LoadingTransition.clear_pending()
	await _play_exit_fade()
	var safe_path := path if ResourceLoader.exists(path) else LoadingTransition.MENU_SCENE_PATH
	call_deferred("_deferred_commit_scene_path_or_menu", safe_path)


func _deferred_commit_loaded_scene(packed_scene: PackedScene, commit_path: String) -> void:
	if not is_inside_tree():
		return
	if packed_scene == null or not packed_scene.can_instantiate():
		push_error(
			"LoadingScreen: fase COMMIT — PackedScene inválido o no instanciable para `%s`."
			% commit_path
		)
		_log_scene_load_diagnostic(commit_path)
		_with_retries(
			SCENE_CHANGE_RETRIES,
			get_tree().change_scene_to_file.bind(LoadingTransition.MENU_SCENE_PATH),
			"change_scene_to_file(menu)"
		)
		return
	var tree := get_tree()
	var err: int = _with_retries(
		SCENE_CHANGE_RETRIES,
		tree.change_scene_to_packed.bind(packed_scene),
		"change_scene_to_packed(%s)" % commit_path
	)
	if err != OK:
		push_warning(
			"LoadingScreen: change_scene_to_packed err=%s → change_scene_to_file(%s)"
			% [error_string(err), commit_path]
		)
		err = _with_retries(
			SCENE_CHANGE_RETRIES,
			tree.change_scene_to_file.bind(commit_path),
			"change_scene_to_file(%s)" % commit_path
		)
	if err != OK:
		push_warning(
			"LoadingScreen: change_scene_to_file err=%s → change_scene_to_node(instantiate)"
			% error_string(err)
		)
		var instance: Node = packed_scene.instantiate()
		if instance != null:
			err = tree.change_scene_to_node(instance)
	if err != OK:
		push_error(
			"LoadingScreen: fase MOUNT — no se pudo montar el nivel `%s` (%s); vuelvo al menú."
			% [commit_path, error_string(err)]
		)
		_log_scene_load_diagnostic(commit_path)
		_with_retries(
			SCENE_CHANGE_RETRIES,
			tree.change_scene_to_file.bind(LoadingTransition.MENU_SCENE_PATH),
			"change_scene_to_file(menu)"
		)


func _deferred_commit_scene_path_or_menu(path: String) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var err: int = _with_retries(
		SCENE_CHANGE_RETRIES,
		tree.change_scene_to_file.bind(path),
		"change_scene_to_file(%s)" % path
	)
	if err != OK:
		push_error(
			"LoadingScreen: change_scene_to_file(%s) err=%s; vuelvo al menú."
			% [path, error_string(err)]
		)
		_with_retries(
			SCENE_CHANGE_RETRIES,
			tree.change_scene_to_file.bind(LoadingTransition.MENU_SCENE_PATH),
			"change_scene_to_file(menu)"
		)


func _with_retries(retries: int, change: Callable, label: String) -> int:
	var attempts := maxi(1, retries)
	var err := FAILED
	for i in range(attempts):
		err = change.call()
		if err == OK:
			return OK
		if i < attempts - 1:
			push_warning(
				"LoadingScreen: reintento %s/%s %s err=%s"
				% [i + 1, attempts, label, error_string(err)]
			)
	return err
