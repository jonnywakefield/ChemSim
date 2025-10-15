extends UnitProcess

# This function overrides the parent's logic with a simple conversion.
func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return []

	# Create a copy of the input stream to modify
	var stream = input_streams[0].replicate()
	
	# Check if there is any Methanol in the stream to convert
	if stream.composition.has("Methanol"):
		var methanol_amount = stream.composition["Methanol"]
		
		# If there is methanol, consume all of it
		if methanol_amount > 0:
			stream.composition["Methanol"] = 0.0
			
			# Ensure the "H2O" key exists in the dictionary
			if not stream.composition.has("H2O"):
				stream.composition["H2O"] = 0.0
			
			# Create an equivalent amount of Water (a simple 1:1 conversion for gameplay)
			stream.composition["H2O"] += methanol_amount
			
	# Return the stream with the modified composition
	return [stream]
