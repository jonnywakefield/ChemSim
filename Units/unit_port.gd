class_name UnitPort
extends Area2D

var current_stream: StreamData = null

enum PortType { INPUT, OUTPUT }
@export var type: PortType = PortType.INPUT

@export var exit_direction: Vector2i = Vector2i.RIGHT

var parent_unit: Node2D

# --- References to other manager nodes ---
@onready var inspector_panel = get_node("/root/Main/CanvasLayer/InspectorPanel")
# --- FIX: Added reference to InteractionManager ---
@onready var interaction_manager: InteractionManager = get_node("/root/Main/InteractionManager")
# ----------------------------------------------

func _ready():
	parent_unit = get_parent()
	# Connect to self's input_event signal
	self.input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		
		# --- FIX: Check against InteractionManager for the active tool ---
		if interaction_manager and interaction_manager.active_tool == InteractionManager.Tool.INSPECT:
			if inspector_panel:
				inspector_panel.show_on_port(self)
			else:
				push_warning("Inspector panel not found on UnitPort. Check the node path.")
		# -------------------------------------------------------------
