@tool
extends Path2D
class_name RailWay


@export var texture:Texture2D = null : 
	set = tool_texture_set
func tool_texture_set(textur:Texture2D):
	$visual.texture = textur
	texture = textur

@export var width:float = 10 :
	set = tool_width_set
func tool_width_set(widt:float):
	if widt > 0:
		$visual.width = widt
		width = widt

@export var connection_zone:float = 10:
	set = tool_connection_zone_set
func tool_connection_zone_set(zone:float):
	if zone > 1:
		$beginning/shape.shape.radius = zone
		$end/shape.shape.radius = zone
		connection_zone = zone

@export var one_sided:bool = false


func _ready():
	event_gui_way()
	tool_texture_set(texture)
	tool_width_set(width)
	tool_connection_zone_set(connection_zone)

func event_gui_way() -> bool:
	if curve != null and curve.tessellate().size() > 0:
		$beginning.show()
		$end.show()
		get_node("visual").points = curve.tessellate()
		
		$beginning.position = get_node("visual").points[0]
		$end.position = get_node("visual").points[-1]
		print("Train API: "+name+": event_gui_way() -> update")
		return true
	else:
		$beginning.hide()
		$end.hide()
		get_node("visual").points = PackedVector2Array([Vector2.ZERO])
		print("Train API: "+name+": event_gui_way() -> ERROR! Log:")
		print(
			"curve created IS "+str(curve != null),
			";   RailWay points > 0 IS "+str(curve != null and curve.tessellate().size() > 0)+"."
		)
	return false


#Помогает поезду двигаться
#Получает координаты относительно в ноде Path и возвращает глобальные
func help_train(pos:float) -> Vector2:
	$help_train.progress = pos
	return $help_train.global_position

#Возвращает длину всей кривой
func length_path() -> float:
	return curve.get_baked_length()

#Возвращают данные вида [position_fork, [paths], is_begin_fork]
func get_previous_fork() -> Array:
	return [0, get_fork_worker($beginning, true), true]
func get_next_fork()     -> Array:
	return [length_path(), get_fork_worker($end, false), false]
func get_fork_worker(area:Area2D, begin:bool = false) -> Array:
	var turns = []
	for node in area.get_overlapping_areas():
		if node.is_in_group("train_api_turn") and node.get_parent() is RailWay:
			if node.name == "beginning" or not node.get_parent().one_sided:
				turns.append([node.get_parent(), begin and node.name == "beginning", node.name == "end"])
	return turns
