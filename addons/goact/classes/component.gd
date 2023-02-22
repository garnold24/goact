extends Object
class_name Component

enum LifecyclePhase {
	# Component methods
	INIT,
	RENDER,
	SHOULD_UPDATE,
	WILL_UPDATE,
	DID_MOUNT,
	DID_UPDATE,
	WILL_UNMOUNT,

	# Phases describing reconciliation status
	RECONCILE_CHILDREN,
	IDLE,
}

# consts

#	Calling setState during certain lifecycle allowed methods has the potential
#	to create an infinitely updating component. Rather than time out, we exit
#	with an error if an unreasonable number of self-triggering updates occur
const MAX_PENDING_UPDATES: int = 100

# instance properties
var reconciler: Reconciler
var virtual_node: VirtualNode
var component_class: Script
var lifecycle_phase: LifecyclePhase = LifecyclePhase.INIT
var pending_state: Variant
var props: Dictionary
var state: Dictionary
var context: Dictionary

#	Get Default Props (GDscript does not allow extended classes to override parents' default variables, so a virtual static function will have to do)
static func _get_default_props() -> Dictionary:
	const DEFAULT_PROPS: Dictionary = {}
	return DEFAULT_PROPS

#	LifeCycle Methods (implemented by extension)

func _init(_reconciler: Reconciler, _virtual_node: VirtualNode, _component_class: Script, _props: Dictionary):
	# used with Component.new(), should *not* be overridden
	self.reconciler = _reconciler
	self.virtual_node = _virtual_node
	self.component_class = _component_class
	self.props = _props
	self.state = {}

func _comp_init(_initialProps: Dictionary):
	# i'd really like to call this _init but that's used by the constructor >:(
	pass

func _render() -> Variant:
	# unoptionally must be implemented by extended component, so if this block runs it should error
	return null

func _did_mount():
	pass

static func _get_derived_state_from_props(_next_props: Variant, _last_state: Variant) -> Variant:
	return null

func _should_update(_incoming_props: Dictionary, _incoming_state: Dictionary) -> bool:
	return true

func _will_update(_next_props: Dictionary, _next_state: Dictionary):
	pass

func _did_update(_previous_props: Variant, _previous_state: Variant):
	pass

func _will_unmount():
	pass

#	Get derived state when updating
func get_derived_state(incoming_props: Variant, incoming_state: Variant):
	var _derived_state = component_class._get_derived_state_from_props(incoming_props, incoming_state)
	if typeof(_derived_state) != TYPE_NIL:
		# type check eventually?
		return _derived_state
	return null

# 	State Setter:
func set_state(map_state: Variant):
	#	When preparing to update, render, or unmount, it is not safe
	#	to call `setState` as it will interfere with in-flight updates. It's
	#	also disallowed during unmounting

	match lifecycle_phase:
		LifecyclePhase.SHOULD_UPDATE:
			printerr("""setState cannot be used in the shouldUpdate lifecycle method.
			shouldUpdate must be a pure function that only depends on props and state.
			
			Check the definition of shouldUpdate in the component {0}.""".format([component_class]))
			return
		LifecyclePhase.WILL_UPDATE:
			printerr("""setState cannot be used in the willUpdate lifecycle method.
			Consider using the didUpdate method instead, or using getDerivedStateFromProps.
			
			Check the definition of willUpdate in the component {0}.""".format([component_class]))
			return
		LifecyclePhase.RENDER:
			printerr("""setState cannot be used in the render method.
			render must be a pure function that only depends on props and state.
			
			Check the definition of render in the component {0}.""".format([component_class]))
			return
		LifecyclePhase.WILL_UNMOUNT:
			# Should not print error message. See https://github.com/facebook/react/pull/22114
			return
	
	var partial_state: Variant = null
	if typeof(map_state) == TYPE_CALLABLE:
		partial_state = map_state.call(pending_state if pending_state else state, props)
		if typeof(partial_state) == TYPE_NIL:
			return
	elif typeof(map_state) == TYPE_DICTIONARY:
		partial_state = map_state
	else:
		printerr("Invalid argument to set_state, expected lambda `Callable` or `Dictionary`")
	
	var new_state: Variant = null
	if typeof(pending_state) != TYPE_NIL:
		new_state = Component._assign(pending_state, [partial_state])
	else:
		new_state = Component._assign({}, [state, partial_state])

	if lifecycle_phase == LifecyclePhase.INIT:
		# 	If `set_state` is called in `comp_init`, we can skip triggering an update!
		state = Component._assign(new_state, [get_derived_state(props, new_state)])

	elif lifecycle_phase == LifecyclePhase.DID_MOUNT or lifecycle_phase == LifecyclePhase.DID_UPDATE or lifecycle_phase == LifecyclePhase.RECONCILE_CHILDREN:
		#	During certain phases of the component lifecycle, it's acceptable to
		#	allow `set_state` but defer the update until we're done with ones in flight.
		#	We do this by collapsing it into any pending updates we have.
		pending_state = Component._assign(new_state, [get_derived_state(props, new_state)])

	elif lifecycle_phase == LifecyclePhase.IDLE:
		#	Outside of our lifecycle, the state update is safe to make immediately
		update(null, new_state)
	
	else:
		# Something went wrong, error
		printerr("""setState can not be used in the current situation, because Roact doesn't know
		which part of the lifecycle this component is in.
		
		This is a bug in Roact.
		It was triggered by the component {0}.""".format([component_class]))

#	Internal method used by update to apply new props and state
#	
#	Returns true if the update was completed, false if it was cancelled by should_update
func resolve_update(incoming_props: Variant = null, incoming_state: Variant = null) -> bool:
	var old_props = props
	var old_state = state

	if typeof(incoming_props) == TYPE_NIL:
		incoming_props = old_props

	if typeof(incoming_state) == TYPE_NIL:
		incoming_state = old_state

	# Should Update
	lifecycle_phase = LifecyclePhase.SHOULD_UPDATE
	if not _should_update(incoming_props, incoming_state):
		lifecycle_phase = LifecyclePhase.IDLE
		return false

	# Will Update
	lifecycle_phase = LifecyclePhase.WILL_UPDATE
	_will_update(incoming_props, incoming_state)

	# Render
	lifecycle_phase = LifecyclePhase.RENDER
	props = incoming_props
	state = incoming_state
	var render_result: Variant = virtual_node.instance._render()
	
	# Reconcile render result
	lifecycle_phase = LifecyclePhase.RECONCILE_CHILDREN
	reconciler.update_virtual_node_with_render_result(virtual_node, virtual_node.host_parent, render_result)

	# Did Update
	lifecycle_phase = LifecyclePhase.DID_UPDATE
	_did_update(old_props, old_state)

	lifecycle_phase = LifecyclePhase.IDLE

	return true

#	Internal method used by setState (to trigger updates based on state) and by
#	the reconciler (to trigger updates based on props)
#
#	Returns true if the update was completed, false if it was cancelled by should_update
func update(updated_element: Variant = null, _updated_state: Variant = null) -> bool:
	var new_props = props
	if typeof(updated_element) != TYPE_NIL:
		new_props = Component._assign({}, [component_class._get_default_props(), updated_element.props]) 

	var update_count: int = 0
	while true:
		var _final_state = null
		var _pending_state = null

		# Consume any pending state we might have
		if typeof(pending_state) != TYPE_NIL:
			_pending_state = pending_state
			pending_state = null
		
		# Consume a standard update to state or props
		if typeof(_updated_state) != TYPE_NIL or new_props != props:
			if typeof(_pending_state) == TYPE_NIL:
				_final_state = _updated_state if typeof(_updated_state) != TYPE_NIL else state
			else:
				_final_state = Component._assign(_pending_state, [_updated_state])
			
			var derived_state = get_derived_state(new_props, _final_state)
			if typeof(derived_state) != TYPE_NIL:
				_final_state = Component._assign({}, [_final_state, derived_state])
			
			_updated_state = null
		else:
			_final_state = _pending_state

		if not resolve_update(new_props, _final_state):
			# If the update was short-circuited, bubble the result up to the caller
			return false

		update_count += 1

		if update_count > MAX_PENDING_UPDATES:
			printerr("""The component `{0}` has reached the setState update recursion limit.
			When using `setState` in `didUpdate`, make sure that it won't repeat infinitely!""".format([component_class]))

		if pending_state == null:
			break
	
	return true

#	Internal method used by the reconciler to clean up any resources held by
#	this component instance.
func unmount():
	self.lifecycle_phase = LifecyclePhase.WILL_UNMOUNT
	self._will_unmount()

	for child_node in virtual_node.children.values():
		reconciler.unmount_virtual_node(child_node)

#	Static Methods: these will be called by the reconciler

static func _assign(target: Dictionary, sources: Array[Dictionary]):
	# merge all the dictionaries in Array to the target
	for source in sources:
		if source:
			for key in source:
				var val: Variant = source[key]
				if typeof(val) == TYPE_OBJECT and (val is Symbol) and val == Goact.None:
					if target.has(key):
						target.erase(key)
				else:
					target[key] = val
			
	return target

#	An internal method used by the reconciler to construct a new component
#	instance and attach it to the given virtualNode.

static func __mount(_component_class: Script, _reconciler: Reconciler, _virtual_node: VirtualNode):
	var _current_element: Element = _virtual_node.current_element
	var _host_parent: Object = _virtual_node.host_parent

	# merge default props and element.props into _props
	var _default_props: Dictionary = _component_class._get_default_props()
	var _props: Dictionary = Component._assign({}, [_default_props, _current_element.props])
	
	# assign context

	# create a new instance of component_type
	var instance: Component = _component_class.new(_reconciler, _virtual_node, _component_class, _props)
	_virtual_node.instance = instance

	# set initial state
	var derived_state = instance.get_derived_state(instance.props, {})
	if typeof(derived_state) != TYPE_NIL:
		instance.state = Component._assign({}, [derived_state])

	# call _comp_init()
	instance._comp_init(instance.props)

	# assign state after comp_init()
	derived_state = instance.get_derived_state(instance.props, instance.state)
	if typeof(derived_state) != TYPE_NIL:
		Component._assign(instance.state, [derived_state])
	
	# It's possible for comp_init() to redefine _context!
	_virtual_node.legacy_context = instance.context

	# render component
	instance.lifecycle_phase = LifecyclePhase.RENDER
	var render_result: Variant = instance._render()
	
	# reconcile result
	instance.lifecycle_phase = LifecyclePhase.RECONCILE_CHILDREN
	_reconciler.update_virtual_node_with_render_result(_virtual_node, _host_parent, render_result)

	# did mount phase
	instance.lifecycle_phase = LifecyclePhase.RECONCILE_CHILDREN
	instance._did_mount()

	if instance.pending_state:
		instance.update(null, null)

	instance.lifecycle_phase = LifecyclePhase.IDLE