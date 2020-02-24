class_name Flock

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER, DRIFT }

export(NodePath) var target : NodePath
export(BOID_MODE) var mode = BOID_MODE.DRIFT
export(int, 1, 250, 1) var boidsCount = 1

onready var bounds : Vector2 = get_viewport_rect().size

func _ready() -> void:
	for i in range(0, self.boidsCount):
		var startPos : Vector2 = Vector2(rand_range(0, self.bounds.x), rand_range(0, self.bounds.y))
		var b : Boid = Boid.new(startPos, i, get_node(target), self, mode)
		self.add_child(b)
