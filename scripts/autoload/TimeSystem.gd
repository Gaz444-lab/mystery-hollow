extends Node
## In-game day/night clock. 1 real second ≈ 1 in-game minute at 1x speed.

const MINUTES_PER_DAY := 24.0 * 60.0

var day: int = 1
var minutes: float = 8.0 * 60.0  # start 08:00
var time_scale: float = 1.0       # game minutes per real second
var paused: bool = false
var _was_night: bool = false


func _process(delta: float) -> void:
	if paused or GameState.phase != GameState.GamePhase.PLAYING:
		return
	advance_minutes(delta * time_scale)


func reset_clock() -> void:
	day = 1
	minutes = 8.0 * 60.0
	_was_night = false
	_emit()


func advance_hours(hours: float) -> void:
	advance_minutes(hours * 60.0)


func advance_minutes(amount: float) -> void:
	minutes += amount
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
	_emit()


func get_hour() -> float:
	return minutes / 60.0


func get_clock_string() -> String:
	var h := int(get_hour()) % 24
	var m := int(minutes) % 60
	return "%02d:%02d" % [h, m]


func is_night() -> bool:
	var h := get_hour()
	return h < 6.0 or h >= 20.0


func get_sun_factor() -> float:
	## 0 = midnight, 1 = noon-ish for lighting.
	var h := get_hour()
	if h >= 6.0 and h <= 18.0:
		return sin(((h - 6.0) / 12.0) * PI)
	return 0.05


func _emit() -> void:
	EventBus.time_changed.emit(get_hour(), day)
	var night := is_night()
	if night != _was_night:
		_was_night = night
		EventBus.day_night_changed.emit(night)


func to_dict() -> Dictionary:
	return {"day": day, "minutes": minutes, "time_scale": time_scale}


func from_dict(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	minutes = float(data.get("minutes", 8 * 60))
	time_scale = float(data.get("time_scale", 1.0))
	_was_night = is_night()
	_emit()
