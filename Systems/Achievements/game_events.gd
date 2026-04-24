extends Node

signal event_emitted(event_name: StringName, payload: Dictionary)


func emit_event(event_name: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_name, payload)
