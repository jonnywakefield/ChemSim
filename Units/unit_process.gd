class_name UnitProcess
extends Area2D

# --- Stores precise port-to-port connections ---
# Format: {output_port_node: input_port_node, ...}
var downstream_connections: Dictionary = {}
# Format: {input_port_node: output_port_node, ...}
var upstream_connections: Dictionary = {}

# --- Connection management functions ---
func clear_connections():
	downstream_connections.clear()
	upstream_connections.clear()

func add_connection(output_port: UnitPort, input_port: UnitPort):
	if not output_port or not input_port: return
	downstream_connections[output_port] = input_port
	
	var target_unit = input_port.parent_unit as UnitProcess
	if target_unit:
		target_unit.upstream_connections[input_port] = output_port

# --- Obstacle Registration ---
func register_self_as_obstacle():
	await get_tree().process_frame # Wait a frame to ensure global position is correct
	
	var connection_manager = get_node("/root/Main/ConnectionManager") as ConnectionManager
	if not connection_manager: return

	var grid_size = connection_manager.PIPE_GRID_SIZE
	
	var shape_node = get_node("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is RectangleShape2D:
		push_warning("UnitProcess needs a CollisionShape2D with a RectangleShape2D to register as an obstacle.")
		return
		
	var rect = shape_node.shape.get_rect()
	var transformed_rect = shape_node.global_transform * rect
	
	var start_grid = Vector2i((transformed_rect.position / grid_size).floor())
	var end_grid = Vector2i((transformed_rect.end / grid_size).floor())

	# Mark the entire unit area as solid
	for y in range(start_grid.y, end_grid.y):
		for x in range(start_grid.x, end_grid.x):
			connection_manager.set_grid_solid(Vector2i(x, y), true)
	
	# "Punch holes" for the ports so they are accessible
	for port in get_children():
		if port is UnitPort:
			var port_grid_pos = Vector2i((port.global_position / grid_size).floor())
			connection_manager.set_grid_solid(port_grid_pos, false)

# --- NEW: Unregisters the obstacle when a unit is deleted ---
func unregister_self_as_obstacle():
	var connection_manager = get_node("/root/Main/ConnectionManager") as ConnectionManager
	if not connection_manager: return

	var grid_size = connection_manager.PIPE_GRID_SIZE
	
	var shape_node = get_node("CollisionShape2D") as CollisionShape2D
	if not shape_node or not shape_node.shape is RectangleShape2D:
		return
		
	var rect = shape_node.shape.get_rect()
	var transformed_rect = shape_node.global_transform * rect
	
	var start_grid = Vector2i((transformed_rect.position / grid_size).floor())
	var end_grid = Vector2i((transformed_rect.end / grid_size).floor())

	# Un-mark the entire unit area, making it available for pathfinding again
	for y in range(start_grid.y, end_grid.y):
		for x in range(start_grid.x, end_grid.x):
			connection_manager.set_grid_solid(Vector2i(x, y), false)
# ---------------------------------------------------------------------

# --- Simulation Logic ---
func get_max_flow_rate() -> float:
	return 100.0

func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return []
	var output_stream = input_streams[0].replicate()
	return [output_stream]
