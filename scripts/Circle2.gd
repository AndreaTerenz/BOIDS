class_name Circle2

extends Object

var center : Vector2
var radius : float
var radiusSq : float

func _init(c : Vector2, r : float) -> void:
	self.center = c
	self.radius = abs(r)
	self.radiusSq = r*r
	
func has_point(pos : Vector2) -> bool:
	var dist = self.center.distance_squared_to(pos)
	return dist <= radiusSq
	
func intersects(other : Circle2) -> bool:
	var distance = self.center.distance_squared_to(other.center)
	var radSqSum = pow(self.radius + other.radius, 2)
	return distance <= radSqSum

func intersectsRect(rect : Rect2) -> bool:
	var tempX : float = self.center.x
	var tempY : float = self.center.y
	
	if self.center.x < rect.position.x:
		tempX = rect.position.x
	elif center.x > rect.position.x + rect.size.x:
		tempX = rect.position.x + rect.size.x
		
	if self.center.y < rect.position.y:
		tempY = rect.position.y
	elif self.center.y > rect.position.y + rect.size.y:
		tempY = rect.position.y + rect.size.y
		
	var deltaX : float = self.center.x - tempX
	var deltaY : float = self.center.y - tempY
	var dist : float = deltaX*deltaX + deltaY*deltaY
	
	return dist <= self.radius*self.radius
