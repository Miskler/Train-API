extends Node2D
class_name TrainAPI

@export_category("Templates")
@export var template_texture:Texture2D = null
@export var template_width:float = 10
@export var template_connection_zone:float = 10
@export var template_one_sided:bool = false

@export_category("Rules")
#Включает/отключает столкновение вагонов друг с другом
#Если отключено вагоны будут проходить насквозь
#При отключении, службы связанные с коллизией остаются доступны
@export var collision:bool = true
#Зона рядом с позицией поезда где он останавливает другие вагоны
@export var collision_distance:float = 10
