extends PropMarker
class_name PropMarkerMap

var name: String
var instanced_changes: Dictionary 

# when indexed, check the dictionary for a symbol with name of property, if not already creted, create a new one
func _get(property: StringName) -> Variant:
    var prop_symbol: MappedSymbol = instanced_changes.get(property)
    if prop_symbol:
        return prop_symbol
    
    prop_symbol = MappedSymbol.new(self, property)
    instanced_changes[property] = prop_symbol
    return prop_symbol

func _init(_name: String):
    self.name = _name

func _to_string():
    return "PropMarkerMap({0})".format([name])