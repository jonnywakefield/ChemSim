class_name VaporPressureCalculator

# Calculates the vapor pressure of a substance at a given temperature.
static func calculate_antoine_pressure(chemical_name: String, temperature_k: float) -> float:
	var chemical_data = ChemicalDatabase.get_chemical_data(chemical_name)
	
	if chemical_data.is_empty():
		push_warning("Chemical data not found for: " + chemical_name)
		return -1.0

	# The Antoine equation typically uses Temperature in Celsius.
	var temperature_c = temperature_k - 273.15

	# --- FIX: Handle non-condensable gases ---
	# Check if the substance has a boiling point defined.
	if chemical_data.has("normal_boiling_point_c"):
		var boiling_point_c = chemical_data["normal_boiling_point_c"]
		# If we are above the boiling point, it's a gas. Antoine is not applicable.
		# Return a very large pressure to ensure its K-value is >> 1.
		if temperature_c > boiling_point_c:
			return 1e10 # A large number in Pascals.
	# ----------------------------------------

	# If it's not a gas, proceed with Antoine calculation for liquids.
	if not chemical_data.has("antoine_coefficients"):
		push_warning("Antoine coefficients not found for chemical: " + chemical_name)
		return -1.0 # Return an invalid pressure.

	var antoine = chemical_data["antoine_coefficients"]
	if not antoine.has("A") or not antoine.has("B") or not antoine.has("C"):
		push_warning("Incomplete Antoine coefficients for chemical: " + chemical_name)
		return -1.0

	var A = antoine["A"]
	var B = antoine["B"]
	var C = antoine["C"]
	
	# Prevent division by zero if T is exactly -C.
	if abs(C + temperature_c) < 1e-9:
		return -1.0

	# Calculate log10 of the pressure in mmHg.
	var log_p = A - (B / (C + temperature_c))
	
	# Convert from mmHg to Pascals (Pa) for consistency.
	var pressure_mmhg = pow(10, log_p)
	var pressure_pa = pressure_mmhg * 133.322
	
	return pressure_pa
