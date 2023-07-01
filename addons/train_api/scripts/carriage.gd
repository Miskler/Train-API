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



func _physics_process(delta):
	var vec = speed * delta
	
	var indexes = redefinition_railway(vec)
	
	if indexes is Array: #Проверяем можем ли двигаться
		real_position_railway += vec   * (-1 if real_inverted_path   else 1)
		select_position_railway += vec * (-1 if select_inverted_path else 1)
		
		global_position = real_railway.help_train(real_position_railway)
		look_at(select_railway.help_train(select_position_railway))


var last_turn = null #Вектор и сам поворот
func redefinition_railway(vec):
	#Проверяем данные на корректность
	if not data_repair(): return
	
	var vec_to_pos  = vec * (-1 if real_inverted_path   else 1)
	var vec_to_look = vec * (-1 if select_inverted_path else 1)
	
	#Запрашиваем возможность поворота для 2 опорных точек вагона
	var indexes = [checking_turn(vec_to_pos, real_position_railway, last_turn), 
		checking_turn(vec_to_look, select_position_railway, last_turn)]
	
	#Останавливаем физику поезда если данные не корректны
	if not indexes[0] is Array or not indexes[1] is Array:
		return
	
	#Если одна из опорных точек готова к повороту
	if indexes[0][2] or indexes[1][2]:
		#Определяем какая точка готова поворачивать
		var fork = []
		if indexes[0][2]: fork = indexes[0][3]
		else: fork = indexes[1][3]
		
		#Удостоверяемся, что ссылаемся на существующий поворот
		if fork[1].size() <= selected_turn:
			selected_turn = 0
			print("Train API: "+name+": redefinition_railway() -> selected_turn reset!")
		
		#Определяем какая точка поворачивает и поворачиваем
		if indexes[0][2]:
			set_last_turn(fork[0], real_railway)   #Сохраняем последний поворот
			real_railway = fork[1][selected_turn][0]
			real_inverted_path = fork[1][selected_turn][1]
			if real_inverted_path:
				print("Train API: "+name+": redefinition_railway() -> real_railway reconnect to: "+real_railway.name+" (inverted)")
				real_position_railway = real_railway.length_path()
			else:
				real_position_railway = 0
				print("Train API: "+name+": redefinition_railway() -> real_railway reconnect to: "+real_railway.name)
		else:
			set_last_turn(fork[0], select_railway) #Сохраняем последний поворот
			select_railway = fork[1][selected_turn][0]
			select_inverted_path = fork[1][selected_turn][1]
			select_position_railway = 0
			if select_inverted_path:
				print("Train API: "+name+": redefinition_railway() -> select_railway reconnect to: "+select_railway.name+" (inverted)")
				select_position_railway = select_railway.length_path()
			else:
				select_position_railway = 0
				print("Train API: "+name+": redefinition_railway() -> select_railway reconnect to: "+select_railway.name)
	
	#Возвращаем итоги вычислений
	return indexes

func set_last_turn(fork:float, path:Node) -> bool:
	if last_turn == null:
		last_turn = [fork, path]
		print("Train API: "+name+": set_last_turn() -> update")
		return true
	last_turn = null
	print("Train API: "+name+": set_last_turn() -> reset")
	return false
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
func checking_turn(vec:float, pos:float, lasti_turn = null):
	#Получаем следующий поворот и определяем нужно ли поворачивать в этом кадре
	var index = [0, 0, false] #Движение до поворота, движение после поворота, нужно ли поворачивать
	var fork:Array = []
	if vec >= 0: #Поезд едет вперед
		fork = real_railway.get_next_fork()
		
		#Нужно ли поворачивать в этом кадре
		if fork[0] > pos and pos+vec > fork[0]:
			#Разница между вагоном и распутьем
			index = [fork[0]-pos, fork[0]-pos, true, fork]
			index[0] -= vec      #Расчитываем как подавить чтоб не проехать поворот
			index[1] -= index[0] #Остаточное движение идет на следующую дорогу
	else: #Поезд едет назад
		fork = real_railway.get_previous_fork()
		
		#Нужно ли поворачивать в этом кадре
		if fork[0] < pos and pos+vec < fork[0]:
			#Разница между вагоном и распутьем
			index = [pos-fork[0], pos-fork[0], true, fork]
			index[0] -= vec      #Расчитываем как подавить чтоб не проехать поворот
			index[1] -= index[0] #Остаточное движение идет на следующую дорогу
	return index
