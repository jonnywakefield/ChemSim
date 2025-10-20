class_name Mixer
extends UnitProcess


func process_stream(input_streams: Array) -> Array[StreamData]:
	# This is where you would write mixing logic (e.g., combining flows).
	# For now, we'll just merge the first two streams.
	if input_streams.size() < 2:
		return []
	
	var stream_a = input_streams[0]
	var stream_b = input_streams[1]
	
	var mixed_stream = stream_a.replicate()
	for chemical in stream_b.composition:
		if mixed_stream.composition.has(chemical):
			mixed_stream.composition[chemical] += stream_b.composition[chemical]
		else:
			mixed_stream.composition[chemical] = stream_b.composition[chemical]
	
	return [mixed_stream]
