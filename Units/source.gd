extends UnitProcess

@export_group("Initial Stream")
@export var molar_flows: Dictionary = {"Methanol": 0.5, "H2O": 0.5}
@export var temperature: float = 25.0

func process_stream(_input_streams: Array) -> Array[StreamData]:
	var new_stream = StreamData.new()
	
	# The dictionary now directly represents the molar flow of each component.
	# No calculation is needed; we just copy the dictionary.
	new_stream.composition = molar_flows.duplicate(true)
	new_stream.temperature = temperature
	
	return [new_stream]
