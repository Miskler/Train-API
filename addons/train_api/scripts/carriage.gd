@tool
extends Area2D
class_name Carriage


@export var select_railway:RailWay = null         #То в сторону чего поезд поворачивается
var select_position_railway:float = CAR_LENGTH    #Позиция на отрезке
var select_inverted_path:bool = false

@export var real_railway:RailWay = null           #То, где он находится
@export var real_position_railway:float = 0.0     #Позиция на отрезке
var real_inverted_path:bool = false

@export var debug_mode:bool = false               #Режим отладки


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
@export var CAR_LENGTH:float = 100 :       #Длина вагона
	set = tool_car_length_reset
func tool_car_length_reset(new_length:float):
	if new_length >= 1 and((select_railway == null or real_railway == select_railway) or Engine.is_editor_hint()):
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


func _ready():
	if Engine.is_editor_hint(): return
	
	$look.visible = debug_mode
	
	$in_train.shape = $in_train.shape.duplicate()
	tool_car_length_reset(CAR_LENGTH)
	select_position_railway = CAR_LENGTH
	if real_railway == select_railway: select_position_railway += real_position_railway

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	var vec = speed * delta
	
	if abs(vec) > 50:
		push_warning("Train API: "+name+": too high speed can affect the quality of calculations!")
	
	var indexes = redefinition_railway(vec)
	
	if indexes is Array: #Проверяем можем ли двигаться
		real_position_railway += (vec * (-1 if real_inverted_path else 1))
		select_position_railway += (vec * (-1 if select_inverted_path else 1))
		
		global_position = real_railway.help_train(real_position_railway)
		if debug_mode:
			$look.global_position = select_railway.help_train(select_position_railway)-$look.pivot_offset
		look_at(select_railway.help_train(select_position_railway))


func redefinition_railway(vec):
	#Проверяем данные на корректность
	if not data_repair(): return -1
	
	var vec_to_pos  = vec * (-1 if real_inverted_path   else 1)
	var vec_to_look = vec * (-1 if select_inverted_path else 1)
	
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
		
		var convert = converting_array(fork[1])
		#Определяем какая точка поворачивает и поворачиваем
		if indexes[0][2]:
			if real_railway != select_railway and select_railway in convert:
				real_railway = select_railway
				real_inverted_path = select_inverted_path
			else:
				real_railway = fork[1][selected_turn][0]
				real_inverted_path = fork[1][selected_turn][1]
			
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
		else:
			if real_railway != select_railway and real_railway in convert:
				select_railway = real_railway
				select_inverted_path = real_inverted_path
			else:
				select_railway = fork[1][selected_turn][0]
				select_inverted_path = fork[1][selected_turn][2]
			
			if fork[1][selected_turn][2]:
				select_position_railway = select_railway.length_path()
			else:
				select_position_railway = 0
			
			print("Train API: "+name+": redefinition_railway() -> select_railway reconnect to: "+select_railway.name+(" (inverted)" if select_inverted_path else ""))
	
	#Возвращаем итоги вычислений
	return indexes
func converting_array(array):
	var new_array = []
	for i in array:
		new_array.append(i[0])
	return new_array



func data_repair() -> bool:
	#Подготовка переменных
	if select_railway == null and real_railway != null:   #Если объект на котором находимся не указан
		select_railway = real_railway #Фиксим
		print("Train API: "+name+": data_repair() -> select_railway = real_railway")
	elif select_railway != null and real_railway == null: #Если объект за которым смотрим не указан
		real_railway = select_railway #Фиксим
		print("Train API: "+name+": data_repair() -> real_railway = select_railway")
	elif select_railway == null and real_railway == null: #Если никакая из дорог не указана
		print("Train API: "+name+": data_repair() -> ERROR")
		return false #Двигаться НЕ можем
	return true

#Определяет когда нужно поворачивать и куда
func checking_turn(select_way:Node, vec:float, pos:float):
	#Получаем следующий поворот и определяем нужно ли поворачивать в этом кадре
	var index = [0, 0, false] #Движение до поворота, движение после поворота, нужно ли поворачивать
	var fork:Array = []
	if vec >= 0: #Поезд едет вперед
		fork = select_way.get_next_fork()
		
		#Нужно ли поворачивать в этом кадре
		if (fork[0] > pos and pos+vec > fork[0]) or (pos+vec) > select_way.length_path():
			#Разница между вагоном и распутьем
			index = [0, 0, true, fork] #2000 - 1750 = 250
			index[0] = fork[0]-pos #Расстояние точки до поворота
			index[1] = CAR_LENGTH-index[0] #Длина вагона - расстояние до поворота
	else: #Поезд едет назад
		fork = select_way.get_previous_fork()
		
		#Нужно ли поворачивать в этом кадре
		if (fork[0] < pos and pos+vec < fork[0]) or (pos+vec) < 0:
			#Разница между вагоном и распутьем
			index = [0, 0, true, fork]
			index[0] = pos-fork[0] #Расстояние точки до поворота
			index[1] = CAR_LENGTH-index[0] #Длина вагона - расстояние до поворота
	return index
