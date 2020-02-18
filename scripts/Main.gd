extends Node2D

export(PackedScene) var boidScene = preload("res://scenes/Boid.tscn")

func _ready() -> void:
	randomize()
	var boid : Boid = boidScene.instance()
	self.add_child(boid)
	boid.setup($Start.position, $Target)
	
func _input(_event: InputEvent) -> void:
	
	if Input.is_mouse_button_pressed(1):
		$Target.position = get_global_mouse_position()
