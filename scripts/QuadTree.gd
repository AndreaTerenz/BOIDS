class_name QuadTree

extends Object

var bounds : Rect2 = Rect2(0, 0, 0, 0)
var elements : Array = []
var children : Array = []
var capacity : int = -1
var id : String = ""
var isDivided : bool = false

func _init(bnds : Rect2, cap : int = 5, i : String = "0") -> void:
	self.bounds = bnds
	self.id = i
	self.capacity = cap
	
func divide() -> void:
	var startX = self.bounds.position.x
	var startY = self.bounds.position.y
	var halfWidth = self.bounds.size.x / 2
	var halfHeight = self.bounds.size.y / 2
	
	self.children.append(get_script().new(Rect2(startX, startY, halfWidth, halfHeight), self.capacity, self.id+".0"))
	self.children.append(get_script().new(Rect2(startX+halfWidth, startY, halfWidth, halfHeight), self.capacity, self.id+".1"))
	self.children.append(get_script().new(Rect2(startX, startY+halfHeight, halfWidth, halfHeight), self.capacity, self.id+".2"))
	self.children.append(get_script().new(Rect2(startX+halfWidth, startY+halfHeight, halfWidth, halfHeight), self.capacity, self.id+".3"))
	
	self.isDivided = true
	
	partition()

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

func allElements() -> Array:
	return elementsInRect(self.bounds)

func partition() -> void:
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
		for elem in self.elements:
			if circle.has_point(elem.position):
				output.append(elem)
		for child in children:
			for e in child.elementsInCircle(circle):
				output.append(e)
	
	return output

func elementsAroundElement(element : QuadTreeElement, radius : int) -> Array:
	var output = []
	var circle = Circle2.new(element.position, radius)
	if circle.intersectsRect(self.bounds):
		for elem in self.elements:
			if elem.id != element.id and circle.has_point(elem.position):
				output.append(elem)
		for child in children:
			for e in child.elementsInCircle(circle):
				output.append(e)
	
	return output

func objectsInRect(area : Rect2) -> Array:
	return elementsToReferences(elementsInRect(area))
	
func objectsInCircle(circle : Circle2) -> Array:
	return elementsToReferences(elementsInCircle(circle))

func objectsAroundElement(element : QuadTreeElement, radius : int) -> Array:
	return elementsToReferences(elementsAroundElement(element, radius))

func elementsToReferences(elements : Array) -> Array:
	var output = []
	for e in elements:
		output.append(e.reference)
	return output

func insert(qte : QuadTreeElement) -> bool:
	if (self.bounds.has_point(qte.position)):
		if (self.elements.size() < self.capacity and not(self.isDivided)):
			if not(self.elements.has(qte)):
				self.elements.append(qte)
				return true
			else:
				return false
		else:
			if not(self.isDivided):
				divide()
			for child in children:
				if child.insert(qte):
					return true
			return false #IF THIS HAPPENS WE ARE IN TROUBLE
	else:
		return false

func insertMany(qtes : Array) -> bool:
	var output : bool = true
	for qte in qtes:
		output = output and insert(qte)
	return output

func clear() -> void:
	for child in self.children:
		child.clear()
	self.children.clear()
	self.elements.clear()
	self.isDivided = false
