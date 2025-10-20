extends UnitProcess

@export_group("Stream Configuration")
# This dictionary allows you to define a mixture. 
# In the Inspector, you can add key-value pairs.
# Keys should be chemical names (String) from your JSON file, and values their flow rates (float, mol/s).
@export var molar_flows: Dictionary = {"Water": 0.5, "Nitrogen": 0.5}
@export var temperature: float = 298.15    # The temperature of the stream in Kelvin.


func process_stream(_input_streams: Array) -> Array[StreamData]:
	var new_stream = StreamData.new()
	var final_composition = {}
	
	# Validate each chemical in the dictionary to ensure it exists and has a valid flow rate.
	for chemical_name in molar_flows:
		var flow_rate = molar_flows[chemical_name]
		
		# Ensure the flow rate is a valid number and greater than zero.
		if not typeof(flow_rate) in [TYPE_INT, TYPE_FLOAT] or flow_rate <= 0:
			push_warning("Source unit '" + self.name + "' has an invalid flow rate for '" + chemical_name + "'. Skipping this component.")
			continue

		# Check that the chemical actually exists in the database.
		if ChemicalDatabase.get_chemical_data(chemical_name).is_empty():
			push_warning("Source unit '" + self.name + "' is configured with an unknown chemical: '" + chemical_name + "'. Skipping this component.")
			continue
		
		# If valid, add it to our final composition for the stream.
		final_composition[chemical_name] = flow_rate

	# If no valid chemicals were found after checking, return an empty stream to prevent errors downstream.
	if final_composition.is_empty():
		push_warning("Source unit '" + self.name + "' has no valid components defined. Outputting an empty stream.")
		return []

	new_stream.composition = final_composition
	new_stream.temperature = temperature
	
	return [new_stream]
