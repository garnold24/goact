extends Node

enum ElementUtils {
    UseParentKey
}

# If `elementOrElements` is a boolean or nil, this will return an iterator with
# zero elements.
class NoopIterator:
    var element_or_elements
    func _init(_element_or_elements):
        pass

    func _iter_init(_arg):
        return false

    func _iter_next(_arg):
        return false

    func _iter_get(_arg):
        return null


# If `elementOrElements` is a single element, this will return an iterator with
# one element: a tuple where the first value is ElementUtils.UseParentKey, and
# the second is the value of `elementOrElements`.
class SingleIterator:
    var element_or_elements: Element

    func _init(_element_or_elements: Element):
        self.element_or_elements = _element_or_elements

    func _iter_init(_arg):
        return true

    func _iter_next(_arg):
        return false

    func _iter_get(_arg):
        return [ElementUtils.UseParentKey, element_or_elements]


# If `elementOrElements` is a fragment or a Dictionary, this will return an iterator
# over all the elements of the Dictionary.
class PairsIterator:
    var element_or_elements: Dictionary
    var size: int = 0
    var index: int = 0

    var keys: Array

    func _init(_element_or_elements: Dictionary):
        self.element_or_elements = _element_or_elements
    
    func _iter_init(_arg):
        index = 0
        size = element_or_elements.size()
        keys = element_or_elements.keys()

        return index < size

    func _iter_next(_arg):
        index += 1
        return index < size

    func _iter_get(_arg):
        var key = self.keys[index]
        return [key, element_or_elements[key]]

func iterate_elements(element_or_elements = null) -> Variant:
    # Single child
    if element_or_elements is Element:
        return SingleIterator.new(element_or_elements)

    # get variant type
    var variant_type: int = typeof(element_or_elements)

    # bool or null elements
    if variant_type == TYPE_NIL or (element_or_elements is bool):
        return NoopIterator.new(element_or_elements)

    assert(variant_type == TYPE_DICTIONARY, "Invalid elements")
    return PairsIterator.new(element_or_elements)

func get_element_by_key(elements, host_key) -> Element:
    if elements == null or (elements is bool):
        return null
    
    if elements is Element:
        if host_key == ElementUtils.UseParentKey:
            return elements
        return null

    var variant_type: int = typeof(elements)
    assert(variant_type == TYPE_DICTIONARY, "Invalid elements")
    return elements[host_key]

