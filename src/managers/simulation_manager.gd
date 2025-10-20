extends Node

var tick_timer: Timer

# This will hold the reference to the ConnectionManager node from the scene.
var connection_manager: ConnectionManager = null

func _ready():
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.timeout.connect(solve_entire_factory)
	add_child(tick_timer)
	
	# Wait until the scene tree is fully loaded before we do anything else.
	get_tree().root.ready.connect(func():
		# Get the essential reference to the ConnectionManager.
		connection_manager = get_tree().root.get_node("Main/ConnectionManager")
		
		# Now that we have the reference and the scene is ready,
		# it is safe to start the simulation timer.
		if is_instance_valid(connection_manager):
			tick_timer.start()
		else:
			push_error("SimulationManager could not find ConnectionManager. Simulation will not start.")
	, CONNECT_ONE_SHOT)


func solve_entire_factory():
	# Guard clause in case the scene hasn't loaded or the node isn't found
	if not is_instance_valid(connection_manager):
		print("SIM ERROR: ConnectionManager node not found. Skipping tick.")
		return

	# --- Wipe all old data before each run ---
	# This is inefficient. We'll fix this later, but for now it works.
	var all_ports = get_tree().get_nodes_in_group("all_ports")
	for port in all_ports:
		if port is UnitPort:
			port.current_stream = null
			
	# --- PHASE 1: Build the logical DAG from the physical pipe network ---
	_build_dag_from_pipes()
	
	# --- PHASE 2: Solve the newly built DAG ---
	var input_cache = {}
	var source_nodes = get_tree().get_nodes_in_group("source_units")
	
	print("\n--- SIMULATION TICK ---")
	if source_nodes.is_empty():
		print("SIM: No source units found.")
		print("--- TICK COMPLETE ---\n")
		return

	print("SIM: Found ", source_nodes.size(), " source unit(s).")
	
	for source_unit in source_nodes:
		_start_propagation_from(source_unit, input_cache)
	
	print("--- TICK COMPLETE ---\n")

func _build_dag_from_pipes():
	var all_units = get_tree().get_nodes_in_group("all_units")

	# Reset all connections from the previous tick
	for unit in all_units:
		if unit is UnitProcess:
			unit.clear_connections()
	
	# Create logical connections based on the physical pipes
	for pipe in connection_manager.pipes:
		if pipe.start_port and pipe.end_port:
			var source_unit = pipe.start_port.parent_unit as UnitProcess
			if source_unit:
				source_unit.add_connection(pipe.start_port, pipe.end_port)

# --- The rest of the functions below this line do not need to be changed ---

func _start_propagation_from(source_unit: UnitProcess, input_cache: Dictionary):
	print("SIM: Starting propagation from '", source_unit.name, "'")
	var initial_stream_array = source_unit.process_stream([])
	if initial_stream_array.is_empty():
		print("SIM ERROR: Source unit '", source_unit.name, "' produced no initial stream.")
		return
	_handle_outputs(source_unit, initial_stream_array, input_cache)

func _handle_outputs(solved_unit: UnitProcess, output_streams: Array, input_cache: Dictionary):
	var output_ports = _get_ports(solved_unit, UnitPort.PortType.OUTPUT)
	
	if output_streams.size() != output_ports.size():
		print("SIM WARNING: Unit '", solved_unit.name, "' produced ", output_streams.size(), " stream(s) but has ", output_ports.size(), " output port(s).")

	for i in range(min(output_streams.size(), output_ports.size())):
		var source_port = output_ports[i]
		var stream_to_send = output_streams[i]
		
		source_port.current_stream = stream_to_send
		
		if solved_unit.downstream_connections.has(source_port):
			var target_port = solved_unit.downstream_connections[source_port]
			if is_instance_valid(target_port):
				_propagate_to_next(target_port, stream_to_send, input_cache)

func _propagate_to_next(target_port: UnitPort, stream: StreamData, input_cache: Dictionary):
	var target_unit = target_port.parent_unit as UnitProcess
	if not target_unit: return

	print("SIM: Propagating stream to '", target_unit.name, "' via port '", target_port.name, "'")
	
	target_port.current_stream = stream

	if not input_cache.has(target_unit):
		input_cache[target_unit] = {}
	input_cache[target_unit][target_port] = stream

	var required_inputs = target_unit.upstream_connections.size()
	
	if input_cache[target_unit].size() < required_inputs:
		print("SIM: '", target_unit.name, "' is waiting for more inputs (", input_cache[target_unit].size(), "/", required_inputs, ")")
		return

	print("SIM: '", target_unit.name, "' has all inputs, running process...")
	var sorted_input_ports = _get_ports(target_unit, UnitPort.PortType.INPUT)
	var ordered_streams = []
	for port in sorted_input_ports:
		if input_cache[target_unit].has(port):
			ordered_streams.append(input_cache[target_unit][port])
	
	var resulting_streams = target_unit.process_stream(ordered_streams)
	if not resulting_streams.is_empty():
		_handle_outputs(target_unit, resulting_streams, input_cache)

func _get_ports(unit: Node, type: UnitPort.PortType) -> Array:
	var ports = []
	for child in unit.get_children():
		if child is UnitPort and child.type == type and child.is_visible_in_tree():
			ports.append(child)
	ports.sort_custom(func(a,b): return a.name < b.name)
	return ports
