extends Symbol
class_name MappedSymbol

var type: PropMarkerMap

func _init(_type: PropMarkerMap, _name: String):
    self.type = _type
    self.name = _name

func _to_string():
    return "[MappedSymbol({0}.{1})]".format([self.type.name, self.name])