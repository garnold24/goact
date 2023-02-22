extends Node

var renderer: Renderer
var reconciler: Reconciler

# prop marker children
var Children: Symbol = Symbol.new("Children")
var Ref: Symbol = Symbol.new("Ref")
var Portal: Symbol = Symbol.new("Portal")
var None: Symbol = Symbol.new("None")
var Change: PropMarkerMap = PropMarkerMap.new("Change")
var Event: PropMarkerMap = PropMarkerMap.new("Event")

# pack_args util function
func _pack_args_base(
		arg0: Variant = null, 
		arg1: Variant = null, 
		arg2: Variant = null, 
		arg3: Variant = null, 
		arg4: Variant = null, 
		arg5: Variant = null, 
		arg6: Variant = null, 
		arg7: Variant = null, 
		arg8: Variant = null, 
		arg9: Variant = null, 
	):

	var packed_stack: Array = [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]
	# pop until we get a callable, then call with the rest of the args
	while packed_stack.size() > 0:
		var top: Variant = packed_stack.pop_back()
		if typeof(top) == TYPE_CALLABLE:
			return top.call(packed_stack)

func pack_args(lambda: Callable):
	return _pack_args_base.bind(lambda)

func create_element(component, props: Dictionary = {}, children: Dictionary = {}) -> Element:
	return Element.new(component, props, children)

func create_fragment():
	pass

func create_ref():
	return GoactRef.create()

func create_binding(initial_value: Variant) -> Array:
	return GoactBinding.create(initial_value)

func join_bindings():
	pass

func create_context():
	pass

func mount(element: Element, host_parent, host_key: String) -> VirtualTree:
	return reconciler.mount_virtual_tree(element, host_parent, host_key)

func unmount(tree: VirtualTree) -> void:
	reconciler.unmount_virtual_tree(tree)

func update(tree: VirtualTree, new_element: Element) -> VirtualTree:
	return reconciler.update_virtual_tree(tree, new_element)

# Called when the node enters the scene tree for the first time.
func _ready():
	renderer = GodotRenderer.new()
	reconciler = Reconciler.new(renderer)
