class_name QuadTreeElement

extends Object

var position : Vector2 = Vector2.ZERO
var reference : Object = null
var id : String = ""

func _init(p : Vector2, i : String, r : Object = null) -> void:
	self.position = p
	self.id = i
	self.reference = r

func duplicate() -> QuadTreeElement:
	return get_script().new(self.position, self.id, self.reference)
