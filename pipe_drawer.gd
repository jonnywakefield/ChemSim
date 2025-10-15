extends Node2D

var preview_path: Array[Vector2i] = []
var permanent_paths: Array = []

const PIPE_GRID_SIZE = 32

func _ready():
	# This forces the node to ignore its parents' transforms,
	# guaranteeing its coordinate space is the same as the world's.
	top_level = true

func _draw():
	# Draw all permanent, finalized pipe paths
	for path in permanent_paths:
		if path.size() > 1:
			for i in range(path.size() - 1):
				var point_a = Vector2(path[i] * PIPE_GRID_SIZE) + Vector2(PIPE_GRID_SIZE / 2, PIPE_GRID_SIZE / 2)
				var point_b = Vector2(path[i+1] * PIPE_GRID_SIZE) + Vector2(PIPE_GRID_SIZE / 2, PIPE_GRID_SIZE / 2)
				draw_line(point_a, point_b, Color.GRAY, 5.0)

	# Draw the live preview path
	if preview_path.size() > 1:
		for i in range(preview_path.size() - 1):
			var point_a = Vector2(preview_path[i] * PIPE_GRID_SIZE) + Vector2(PIPE_GRID_SIZE / 2, PIPE_GRID_SIZE / 2)
			var point_b = Vector2(preview_path[i+1] * PIPE_GRID_SIZE) + Vector2(PIPE_GRID_SIZE / 2, PIPE_GRID_SIZE / 2)
			draw_line(point_a, point_b, Color.WHITE, 3.0)

# Public functions for the ConnectionManager to call
func update_preview(path: Array[Vector2i]):
	preview_path = path
	queue_redraw()

func add_permanent_path(path: Array[Vector2i]):
	if not path.is_empty():
		permanent_paths.append(path.duplicate(true))
	queue_redraw()

func clear_preview():
	preview_path.clear()
	queue_redraw()
