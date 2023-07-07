extends Node2D

##Этот класс управляет дорогами вложенными в него.
##Если дорога не имеет родителя TrainAPI, то она теряет часть функций.
class_name TrainAPI

##Шаблоны для удобного создания новых дорог.
##Данные применяются только при создании новой дороги.
@export_category("Templates")

##Текстура дороги.
@export var template_texture:Texture2D = null

##Ширина текстуры дороги.
@export var template_width:float = 10

##Размер зоны логического присоеденения дорог друг с другом.
@export var template_connection_zone:float = 10

##Если True, то на дорогу нельзя переключится с конца.
@export var template_one_sided:bool = false

##Правила действующие в пределах этой группы дорог.
#@export_category("Rules")

##Включает/отключает столкновение вагонов друг с другом.
##Если отключено вагоны будут проходить насквозь.
##При отключении, службы связанные с коллизией остаются доступны.
#@export var collision:bool = true

##Зона рядом с позицией поезда где он останавливает другие вагоны.
#@export var collision_distance:float = 10
