@tool
extends Control

var edit_or_new = true #false = edit // true = new

func edit_or_new_toggled(button_pressed):
	edit_or_new = button_pressed


func binding_selected(index):
	$box.alignment = index
