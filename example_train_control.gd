extends CanvasLayer


func value_changed(value):
	$"../../Carriage".speed = value*4
	$full/speed.text = str(value)
