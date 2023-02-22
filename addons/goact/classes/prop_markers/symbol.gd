extends PropMarker
class_name Symbol

var name: String

func _init(_name: String):
    self.name = _name

func _to_string():
    return "[Symbol({0})]".format([self.name])