class_name Pipe
extends Resource

# The path of the pipe on the grid
var path: Array[Vector2i] = []
# The port where the pipe starts (can be null)
var start_port: UnitPort = null
# The port where the pipe ends (can be null)
var end_port: UnitPort = null
