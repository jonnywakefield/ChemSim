class_name InteractionManager
extends Node2D

enum Tool { SELECT, PIPE, BUILD, INSPECT }

signal tool_changed(new_tool: Tool)
signal port_inspect_requested(port: UnitPort)

# Get direct references to sibling manager nodes. This is the correct pattern.
@onready var connection_manager: ConnectionManager = get_node("../ConnectionManager")
@onready var pipe_builder: PipeBuilder = get_node("../PipeBuilder")
@onready var build_manager: BuildManager = get_node("../BuildManager")

var active_tool: Tool = Tool.SELECT:
	set(value):
		if active_tool == value: return
		active_tool = value
		set_selection(null)
		if active_tool != Tool.PIPE:
			pipe_builder.reset_drawing()
		if active_tool != Tool.BUILD:
			build_manager.cancel_placing()
		tool_changed.emit(active_tool)

var selected_object = null

func _unhandled_input(event):
	if event.is_action_pressed("delete_object"):
		delete_selected_object()

	if event is InputEventMouseButton and event.is_pressed():
		match active_tool:
			Tool.SELECT: _handle_selection_click()
			Tool.PIPE: pipe_builder.handle_click()
			Tool.BUILD: pass
			Tool.INSPECT: pass

func _handle_selection_click():
	var world_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 4
	query.collide_with_areas = true
	var result = space_state.intersect_point(query)
	
	if not result.is_empty():
		set_selection(result[0].collider)
		return

	var grid_pos = Vector2i(world_pos / connection_manager.PIPE_GRID_SIZE)
	var clicked_pipe = connection_manager.get_pipe_at_grid_pos(grid_pos)
	if clicked_pipe:
		set_selection(clicked_pipe)
		return
	
	set_selection(null)

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
