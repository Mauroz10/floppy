extends Control
class_name WorldBackdrop

var _time: float = 0.0

func _ready() -> void:
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var bands := 12
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var color := Color(0.12, 0.55, 0.92).lerp(Color(0.78, 0.93, 1.0), t)
		var y := size.y * float(i) / float(bands)
		draw_rect(Rect2(0.0, y, size.x, size.y / float(bands) + 2.0), color)
	_draw_cloud(size * Vector2(0.22, 0.2) + Vector2(sin(_time * 0.12) * 28.0, 0.0), 1.0)
	_draw_cloud(size * Vector2(0.78, 0.34) + Vector2(sin(_time * 0.08 + 2.0) * 36.0, 0.0), 0.8)
	_draw_cloud(size * Vector2(0.4, 0.7) + Vector2(sin(_time * 0.1 + 4.0) * 22.0, 0.0), 0.65)

func _draw_cloud(center: Vector2, scale_value: float) -> void:
	var c := Color(1.0, 1.0, 1.0, 0.72)
	draw_circle(center + Vector2(-48, 8) * scale_value, 34.0 * scale_value, c)
	draw_circle(center + Vector2(-12, -8) * scale_value, 45.0 * scale_value, c)
	draw_circle(center + Vector2(34, 5) * scale_value, 36.0 * scale_value, c)
	draw_rect(Rect2(center + Vector2(-70, 5) * scale_value, Vector2(140, 35) * scale_value), c)
