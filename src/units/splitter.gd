class_name Splitter
extends UnitProcess

# The splitter's process function is simple: it just prepares its single input
# to be divided and sent to its multiple outputs by the SimulationManager.
func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return []
	
	# The number of connected outputs determines the split ratio.
	var connected_outputs = downstream_connections.size()
	if connected_outputs == 0:
		return [] # No outputs connected, so nothing flows.

	var input_stream = input_streams[0]
	var split_streams: Array[StreamData] = []
	
	for _i in range(connected_outputs):
		var split_stream = input_stream.replicate()
		# Divide the flow of each component by the number of outputs.
		for chemical in split_stream.composition:
			split_stream.composition[chemical] /= connected_outputs
		split_streams.append(split_stream)
		
	return split_streams
