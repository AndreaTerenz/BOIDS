extends Node2D

export(PackedScene) var boidScene = preload("res://scenes/Boid.tscn")

onready var screen_size = get_viewport_rect().size

func _ready() -> void:
	randomize()

	var boids = []
	#Shouldnt be more than 250
	for i in range(0, 40):
		var boid : Boid = boidScene.instance()
		self.add_child(boid)
		boid.setup(Vector2(rand_range(0, screen_size.x), rand_range(0, screen_size.y)), i, $Target)
		boids.append(boid)
		
	for b in boids:
		b.setOthers(boids)
	
func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(1):
		$Target.position = get_global_mouse_position()
		
	
