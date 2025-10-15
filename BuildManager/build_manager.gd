class_name BuildManager
extends Node2D

@onready var connection_manager: ConnectionManager = get_node("/root/Main/ConnectionManager")

const PLACEMENT_GRID_SIZE = 16

enum State {IDLE, PLACING}
var current_state = State.IDLE

var preview_unit = null

func _ready():
	# Ensure the pathfinding grid is initialized on startup
	connection_manager.initialize_pathfinding_grid(Vector2i(200, 200))

func _unhandled_input(event):
	if current_state != State.PLACING: return

	if event is InputEventMouseMotion:
		if preview_unit:
			update_preview_position()

	if event is InputEventMouseButton:
		if event.is_action_pressed("ui_left_click"):
			place_unit()
		elif event.is_action_pressed("ui_right_click"):
			cancel_placing()

func start_placing_unit(unit_scene: PackedScene):
	if not unit_scene or current_state != State.IDLE: return

	current_state = State.PLACING
	preview_unit = unit_scene.instantiate()
	
	preview_unit.collision_layer = 0
	preview_unit.collision_mask = 4
	
	get_node("/root/Main/Units").add_child(preview_unit)
	update_preview_position()

func update_preview_position():
	var mouse_pos = get_global_mouse_position()
	
	var grid_pos = (mouse_pos / PLACEMENT_GRID_SIZE).floor()
	var cell_center_pos = grid_pos * PLACEMENT_GRID_SIZE + Vector2.ONE * (PLACEMENT_GRID_SIZE / 2.0)
	preview_unit.global_position = cell_center_pos

	if is_spot_valid():
		preview_unit.modulate = Color(0.5, 1.0, 0.5, 0.5)
	else:
		preview_unit.modulate = Color(1.0, 0.5, 0.5, 0.5)

func is_spot_valid() -> bool:
	if not preview_unit: return false

	# Check 1: Overlapping with other units (using physics)
	if not preview_unit.get_overlapping_areas().is_empty():
		return false

	# Check 2: Overlapping with pipes (using grid data)
	var shape = preview_unit.get_node("CollisionShape2D").shape as RectangleShape2D
	if not shape: return false # Should not happen if units are set up correctly
	
	var rect = shape.get_rect()
	var transformed_rect = preview_unit.global_transform * rect
	
	var start_grid = Vector2i((transformed_rect.position / connection_manager.PIPE_GRID_SIZE).floor())
	var end_grid = Vector2i((transformed_rect.end / connection_manager.PIPE_GRID_SIZE).floor())

	for y in range(start_grid.y, end_grid.y):
		for x in range(start_grid.x, end_grid.x):
			if connection_manager.is_cell_occupied_by_pipe(Vector2i(x, y)):
				return false # Found a pipe in the way

	return true

func place_unit():
	if is_spot_valid():
		var new_unit = preview_unit
		
		new_unit.collision_layer = 4
		new_unit.collision_mask = 0
		new_unit.modulate = Color.WHITE
		
		# Register the unit as an obstacle for pipe pathfinding
		new_unit.register_self_as_obstacle()
		
		preview_unit = null
		current_state = State.IDLE

func cancel_placing():
	if preview_unit:
		preview_unit.queue_free()
		preview_unit = null
	current_state = State.IDLE

# --- MODIFIED: Now also deletes any connected pipes ---
func delete_unit(unit_to_delete: UnitProcess):
	if not is_instance_valid(unit_to_delete): return
	
	# Find and delete all pipes connected to this unit
	# Iterate over a copy, as the original array will be modified
	for pipe in connection_manager.pipes.duplicate():
		if pipe.start_port.parent_unit == unit_to_delete or pipe.end_port.parent_unit == unit_to_delete:
			connection_manager.delete_pipe(pipe)
			
	# Unregister the obstacle before deleting
	unit_to_delete.unregister_self_as_obstacle()
	unit_to_delete.queue_free()
# ----------------------------------------------------
