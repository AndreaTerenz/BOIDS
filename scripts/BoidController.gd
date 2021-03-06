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

export(bool) var KEEP_SEARCHING = true

var wanderAngleNoise : OpenSimplexNoise
var acceleration : Vector2 = Vector2(0,0)
var velocity : Vector2 = Vector2(0,0)
var targetInSight : bool = false
var wanderNoisePos : float = 0.0
var actualFOVAngle : float = 0
var wanderAngle : float = 0
var debug : bool = true
var id : int = -1
var parent = null

var lastTargetPos : Vector2
var target : Node
var mode

onready var screen_size = get_viewport_rect().size + Vector2(10, 10)

func _init(pos : Vector2, i : int, trgt : Node, prnt, m, scn : PackedScene, dbg : bool = true) -> void:
	self.position = pos
	self.id = i
	self.parent = prnt
	self.target = trgt
	self.mode = m
	self.debug = dbg
	initNoise()
	
	if (self.mode == BOID_MODE.DRIFT):
		self.velocity = Vector2(MAX_SPEED, 0).rotated(randf()*2*PI)
	self.actualFOVAngle = FOV_ANGLE*(PI/2)
	
	var scene : Node = scn.instance()
	self.add_child(scene)
	
	getTargetPos()

func initNoise() -> void:
	self.wanderAngleNoise = OpenSimplexNoise.new()
	self.wanderAngleNoise.seed = randi()
	self.wanderAngleNoise.octaves = 3
	self.wanderAngleNoise.period = 15.0

func _draw() -> void:
	var othersCount = self.parent.getBoidsCount()
	
	if (self.parent.showDebug):
		if not(self.mode in [BOID_MODE.WANDER, BOID_MODE.DRIFT]):
			var p = Vector2(FOV_RADIUS, 0)
			var col : Color
			var wand : bool = canWander()
			var arr : bool = hasArrived()
			
			match (true):
				wand : col = Color.white
				arr : col = Color.green
				_ : col = Color.yellow
			
			if not(hasArrived()):
				draw_line(Vector2.ZERO, Vector2(WANDER_DISTANCE, 0), col, 3)
			
			draw_line(Vector2.ZERO, p.rotated(self.actualFOVAngle), col, 3)
			draw_line(Vector2.ZERO, p.rotated(-self.actualFOVAngle), col, 3)
			draw_arc(Vector2.ZERO, FOV_RADIUS, -self.actualFOVAngle, self.actualFOVAngle, 30, col, 3)
		elif (othersCount > 1):
			draw_empty_circle(Vector2.ZERO, COHESION_RADIUS, Color.blue, 3)
			draw_empty_circle(Vector2.ZERO, SEPARATION_RADIUS, Color.red, 3)
			draw_empty_circle(Vector2.ZERO, ALIGNMENT_RADIUS, Color.green, 3)

func draw_empty_circle(center : Vector2, radius : float, color : Color, thickness : float = 1.0) -> void:
	draw_arc(center, radius, 0, 2*PI, 80, color, thickness)

func move() -> void:
	if not(hasArrived()):
		self.position += self.velocity
		wrapAroundScreen()
		orient()
	update()

func setVelocity() -> void:
	if not(hasArrived()):
		getTargetPos()
		self.acceleration = getTotalAcceleration()
		self.velocity += self.acceleration

func orient() -> void:
	if (self.mode != BOID_MODE.DRIFT):
		look_at(self.lastTargetPos)
		$Sprite.flip_v = ((self.velocity.x < 0 and self.mode == BOID_MODE.SEEK) or \
						  (self.velocity.x > 0 and self.mode == BOID_MODE.FLEE))

func getTotalAcceleration() -> Vector2:
	var output = getDesire()
	output += getFlockForces()
		
	return output.clamped(MAX_FORCE)

func getFlockForces() -> Vector2:
	var totalOutput : Vector2 = Vector2.ZERO
	var maxRadius : int = [SEPARATION_RADIUS, COHESION_RADIUS, ALIGNMENT_RADIUS].max()
	var others : Array = self.parent.getOtherBoidsInRange(self, maxRadius*2)
	
	if (others.size() > 0):
		var cohIndx = 0
		var sepIndx = 1
		var alIndx = 2
		var counts : Array = [0, 0, 0]
		var outputs : Array = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		
		for o in others:
			var dist = o.position.distance_squared_to(self.position)
			if (dist <= pow(COHESION_RADIUS*2,2)):
				outputs[cohIndx] += o.position
				counts[cohIndx] += 1
			if (dist <= pow(ALIGNMENT_RADIUS*2,2)):
				outputs[alIndx] += o.velocity
				counts[alIndx] += 1
			if (dist <= pow(SEPARATION_RADIUS*2, 2)):
				var diff : Vector2 = (self.position - o.position).normalized()
				outputs[sepIndx] += diff
				counts[sepIndx] += 1
		
		if (counts[sepIndx] > 0):
			outputs[sepIndx] /= counts[sepIndx]
			outputs[sepIndx] = (outputs[sepIndx].normalized() * MAX_SPEED)
			totalOutput += outputs[sepIndx] - self.velocity
		if not(self.mode in [BOID_MODE.SEEK, BOID_MODE.FLEE]):
			if (counts[cohIndx] > 0):
				outputs[cohIndx] /= counts[cohIndx]
				totalOutput += getDesireToPosition(outputs[cohIndx])
			if (counts[alIndx] > 0):
				outputs[alIndx] /= counts[alIndx]
				outputs[alIndx] = (outputs[alIndx].normalized() * MAX_SPEED)
				totalOutput += outputs[alIndx] - self.velocity

	return totalOutput

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
	if not(self.is_inside_tree()):
		self.lastTargetPos = self.position + getWanderTargetPos()
	else:
		var actualPos : Vector2 = self.target.position
		self.targetInSight = isPositionInSight(actualPos)
		
		if (canWander()):
			self.lastTargetPos = self.position + getWanderTargetPos()
		elif self.targetInSight:
			self.lastTargetPos = actualPos

func getWanderTargetPos() -> Vector2:
	self.wanderAngle += self.wanderAngleNoise.get_noise_1d(self.wanderNoisePos)*PI/6
	self.wanderNoisePos += 2
	return Vector2(WANDER_RADIUS, 0).rotated(self.wanderAngle)

func getActualTargetDistance() -> float:
	return self.target.position.distance_squared_to(self.position)

func getTargetDistance() -> float:
	return self.position.distance_squared_to(self.lastTargetPos)

func isPositionInSight(pos : Vector2) -> bool:
	var distance = pos.distance_squared_to(self.position)
	var angle : float = to_local(pos).angle()
	return (distance <= pow(FOV_RADIUS,2)) and (angle >= -self.actualFOVAngle) and (angle <= self.actualFOVAngle)

func wrapAroundScreen() -> void:
	var width = screen_size.x
	var height = screen_size.y
	
	self.position.x = wrapf(self.position.x, -10, width)
	self.position.y = wrapf(self.position.y, -10, height)

func hasArrived() -> bool:
	return getActualTargetDistance() < pow(ARRIVED_RADIUS,2)

func canWander() -> bool:
	return (self.mode == BOID_MODE.WANDER or (not(self.targetInSight) and KEEP_SEARCHING))

func smootherstep(minVal : float, maxVal : float, val : float) ->  float:
	minVal = min(minVal, maxVal)
	maxVal = max(minVal, maxVal)
	val = clamp(val, minVal, maxVal)
	val = range_lerp(val, minVal, maxVal, 0.0, 1.0)

	return -2*pow(val,3) + 3*pow(val,2)
