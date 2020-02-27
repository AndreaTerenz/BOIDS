extends Node2D

var qt : QuadTree
var testBound : Rect2 = Rect2(200, 200, 100, 50)
var testCircle : Circle2 = Circle2.new(Vector2(200, 200), 80)
var allPoints : Array = []
onready var scrn = get_viewport_rect()
onready var scrn_size = get_viewport_rect().size

func _ready() -> void:
	randomize()
	qt = QuadTree.new(scrn)
	
	for i in range(0, 180):
		insertRandomPoint()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("add_point"):
		insertRandomPoint()
	
	if event is InputEventMouseMotion:
		var tbSize = testBound.size
		#testBound.position = get_global_mouse_position() - (tbSize/2)
		testCircle.center = get_global_mouse_position()
		update()
	
	if Input.is_mouse_button_pressed(1):
		insertPointAt(get_global_mouse_position())

func _draw() -> void:
	var bounds = qt.getBoundsList()
	for b in bounds:
#		if b.intersects(testBound):
		if testCircle.intersectsRect(b):
			draw_rect(b, Color.white, false, 2.0)
			
	#draw_rect(testBound, Color.red, false, 3.0)
	draw_arc(testCircle.center, testCircle.radius, 0, 2*PI, 80, Color.red, 3.0)
		
	for p in self.allPoints:
		draw_circle(p, 3, Color.white)
		
	#var points = qt.elementsInRect(testBound)
	for p in qt.elementsInCircle(testCircle):
		draw_circle(p.position, 3, Color.green)

func insertRandomPoint() -> void:
	var randX : float = rand_range(0.0, scrn_size.x)
	var randY : float = rand_range(0.0, scrn_size.y)
	var pos = Vector2(randX, randY)
	insertPointAt(pos)

func insertPointAt(pos : Vector2) -> void:
	var elem : QuadTreeElement = QuadTreeElement.new(pos)
	if qt.insert(elem):
		self.allPoints.append(pos)
		update()
