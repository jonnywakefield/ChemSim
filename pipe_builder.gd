class_name PipeBuilder
extends Node2D

enum State { IDLE, DRAWING_PIPE }
var current_state = State.IDLE

var full_pipe_path: Array[Vector2i] = []
var current_preview_path: Array[Vector2i] = []
var start_port: UnitPort = null

@onready var connection_manager = get_node("/root/Main/ConnectionManager") as ConnectionManager

func _process(_delta):
	if current_state == State.DRAWING_PIPE:
		_update_path_preview()

func handle_click():
	var mouse_grid_pos = Vector2i(get_global_mouse_position() / connection_manager.PIPE_GRID_SIZE)
	if not connection_manager.is_in_bounds(mouse_grid_pos.x, mouse_grid_pos.y): return

	var clicked_port = connection_manager.get_port_at_grid_pos(mouse_grid_pos)

	if current_state == State.IDLE:
		if clicked_port and clicked_port.type == UnitPort.PortType.OUTPUT:
			start_port = clicked_port
			var start_pos = Vector2i((start_port.global_position / connection_manager.PIPE_GRID_SIZE).floor())
			var entry_pos = start_pos + start_port.exit_direction
			
			if not connection_manager.is_in_bounds(entry_pos.x, entry_pos.y) or connection_manager.is_grid_solid(entry_pos):
				print("Pipe entry point is blocked!")
				return
			
			full_pipe_path.append(start_pos)
			full_pipe_path.append(entry_pos)
			current_state = State.DRAWING_PIPE
	
	elif current_state == State.DRAWING_PIPE:
		if clicked_port and clicked_port.type == UnitPort.PortType.INPUT and clicked_port.parent_unit != start_port.parent_unit:
			_finalize_pipe(clicked_port)
		elif not clicked_port:
			_add_waypoint(mouse_grid_pos)

func _update_path_preview():
	if full_pipe_path.is_empty(): return
	
	var start_pos = full_pipe_path.back()
	var end_pos = Vector2i(get_global_mouse_position() / connection_manager.PIPE_GRID_SIZE)
	
	if not connection_manager.is_in_bounds(end_pos.x, end_pos.y): return
	
	current_preview_path = connection_manager.find_path(start_pos, end_pos)
	connection_manager.set_preview_path(full_pipe_path, current_preview_path)

func _finalize_pipe(end_port: UnitPort):
	var final_path_segment = connection_manager.find_path(full_pipe_path.back(), Vector2i((end_port.global_position / connection_manager.PIPE_GRID_SIZE).floor()))
	if not final_path_segment.is_empty():
		full_pipe_path.append_array(final_path_segment)
		
		var new_pipe = Pipe.new()
		new_pipe.path = full_pipe_path.duplicate(true)
		new_pipe.start_port = start_port
		new_pipe.end_port = end_port
		
		if connection_manager.add_pipe(new_pipe):
			print("Pipe created successfully!")
		else:
			print("Pipe creation failed: Overlapping segments.")
	
	reset_drawing()

func _add_waypoint(grid_pos: Vector2i):
	var path_segment = connection_manager.find_path(full_pipe_path.back(), grid_pos)
	if not path_segment.is_empty():
		# Check for overlaps before adding the segment
		if not connection_manager.check_for_overlaps(path_segment):
			full_pipe_path.append_array(path_segment)
		else:
			print("Cannot place waypoint: Path would overlap.")

func reset_drawing():
	current_state = State.IDLE
	full_pipe_path.clear()
	current_preview_path.clear()
	start_port = null
	# --- FIX: Use the correct function to clear the drawing preview ---
	connection_manager.set_preview_path([], [])
	# ----------------------------------------------------------------
