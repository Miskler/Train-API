extends CanvasLayer


func value_changed(value):
	$"../../Carriage".speed = value*30
	$full/speed.text = str(value)

func _on_control_speed_2_value_changed(value):
	$"../../Carriage".CAR_LENGTH = value
