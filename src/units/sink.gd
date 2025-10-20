extends UnitProcess

func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return []

	var final_stream = input_streams[0]
	
	if final_stream.composition.has("Methylamine"):
		var product_flow = final_stream.composition["Methylamine"]
		
		# Calculate total flow by summing components
		var total_flow = 0.0
		for chemical in final_stream.composition:
			total_flow += final_stream.composition[chemical]
			
		var purity = 0.0
		if total_flow > 0:
			purity = product_flow / total_flow
		
		var base_price = 50.0 
		var profit = product_flow * purity * base_price
		
		print("Sold ", product_flow, " mol/s of product at ", purity * 100, "% purity for $", profit)
	
	return []
