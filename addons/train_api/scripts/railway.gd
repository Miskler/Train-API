@tool
extends Path2D

##RailWay - вспомогательный класс при помощи которого вагоны (Carriage) могут двигаться.
##Крайне желательно чтобы бы в дереве был ребенком ноды TrainAPI.
class_name RailWay


##Список вагонов которые в данный момент находятся на этой дороге хотя бы одной точкой.
var cars:Array[Carriage] = []

##Текстура дороги.
@export var texture:Texture2D = null : 
	set = tool_texture_set
func tool_texture_set(textur:Texture2D):
	$visual.texture = textur
	texture = textur

##Ширина текстуры дороги.
@export var width:float = 10 :
	set = tool_width_set
func tool_width_set(widt:float):
	if widt > 0:
		$visual.width = widt
		width = widt

##Размер зоны логического присоеденения дорог друг с другом.
@export var connection_zone:float = 10:
	set = tool_connection_zone_set
func tool_connection_zone_set(zone:float):
	if zone > 1:
		$beginning/shape.shape.radius = zone
		$end/shape.shape.radius = zone
		connection_zone = zone

##Если True, то на дорогу нельзя переключится с конца.
@export var one_sided:bool = false


func _enter_tree():
	if Engine.is_editor_hint() and get_child_count() <= 0:
		name = "rand_name"
		
		var root = get_tree().get_edited_scene_root()
		
		var way = load("../scenes/railway.tscn").instantiate()
		
		way.texture = texture
		way.width = width
		way.connection_zone = connection_zone
		way.one_sided = one_sided
		
		var select_node_spawn = root.get_node(get_parent().get_path())
		select_node_spawn.add_child(way, true)
		way.owner = root
		
		root.get_node(get_path()).queue_free()


func _ready():
	event_gui_way()
	tool_texture_set(texture)
	tool_width_set(width)
	tool_connection_zone_set(connection_zone)

##Данные о форме дороги применяет к визуальной и технической части.
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


##Помогает поезду двигаться.
##Получает координаты точки на отрезке и возвращает глобальные координаты сцены.
func help_train(pos:float) -> Vector2:
	$help_train.progress = pos
	return $help_train.global_position

##Возвращает длину дороги.
func length_path() -> float:
	return curve.get_baked_length()

##Возвращает повороты доступные в начале дороги.
func get_previous_fork() -> Array:
	return [0, get_fork_worker($beginning, true), true]

##Возвращает повороты доступные в конце дороги.
func get_next_fork()     -> Array:
	return [length_path(), get_fork_worker($end, false), false]


##Возращают повороты и их позиции.
##Является ядром логики у функций get_previous_fork() и get_next_fork().
##Возвращают данные вида [position_fork, [paths], is_begin_fork].
func get_fork_worker(area:Area2D, begin:bool = false) -> Array:
	var turns = []
	for node in area.get_overlapping_areas():
		if node.is_in_group("train_api_turn") and node.get_parent() is RailWay:
			if node.name == "beginning" or not node.get_parent().one_sided:
				turns.append([node.get_parent(), begin and node.name == "beginning", node.name == "end"])
	return turns
