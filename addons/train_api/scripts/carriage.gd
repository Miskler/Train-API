@tool
extends Area2D
class_name Carriage


@export var select_railway:RailWay = null         #То в сторону чего поезд поворачивается
var select_position_railway:float = CAR_LENGTH    #Позиция на отрезке
var select_inverted_path:bool = false

@export var real_railway:RailWay = null           #То, где он находится
@export var real_position_railway:float = 0.0     #Позиция на отрезке
var real_inverted_path:bool = false

##Привет
@export var debug_mode:bool = false               #Режим отладки
@export var safe_mode:bool = true


@export_category("Move")
@export var speed:float = 1.0                     #Скорость и направление движения

@export var selected_turn:int = 0                 #Выбранный поворот

#Поезд может менять свою длину в динамике, но не всегда!
#1. Нужно чтобы обе части поезда находились на одной дороге
#2. Чтобы новая длина была минимум 1
#3. Чтобы новая длина+текущая позиция при установке прямо сейчас не выходила за длину текущего отрезка
#   ЛИБО
#1. У вагона сейчас не установлена дорога select_railway
#2. Чтобы новая длина была минимум 1
@export var CAR_LENGTH:int = 100 :              #Длина вагона
	set = tool_car_length_reset
func tool_car_length_reset(new_length:float):
	if new_length >= 0 and((select_railway == null or real_railway == select_railway) or Engine.is_editor_hint()):
		var new_pos = new_length
		if select_railway != null:
			if select_position_railway >= real_position_railway and real_position_railway+new_length<select_railway.length_path():
				select_position_railway = real_position_railway+new_length
			elif select_position_railway < real_position_railway and real_position_railway-new_length>0:
				select_position_railway = real_position_railway-new_length
			else: return
		else:
			select_position_railway = real_position_railway+new_length
		
		print("Train API: "+name+": tool_car_length_reset() -> update to "+str(new_length))
		CAR_LENGTH = new_length
		
		if get_node_or_null("in_train") != null:
			$in_train.shape.size.x = new_length
			$in_train.position.x = new_length/2.0
			$icon.size.x = new_length

@export var move_node:Node = self                 #Какую ноду он будет двигать по дороге (по умолчанию - себя)


func _enter_tree() -> void:
	if Engine.is_editor_hint() and get_child_count() <= 0:
		name = "rand_name"
		
		var root = get_tree().get_edited_scene_root()
		
		var car = load("../scenes/carriage.tscn").instantiate()
		
		var select_node_spawn = root.get_node(get_parent().get_path())
		
		select_node_spawn.add_child(car, true)
		car.owner = root
		
		root.get_node(get_path()).queue_free()


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	$look.visible = debug_mode
	
	$in_train.shape = $in_train.shape.duplicate()
	tool_car_length_reset(CAR_LENGTH)
	select_position_railway = CAR_LENGTH
	if real_railway == select_railway: select_position_railway += real_position_railway

func _physics_process(delta) -> void:
	if Engine.is_editor_hint(): return
	
	var vec = speed * delta
	
	if safe_mode and abs(vec) >= CAR_LENGTH:
		vec = clamp(vec, -(CAR_LENGTH-1), (CAR_LENGTH-1))
	
	if abs(vec) > 50:
		push_warning("Train API: "+name+": too high speed can affect the quality of calculations!")
	
	var indexes = redefinition_railway(vec)
	
	if indexes is Array: #Проверяем можем ли двигаться
		var index_r = (-1.0 if real_inverted_path   else 1.0)
		var index_l = (-1.0 if select_inverted_path else 1.0)
		
		real_position_railway   += round((vec-indexes[0][0]) * index_r)
		select_position_railway += round((vec-indexes[1][0]) * index_l)
		
		if debug_mode:
			$look.global_position = select_railway.help_train(select_position_railway)-$look.pivot_offset
		
		if move_node != null:
			#Такая разбивка нужна чтобы можно было двигать и 3D объекты без лишних проверок
			var pos = real_railway.help_train(real_position_railway)
			move_node.global_position.x = pos.x
			move_node.global_position.y = pos.y
			
			var look_pos = select_railway.help_train(select_position_railway)
			
			if move_node is Node3D:
				look_pos = Vector3(look_pos.x, look_pos.y, 0)
			
			move_node.look_at(look_pos)


func redefinition_railway(vec):
	#Проверяем данные на корректность
	if not data_repair(): return -1
	
	var vec_to_pos  = vec * (-1.0 if real_inverted_path   else 1.0)
	var vec_to_look = vec * (-1.0 if select_inverted_path else 1.0)
	
	#Запрашиваем возможность поворота для 2 опорных точек вагона
	var indexes = [checking_turn(real_railway, vec_to_pos, real_position_railway),
		checking_turn(select_railway, vec_to_look, select_position_railway)]
	
	#Останавливаем физику поезда если данные не корректны
	if not indexes[0] is Array or not indexes[1] is Array:
		return -1
	
	#Если одна из опорных точек готова к повороту
	if indexes[0][2] or indexes[1][2]:
		#Определяем какая точка готова поворачивать
		var fork = []
		if indexes[0][2]: fork = indexes[0][3]
		else: fork = indexes[1][3]
		
		#Удостоверяемся, что ссылаемся на существующий поворот
		if fork[1].size() == 0:
			print("Train API: "+name+": redefinition_railway() -> ERROR! NOT FORKS!")
			return -1
		elif fork[1].size() <= selected_turn:
			selected_turn = 0
			print("Train API: "+name+": redefinition_railway() -> selected_turn reset!")
		
		#Определяем какая точка поворачивает и поворачиваем
		if indexes[0][2]:
			var turn_data = turn(real_railway, select_railway, indexes[0][3], real_inverted_path, select_inverted_path, real_position_railway, indexes[0][3][1][selected_turn][1])
			
			real_railway = turn_data[0]
			real_inverted_path = turn_data[1]
			real_position_railway = turn_data[2]
			
			if safe_mode and select_railway == real_railway:
				if fork[1][selected_turn][2]:
					real_position_railway = real_railway.length_path()
					
					#Фиксим погрешность в рассчете при повороте
					if vec_to_pos >= 0:
						select_position_railway = select_railway.length_path()-indexes[0][1]
					else:
						select_position_railway = indexes[0][1]
				else:
					real_position_railway = 0
					
					#Фиксим погрешность в рассчете при повороте
					if vec_to_pos >= 0:
						select_position_railway = indexes[0][1]
					else:
						select_position_railway = indexes[0][1]
			
			print("Train API: "+name+": redefinition_railway() -> real_railway reconnect to: "+real_railway.name+(" (inverted)" if real_inverted_path else ""))
		if indexes[1][2]:
			var turn_data = turn(select_railway, real_railway, indexes[1][3], select_inverted_path, real_inverted_path, select_position_railway, indexes[1][3][1][selected_turn][2])
			
			select_railway = turn_data[0]
			select_inverted_path = turn_data[1]
			select_position_railway = turn_data[2]
			
			print("Train API: "+name+": redefinition_railway() -> select_railway reconnect to: "+select_railway.name+(" (inverted)" if select_inverted_path else ""))
	
	#Возвращаем итоги вычислений
	return indexes
func converting_array(array) -> Array:
	var new_array = []
	for i in array:
		new_array.append(i[0])
	return new_array


func data_repair() -> bool:
	#Подготовка переменных
	if select_railway == null and real_railway != null:   #Если объект на котором находимся не указан
		select_railway = real_railway #Фиксим
		print("Train API: "+name+": data_repair() -> select_railway = real_railway")
		railway_reselect(select_railway, real_railway)
	elif select_railway != null and real_railway == null: #Если объект за которым смотрим не указан
		real_railway = select_railway #Фиксим
		print("Train API: "+name+": data_repair() -> real_railway = select_railway")
		railway_reselect(select_railway, real_railway)
	elif select_railway == null and real_railway == null: #Если никакая из дорог не указана
		print("Train API: "+name+": data_repair() -> ERROR")
		return false #Двигаться НЕ можем
	return true

#Определяет когда нужно поворачивать и куда
func checking_turn(select_way:RailWay, vec:float, pos:float) -> Array:
	#Получаем следующий поворот и определяем нужно ли поворачивать в этом кадре
	var index = [0, 0, false] #Движение до поворота, движение после поворота, нужно ли поворачивать
	var fork:Array = []
	if vec >= 0: #Поезд едет вперед
		fork = select_way.get_next_fork()
		
		#Нужно ли поворачивать в этом кадре
		if (fork[0] > pos and pos+vec > fork[0]) or (pos+vec) > select_way.length_path() or (pos+vec) < 0:
			#Разница между вагоном и распутьем
			index = [0, 0, true, fork]
			index[0] = -(fork[0]-pos) #Расстояние точки до поворота
			index[1] = CAR_LENGTH-(index[0]*-1) #Длина вагона - расстояние до поворота
	else: #Поезд едет назад
		fork = select_way.get_previous_fork()
		
		#Нужно ли поворачивать в этом кадре
		if (fork[0] < pos and pos+vec < fork[0]) or (pos+vec) > select_way.length_path() or (pos+vec) < 0:
			#Разница между вагоном и распутьем
			index = [0, 0, true, fork]
			index[0] = pos-fork[0] #Расстояние точки до поворота
			index[1] = CAR_LENGTH-index[0] #Длина вагона - расстояние до поворота
	return index

func turn(one:RailWay, two:RailWay, fork:Array, one_invert:bool, two_invert:bool, one_pos:float, invert:bool) -> Array:
	var convert = converting_array(fork[1])
	if one != two and two in convert:
		one = two
		one_invert = two_invert
	else:
		one = fork[1][selected_turn][0]
		one_invert = invert
	
	if fork[1][selected_turn][2]:
		one_pos = one.length_path()
	else:
		one_pos = 0
	
	return [one, one_invert, one_pos]


#Вызывать ДО переопределения переменных
#Синхронизирует данные о положении с дорогами
#Нужно для "коллизии" поездов друг с другом
func railway_reselect(select_new_railway:RailWay, real_new_railway:RailWay) -> void:
	if not self in select_new_railway.cars:
		select_new_railway.cars.append(self)
		print("Train API: "+name+": railway_reselect() -> select_railway \""+str(select_new_railway.name)+"\" append")
	if not self in real_new_railway.cars:
		real_new_railway.cars.append(self)
		print("Train API: "+name+": railway_reselect() -> real_railway \""+str(real_new_railway.name)+"\" append")
	
	if not select_railway in [null, select_new_railway]:
		select_railway.cars.erase(self)
		print("Train API: "+name+": railway_reselect() -> select_railway \""+str(select_railway.name)+"\" erase")
	if not real_railway in [null, real_new_railway]:
		real_railway.cars.erase(self)
		print("Train API: "+name+": railway_reselect() -> real_railway \""+str(real_railway.name)+"\" erase")
