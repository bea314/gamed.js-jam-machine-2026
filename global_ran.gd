extends Node

var lavel_Actual = 1
var ROOM_ACTUAL : String
var _buff_drop_fail_streak: int = 0
var _ammo_drop_fail_streak: int = 0


func register_buff_drop_result(did_drop: bool) -> void:
	if did_drop:
		_buff_drop_fail_streak = 0
		return
	_buff_drop_fail_streak += 1


func get_buff_drop_fail_streak() -> int:
	return _buff_drop_fail_streak


func register_ammo_drop_result(did_drop: bool) -> void:
	if did_drop:
		_ammo_drop_fail_streak = 0
		return
	_ammo_drop_fail_streak += 1


func get_ammo_drop_fail_streak() -> int:
	return _ammo_drop_fail_streak


func reset_run_state() -> void:
	_buff_drop_fail_streak = 0
	_ammo_drop_fail_streak = 0
