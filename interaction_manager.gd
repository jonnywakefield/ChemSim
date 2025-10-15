class_name InteractionManager
extends Node2D

enum Tool { SELECT, PIPE, BUILD, INSPECT }

signal tool_changed(new_tool: Tool)

var active_tool: Tool = Tool.SELECT:
	set(value):
		if active_tool == value: return
		active_tool = value
		
		# When tool changes, clear selection and cancel any operations
		set_selection(null)
		if pipe_builder and active_tool != Tool.PIPE:
			pipe_builder.reset_drawing()
		if build_manager and active_tool != Tool.BUILD:
			build_manager.cancel_placing()
			
		tool_changed.emit(active_tool)

var selected_object = null

@onready var connection_manager: ConnectionManager = get_node("/root/Main/ConnectionManager")
@onready var pipe_builder: PipeBuilder = get_node("/root/Main/PipeBuilder")
@onready var build_manager: BuildManager = get_node("/root/Main/BuildManager")
@onready var inspector_panel: InspectorPanel = get_node("/root/Main/CanvasLayer/InspectorPanel")


func _unhandled_input(event):
	if event.is_action_pressed("delete_object"):
		delete_selected_object()

	if event is InputEventMouseButton and event.is_pressed():
		match active_tool:
			Tool.SELECT:
				_handle_selection_click()
			Tool.PIPE:
				pipe_builder.handle_click()
			Tool.BUILD:
				pass # BuildManager handles its own clicks
			Tool.INSPECT:
				pass # UnitPort handles its own clicks

# --- MODIFIED: Now checks for pipes if no unit is found ---
func _handle_selection_click():
	var world_pos = get_global_mouse_position()
	
	# First, try to find a UnitProcess
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 4 # "placed_units" layer
	# --- FIX: The query must be configured to collide with Area2D nodes ---
	query.collide_with_areas = true
	# --------------------------------------------------------------------
	var result = space_state.intersect_point(query)
	
	if not result.is_empty():
		var clicked_unit = result[0].collider
		set_selection(clicked_unit)
		return

	# If no unit was found, try to find a Pipe
	var grid_pos = Vector2i((world_pos / connection_manager.PIPE_GRID_SIZE).floor())
	var clicked_pipe = connection_manager.get_pipe_at_grid_pos(grid_pos)
	if clicked_pipe:
		set_selection(clicked_pipe)
		return
		
	# If nothing was found, deselect
	set_selection(null)
# -------------------------------------------------------------------

func set_selection(object):
	if selected_object == object: return
	selected_object = object
	connection_manager.set_selection(selected_object)
	print("Selected: ", selected_object)

func delete_selected_object():
	if not selected_object: return

	if selected_object is UnitProcess:
		build_manager.delete_unit(selected_object)
	elif selected_object is Pipe:
		connection_manager.delete_pipe(selected_object)
	
	set_selection(null)
