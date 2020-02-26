class_name Flock

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER, DRIFT }

export(PackedScene) var boidScene = preload("res://scenes/Boid.tscn")
export(NodePath) var target : NodePath
export(BOID_MODE) var mode = BOID_MODE.DRIFT
export(int, 1, 250, 1) var count = 1

onready var bounds : Vector2 = get_viewport_rect().size

func _ready() -> void:
	for i in range(0, self.count):
		var startPos : Vector2 = Vector2(rand_range(0, self.bounds.x), rand_range(0, self.bounds.y))
		var b : Boid = Boid.new(startPos, i, get_node(target), self, mode, boidScene)
		self.add_child(b)

func _process(_delta: float) -> void:
	#move boids AFTER computing everyone's velocity
	for boid in getBoids():
		boid.setVelocity()
	for boid in getBoids():
		boid.move()
		boid.update()

func getBoidsCount() -> int:
	return self.get_children().size()

func getOtherBoidsInRange(exclude : int, distance : int) -> Array:
	var refPos : Vector2 = getBoids()[exclude].position
	var others : Array = []
	for o in getBoids():
		var d = o.position.distance_squared_to(refPos)
		if (o.id != exclude) and (d <= pow(distance*2, 2)):
			others.append(o)
	return others

func getOtherBoids(exclude : int) -> Array:
	var b = []
	if (exclude >= 0 and exclude < getBoidsCount()):
		b = getBoids()
		b.remove(exclude)
	return b

func getBoids() -> Array:
	return self.get_children()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("reset"):
		reset()

func reset() -> void:
	for b in getBoids():
		remove_child(b)
		b.queue_free()
	for i in range(0, self.count):
		var startPos : Vector2 = Vector2(rand_range(0, self.bounds.x), rand_range(0, self.bounds.y))
		var b : Boid = Boid.new(startPos, i, get_node(target), self, mode, boidScene)
		self.add_child(b)
