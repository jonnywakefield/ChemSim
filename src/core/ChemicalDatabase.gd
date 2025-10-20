extends Node

var _chemical_data: Dictionary = {}

func _ready():
	_load_chemical_data()

func _load_chemical_data():
	var file_path = "res://data/chemicals.json"
	
	# 1. Check for file existence first.
	if not FileAccess.file_exists(file_path):
		push_error("ChemicalDatabase Error: File not found at 'res://data/chemicals.json'. Make sure the file exists and the path is correct.")
		return

	# 2. Open and read the file.
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("ChemicalDatabase Error: Could not open file. Error code: " + str(FileAccess.get_open_error()))
		return
		
	var content = file.get_as_text()
	file.close()

	# 3. Parse the JSON content.
	var parsed_result = JSON.parse_string(content)
	if parsed_result == null:
		push_error("ChemicalDatabase Error: Failed to parse JSON. The content of 'chemicals.json' is likely invalid.")
		return

	# 4. Validate the top-level structure.
	if not typeof(parsed_result) == TYPE_DICTIONARY or not parsed_result.has("chemicals"):
		push_error("ChemicalDatabase Error: JSON root must be a dictionary with a 'chemicals' array.")
		return
	
	# 5. Validate the 'chemicals' array.
	var chemicals_array = parsed_result["chemicals"]
	if not typeof(chemicals_array) == TYPE_ARRAY:
		push_error("ChemicalDatabase Error: The 'chemicals' key in your JSON does not contain an array.")
		return
		
	# 6. Populate the internal dictionary.
	for entry in chemicals_array:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("name"):
			var chemical_name = entry["name"]
			_chemical_data[chemical_name] = entry
		else:
			push_warning("ChemicalDatabase Warning: Skipping an invalid entry in the chemicals array.")
			
	if _chemical_data.is_empty():
		push_warning("ChemicalDatabase Warning: Database loaded, but no valid chemical entries were found.")
	else:
		print("ChemicalDatabase: Successfully loaded ", _chemical_data.size(), " chemicals.")

# Public accessor function.
func get_chemical_data(chemical_name: String) -> Dictionary:
	return _chemical_data.get(chemical_name, {})
