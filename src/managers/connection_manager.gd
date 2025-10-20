class_name ConnectionManager
extends Node2D

const PIPE_GRID_SIZE = 16
@onready var pipe_drawer: PipeDrawer = $PipeDrawer

var pipes: Array[Pipe] = []
var occupied_segments: Dictionary = {}
var astar_grid: AStarGrid2D
var occupied_pipe_cells: Dictionary = {}
var selected_object_for_highlight = null

func set_selection(object):
	if selected_object_for_highlight == object: return
	selected_object_for_highlight = object
	if is_instance_valid(pipe_drawer):
		pipe_drawer.queue_redraw()

func add_pipe(pipe: Pipe) -> bool:
	if check_for_overlaps(pipe.path, true): return false
	pipes.append(pipe)
	for i in range(pipe.path.size() - 1):
		var key = _get_canonical_segment_key(pipe.path[i], pipe.path[i+1])
		occupied_segments[key] = pipe
	for point in pipe.path:
		occupied_pipe_cells[point] = pipe
	if is_instance_valid(pipe_drawer):
		pipe_drawer.queue_redraw()
	return true

func delete_pipe(pipe_to_delete: Pipe):
	if not pipe_to_delete in pipes: return
	for i in range(pipe_to_delete.path.size() - 1):
		var key = _get_canonical_segment_key(pipe_to_delete.path[i], pipe_to_delete.path[i+1])
		occupied_segments.erase(key)
	for point in pipe_to_delete.path:
		occupied_pipe_cells.erase(point)
	pipes.erase(pipe_to_delete)
	if is_instance_valid(pipe_drawer):
		pipe_drawer.queue_redraw()

# --- The rest of the script is logic and remains the same ---
func initialize_pathfinding_grid(world_size_in_tiles: Vector2i):
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(Vector2i.ZERO, world_size_in_tiles * 4)
	astar_grid.cell_size = Vector2i(PIPE_GRID_SIZE, PIPE_GRID_SIZE)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

func set_grid_solid(grid_pos: Vector2i, is_solid: bool):
	if astar_grid.is_in_bounds(grid_pos.x, grid_pos.y):
		astar_grid.set_point_solid(grid_pos, is_solid)

func is_grid_solid(grid_pos: Vector2i) -> bool:
	if astar_grid.is_in_bounds(grid_pos.x, grid_pos.y):
		return astar_grid.is_point_solid(grid_pos)
	return true

func find_path(start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
	return astar_grid.get_id_path(start_pos, end_pos)

func check_for_overlaps(path: Array[Vector2i], check_against_self: bool = false) -> bool:
	var path_segments = {}
	for i in range(path.size() - 1):
		var key = _get_canonical_segment_key(path[i], path[i+1])
		if occupied_segments.has(key): return true
		if check_against_self:
			if path_segments.has(key): return true
			path_segments[key] = true
	return false

func _get_canonical_segment_key(p1: Vector2i, p2: Vector2i) -> int:
	var sorted_points = [p1, p2] if p1.x < p2.x or (p1.x == p2.x and p1.y < p2.y) else [p2, p1]
	return hash(sorted_points)

func get_port_at_grid_pos(grid_pos: Vector2i) -> UnitPort:
	var world_pos = Vector2(grid_pos) * PIPE_GRID_SIZE + Vector2.ONE * (PIPE_GRID_SIZE / 2.0)
	var space_state = get_world_2d().direct_space_state
	var query_params = PhysicsPointQueryParameters2D.new()
	query_params.position = world_pos
	query_params.collide_with_areas = true
	query_params.collision_mask = 2
	var results = space_state.intersect_point(query_params)
	for result in results:
		if result.collider is UnitPort:
			return result.collider
	return null

func get_pipe_at_grid_pos(grid_pos: Vector2i) -> Pipe:
	if occupied_pipe_cells.has(grid_pos):
		return occupied_pipe_cells[grid_pos]
	return null

func is_in_bounds(x: int, y: int) -> bool:
	return astar_grid.is_in_bounds(x, y)

func is_cell_occupied_by_pipe(grid_pos: Vector2i) -> bool:
	return occupied_pipe_cells.has(grid_pos)
