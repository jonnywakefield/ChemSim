class_name DistillationProcess
extends UnitProcess


# This function separates the incoming stream into two products.
func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return []

	var input_stream = input_streams[0]
	
	var overhead_product = StreamData.new() # For lighter components
	var bottoms_product = StreamData.new()  # For heavier components
	
	for chemical in input_stream.composition:
		var flow = input_stream.composition[chemical]
		if flow <= 0:
			continue
			
		# Simple logic: Methanol goes up, everything else goes down.
		if chemical == "Methanol":
			overhead_product.composition[chemical] = flow
		else:
			bottoms_product.composition[chemical] = flow
	
	return [overhead_product, bottoms_product]
