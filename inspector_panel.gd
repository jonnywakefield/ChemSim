class_name InspectorPanel
extends PanelContainer

@onready var data_label: Label = $MarginContainer/VBoxContainer/DataLabel

func _ready():
	hide()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and is_visible():
		hide()
		get_viewport().set_input_as_handled()

func show_on_port(port: UnitPort):
	var text = "Inspecting Port: " + port.name + "\n"
	text += "Path: " + str(port.get_path()) + "\n\n"

	if port.current_stream:
		text += "Status: Data Found\n\n"
		
		var total_flow = port.current_stream.get_total_flow()

		text += "Flow Rate: " + str(snapped(total_flow, 0.01)) + " mol/s\n"
		text += "Temperature: " + str(snapped(port.current_stream.temperature, 0.1)) + " K\n"
		text += "Pressure: " + port.current_stream.pressure_state + "\n\n"
		text += "Composition:\n"
		
		if port.current_stream.composition.is_empty():
			text += "- Empty"
		else:
			for chemical in port.current_stream.composition:
				var amount = port.current_stream.composition[chemical]
				text += "- " + chemical + ": " + str(snapped(amount, 0.01)) + "\n"
	else:
		text += "Status: No Stream Data Present"
	
	data_label.text = text
	show()

# --- NEW: Function to be connected to the close button's signal ---
func _on_button_close_pressed():
	hide()
# ---------------------------------------------------------------
