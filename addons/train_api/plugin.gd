@tool
extends EditorPlugin

var select_ways:Node = null

var bottom_gui = preload("scenes/ui.tscn").instantiate()
func _enter_tree():
	print("Train API: plugin.gd: START")
	
	add_custom_type("Train API", "Node2D", preload("scripts/ways.gd"), preload("resources/train.svg"))
	add_custom_type("Rail Way", "Path2D", preload("scripts/railway.gd"), preload("resources/way.svg"))
	add_custom_type("Carriage Base", "Area2D", preload("scripts/carriage.gd"), preload("resources/carriage.svg"))
	
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM, bottom_gui)
	_make_visible(false)
	set_force_draw_over_forwarding_enabled()
	
	get_editor_interface().get_selection().clear()


func _exit_tree():
	print("Train API: plugin.gd: STOP")
	remove_custom_type("Train API")
	remove_custom_type("Rail Way")
	remove_custom_type("Carriage Base")
	
	bottom_gui.queue_free()
func _make_visible(visible):
	print("Train API: plugin.gd: _make_visible() -> editor gui visible is "+str(visible))
	bottom_gui.visible = visible


func _handles(object:Object) -> bool:
	if object is Node and (object is TrainAPI or object.get_parent() is TrainAPI):
		select_ways = object
		_make_visible(true)
		return true
	else: 
		select_ways = null
		_make_visible(false)
		return false


var last_pos = Vector2.ZERO
func _forward_canvas_gui_input(event):
	if select_ways == null:
		return false
	elif event is InputEventMouseButton and select_ways != null and event.button_index == 1 and bottom_gui.edit_or_new:
		new_way()
	elif event is InputEventMouse and select_ways != null and select_ways is RailWay and \
			select_ways.curve.tessellate() != select_ways.get_node("visual").points:
		select_ways.event_gui_way()
	return true


func new_way():
	var root = get_tree().get_edited_scene_root()
	
	var path = preload("scenes/railway.tscn").instantiate()
	
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO)
	path.name = "railway"
	
	bottom_gui.edit_or_new = false
	bottom_gui.get_node("box/edit_or_new").button_pressed = false
	
	var select_node_spawn = root.get_node(select_ways.get_path())
	if not select_node_spawn is TrainAPI:
		select_node_spawn = root.get_node(select_ways.get_parent().get_path())
	
	path.global_position = select_node_spawn.global_position+select_node_spawn.get_local_mouse_position()
	
	path.get_node("beginning/shape").shape = path.get_node("beginning/shape").shape.duplicate()
	path.get_node("end/shape").shape = path.get_node("end/shape").shape.duplicate()
	path.texture = select_node_spawn.template_texture
	path.width = select_node_spawn.template_width
	path.connection_zone = select_node_spawn.template_connection_zone
	path.one_sided = select_node_spawn.template_one_sided
	
	
	select_node_spawn.add_child(path, true)
	path.owner = root
	
	get_editor_interface().get_selection().clear()
	get_editor_interface().get_selection().add_node(root.get_node(path.get_path()))
	
	print("Train API: plugin.gd: new_way() -> created, name: "+path.name)
