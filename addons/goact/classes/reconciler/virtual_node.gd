class_name VirtualNode

var current_element: Element
var host_key: String
var children: Dictionary
var instance: Object # can be a Godot 'Node' or 'Component'
var bindings: Dictionary

var event_manager: HostEventManager
var host_object: Object
var host_parent: Object
var parent
var context
var original_context
var legacy_context
var parent_legacy_context

var depth: int = 1
var update_children_count: int = 1
var was_unmounted: bool = false

func _init(_element: Element, _host_parent: Object, _host_key: String, _context = null, _legacy_context = null):
    self.current_element = _element
    self.host_key = _host_key
    self.host_parent = _host_parent

    self.bindings = {}
    self.children = {}