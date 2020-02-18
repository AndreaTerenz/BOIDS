class_name Boid

extends Node2D

enum BOID_MODE { SEEK, FLEE, WANDER }

export(float, 0.1, 12, 0.1) var MAX_SPEED = 5
export(float, 0.05, 2, 0.05) var MAX_FORCE = 1
export(float, 1, 200, 0.5) var BREAK_RADIUS = 20
export(float, 0, 2, 0.01) var ARRIVED_RADIUS = 0.01
export(float, 1, 40, 0.1) var WANDER_RADIUS = 12
export(float, 5, 200, 0.5) var WANDER_DISTANCE = 40
export(BOID_MODE) var DEFAULT_MODE = BOID_MODE.SEEK

var velocity : Vector2 = Vector2(0,0)
var acceleration : Vector2 = Vector2(0,0)
var wanderAngle = -1
var mode = null
var target : Node = null

onready var screen_size = get_viewport_rect().size

func setup(pos : Vector2, t : Node = null, m = null):
	self.position = pos
	self.target = t
	self.mode = m if m != null else DEFAULT_MODE
	self.wanderAngle = -1 if self.mode != BOID_MODE.WANDER else 0

func _process(_delta: float) -> void:
	var tPos : Vector2 = getTargetPos()
	var tDist : float = tPos.distance_to(self.position)
	
	if (tDist >= ARRIVED_RADIUS):
		self.acceleration = (getDesire() - self.velocity).clamped(MAX_FORCE)
		self.velocity += self.acceleration
		self.position += self.velocity
		self.acceleration *= 0
		wrapAroundScreen()
		orientTowardsTarget()

func orientTowardsTarget() -> void:
	var tPos : Vector2 = getTargetPos()
	look_at(tPos)
	$Sprite.flip_v = ((self.velocity.x < 0 and self.mode == BOID_MODE.SEEK) or \
					  (self.velocity.x > 0 and self.mode == BOID_MODE.FLEE))

func getDesire() -> Vector2:
	var tPos : Vector2 = getTargetPos()
	var tDist : float = tPos.distance_to(self.position)
	var mult : float = -1
	
	var desire = tPos - self.position
	
	match (self.mode):
		BOID_MODE.WANDER:
			mult = MAX_SPEED
		BOID_MODE.SEEK:
			mult = smootherstep(0, BREAK_RADIUS, tDist) * MAX_SPEED
		BOID_MODE.FLEE:
			mult = -1

	desire = desire.normalized() * mult
	
	return desire

func getTargetPos() -> Vector2:
	var output : Vector2 = Vector2(-1,-1)
	
	if self.mode == BOID_MODE.WANDER:
		var wanderCircleCenter : Vector2 = Vector2(WANDER_DISTANCE, 0)
		var wanderTarget : Vector2 = Vector2(0, 0)
		self.wanderAngle += range_lerp(randf(), 0, 1, -PI/10, PI/10)
		
		wanderTarget.x = (WANDER_RADIUS * cos(wanderAngle))
		wanderTarget.y = (WANDER_RADIUS * sin(wanderAngle))
		
		output = self.position + wanderCircleCenter + wanderTarget
	else:
		output = get_global_mouse_position() if self.target == null else self.target.position
	
	return output

func wrapAroundScreen() -> void:
	var width = screen_size.x
	var height = screen_size.y
	
	self.position.x = wrapValue(self.position.x, 0, width)
	self.position.y = wrapValue(self.position.y, 0, height)
	
func wrapValue(val : float, minVal : float, maxVal : float) ->  float:
	minVal = min(minVal, maxVal)
	maxVal = max(minVal, maxVal)
	
	if (val > maxVal):
		return minVal
	elif (val < minVal):
		return maxVal
	else:
		return val

func smootherstep(minVal : float, maxVal : float, val : float) ->  float:
	minVal = min(minVal, maxVal)
	maxVal = max(minVal, maxVal)
	val = clamp(val, minVal, maxVal)
	val = range_lerp(val, minVal, maxVal, 0.0, 1.0)

	return -2*pow(val,3) + 3*pow(val,2)
