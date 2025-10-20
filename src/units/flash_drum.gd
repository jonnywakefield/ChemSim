extends UnitProcess

@export_group("Distillation Settings")
# The operating pressure of the column in Pascals (Pa). 1 atm ≈ 101325 Pa.
@export var pressure: float = 101325.0
# The number of theoretical equilibrium stages. More stages = better separation.
@export var number_of_stages: int = 1

func process_stream(input_streams: Array) -> Array[StreamData]:
	if input_streams.is_empty():
		return [] # No input, no output.

	var combined_bottoms_stream = StreamData.new()
	var current_feed_stream = input_streams[0].replicate()

	# --- Loop through each stage of the distillation ---
	for _i in range(number_of_stages):
		# --- FIX: Correctly unpack the array returned by the function ---
		var flash_results = _perform_single_flash(current_feed_stream)
		var vapor_stream = flash_results[0]
		var liquid_stream = flash_results[1]
		# -----------------------------------------------------------------
		
		# The vapor from this stage becomes the feed for the next stage.
		current_feed_stream = vapor_stream
		
		# Collect the liquid from this stage.
		for component in liquid_stream.composition:
			if not combined_bottoms_stream.composition.has(component):
				combined_bottoms_stream.composition[component] = 0.0
			combined_bottoms_stream.composition[component] += liquid_stream.composition[component]

	# The final vapor stream after all stages is the distillate (top product).
	var distillate_stream = current_feed_stream
	
	# The combined liquid streams are the bottoms product.
	# We can average the temperature, but for now, we'll just use the initial feed temp.
	combined_bottoms_stream.temperature = input_streams[0].temperature
	distillate_stream.temperature = input_streams[0].temperature
	
	# The top output port will be vapor (distillate), the bottom will be liquid (bottoms).
	return [distillate_stream, combined_bottoms_stream]


# This function contains the original flash drum logic for a single stage.
func _perform_single_flash(feed_stream: StreamData) -> Array[StreamData]:
	var feed_temperature = feed_stream.temperature
	var feed_composition = feed_stream.composition
	var total_feed_moles = feed_stream.get_total_flow()
	
	if total_feed_moles <= 0:
		return [StreamData.new(), StreamData.new()]

	# --- 1. Calculate K-values using Raoult's Law (K_i = P_sat_i / P_total) ---
	var k_values = {}
	for component in feed_composition:
		var vapor_pressure = VaporPressureCalculator.calculate_antoine_pressure(component, feed_temperature)
		if vapor_pressure < 0:
			k_values[component] = 0.0 
		else:
			k_values[component] = vapor_pressure / pressure

	# --- 2. Solve Rachford-Rice equation for Vapor Fraction (beta) ---
	var vapor_fraction = _solve_rachford_rice(feed_composition, k_values)
	vapor_fraction = clamp(vapor_fraction, 0.0, 1.0)

	# --- 3. Calculate Liquid and Vapor Compositions ---
	var liquid_stream = StreamData.new()
	var vapor_stream = StreamData.new()
	
	for component in feed_composition:
		var z = feed_composition[component] / total_feed_moles
		var k = k_values.get(component, 0.0)
		
		# Gracefully handle the denominator being zero if vapor_fraction and k are just right
		var denominator = 1.0 + vapor_fraction * (k - 1.0)
		if abs(denominator) < 1e-9:
			denominator = 1e-9 # Prevent division by zero, effectively making x very large

		var x = z / denominator
		var y = k * x
		
		var liquid_moles = x * (total_feed_moles * (1.0 - vapor_fraction))
		var vapor_moles = y * (total_feed_moles * vapor_fraction)
		
		if liquid_moles > 1e-6: # Use a small threshold to avoid floating point dust
			liquid_stream.composition[component] = liquid_moles
		if vapor_moles > 1e-6:
			vapor_stream.composition[component] = vapor_moles
			
	return [vapor_stream, liquid_stream]


# Solves the Rachford-Rice equation using a numerical method (Newton-Raphson).
func _solve_rachford_rice(feed_comp, k_values) -> float:
	var total_moles = 0.0
	for c in feed_comp: total_moles += feed_comp[c]
	if total_moles <= 0.0: return 0.0

	# Initial guess for vapor fraction (beta)
	var beta = 0.5
	var iterations = 0
	
	while iterations < 20: # Limit iterations to prevent infinite loops
		var f = 0.0
		var df = 0.0 # Derivative of f
		
		for comp in feed_comp:
			var z = feed_comp[comp] / total_moles
			var k = k_values[comp]
			var denominator = 1.0 + beta * (k - 1.0)
			
			if abs(denominator) < 1e-9: continue # Avoid division by zero
			
			f += z * (k - 1.0) / denominator
			df -= z * (k - 1.0) * (k - 1.0) / (denominator * denominator)

		if abs(df) < 1e-9: break # Avoid division by zero if derivative is flat
		
		var beta_new = beta - f / df
		
		# Clamp beta to a reasonable range to prevent divergence
		beta_new = clamp(beta_new, -0.5, 1.5)
		
		if abs(beta_new - beta) < 1e-6:
			return beta_new # Converged
		
		beta = beta_new
		iterations += 1
		
	return beta # Return the best guess if it didn't converge
