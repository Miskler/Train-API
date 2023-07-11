@tool
extends Control

var edit_or_new = false #false = edit // true = new


func _ready():
	$box_railways.hide()
	$box_carriage.hide()
	
	var editor_settings = EditorSettings.new()
	match editor_settings.get_setting("interface/editor/editor_language"):
		"ru":
			print("Train API: Язык редактора: РУССКИЙ")
			$box_railways/edit_or_new.text = "Новый"
			$box_railways/binding.set_item_text(0, "Лево")
			$box_railways/binding.set_item_text(1, "Центр")
			$box_railways/binding.set_item_text(2, "Право")
			
			$box_carriage/preview.text = "Предпросмотр"
			$box_carriage/binding.set_item_text(0, "Лево")
			$box_carriage/binding.set_item_text(1, "Центр")
			$box_carriage/binding.set_item_text(2, "Право")
		_:
			print("Train API: Editor's language: ENGLISH")
			$box_railways/edit_or_new.text = "New"
			$box_railways/binding.set_item_text(0, "Left")
			$box_railways/binding.set_item_text(1, "Centre")
			$box_railways/binding.set_item_text(2, "Right")
			
			$box_carriage/preview.text = "Preview"
			$box_carriage/binding.set_item_text(0, "Left")
			$box_carriage/binding.set_item_text(1, "Centre")
			$box_carriage/binding.set_item_text(2, "Right")


func edit_or_new_toggled(button_pressed):
	edit_or_new = button_pressed


func binding_selected(index):
	$box_railways.alignment = index
	$box_carriage.alignment = index
	
	$box_railways/binding.select(index)
	$box_carriage/binding.select(index)


func toggled_preview(button_pressed):
	$box_carriage/preview.button_pressed = button_pressed
	$box_carriage/preview/event.paused = not button_pressed
