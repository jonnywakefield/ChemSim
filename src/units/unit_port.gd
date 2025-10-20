class_name UnitPort
extends Area2D

var current_stream: StreamData = null

enum PortType { INPUT, OUTPUT }
@export var type: PortType = PortType.INPUT
@export var exit_direction: Vector2i = Vector2i.RIGHT

var parent_unit: Node2D

# This will hold the reference to the actual InteractionManager node in the scene.
var interaction_manager: InteractionManager

func _ready():
	parent_unit = get_parent()
	self.input_event.connect(_on_input_event)
	
	# This is the fix: Get the InteractionManager node from the scene tree.
	# This is robust and will not fail as long as your main scene is named "Main".
	interaction_manager = get_tree().root.get_node("Main/InteractionManager")

func _on_input_event(_viewport, event, _shape_idx):
	# Guard against clicks before the reference is ready.
	if not is_instance_valid(interaction_manager): return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# Use the local variable 'interaction_manager' to check the tool
		if interaction_manager.active_tool == InteractionManager.Tool.INSPECT:
			# Use the global signal on the InteractionManager node
			interaction_manager.port_inspect_requested.emit(self)
