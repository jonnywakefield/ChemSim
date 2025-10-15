class_name StreamData
extends Resource

var composition: Dictionary = {}
var temperature: float = 298.15
var pressure_state: String = "Low"

# --- NEW: Calculates total flow on the fly ---
func get_total_flow() -> float:
	var total = 0.0
	for component_flow in composition.values():
		total += component_flow
	return total

# --- NEW: Scales composition to a new total flow ---
func set_total_flow(new_total_flow: float):
	var current_total_flow = get_total_flow()
	if current_total_flow == 0:
		# Cannot scale from zero, this case should be handled by the source block.
		# For now, we'll just print a warning.
		if new_total_flow > 0:
			print("Warning: Attempted to set flow on a stream with no initial composition.")
		return

	var scale_factor = new_total_flow / current_total_flow
	for component in composition:
		composition[component] *= scale_factor

func replicate() -> Resource:
	var new_stream = StreamData.new()
	new_stream.composition = self.composition.duplicate(true)
	new_stream.temperature = self.temperature
	new_stream.pressure_state = self.pressure_state
	return new_stream
