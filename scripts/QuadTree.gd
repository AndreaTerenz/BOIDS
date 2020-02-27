class_name QuadTree

extends Object

var bounds : Rect2 = Rect2(0, 0, 0, 0)
var elements : Array = []
var children : Array = []
var capacity : int = -1
var id : String = ""
var isDivided : bool = false

func _init(bnds : Rect2, cap : int = 5, i : String = "0") -> void:
	print("created QT - bounds: " + str(bnds) + " | capacity: " + str(cap) + " | id: " + i)
	self.bounds = bnds
	self.id = i
	self.capacity = cap
	
func divide() -> void:
	if not(self.isDivided):
		var startX = self.bounds.position.x
		var startY = self.bounds.position.y
		var halfWidth = self.bounds.size.x / 2
		var halfHeight = self.bounds.size.y / 2
		
		print(" ")
		self.children.append(get_script().new(Rect2(startX, startY, halfWidth, halfHeight), self.capacity, self.id+".0"))
		self.children.append(get_script().new(Rect2(startX+halfWidth, startY, halfWidth, halfHeight), self.capacity, self.id+".1"))
		self.children.append(get_script().new(Rect2(startX, startY+halfHeight, halfWidth, halfHeight), self.capacity, self.id+".2"))
		self.children.append(get_script().new(Rect2(startX+halfWidth, startY+halfHeight, halfWidth, halfHeight), self.capacity, self.id+".3"))
		
		self.isDivided = true

func printElements() -> void:
	for e in self.elements:
		print(str(e.position) + " | " + self.id)
	if (self.isDivided):
		for c in children:
			c.printElements()
			
func getBoundsList() -> Array:
	if not(self.isDivided):
		return [self.bounds]
	else:
		var output = []
		for child in self.children:
			for childBound in child.getBoundsList():
				output.append(childBound)
		return output

func getPointsList() -> Array:
	var output = []
	
	for elem in self.elements:
		output.append(elem.position)
	
	for child in children:
		for childPoint in child.getPointsList():
			output.append(childPoint)
	
	return output

func partitionElements() -> void:
	var count = self.elements.size()
	for e in self.elements:
		var copy = e.duplicate()
		for child in children:
			if child.insert(copy):
				break
	self.elements.clear()

func elementsInRect(area : Rect2) -> Array:
	var output = []
	if self.bounds.intersects(area):
		if not(self.isDivided):
			for elem in self.elements:
				if area.has_point(elem.position):
					output.append(elem)
		else:
			for child in children:
				for e in child.elementsInRect(area):
					output.append(e)
	
	return output
	
func elementsInCircle(circle : Circle2) -> Array:
	var output = []
	if circle.intersectsRect(self.bounds):
		if not(self.isDivided):
			for elem in self.elements:
				if circle.has_point(elem.position):
					output.append(elem)
		else:
			for child in children:
				for e in child.elementsInCircle(circle):
					output.append(e)
	
	return output

func insert(qte : QuadTreeElement) -> bool:
	if (self.bounds.has_point(qte.position)):
		if (self.elements.size() < self.capacity and not(self.isDivided)):
			self.elements.append(qte)
			return true
		else:
			var wasDivided = self.isDivided
			divide()
			if wasDivided != self.isDivided:
				partitionElements()
			for child in children:
				if child.insert(qte):
					return true
			return false #IF THIS HAPPENS WE ARE IN TROUBLE
	else:
		return false
