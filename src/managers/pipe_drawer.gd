class_name PipeDrawer
extends Node2D

@onready var connection_manager = get_parent() as ConnectionManager

var preview_permanent_path: Array[Vector2i] = []
var preview_temp_path: Array[Vector2i] = []

func _ready():
	top_level = true

func set_preview_path(permanent_path: Array[Vector2i], temp_path: Array[Vector2i]):
	preview_permanent_path = permanent_path
	preview_temp_path = temp_path
	queue_redraw()

func _draw():
	if not is_instance_valid(connection_manager): return

	# Draw permanent pipes
	for pipe in connection_manager.pipes:
		if pipe.path.size() > 1:
			for i in range(pipe.path.size() - 1):
				var p1 = Vector2(pipe.path[i]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
				var p2 = Vector2(pipe.path[i+1]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
				draw_line(p1, p2, Color.DARK_SLATE_GRAY, 5.0)

	# Draw live preview path
	var full_preview_path = preview_permanent_path + preview_temp_path
	if full_preview_path.size() > 1:
		for i in range(full_preview_path.size() - 1):
			var p1 = Vector2(full_preview_path[i]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
			var p2 = Vector2(full_preview_path[i+1]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
			draw_line(p1, p2, Color.STEEL_BLUE, 3.0)

	# Draw selection highlight
	var selected_object = connection_manager.selected_object_for_highlight
	if is_instance_valid(selected_object):
		if selected_object is UnitProcess:
			var unit_rect = selected_object.get_node("CollisionShape2D").shape.get_rect()
			draw_set_transform_matrix(selected_object.global_transform)
			draw_rect(unit_rect, Color.YELLOW, false, 2.0)
			draw_set_transform_matrix(Transform2D())
		elif selected_object is Pipe:
			var pipe_path = selected_object.path
			if pipe_path.size() > 1:
				for i in range(pipe_path.size() - 1):
					var p1 = Vector2(pipe_path[i]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
					var p2 = Vector2(pipe_path[i+1]) * connection_manager.PIPE_GRID_SIZE + Vector2.ONE * connection_manager.PIPE_GRID_SIZE / 2
					draw_line(p1, p2, Color.YELLOW, 7.0)
