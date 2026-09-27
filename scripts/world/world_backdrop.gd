extends Control
class_name WorldBackdrop


var _time: float = 0.0
var _altitude_m: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not GameManager.altitude_changed.is_connected(
		_on_altitude_changed
	):
		GameManager.altitude_changed.connect(
			_on_altitude_changed
		)

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_altitude_changed(value: float) -> void:
	_altitude_m = value


func _draw() -> void:
	var size := get_viewport_rect().size

	if size.x <= 0.0 or size.y <= 0.0:
		return

	_draw_sky(size)
	_draw_far_clouds(size)
	_draw_distant_islands(size)
	_draw_near_clouds(size)


func _draw_sky(size: Vector2) -> void:
	var zone_progress := clampf(
		_altitude_m / 300.0,
		0.0,
		1.0
	)

	var sky_top := Color("178ee0").lerp(
		Color("55b9ee"),
		zone_progress
	)

	var sky_bottom := Color("c8efff").lerp(
		Color("edfaff"),
		zone_progress
	)

	var bands := 14

	for i in range(bands):
		var t := float(i) / float(bands - 1)

		var color := sky_top.lerp(
			sky_bottom,
			t
		)

		var y := (
			size.y
			* float(i)
			/ float(bands)
		)

		draw_rect(
			Rect2(
				0.0,
				y,
				size.x,
				size.y / float(bands) + 3.0
			),
			color
		)


func _draw_far_clouds(size: Vector2) -> void:
	var movement := _altitude_m * 3.0

	var positions := [
		Vector2(
			size.x * 0.18,
			_wrap_y(
				size.y * 0.16 + movement,
				size.y,
				180.0
			)
		),
		Vector2(
			size.x * 0.76,
			_wrap_y(
				size.y * 0.43 + movement,
				size.y,
				180.0
			)
		),
		Vector2(
			size.x * 0.38,
			_wrap_y(
				size.y * 0.78 + movement,
				size.y,
				180.0
			)
		),
	]

	for i in range(positions.size()):
		var drift := sin(
			_time * 0.10 + float(i)
		) * 18.0

		var position := positions[i]
		position.x += drift

		_draw_cloud(
			position,
			0.65,
			Color(
				1.0,
				1.0,
				1.0,
				0.42
			)
		)


func _draw_near_clouds(size: Vector2) -> void:
	var movement := _altitude_m * 7.0

	var positions := [
		Vector2(
			size.x * 0.12,
			_wrap_y(
				size.y * 0.30 + movement,
				size.y,
				220.0
			)
		),
		Vector2(
			size.x * 0.82,
			_wrap_y(
				size.y * 0.62 + movement,
				size.y,
				220.0
			)
		),
		Vector2(
			size.x * 0.48,
			_wrap_y(
				size.y * 0.95 + movement,
				size.y,
				220.0
			)
		),
	]

	for i in range(positions.size()):
		var drift := sin(
			_time * 0.16
			+ float(i) * 1.7
		) * 26.0

		var position := positions[i]
		position.x += drift

		_draw_cloud(
			position,
			1.0,
			Color(
				1.0,
				1.0,
				1.0,
				0.72
			)
		)


func _draw_distant_islands(size: Vector2) -> void:
	var movement := _altitude_m * 5.0

	var island_y := _wrap_y(
		size.y * 0.72 + movement,
		size.y,
		280.0
	)

	var center := Vector2(
		size.x * 0.72,
		island_y
	)

	_draw_island(
		center,
		0.8
	)


func _draw_cloud(
	center: Vector2,
	scale_value: float,
	color: Color
) -> void:
	draw_circle(
		center + Vector2(-48, 8) * scale_value,
		34.0 * scale_value,
		color
	)

	draw_circle(
		center + Vector2(-12, -8) * scale_value,
		45.0 * scale_value,
		color
	)

	draw_circle(
		center + Vector2(34, 5) * scale_value,
		36.0 * scale_value,
		color
	)

	draw_rect(
		Rect2(
			center
			+ Vector2(-70, 5)
			* scale_value,
			Vector2(140, 35)
			* scale_value
		),
		color
	)


func _draw_island(
	center: Vector2,
	scale_value: float
) -> void:
	var grass := Color(
		0.25,
		0.65,
		0.32,
		0.36
	)

	var rock := Color(
		0.28,
		0.36,
		0.42,
		0.30
	)

	draw_ellipse(
		center,
		Vector2(
			110,
			32
		) * scale_value,
		grass
	)

	var points := PackedVector2Array([
		center
		+ Vector2(-90, 10)
		* scale_value,

		center
		+ Vector2(90, 10)
		* scale_value,

		center
		+ Vector2(35, 110)
		* scale_value,

		center
		+ Vector2(-20, 145)
		* scale_value,

		center
		+ Vector2(-55, 90)
		* scale_value,
	])

	draw_colored_polygon(
		points,
		rock
	)


func draw_ellipse(
	center: Vector2,
	radius: Vector2,
	color: Color
) -> void:
	var points := PackedVector2Array()
	var segments := 32

	for i in range(segments):
		var angle := (
			TAU
			* float(i)
			/ float(segments)
		)

		points.append(
			center
			+ Vector2(
				cos(angle) * radius.x,
				sin(angle) * radius.y
			)
		)

	draw_colored_polygon(
		points,
		color
	)


func _wrap_y(
	value: float,
	screen_height: float,
	margin: float
) -> float:
	return (
		fposmod(
			value + margin,
			screen_height + margin * 2.0
		)
		- margin
	)
