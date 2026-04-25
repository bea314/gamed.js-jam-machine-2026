extends CanvasLayer
class_name ScreenFade

var _overlay: ColorRect
var _fade_tween: Tween


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func fade_out(duration: float, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease: Tween.EaseType = Tween.EASE_IN) -> void:
	var tween := start_fade_out(duration, trans, ease)
	if tween != null:
		await tween.finished


func fade_in(duration: float, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease: Tween.EaseType = Tween.EASE_OUT) -> void:
	var tween := start_fade_in(duration, trans, ease)
	if tween != null:
		await tween.finished


func start_fade_out(duration: float, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease: Tween.EaseType = Tween.EASE_IN) -> Tween:
	return _start_fade_to_alpha(1.0, duration, trans, ease)


func start_fade_in(duration: float, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	return _start_fade_to_alpha(0.0, duration, trans, ease)


func set_instant_black(is_black: bool) -> void:
	if _overlay == null:
		return
	_overlay.color.a = 1.0 if is_black else 0.0


func _start_fade_to_alpha(target_alpha: float, duration: float, trans: Tween.TransitionType, ease: Tween.EaseType) -> Tween:
	if _overlay == null:
		return null
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_trans(trans)
	_fade_tween.set_ease(ease)
	_fade_tween.tween_property(_overlay, "color:a", target_alpha, maxf(duration, 0.0))
	return _fade_tween
