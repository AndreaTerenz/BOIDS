extends Node2D

export(PackedScene) var boidScene = preload("res://scenes/Boid.tscn")

func _ready() -> void:
	var boid : Boid = boidScene.instance()
	boid.setup($Start.position, $Target, Boid.BOID_MODE.SEEK)
	self.add_child(boid)
	
func _input(event: InputEvent) -> void:
	
	if Input.is_mouse_button_pressed(1):
		$Target.position = get_global_mouse_position()
