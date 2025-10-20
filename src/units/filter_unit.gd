extends UnitProcess

# This function is specific to the Filter. It overrides the parent's version.
func get_optimal_flow_rate() -> float:
	# Filters are fast but affected by processing speed differently.
	return 150.0

# _ready is called when the node enters the scene.
func _ready():
	# You can call functions from the parent or just add new logic.
	print("A Filter Unit has been initialized!")
