extends Node2D

var qt : QuadTree
var testCircle : Circle2 = Circle2.new(Vector2(200, 200), 80)
var allPoints : Array = []
onready var scrn = get_viewport_rect()
onready var scrn_size = get_viewport_rect().size

func _ready() -> void:
	randomize()
	qt = QuadTree.new(scrn)
	
	for i in range(0, 20):
		insertRandomPoint()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("add_point"):
		insertRandomPoint()
		
	if Input.is_action_just_pressed("clear"):
		self.qt.clear()
		self.allPoints.clear()
		update()
	
	if event is InputEventMouseMotion:
		testCircle.center = get_global_mouse_position()
		update()
	
	if Input.is_action_pressed("add_point_at_mouse"):
		insertPointAt(get_global_mouse_position())

func _draw() -> void:
	var bounds = qt.getBoundsList()
	for b in bounds:
		if testCircle.intersectsRect(b):
			draw_rect(b, Color.white, false, 2.0)
			
	draw_arc(testCircle.center, testCircle.radius, 0, 2*PI, 80, Color.red, 3.0)
		
	for p in self.allPoints:
		draw_circle(p, 3, Color.white)
		
	for p in qt.elementsInCircle(testCircle):
		draw_circle(p.position, 3, Color.green)

func insertRandomPoint() -> void:
	var randX : float = rand_range(0.0, scrn_size.x)
	var randY : float = rand_range(0.0, scrn_size.y)
	var pos = Vector2(randX, randY)
	insertPointAt(pos)

func insertPointAt(pos : Vector2) -> void:
	var elem : QuadTreeElement = QuadTreeElement.new(pos)
	if qt.insert(pos):
		self.allPoints.append(pos)
		update()
