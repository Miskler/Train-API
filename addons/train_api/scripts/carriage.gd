extends Area2D
class_name Carriage

@export var select_railway:Node = null         #То в сторону чего поезд поворачивается
var select_position_railway:float = CAR_LENGTH #Позиция на отрезке
var select_inverted_path:bool = false

@export var real_railway:Node = null           #То, где он находится
@export var real_position_railway:float = 0.0  #Позиция на отрезке
var real_inverted_path:bool = false

@export var speed:float = 1.0                  #Скорость и направление движения

@export var selected_turn:int = 0              #Выбранный поворот

const CAR_LENGTH:int = 138                     #Длина вагона
#Если поезд хочет переключится на трек с конца, то вагон будет это учитывать


func _ready():
	var dd = get_children()+[self]
	printt(dd, self in dd)

func _physics_process(delta):
	var vec = speed * delta
	
	var indexes = redefinition_railway(vec)
	
	#printt(real_railway.name, round(real_position_railway), real_inverted_path, "", select_railway.name, round(select_position_railway), select_inverted_path)
	
	if indexes is Array: #Проверяем можем ли двигаться
		#if not indexes[0][2] and not indexes[1][2]:
		real_position_railway += (vec * (-1 if real_inverted_path else 1))
		select_position_railway += (vec * (-1 if select_inverted_path else 1))
		
		global_position = real_railway.help_train(real_position_railway)
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
		print(fork)
		
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
			if hash(real_railway) != hash(select_railway) and select_railway in convert:
				printt(1)
				real_railway = select_railway
				real_inverted_path = select_inverted_path#fork[1][convert.find(select_railway)][1]
			else:
				printt(2)
				real_railway = fork[1][selected_turn][0]
				real_inverted_path = fork[1][selected_turn][1]
			
			if fork[1][selected_turn][2]:
				real_position_railway = real_railway.length_path()
			else:
				real_position_railway = 0
			print("Train API: "+name+": redefinition_railway() -> real_railway reconnect to: "+real_railway.name+(" (inverted)" if real_inverted_path else ""))
		else:
			if hash(real_railway) != hash(select_railway) and real_railway in convert:
				printt(3, vec_to_look)
				select_railway = real_railway
				select_inverted_path = real_inverted_path
			else:
				printt(4, vec_to_look)
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
	if select_railway == null and real_railway != null:   #Если объект за которым смотрим не указан
		select_railway = real_railway
		print("Train API: "+name+": data_repair() -> select_railway = real_railway")
	elif select_railway != null and real_railway == null:
		real_railway = select_railway
		print("Train API: "+name+": data_repair() -> real_railway = select_railway")
	elif select_railway == null and real_railway == null: #Если дорога по которой движемся не указана
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
			index = [fork[0]-pos, fork[0]-pos, true, fork]
			index[0] -= vec      #Расчитываем как подавить чтоб не проехать поворот
			index[1] -= index[0] #Остаточное движение идет на следующую дорогу
	else: #Поезд едет назад
		fork = select_way.get_previous_fork()
		
		#Нужно ли поворачивать в этом кадре
		if (fork[0] < pos and pos+vec < fork[0]) or (pos+vec) < 0:
			#Разница между вагоном и распутьем
			index = [pos-fork[0], pos-fork[0], true, fork]
			index[0] += vec      #Расчитываем как подавить чтоб не проехать поворот
			index[1] += index[0] #Остаточное движение идет на следующую дорогу
	return index
