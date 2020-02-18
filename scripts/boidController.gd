class_name Boid

extends Node2D

enum BOID_MODE { SEEK, FLEE }

export(float, 0.1, 12, 0.1) var MAX_SPEED = 5
export(float, 0.05, 2, 0.05) var MAX_FORCE = 1
export(float, 1, 200, 0.5) var BREAK_RADIUS = 20
export(float, 0, 2, 0.01) var ARRIVED_RADIUS = 0.01
export(BOID_MODE) var DEFAULT_MODE = BOID_MODE.SEEK

var velocity : Vector2 = Vector2(0,0)
var acceleration : Vector2 = Vector2(0,0)
var mode = null
var targetMouse : bool = false
var target : Node = null

func setup(pos : Vector2, t : Node = null, m = null):
	self.position = pos
	self.targetMouse = (t==null)
	self.target = t
	self.mode = m if m != null else DEFAULT_MODE

func _process(delta: float) -> void:
	var tPos : Vector2 = getTargetPos()
	var tDist : float = tPos.distance_to(self.position)
	
	if (tDist >= ARRIVED_RADIUS):
		self.acceleration = (getDesire() - self.velocity).clamped(MAX_FORCE)
		self.velocity += self.acceleration
		self.position += self.velocity
		self.acceleration *= 0
		
		orientTowardsTarget()

func orientTowardsTarget() -> void:
	var tPos : Vector2 = getTargetPos()
	look_at(tPos)
	$Sprite.flip_v = (self.velocity.x < 0)

func getDesire() -> Vector2:
	var tPos : Vector2 = getTargetPos()
	var tDist : float = tPos.distance_to(self.position)
	var mult : float = MAX_SPEED
	
	var desire = tPos - self.position
	if (self.mode == BOID_MODE.FLEE):
		mult = -1
	elif (tDist <= BREAK_RADIUS):
		mult = range_lerp(tDist, BREAK_RADIUS, 0, MAX_SPEED, 0)

	desire = desire.normalized() * mult
	
	return desire

func getTargetPos() -> Vector2:
	return get_global_mouse_position() if self.targetMouse else self.target.position
