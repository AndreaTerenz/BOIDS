class_name QuadTreeElement

extends Object

var position : Vector2 = Vector2.ZERO
var reference : Object = null

func _init(p : Vector2, r : Object = null) -> void:
	self.position = p
	self.reference = r

func duplicate() -> QuadTreeElement:
	return get_script().new(self.position, self.reference)
