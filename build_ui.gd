class_name BuildUI
extends Control

# --- This dictionary now drives the entire build menu ---
# To add a new unit, just add a new entry here.
var buildable_units = {
	"Source": preload("res://Units/Source.tscn"),
	"Sink": preload("res://Units/Sink.tscn"),
	"Reactor": preload("res://Units/ReactorProcess.tscn"),
	"Filter": preload("res://Units/FilterProcess.tscn"),
	"Distillation": preload("res://Units/DistillationProcess.tscn"),
	"Mixer": preload("res://Units/Mixer.tscn"),
	"Splitter": preload("res://Units/Splitter.tscn"),
}
# --------------------------------------------------------

@onready var build_manager: BuildManager = get_node("/root/Main/BuildManager")
@onready var interaction_manager: InteractionManager = get_node("/root/Main/InteractionManager")

# --- FIX: Paths updated to match the scene tree structure ---
@onready var tool_indicator_label: Label = $HBoxContainer/ToolIndicatorLabel
@onready var build_menu_container = $BuildMenuContainer
@onready var build_button = $HBoxContainer/ButtonBuild
# -----------------------------------------------------------

func _ready():
	interaction_manager.tool_changed.connect(_on_tool_changed)
	_on_tool_changed(interaction_manager.active_tool)
	_generate_build_buttons()

func _generate_build_buttons():
	for child in build_menu_container.get_children():
		child.queue_free()
	
	for unit_name in buildable_units:
		var unit_scene = buildable_units[unit_name]
		
		var new_button = Button.new()
		new_button.text = unit_name
		new_button.pressed.connect(func(): _on_unit_build_button_pressed(unit_scene))
		
		build_menu_container.add_child(new_button)

func _on_tool_changed(new_tool: InteractionManager.Tool):
	tool_indicator_label.text = "Mode: " + InteractionManager.Tool.keys()[new_tool]

func _on_button_build_pressed():
	build_menu_container.visible = not build_menu_container.visible

func _on_unit_build_button_pressed(unit_scene: PackedScene):
	interaction_manager.active_tool = InteractionManager.Tool.BUILD
	build_manager.start_placing_unit(unit_scene)
	build_menu_container.visible = false

# --- Other Tool Buttons ---
func _on_button_select_pressed():
	interaction_manager.active_tool = InteractionManager.Tool.SELECT

func _on_button_connect_pressed():
	interaction_manager.active_tool = InteractionManager.Tool.PIPE

func _on_button_inspect_pressed():
	interaction_manager.active_tool = InteractionManager.Tool.INSPECT
	
func _on_button_delete_pressed():
	interaction_manager.delete_selected_object()
