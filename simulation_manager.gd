extends Node

var tick_timer: Timer

func _ready():
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.timeout.connect(solve_entire_factory)
	add_child(tick_timer)
	tick_timer.start()

func solve_entire_factory():
	# --- Wipe all old data before each run ---
	for port in get_tree().get_nodes_in_group("all_ports"):
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

# --- REWRITTEN: Builds a port-to-port connection graph ---
func _build_dag_from_pipes():
	var all_units = get_tree().get_nodes_in_group("all_units")
	var connection_manager = get_node("/root/Main/ConnectionManager") as ConnectionManager
	
	if not connection_manager:
		print("SIM ERROR: ConnectionManager node not found.")
		return
	
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
# -----------------------------------------------------------

func _start_propagation_from(source_unit: UnitProcess, input_cache: Dictionary):
	print("SIM: Starting propagation from '", source_unit.name, "'")
	var initial_stream_array = source_unit.process_stream([])
	if initial_stream_array.is_empty():
		print("SIM ERROR: Source unit '", source_unit.name, "' produced no initial stream.")
		return
	_handle_outputs(source_unit, initial_stream_array, input_cache)

# --- REWRITTEN: Uses the port-to-port connection data ---
func _handle_outputs(solved_unit: UnitProcess, output_streams: Array, input_cache: Dictionary):
	var output_ports = _get_ports(solved_unit, UnitPort.PortType.OUTPUT)
	
	# Make sure the number of output streams matches the number of output ports
	if output_streams.size() != output_ports.size():
		print("SIM WARNING: Unit '", solved_unit.name, "' produced ", output_streams.size(), " stream(s) but has ", output_ports.size(), " output port(s).")

	for i in range(min(output_streams.size(), output_ports.size())):
		var source_port = output_ports[i]
		var stream_to_send = output_streams[i]
		
		# Store data on the source port for inspection
		source_port.current_stream = stream_to_send
		
		# Find the connected input port and propagate
		if solved_unit.downstream_connections.has(source_port):
			var target_port = solved_unit.downstream_connections[source_port]
			if is_instance_valid(target_port):
				_propagate_to_next(target_port, stream_to_send, input_cache)
# -------------------------------------------------------------

# --- REWRITTEN: Now receives the specific target port ---
func _propagate_to_next(target_port: UnitPort, stream: StreamData, input_cache: Dictionary):
	var target_unit = target_port.parent_unit as UnitProcess
	if not target_unit: return

	print("SIM: Propagating stream to '", target_unit.name, "' via port '", target_port.name, "'")
	
	# Store data on the target port for inspection
	target_port.current_stream = stream

	# Cache the input for the unit's calculation
	if not input_cache.has(target_unit):
		input_cache[target_unit] = {} # Use a dictionary to store inputs per port
	input_cache[target_unit][target_port] = stream

	# Check if the unit has all its required inputs to run
	var required_inputs = target_unit.upstream_connections.size()
	
	if input_cache[target_unit].size() < required_inputs:
		print("SIM: '", target_unit.name, "' is waiting for more inputs (", input_cache[target_unit].size(), "/", required_inputs, ")")
		return

	# If ready, gather streams in the correct order and process
	print("SIM: '", target_unit.name, "' has all inputs, running process...")
	var sorted_input_ports = _get_ports(target_unit, UnitPort.PortType.INPUT)
	var ordered_streams = []
	for port in sorted_input_ports:
		if input_cache[target_unit].has(port):
			ordered_streams.append(input_cache[target_unit][port])
	
	var resulting_streams = target_unit.process_stream(ordered_streams)
	if not resulting_streams.is_empty():
		_handle_outputs(target_unit, resulting_streams, input_cache)
# ---------------------------------------------------------

# Helper to find and sort ports on a unit
func _get_ports(unit: Node, type: UnitPort.PortType) -> Array:
	var ports = []
	for child in unit.get_children():
		if child is UnitPort and child.type == type and child.is_visible_in_tree():
			ports.append(child)
	ports.sort_custom(func(a,b): return a.name < b.name)
	return ports
