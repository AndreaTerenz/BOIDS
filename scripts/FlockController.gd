class_name Flock

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER, DRIFT }

export(PackedScene) var boidScene = preload("res://scenes/Boid.tscn")
export(NodePath) var target : NodePath
export(BOID_MODE) var mode = BOID_MODE.DRIFT
export(int, 1, 310, 1) var count = 30
export(bool) var showDebug = false

var qtree : QuadTree = null

onready var bounds : Rect2 = get_viewport_rect()
onready var boundsSize : Vector2 = get_viewport_rect().size

func _ready() -> void:
	reset()

func _process(_delta: float) -> void:
	self.qtree = QuadTree.new(self.bounds)
	var boids = getBoids()

	for stage in [1,2,3]:
		for boid in boids:
			match stage:
				1 : #First, add each boid to the quadtree
					self.qtree.insert(QuadTreeElement.new(boid.position, str(boid.id), boid))
				2 : #Second, calculate each boid's velocity
					boid.setVelocity()
				3 : #Third, move each boid
					boid.move()
		
	self.qtree.clear()
	self.qtree.free()

func getBoidsCount() -> int:
	return self.get_children().size()

func getOtherBoidsInRange(exclude : Boid, distance : int) -> Array:
	var elem : QuadTreeElement = QuadTreeElement.new(exclude.position, str(exclude.id), exclude)
	return self.qtree.objectsAroundElement(elem, distance)

func getOtherBoids(exclude : int) -> Array:
	var b = []
	if (exclude >= 0 and exclude < getBoidsCount()):
		b = getBoids()
		b.remove(exclude)
	return b

func getBoids() -> Array:
	return self.get_children()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("reset"):
		reset()
	if Input.is_action_just_pressed("draw_debug"):
		self.showDebug = not(self.showDebug)

func reset() -> void:
	for b in getBoids():
		remove_child(b)
		b.queue_free()
	for i in range(0, self.count):
		var startPos : Vector2 = Vector2(rand_range(0, self.boundsSize.x), rand_range(0, self.boundsSize.y))
		var b : Boid = Boid.new(startPos, i, get_node(target), self, mode, boidScene)
		self.add_child(b)
