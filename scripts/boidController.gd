class_name Boid

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER }

export(float, 0.1, 12, 0.1) var MAX_SPEED = 5
export(float, 0.05, 2, 0.05) var MAX_FORCE = 1
export(float, 1, 200, 0.5) var BREAK_RADIUS = 20
export(float, 0.15, 2, 0.01) var ARRIVED_RADIUS = 0.15
export(float, 10.0, 300.0, 0.5) var FOV_RADIUS = 160.0
export(float, 0.01, 2.0, 0.05) var FOV_ANGLE = 0.25
export(float, 1, 40, 0.1) var WANDER_RADIUS = 12
export(float, 5, 200, 0.5) var WANDER_DISTANCE = 40
export(BOID_MODE) var DEFAULT_MODE = BOID_MODE.SEEK
export(bool) var KEEP_SEARCHING = true

var wanderAngleNoise : OpenSimplexNoise
var acceleration : Vector2 = Vector2(0,0)
var velocity : Vector2 = Vector2(0,0)
var targetInSight : bool = false
var wanderNoisePos : float = 0.0
var wanderAngle : float = 0
var lastTargetPos : Vector2
var target : Node
var mode

onready var screen_size = get_viewport_rect().size

func setup(pos : Vector2, t : Node = null, m = null):
	self.position = pos
	self.target = t
	self.mode = m if m != null else DEFAULT_MODE
	self.lastTargetPos = self.position
	self.wanderAngleNoise = OpenSimplexNoise.new()
	self.wanderAngleNoise.seed = randi()
	self.wanderAngleNoise.octaves = 3
	self.wanderAngleNoise.period = 15.0

func _process(_delta: float) -> void:
	getTargetPos()
	if (getTargetDistance() >= ARRIVED_RADIUS):
		move()
		orient()
	update()
	
func move() -> void:
	self.acceleration = (getDesire() - self.velocity).clamped(MAX_FORCE)
	self.velocity += self.acceleration
	self.position += self.velocity
	self.acceleration *= 0
	wrapAroundScreen()

func _draw() -> void:
	var col : Color = Color.green if self.targetInSight else Color.white
	
	draw_line(Vector2(0,0), Vector2(WANDER_DISTANCE, 0), col, 3)
	
	if (self.mode != BOID_MODE.WANDER):
		var p = Vector2(FOV_RADIUS, 0)
		var angle = (FOV_ANGLE*PI)/2
		draw_line(Vector2.ZERO, p.rotated(angle), col, 3)
		draw_line(Vector2.ZERO, p.rotated(-angle), col, 3)
		draw_arc(Vector2.ZERO, FOV_RADIUS, -angle, angle, 30, col, 3)
	
func orient() -> void:
	look_at(self.lastTargetPos)
	$Sprite.flip_v = ((self.velocity.x < 0 and self.mode == BOID_MODE.SEEK) or \
					  (self.velocity.x > 0 and self.mode == BOID_MODE.FLEE))

func getDesire() -> Vector2:
	var tDist : float = self.lastTargetPos.distance_to(self.position)
	var mult : float = -1
	
	var desire = self.lastTargetPos - self.position
	
	if (canWander()):
		mult = MAX_SPEED
	elif (self.mode == BOID_MODE.SEEK):
		mult = smootherstep(0, BREAK_RADIUS, tDist) * MAX_SPEED
	elif (self.mode == BOID_MODE.FLEE):
		mult = -MAX_SPEED

	desire = desire.normalized() * mult
	
	return desire

func getTargetPos() -> void:
	var actualPos : Vector2 = getActualTargetPos()
	self.targetInSight = isPositionInSight(actualPos)
	
	if (canWander()):
		self.lastTargetPos = self.position + getNextWanderTarget()
	elif self.targetInSight:
		self.lastTargetPos = actualPos

func getNextWanderTarget() -> Vector2:
	self.wanderAngle += self.wanderAngleNoise.get_noise_1d(self.wanderNoisePos)*PI/6
	self.wanderNoisePos += 2
	return Vector2(WANDER_RADIUS, 0).rotated(self.wanderAngle)

func getActualTargetPos() -> Vector2:
	return get_global_mouse_position() if (self.target == null) else self.target.position
	
func getTargetDistance() -> float:
	return self.position.distance_to(self.lastTargetPos)

func isPositionInSight(pos : Vector2) -> bool:
	var distance = pos.distance_to(self.position)
	var angle : float = to_local(pos).angle()
	var actualFOVAngle = FOV_ANGLE*PI/2
	
	return (distance <= FOV_RADIUS) and isFloatInRange(angle, -actualFOVAngle, actualFOVAngle)

func isFloatInRange(val : float, minVal : float, maxVal : float) -> bool:
	return (val >= minVal) and (val <= maxVal)

func wrapAroundScreen() -> void:
	var width = screen_size.x
	var height = screen_size.y
	
	self.position.x = wrapf(self.position.x, 0, width)
	self.position.y = wrapf(self.position.y, 0, height)

func canWander() -> bool:
	return (self.mode == BOID_MODE.WANDER or (not(self.targetInSight) and KEEP_SEARCHING))

func smootherstep(minVal : float, maxVal : float, val : float) ->  float:
	minVal = min(minVal, maxVal)
	maxVal = max(minVal, maxVal)
	val = clamp(val, minVal, maxVal)
	val = range_lerp(val, minVal, maxVal, 0.0, 1.0)

	return -2*pow(val,3) + 3*pow(val,2)
