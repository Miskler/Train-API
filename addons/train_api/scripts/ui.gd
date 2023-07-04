@tool
extends Control

var edit_or_new = false #false = edit // true = new


func _ready():
	var editor_settings = EditorSettings.new()
	match editor_settings.get_setting("interface/editor/editor_language"):
		"ru":
			print("Train API: Язык редактора: РУССКИЙ")
			$box/edit_or_new.text = "Новый"
			$box/binding.set_item_text(0, "Лево")
			$box/binding.set_item_text(0, "Центр")
			$box/binding.set_item_text(0, "Право")
		_:
			$box/edit_or_new.text = "New"
			print("Train API: Editor's language: ENGLISH")
			$box/binding.set_item_text(0, "Left")
			$box/binding.set_item_text(0, "Centre")
			$box/binding.set_item_text(0, "Right")


func edit_or_new_toggled(button_pressed):
	edit_or_new = button_pressed


func binding_selected(index):
	$box.alignment = index
