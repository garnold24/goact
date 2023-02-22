class_name Reconciler

var renderer: Renderer

func replace_virtual_node(node: VirtualNode, new_element: Element) -> VirtualNode:
    var host_parent = node.host_parent
    var host_key = node.host_key
    var depth = node.depth
    var parent = node.parent

    # If the node that is being replaced has modified context, we need to
    # use the original *unmodified* context for the new node
    # The `originalContext` field will be nil if the context was unchanged
    var context = node.original_context or node.context
    var parent_legacy_context = node.parent_legacy_context

    # If updating this node has caused a component higher up the tree to re-render
    # and updateChildren to be re-entered then this node could already have been
    # unmounted in the previous updateChildren pass.
    if not node.was_unmounted:
        unmount_virtual_node(node)

    var new_node: VirtualNode = mount_virtual_node(new_element, host_parent, host_key, context, parent_legacy_context)
    
    # mountVirtualNode can return nil if the element is a boolean (hmm idk about that one)
    if new_node:
        new_node.depth = depth
        new_node.parent = parent

    return new_node


# Utility to update the children of a virtual node based on zero or more
# updated children given as elements.
func update_children(node: VirtualNode, host_parent, new_child_elements):
    node.update_children_count += 1

    var current_count = node.update_children_count
    var remove_keys = {}

    # Changed or removed children
    for child_key in node.children:
        var child_node: VirtualNode = node.children[child_key]

        var new_element: Element = ElementUtils.get_element_by_key(new_child_elements, child_key)
        var new_node: VirtualNode = update_virtual_node(child_node, new_element)

        # If updating this node has caused a component higher up the tree to re-render
        # and updateChildren to be re-entered for this virtualNode then
        # this result is invalid and needs to be disgarded.
        if node.update_children_count != current_count:
            if new_node and new_node.children[child_key]:
                unmount_virtual_node(new_node)
            return
        
        if new_node:
            node.children[child_key] = new_node
        else:
            remove_keys[child_key] = true
    
    for child_key in remove_keys:
        node.children.erase(child_key)

    # added children
    for key_value_pair in ElementUtils.iterate_elements(new_child_elements):
        var child_key = key_value_pair[0]
        var new_element = key_value_pair[1]

        var concrete_key = child_key
        if (typeof(child_key) == TYPE_INT) and child_key == ElementUtils.ElementUtils.UseParentKey:
            concrete_key = node.host_key

        if not node.children.has(child_key):
            var child_node: VirtualNode = mount_virtual_node(
                new_element,
                host_parent,
                concrete_key,
                node.context,
                node.legacy_context,
            )
            
            # If updating this node has caused a component higher up the tree to re-render
            # and updateChildren to be re-entered for this virtualNode then
            # this result is invalid and needs to be discarded.
            if node.update_children_count != current_count:
                if child_node:
                    unmount_virtual_node(child_node)
                return

            # mount_virtual_node can return nil if the element is a boolean (can it though?)
            if child_node:
                child_node.depth = node.depth + 1
                child_node.parent = node
                node.children[child_key] = child_node

func update_virtual_node_with_children(virtual_node: VirtualNode, host_parent, new_child_elements):
    update_children(virtual_node, host_parent, new_child_elements)

func update_virtual_node_with_render_result(virtual_node: VirtualNode, host_parent, render_result):
    if (render_result == null) or (render_result is Element) or (render_result is bool):
        update_children(virtual_node, host_parent, render_result)
        return
    
    printerr("Component returned invalid children: " + (virtual_node.current_element.source if virtual_node.current_element.source else "<enable element tracebacks>") ) # these are weird ternaries, i don't think this will work lol

func unmount_virtual_node(node: VirtualNode):
    node.was_unmounted = true

    # call unmounting function based on type of elemen
    # todo make enum for element kinds
    var kind: Element.ElementKind = node.current_element.element_kind

    match kind:
        Element.ElementKind.Host:
            renderer.unmount_host_node(self, node)
        Element.ElementKind.Function:
            for child_node in node.children.values():
                unmount_virtual_node(child_node)
        Element.ElementKind.Stateful:
            node.instance.unmount()
        Element.ElementKind.Portal:
            pass
        Element.ElementKind.Fragment:
            pass
        _:
            printerr("Unknown ElementKind: ", kind)
    
        
func update_function_virtual_node(virtual_node: VirtualNode, new_element: Element):
    #element.component is a Callable
    var children = new_element.component.call(new_element.props)
    update_virtual_node_with_render_result(virtual_node, virtual_node.host_parent, children)
    return virtual_node

func update_portal_virtual_node(virtual_node: VirtualNode, _new_element: Element): #todo at some point in future
    return virtual_node

func update_fragment_virtual_node(virtual_node: VirtualNode, new_element: Element): #todo at some point in future
    # need to create a fragment element that has "elements" as a property
    update_virtual_node_with_children(virtual_node, virtual_node.host_parent, new_element.elements)

# Update the given virtual node using a new element describing what it
# should transform into.
# 
# `updateVirtualNode` will return a new virtual node that should replace
# the passed in virtual node. This is because a virtual node can be
# updated with an element referencing a different component!
# 
# In that case, `updateVirtualNode` will unmount the input virtual node,
# mount a new virtual node, and return it in this case, while also issuing
# a warning to the user.
func update_virtual_node(node: VirtualNode, new_element: Element, new_state = null) -> VirtualNode:
    # if nothing changed, we can skip this update
    if node.current_element == new_element and (new_state == null):
        return node
    
    if not new_element:
        unmount_virtual_node(node)
        return null
    
    if node.current_element.component != new_element.component:
        return replace_virtual_node(node, new_element)
    
    var should_continue_update: bool = true

    # run update function based on element type
    # todo make enum for element kinds
    var kind: Element.ElementKind = node.current_element.element_kind
    match kind:
        Element.ElementKind.Host:
            node = renderer.update_host_node(self, node, new_element)
        Element.ElementKind.Function:
            node = update_function_virtual_node(node, new_element)
        Element.ElementKind.Stateful:
            should_continue_update = node.instance.update(new_element, new_state)
        Element.ElementKind.Portal: #todo portals later
            node = update_portal_virtual_node(node, new_element)
        Element.ElementKind.Fragment:
            node = update_fragment_virtual_node(node, new_element)
        _:
            printerr("Unknown ElementKind: ", kind)
    
    # Stateful components can abort updates via shouldUpdate. If that
    # happens, we should stop doing stuff at this point.
    if not should_continue_update:
        return node
    
    node.current_element = new_element
    
    return node

func create_virtual_node(element: Element, host_parent, host_key: String, context = null, legacy_context = null) -> VirtualNode:
    return VirtualNode.new(element, host_parent, host_key, context, legacy_context)

func mount_function_virtual_node(virtual_node: VirtualNode):
    # component is a Callable
    var element: Element = virtual_node.current_element
    var children = element.component.call(element.props)
    update_virtual_node_with_render_result(virtual_node, virtual_node.host_parent, children)

func mount_portal_virtual_node(_virtual_node: VirtualNode): #todo portals later
    pass

func mount_fragment_virtual_node(virtual_node):
    var element: Element = virtual_node.current_element #FragmentElement
    var children = element.elements
    update_virtual_node_with_children(virtual_node, virtual_node.host_parent, children)

func mount_virtual_node(element, host_parent, host_key: String, context = null, legacy_context = null) -> VirtualNode:
    
    # Boolean values render as nil to enable terse conditional rendering (from roact)
    if element is bool:
        return null

    # todo make enum for element kinds
    var kind: Element.ElementKind = element.element_kind

    var virtual_node: VirtualNode = create_virtual_node(element, host_parent, host_key, context, legacy_context)

    # call mounting function based on type of element
    match kind:
        Element.ElementKind.Host:
            renderer.mount_host_node(self, virtual_node)
        Element.ElementKind.Function:
            mount_function_virtual_node(virtual_node)
        Element.ElementKind.Stateful:
            # mount is static member of Component, but it needs to be able to use itself as an "instance of Component", so this is a sort of pseudo self variable so it can refer to and pass around the static class.
            element.component.__mount(element.component, self, virtual_node)
        Element.ElementKind.Portal: #todo portals later
            mount_portal_virtual_node(virtual_node)
        Element.ElementKind.Fragment:
            mount_fragment_virtual_node(virtual_node)
        _:
            printerr("Unknown ElementKind: ", kind)
    
    return virtual_node

# Constructs a new Roact virtual tree, constructs a root node for
# it, and mounts it.
func mount_virtual_tree(element: Element, hostParent, hostKey: String = "GoactTree") -> VirtualTree:
    var tree: VirtualTree = VirtualTree.new()
    tree.set_root_node(mount_virtual_node(element, hostParent, hostKey))
    return tree

# Unmounts the virtual tree, freeing all of its resources.
# No further operations should be done on the tree after it's been
# unmounted, as indicated by its the `mounted` field.
func unmount_virtual_tree(tree: VirtualTree):
    tree.mounted = false
    if not tree.root_node:
        return
    unmount_virtual_node(tree.root_node)

# Utility method for updating the root node of a virtual tree given a new
# element.
func update_virtual_tree(tree: VirtualTree, new_element: Element) -> VirtualTree:
    tree.root_node = update_virtual_node(tree.root_node, new_element)
    return tree

func _init(_renderer: Renderer):
    self.renderer = _renderer
