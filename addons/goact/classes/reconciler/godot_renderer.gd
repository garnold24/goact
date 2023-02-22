extends Renderer
class_name GodotRenderer

static func _apply_ref(ref: GoactRef, _new_host_object: Variant):
    if ref:
        ref.current = _new_host_object


static func _set_godot_node_property(host_object: Node, key: StringName, new_value: Variant):

    host_object[key] = new_value
    #var err: int = ClassDB.class_set_property(host_object, key, new_value)
    #if err != OK:
        #printerr("set node property: invalid data provided: ", err)


static func _attach_binding(virtual_node: VirtualNode, key: Variant, new_binding: GoactBinding):
    var update_bound_property = func(new_value: Variant):
        _set_godot_node_property(virtual_node.host_object, key, new_value)
        #should probably check for error
    
    virtual_node.bindings[key] = new_binding.subscribe(update_bound_property)
    update_bound_property.call(new_binding.get_value())


static func _remove_binding(virtual_node: VirtualNode, key: Variant):
    if virtual_node.bindings: 
        if not virtual_node.bindings.has(key):
            return
        
        virtual_node.bindings[key].call()
        virtual_node.bindings.erase(key)


static func _detatch_all_bindings(virtual_node):
    if virtual_node.bindings:
        for key in virtual_node.bindings:
            virtual_node.bindings[key].call()
        virtual_node.bindings.clear()


static func _apply_prop(virtual_node: VirtualNode, key: Variant, new_value: Variant, old_value: Variant = null):
    if typeof(new_value) == typeof(old_value):
        if new_value == old_value:
            return
    
    if (typeof(key) == TYPE_OBJECT) and (key is Symbol):
        if key == Goact.Ref or key == Goact.Children:
            # Refs and children are handled in a separate pass
            return
        
        if key.type == Goact.Event:
            if not virtual_node.event_manager:
                virtual_node.event_manager = HostEventManager.new(virtual_node.host_object)

            # set up event signal
            var event_name: String = key.name
            virtual_node.event_manager.connect_event(event_name, new_value)

            return

    if old_value is GoactBinding:
        _remove_binding(virtual_node, key)

    if new_value is GoactBinding:
        _attach_binding(virtual_node, key, new_value)
        return
    
    _set_godot_node_property(virtual_node.host_object, key, new_value)


static func _apply_props(virtual_node: VirtualNode, props: Dictionary):
    for key in props:
        _apply_prop(virtual_node, key, props[key])


static func _update_props(virtual_node: VirtualNode, old_props: Dictionary, new_props):
    for key in new_props:
        var new_val: Variant = new_props[key]
        var old_val: Variant = null
        if old_props.has(key):
            old_val = old_props[key]
        _apply_prop(virtual_node, key, new_val, old_val)
    
    # clean up props that were removed
    for key in old_props:
        if not new_props.has(key):
            _apply_prop(virtual_node, key, null, old_props[key])


func is_host_node(target: Variant) -> bool:
    return typeof(target) == TYPE_OBJECT and target is Node


func mount_host_node(reconciler: Reconciler, virtual_node: VirtualNode):
    # can use ClassDB to create a new host node
    var element: Element = virtual_node.current_element
    var host_parent: Node = virtual_node.host_parent
    var host_key: String = virtual_node.host_key

    var instance: Node = ClassDB.instantiate(element.component)
    virtual_node.host_object = instance

    # apply props
    GodotRenderer._apply_props(virtual_node, element.props)
    instance.set_name(host_key)

    # mount children
    var children: Variant = element.props[Goact.Children]
    if typeof(children) != TYPE_NIL:
        reconciler.update_virtual_node_with_children(virtual_node, virtual_node.host_object, children)

    # parent instance to host parent
    host_parent.add_child(instance, true)

    # apply ref
    GodotRenderer._apply_ref(element.props[Goact.Ref], instance)
    
    # resume event manager if exists
    if virtual_node.event_manager != null:
        virtual_node.event_manager.resume()


func unmount_host_node(reconciler: Reconciler, virtual_node: VirtualNode):
    var element: Element = virtual_node.current_element

    GodotRenderer._apply_ref(element.props[Goact.Ref], null)

    for child_node in virtual_node.children.values():
        reconciler.unmount_virtual_node(child_node)
    
    # detach all bindings
    GodotRenderer._detatch_all_bindings(virtual_node)

    # tell parent to remove, then free instanced object
    var host_parent: Node = virtual_node.host_parent
    host_parent.remove_child(virtual_node.host_object)
    virtual_node.host_object.queue_free()
    virtual_node.host_object = null


func update_host_node(reconciler: Reconciler, virtual_node: VirtualNode, new_element: Element):
    var old_props: Dictionary = virtual_node.current_element.props
    var new_props: Dictionary = new_element.props

    # suspend event manager
    if virtual_node.event_manager != null:
        virtual_node.event_manager.suspend()

    # if refs changed detach old ref and attach new ref
    if old_props[Goact.Ref] != new_props[Goact.Ref]:
        GodotRenderer._apply_ref(old_props[Goact.Ref], null)
        GodotRenderer._apply_ref(new_props[Goact.Ref], virtual_node.host_object)

    GodotRenderer._update_props(virtual_node, old_props, new_props)

    var children: Variant = new_element.props[Goact.Children]
    if typeof(children) != TYPE_NIL or old_props[Goact.Children] != TYPE_NIL:
        reconciler.update_virtual_node_with_children(virtual_node, virtual_node.host_object, children)

    # resume event manager
    if virtual_node.event_manager != null:
        virtual_node.event_manager.resume()

    return virtual_node

