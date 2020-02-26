extends Node2D

onready var screen_size = get_viewport_rect().size

func _ready() -> void:
	randomize()
	
func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(1):
		$Target.position = get_global_mouse_position()
	
	
