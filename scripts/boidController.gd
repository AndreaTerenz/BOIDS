class_name Boid

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER, DRIFT }

export(float, 0.1, 12, 0.1) var MAX_SPEED = 5
export(float, 0.05, 2, 0.05) var MAX_FORCE = 1

export(float, 1, 200, 0.5) var BREAK_RADIUS = 20
export(float, 0.15, 2, 0.01) var ARRIVED_RADIUS = 0.18

export(float, 10.0, 300.0, 0.5) var FOV_RADIUS = 160.0
export(float, 0.01, 2.0, 0.05) var FOV_ANGLE = 0.25

export(float, 0.1, 30.0, 0.1) var SEPARATION_RADIUS = 15
export(float, 0.8, 90.0, 0.1) var ALIGNMENT_RADIUS = 40
export(float, 0.8, 90.0, 0.1) var COHESION_RADIUS = 60

export(float, 1, 40, 0.1) var WANDER_RADIUS = 12
export(float, 5, 200, 0.5) var WANDER_DISTANCE = 40

export(BOID_MODE) var DEFAULT_MODE = BOID_MODE.WANDER
export(bool) var SHOW_DEBUG = true
export(bool) var KEEP_SEARCHING = true

var wanderAngleNoise : OpenSimplexNoise
var acceleration : Vector2 = Vector2(0,0)
var velocity : Vector2 = Vector2(0,0)
var targetInSight : bool = false
var wanderNoisePos : float = 0.0
var actualFOVAngle : float = 0
var wanderAngle : float = 0
var id : int = -1
var others = []

var lastTargetPos : Vector2
var target : Node
var mode

onready var screen_size = get_viewport_rect().size + Vector2(10, 10)

func setup(pos : Vector2, i : int, t : Node = null, m = DEFAULT_MODE):
	self.position = pos
	self.id = i
	self.target = t
	self.mode = m
	self.lastTargetPos = self.position
	
	if (self.mode == BOID_MODE.DRIFT):
		self.velocity = Vector2(MAX_SPEED, 0).rotated(randf()*2*PI)
	self.actualFOVAngle = FOV_ANGLE*(PI/2)
	initNoise()

func initNoise() -> void:
	self.wanderAngleNoise = OpenSimplexNoise.new()
	self.wanderAngleNoise.seed = randi()
	self.wanderAngleNoise.octaves = 3
	self.wanderAngleNoise.period = 15.0

func setOthers(o = []) -> void:
	self.others = o

func _process(_delta: float) -> void:
	getTargetPos()
	if not(hasArrived()):
		move()
		orient()
	update()
	
func _draw() -> void:
	if (SHOW_DEBUG):
		if (others.size() > 1):
			draw_empty_circle(Vector2.ZERO, SEPARATION_RADIUS, Color.white, 3)
			draw_empty_circle(Vector2.ZERO, ALIGNMENT_RADIUS, Color.white, 3)
		
		if (self.mode != BOID_MODE.DRIFT):
			var col : Color
			
			if (canWander()):
				col = Color.white
			elif not(hasArrived()):
				col = Color.yellow
			else:
				col = Color.green
			
			if not(hasArrived()):
				draw_line(Vector2.ZERO, Vector2(WANDER_DISTANCE, 0), col, 3)
				
			if (self.mode != BOID_MODE.WANDER):
				var p = Vector2(FOV_RADIUS, 0)
				draw_line(Vector2.ZERO, p.rotated(self.actualFOVAngle), col, 3)
				draw_line(Vector2.ZERO, p.rotated(-self.actualFOVAngle), col, 3)
				draw_arc(Vector2.ZERO, FOV_RADIUS, -self.actualFOVAngle, self.actualFOVAngle, 30, col, 3)

func draw_empty_circle(center : Vector2, radius : float, color : Color, thickness : float = 1.0) -> void:
	draw_arc(center, radius, 0, 2*PI, 80, color, thickness)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("draw_debug"):
		SHOW_DEBUG = not(SHOW_DEBUG)

func move() -> void:
	self.acceleration = getTotalAcceleration()
	self.velocity += self.acceleration
	self.position += self.velocity
	wrapAroundScreen()

func orient() -> void:
	if (self.mode != BOID_MODE.DRIFT):
		look_at(self.lastTargetPos)
		$Sprite.flip_v = ((self.velocity.x < 0 and self.mode == BOID_MODE.SEEK) or \
						  (self.velocity.x > 0 and self.mode == BOID_MODE.FLEE))

func getTotalAcceleration() -> Vector2:
	var output = getDesire()
	if not(self.mode in [BOID_MODE.SEEK, BOID_MODE.FLEE]):
		output += getSeparation()
		output += getAlignment()
		output += getCohesion()
		
	return output.clamped(MAX_FORCE)

func getCohesion() -> Vector2:
	var cohRadSQ : float = pow(COHESION_RADIUS*2, 2)
	var output : Vector2 = Vector2.ZERO
	var count : int = 0

	for o in self.others:
		var dist = o.position.distance_squared_to(self.position)
		if (o.id != self.id) and (dist <= cohRadSQ):
			output += o.position
			count += 1
	
	if (count > 0):
		output /= count
		output  = getDesireToPosition(output)
	
	return output

func getAlignment() -> Vector2:
	var alRadSQ : float = pow(ALIGNMENT_RADIUS*2, 2)
	var output : Vector2 = Vector2.ZERO
	var count : int = 0

	for o in self.others:
		var dist = o.position.distance_squared_to(self.position)
		if (o.id != self.id) and (dist <= alRadSQ):
			output += o.velocity
			count += 1
	
	if (count > 0):
		output /= count
		output  = (output.normalized() * MAX_SPEED)
		output -= self.velocity
	
	return output

func getSeparation() -> Vector2:
	var sepRadSQ : float = pow(SEPARATION_RADIUS*2, 2)
	var output : Vector2 = Vector2.ZERO
	var count : int = 0

	for o in self.others:
		var dist = o.position.distance_squared_to(self.position)
		if (o.id != self.id) and (dist <= sepRadSQ):
			var diff : Vector2 = (self.position - o.position).normalized()
			output += diff
			count += 1
	
	if (count > 0):
		output /= count
		output  = (output.normalized() * MAX_SPEED)
		output -= self.velocity
	
	return output

func getDesire() -> Vector2:
	return getDesireToPosition(self.lastTargetPos)

func getDesireToPosition(pos : Vector2) -> Vector2:
	var desire = Vector2.ZERO
	
	if (self.mode != BOID_MODE.DRIFT):
		var mult : float = -1
		desire = pos - self.position
		
		if (canWander()):
			mult = MAX_SPEED
		elif (self.mode == BOID_MODE.SEEK):
			var tDist = pos.distance_squared_to(self.position)
			mult = smootherstep(0, BREAK_RADIUS, sqrt(tDist)) * MAX_SPEED
		elif (self.mode == BOID_MODE.FLEE):
			mult = -MAX_SPEED
	
		desire = (desire.normalized() * mult) - self.velocity
		
	return desire

func getTargetPos() -> void:
	var actualPos : Vector2 = getActualTargetPos()
	self.targetInSight = isPositionInSight(actualPos)
	
	if (canWander()):
		self.lastTargetPos = self.position + getWanderTargetPos()
	elif self.targetInSight:
		self.lastTargetPos = actualPos

func getWanderTargetPos() -> Vector2:
	self.wanderAngle += self.wanderAngleNoise.get_noise_1d(self.wanderNoisePos)*PI/6
	self.wanderNoisePos += 2
	return Vector2(WANDER_RADIUS, 0).rotated(self.wanderAngle)

func getActualTargetPos() -> Vector2:
	return get_global_mouse_position() if (self.target == null) else self.target.position

func getTargetDistance() -> float:
	return self.position.distance_squared_to(self.lastTargetPos)

func isPositionInSight(pos : Vector2) -> bool:
	var distance = pos.distance_squared_to(self.position)
	var distOK : bool = (distance <= pow(FOV_RADIUS,2))
	var angle : float = to_local(pos).angle()
	var angleOK : bool = (angle >= -self.actualFOVAngle) and (angle <= self.actualFOVAngle)
	
	return distOK and angleOK

func wrapAroundScreen() -> void:
	var width = screen_size.x
	var height = screen_size.y
	
	self.position.x = wrapf(self.position.x, -10, width)
	self.position.y = wrapf(self.position.y, -10, height)

func hasArrived() -> bool:
	return getTargetDistance() < pow(ARRIVED_RADIUS,2)

func canWander() -> bool:
	return (self.mode == BOID_MODE.WANDER or (not(self.targetInSight) and KEEP_SEARCHING))

func smootherstep(minVal : float, maxVal : float, val : float) ->  float:
	minVal = min(minVal, maxVal)
	maxVal = max(minVal, maxVal)
	val = clamp(val, minVal, maxVal)
	val = range_lerp(val, minVal, maxVal, 0.0, 1.0)

	return -2*pow(val,3) + 3*pow(val,2)
